import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/update_service.dart';
import '../theme/app_colors.dart';

/// 展示「发现新版本」弹窗，手动检查与启动自动检查共用。
///
/// [currentVersion] 传入时正文会显示「当前版本 → 新版本」对比。
Future<void> showUpdateAvailableDialog(
  BuildContext context,
  UpdateInfo info, {
  String? currentVersion,
}) {
  return showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.rocket_launch_outlined, color: AppColors.primary),
          SizedBox(width: 8),
          Text('发现新版本'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            currentVersion == null
                ? '最新版本 v${info.version}'
                : '当前版本 v$currentVersion → 最新版本 v${info.version}',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 280),
            child: SingleChildScrollView(
              child: Text(
                info.releaseNotes,
                style: const TextStyle(fontSize: 13, height: 1.6),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('下次再说'),
        ),
        FilledButton(
          onPressed: () => _openReleasePage(context, ctx, info.releaseUrl),
          child: const Text('前往下载'),
        ),
      ],
    ),
  );
}

Future<void> _openReleasePage(
  BuildContext outerContext,
  BuildContext dialogContext,
  String releaseUrl,
) async {
  Navigator.pop(dialogContext);
  try {
    final uri = Uri.parse(releaseUrl);
    if (!await launchUrl(uri, mode: LaunchMode.platformDefault)) {
      throw Exception('launchUrl returned false');
    }
  } catch (e) {
    debugPrint('Error opening release page: $e');
    if (outerContext.mounted) {
      ScaffoldMessenger.of(outerContext).showSnackBar(
        SnackBar(content: Text('打开下载页失败，请访问 $releaseUrl')),
      );
    }
  }
}
