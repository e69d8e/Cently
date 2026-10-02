import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

/// 兜底版本号：仅在 PackageInfo 不可用（如部分 Web 环境）时使用，
/// 需与 pubspec.yaml 的 version 同步。
const String kFallbackAppVersion = '1.0.5';

/// GitHub 仓库的最新 Release API 地址与下载页地址。
const String kLatestReleaseApiUrl =
    'https://api.github.com/repos/e69d8e/Cently/releases/latest';
const String kReleasesPageUrl = 'https://github.com/e69d8e/Cently/releases';

/// 一个待安装的新版本信息。
class UpdateInfo {
  const UpdateInfo({
    required this.version,
    required this.releaseUrl,
    required this.releaseNotes,
    this.publishedAt,
  });

  /// 新版本号，如 '1.0.5'（已去除 tag 的 v 前缀）。
  final String version;

  /// Release 页面地址，用于跳转下载。
  final String releaseUrl;

  /// 发布说明原文（Markdown 源码，按纯文本展示）。
  final String releaseNotes;

  final String? publishedAt;

  factory UpdateInfo.fromGitHubJson(Map<String, dynamic> json) {
    final tagName = (json['tag_name'] as String? ?? '').trim();
    if (tagName.isEmpty) {
      throw const FormatException('tag_name is empty');
    }
    final body = json['body'] as String?;
    return UpdateInfo(
      version: _stripVersionPrefix(tagName),
      releaseUrl: json['html_url'] as String? ?? kReleasesPageUrl,
      releaseNotes: (body == null || body.trim().isEmpty)
          ? '本次更新暂无发布说明。'
          : body.trim(),
      publishedAt: json['published_at'] as String?,
    );
  }
}

/// 检查更新失败（网络异常、服务端错误等）。
class UpdateCheckException implements Exception {
  const UpdateCheckException(this.message);
  final String message;

  @override
  String toString() => 'UpdateCheckException: $message';
}

/// GitHub Release 检查更新服务。
///
/// 仅在用户开启自动检查或手动触发时访问 GitHub API，不上传任何本地数据；
/// 可注入 [client] 与 [latestReleaseUrl] 便于单测。
class UpdateService {
  UpdateService({http.Client? httpClient, String? latestReleaseUrl})
      : _client = httpClient,
        _latestReleaseUrl = latestReleaseUrl ?? kLatestReleaseApiUrl;

  static const Duration _timeout = Duration(seconds: 10);

  final http.Client? _client;
  final String _latestReleaseUrl;

  /// 读取当前应用版本号；PackageInfo 不可用时回退到 [kFallbackAppVersion]。
  static Future<String> loadAppVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (info.version.isNotEmpty) return info.version;
    } catch (e) {
      debugPrint('Error loading package info: $e');
    }
    return kFallbackAppVersion;
  }

  /// 检查是否有新版本。
  ///
  /// 返回 [UpdateInfo] 表示远端版本更新；返回 null 表示已是最新、
  /// 仓库暂无 Release 或版本号无法解析；网络 / 服务端异常抛
  /// [UpdateCheckException]。
  Future<UpdateInfo?> checkForUpdate({String? currentVersion}) async {
    final current = currentVersion ?? await loadAppVersion();
    final remote = await _fetchLatestRelease();
    if (remote == null) return null;

    try {
      final isNewer = compareVersions(remote.version, current) > 0;
      return isNewer ? remote : null;
    } on FormatException catch (e) {
      debugPrint('Error comparing versions: $e');
      return null;
    }
  }

  /// 请求最新 Release；404（尚无 Release）返回 null，其余失败抛异常。
  Future<UpdateInfo?> _fetchLatestRelease() async {
    final Uri uri;
    try {
      uri = Uri.parse(_latestReleaseUrl);
    } on FormatException catch (e) {
      throw UpdateCheckException('Invalid release URL: $e');
    }

    // 注入的 client 由调用方管理生命周期；自建的用完即关
    final client = _client;
    final bool ownedClient = client == null;
    final http.Client effectiveClient = client ?? http.Client();
    try {
      final http.Response response;
      try {
        response = await effectiveClient
            .get(
              uri,
              headers: const {
                'Accept': 'application/vnd.github+json',
                'User-Agent': 'Cently-App',
              },
            )
            .timeout(_timeout);
      } on TimeoutException {
        throw const UpdateCheckException('Request timed out');
      } catch (e) {
        throw UpdateCheckException('Network error: $e');
      }

      if (response.statusCode == 404) return null;
      if (response.statusCode != 200) {
        throw UpdateCheckException(
          'Unexpected status: ${response.statusCode}',
        );
      }

      try {
        final json = jsonDecode(utf8.decode(response.bodyBytes));
        if (json is! Map<String, dynamic>) {
          throw const UpdateCheckException('Unexpected response payload');
        }
        return UpdateInfo.fromGitHubJson(json);
      } on UpdateCheckException {
        rethrow;
      } catch (e) {
        throw UpdateCheckException('Failed to parse response: $e');
      }
    } finally {
      if (ownedClient) effectiveClient.close();
    }
  }
}

/// 去除版本 tag 的 v/V 前缀。
String _stripVersionPrefix(String tag) {
  final trimmed = tag.trim();
  if (trimmed.startsWith('v') || trimmed.startsWith('V')) {
    return trimmed.substring(1);
  }
  return trimmed;
}

/// 逐段数值比较两个点分版本号（如 '1.0.10' 与 '1.0.9'）。
///
/// 返回 -1 / 0 / 1；段数不等时低位补零；任何一段不是纯数字抛
/// [FormatException]。不接受构建号后缀（如 '+5'）。
int compareVersions(String a, String b) {
  final partsA = a.split('.');
  final partsB = b.split('.');
  final length = partsA.length > partsB.length ? partsA.length : partsB.length;

  for (var i = 0; i < length; i++) {
    final segA = i < partsA.length ? int.parse(partsA[i]) : 0;
    final segB = i < partsB.length ? int.parse(partsB[i]) : 0;
    if (segA != segB) return segA < segB ? -1 : 1;
  }
  return 0;
}
