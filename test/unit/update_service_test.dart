import 'package:flutter_test/flutter_test.dart';
import 'package:cently/services/update_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const String _releaseJson = '''
{
  "tag_name": "v1.1.0",
  "html_url": "https://github.com/e69d8e/Cently/releases/tag/v1.1.0",
  "body": "## 新功能\\n- 支持检查更新",
  "published_at": "2026-10-01T12:00:00Z"
}
''';

http.Response _jsonResponse(String body, [int status = 200]) =>
    http.Response(body, status, headers: {'content-type': 'application/json'});

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('compareVersions', () {
    test('equal versions return 0', () {
      expect(compareVersions('1.0.4', '1.0.4'), 0);
    });

    test('patch segment comparison', () {
      expect(compareVersions('1.0.5', '1.0.4'), 1);
      expect(compareVersions('1.0.4', '1.0.5'), -1);
    });

    test('multi-digit segments compare numerically', () {
      expect(compareVersions('1.0.10', '1.0.9'), 1);
      expect(compareVersions('1.0.2', '1.0.10'), -1);
    });

    test('major and minor segments dominate lower segments', () {
      expect(compareVersions('2.0.0', '1.9.9'), 1);
      expect(compareVersions('1.1.0', '1.0.99'), 1);
    });

    test('shorter version is padded with zeros', () {
      expect(compareVersions('1.0', '1.0.0'), 0);
      expect(compareVersions('1', '1.0.1'), -1);
    });

    test('non-numeric segment throws FormatException', () {
      expect(() => compareVersions('v1.0.5', '1.0.4'), throwsFormatException);
      expect(() => compareVersions('1.0.4+5', '1.0.4'), throwsFormatException);
      expect(() => compareVersions('1..0', '1.0.0'), throwsFormatException);
      expect(() => compareVersions('abc', '1.0.0'), throwsFormatException);
    });
  });

  group('UpdateInfo.fromGitHubJson', () {
    test('parses tag prefix, url, notes and date', () {
      final info = UpdateInfo.fromGitHubJson(
        {
          'tag_name': 'v1.1.0',
          'html_url': 'https://github.com/e69d8e/Cently/releases/tag/v1.1.0',
          'body': '更新说明',
          'published_at': '2026-10-01T12:00:00Z',
        } as Map<String, dynamic>,
      );
      expect(info.version, '1.1.0');
      expect(info.releaseUrl, 'https://github.com/e69d8e/Cently/releases/tag/v1.1.0');
      expect(info.releaseNotes, '更新说明');
      expect(info.publishedAt, '2026-10-01T12:00:00Z');
    });

    test('missing body falls back to placeholder note', () {
      final info = UpdateInfo.fromGitHubJson(
        {'tag_name': '1.2.0', 'html_url': 'https://example.com'} as Map<String, dynamic>,
      );
      expect(info.version, '1.2.0');
      expect(info.releaseNotes, isNotEmpty);
    });

    test('missing html_url falls back to releases page', () {
      final info = UpdateInfo.fromGitHubJson(
        {'tag_name': 'v1.2.0', 'body': 'x'} as Map<String, dynamic>,
      );
      expect(info.releaseUrl, 'https://github.com/e69d8e/Cently/releases');
    });

    test('empty tag_name throws FormatException', () {
      expect(
        () => UpdateInfo.fromGitHubJson({'tag_name': '  '} as Map<String, dynamic>),
        throwsFormatException,
      );
    });
  });

  group('UpdateService.checkForUpdate', () {
    test('returns UpdateInfo when remote is newer', () async {
      late http.Request captured;
      final service = UpdateService(
        httpClient: MockClient((request) async {
          captured = request;
          return _jsonResponse(_releaseJson);
        }),
      );

      final info = await service.checkForUpdate(currentVersion: '1.0.4');

      expect(info, isNotNull);
      expect(info!.version, '1.1.0');
      expect(info.releaseUrl, 'https://github.com/e69d8e/Cently/releases/tag/v1.1.0');
      expect(info.releaseNotes, contains('检查更新'));
      expect(captured.url.toString(), 'https://api.github.com/repos/e69d8e/Cently/releases/latest');
      final headers = {
        for (final e in captured.headers.entries) e.key.toLowerCase(): e.value,
      };
      expect(headers['accept'], 'application/vnd.github+json');
      expect(headers['user-agent'], 'Cently-App');
    });

    test('returns null when versions are equal', () async {
      final service = UpdateService(
        httpClient: MockClient((request) async => _jsonResponse(_releaseJson)),
      );
      expect(await service.checkForUpdate(currentVersion: '1.1.0'), isNull);
    });

    test('returns null when remote is older', () async {
      final service = UpdateService(
        httpClient: MockClient((request) async => _jsonResponse(_releaseJson)),
      );
      expect(await service.checkForUpdate(currentVersion: '1.2.0'), isNull);
    });

    test('returns null on 404 (no releases yet)', () async {
      final service = UpdateService(
        httpClient: MockClient((request) async => _jsonResponse('{}', 404)),
      );
      expect(await service.checkForUpdate(currentVersion: '1.0.4'), isNull);
    });

    test('throws UpdateCheckException on server error', () async {
      final service = UpdateService(
        httpClient: MockClient((request) async => _jsonResponse('oops', 500)),
      );
      expect(
        () => service.checkForUpdate(currentVersion: '1.0.4'),
        throwsA(isA<UpdateCheckException>()),
      );
    });

    test('throws UpdateCheckException on network failure', () async {
      final service = UpdateService(
        httpClient: MockClient((request) async => throw http.ClientException('offline')),
      );
      expect(
        () => service.checkForUpdate(currentVersion: '1.0.4'),
        throwsA(isA<UpdateCheckException>()),
      );
    });

    test('throws UpdateCheckException on malformed payload', () async {
      final service = UpdateService(
        httpClient: MockClient((request) async => _jsonResponse('not-json')),
      );
      expect(
        () => service.checkForUpdate(currentVersion: '1.0.4'),
        throwsA(isA<UpdateCheckException>()),
      );
    });

    test('returns null when versions cannot be compared', () async {
      final service = UpdateService(
        httpClient: MockClient((request) async => _jsonResponse(_releaseJson)),
      );
      expect(await service.checkForUpdate(currentVersion: 'dev-build'), isNull);
    });

    test('honors injected endpoint URL', () async {
      late http.Request captured;
      final service = UpdateService(
        httpClient: MockClient((request) async {
          captured = request;
          return _jsonResponse(_releaseJson);
        }),
        latestReleaseUrl: 'https://example.com/api/latest',
      );

      await service.checkForUpdate(currentVersion: '1.0.4');
      expect(captured.url.toString(), 'https://example.com/api/latest');
    });
  });

  group('UpdateService.loadAppVersion', () {
    test('falls back to kFallbackAppVersion when PackageInfo is unavailable', () async {
      // 测试环境没有 package_info 插件，应静默回退而非抛异常
      final version = await UpdateService.loadAppVersion();
      expect(version, kFallbackAppVersion);
    });
  });
}
