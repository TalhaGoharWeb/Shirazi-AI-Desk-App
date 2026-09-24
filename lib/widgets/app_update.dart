import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ota_update/ota_update.dart';

import '../core/localization/app_strings.dart';
import '../core/theme/shirazi_colors.dart';
import '../core/theme/shirazi_typography.dart';
import '../services/update_service.dart';

/// Shows the "update available" dialog. Called on startup (MainShell) and
/// from the manual "Check for Updates" row in the profile screen.
void showUpdateAvailableDialog(BuildContext context, UpdateInfo info) {
  final strings = AppStrings.of(context);
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: ShiraziColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          const Icon(Icons.system_update_rounded,
              color: ShiraziColors.primary, size: 26),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              strings.updateAvailableTitle,
              style: ShiraziTypography.dynamicHeadline(strings.lang, fontSize: 17),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            strings.updateAvailableBody(info.latestVersion),
            style: ShiraziTypography.dynamicBody(strings.lang, fontSize: 13.5),
          ),
          if (info.apkSizeLabel.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              info.apkSizeLabel,
              style: ShiraziTypography.dynamicLabel(strings.lang,
                  fontSize: 12, color: ShiraziColors.onSurfaceVariant),
            ),
          ],
          if (info.releaseNotes.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              constraints: const BoxConstraints(maxHeight: 140),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: ShiraziColors.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: SingleChildScrollView(
                child: Text(
                  info.releaseNotes.trim(),
                  style: ShiraziTypography.dynamicBody(strings.lang,
                      fontSize: 12.5),
                ),
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () async {
            await UpdateService().dismissVersion(info.latestVersion);
            if (dialogContext.mounted) Navigator.of(dialogContext).pop();
          },
          child: Text(
            strings.remindLaterAction,
            style: ShiraziTypography.dynamicLabel(strings.lang,
                color: ShiraziColors.onSurfaceVariant),
          ),
        ),
        FilledButton.icon(
          onPressed: () {
            Navigator.of(dialogContext).pop();
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (_) => _DownloadProgressDialog(info: info),
            );
          },
          icon: const Icon(Icons.download_rounded, size: 18),
          label: Text(
            strings.updateNowAction,
            style: ShiraziTypography.dynamicLabel(strings.lang,
                color: Colors.white),
          ),
          style: FilledButton.styleFrom(
            backgroundColor: ShiraziColors.primary,
            foregroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    ),
  );
}

/// Manual check from the profile screen's "Check for Updates" row.
Future<void> manualUpdateCheck(BuildContext context) async {
  final strings = AppStrings.of(context);
  final messenger = ScaffoldMessenger.of(context);

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(child: CircularProgressIndicator()),
  );
  final info = await UpdateService().checkForUpdate(includeDismissed: true);
  if (!context.mounted) return;
  Navigator.of(context, rootNavigator: true).pop();

  if (info == null) {
    messenger
        .showSnackBar(SnackBar(content: Text(strings.updateCheckFailedMessage)));
  } else if (info.available) {
    showUpdateAvailableDialog(context, info);
  } else {
    messenger.showSnackBar(SnackBar(content: Text(strings.appUpToDateMessage)));
  }
}

/// Download progress dialog. Owns the ota_update stream; closes itself when
/// the system installer takes over (or on error, shows a retry dismissal).
class _DownloadProgressDialog extends StatefulWidget {
  final UpdateInfo info;
  const _DownloadProgressDialog({required this.info});

  @override
  State<_DownloadProgressDialog> createState() =>
      _DownloadProgressDialogState();
}

class _DownloadProgressDialogState extends State<_DownloadProgressDialog> {
  double _progress = 0;
  bool _failed = false;
  StreamSubscription<OtaEvent>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = UpdateService().downloadAndInstall(widget.info.apkUrl).listen(
      (OtaEvent event) {
        if (!mounted) return;
        final status = event.status.toString().toUpperCase();
        if (status.contains('ERROR')) {
          setState(() => _failed = true);
        } else if (status.contains('INSTALLING')) {
          // The Android install prompt takes over from here.
          Navigator.of(context, rootNavigator: true).pop();
        } else if (status.contains('DOWNLOAD')) {
          final pct = double.tryParse(event.value ?? '');
          if (pct != null) setState(() => _progress = pct.clamp(0, 100));
        }
      },
      onError: (_) {
        if (mounted) setState(() => _failed = true);
      },
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return AlertDialog(
      backgroundColor: ShiraziColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          if (_failed) ...[
            const Icon(Icons.error_outline_rounded,
                color: ShiraziColors.error, size: 44),
            const SizedBox(height: 12),
            Text(
              strings.updateCheckFailedMessage,
              textAlign: TextAlign.center,
              style:
                  ShiraziTypography.dynamicBody(strings.lang, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () =>
                  Navigator.of(context, rootNavigator: true).pop(),
              child: Text(strings.cancelAction),
            ),
          ] else ...[
            Text(
              strings.downloadingUpdateMessage,
              style:
                  ShiraziTypography.dynamicBody(strings.lang, fontSize: 13.5),
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value:
                  _progress <= 0 ? null : (_progress / 100).clamp(0.0, 1.0),
              backgroundColor: ShiraziColors.primary.withValues(alpha: 0.2),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(ShiraziColors.primary),
              borderRadius: BorderRadius.circular(8),
              minHeight: 8,
            ),
            const SizedBox(height: 8),
            Text(
              _progress <= 0 ? '…' : '${_progress.toStringAsFixed(0)}%',
              style: ShiraziTypography.dynamicLabel(strings.lang,
                  fontSize: 12, color: ShiraziColors.onSurfaceVariant),
            ),
          ],
        ],
      ),
    );
  }
}
