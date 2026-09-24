import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:ota_update/ota_update.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Result of a GitHub release check.
class UpdateInfo {
  final bool available;
  final String currentVersion;
  final String latestVersion;
  final String releaseNotes;
  final String apkUrl;
  final int apkSizeBytes;

  const UpdateInfo({
    required this.available,
    required this.currentVersion,
    required this.latestVersion,
    required this.releaseNotes,
    required this.apkUrl,
    required this.apkSizeBytes,
  });

  String get apkSizeLabel {
    if (apkSizeBytes <= 0) return '';
    final mb = apkSizeBytes / (1024 * 1024);
    return '${mb.toStringAsFixed(1)} MB';
  }
}

/// Checks the app's GitHub releases for a newer APK and installs it.
///
/// Flow the user follows to ship an update:
/// 1. Bump `version:` in pubspec.yaml (e.g. 1.0.1+2).
/// 2. Commit, then `git tag v1.0.1 && git push origin v1.0.1`.
/// 3. The `release.yml` workflow builds the APK and attaches it to the
///    GitHub release. Devices pick it up on next launch (Android only;
///    the web build updates when it is redeployed).
class UpdateService {
  static const String _repo = 'TalhaGoharWeb/Shirazi-AI-Desk-App';
  static const String _dismissedVersionKey = 'update_dismissed_version';

  /// Returns update info, or null when the check does not apply / failed.
  /// When [includeDismissed] is false (startup check), a version the user
  /// already dismissed with "Later" is not reported again.
  Future<UpdateInfo?> checkForUpdate({bool includeDismissed = false}) async {
    if (!Platform.isAndroid) return null;
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final current = _normalizeVersion(packageInfo.version);

      final response = await http
          .get(
            Uri.parse('https://api.github.com/repos/$_repo/releases/latest'),
            headers: {'Accept': 'application/vnd.github+json'},
          )
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) return null;

      final Map<String, dynamic> release =
          jsonDecode(response.body) as Map<String, dynamic>;
      final latest = _normalizeVersion((release['tag_name'] ?? '').toString());
      if (latest.isEmpty) return null;

      String apkUrl = '';
      int apkSize = 0;
      final assets = release['assets'] as List<dynamic>? ?? [];
      for (final asset in assets) {
        final map = asset as Map<String, dynamic>;
        final name = (map['name'] ?? '').toString().toLowerCase();
        if (name.endsWith('.apk')) {
          apkUrl = (map['browser_download_url'] ?? '').toString();
          apkSize = (map['size'] as num?)?.toInt() ?? 0;
          break;
        }
      }

      final available = _isNewer(latest, current) && apkUrl.isNotEmpty;
      if (!available) return const UpdateInfo(
        available: false, currentVersion: '', latestVersion: '',
        releaseNotes: '', apkUrl: '', apkSizeBytes: 0,
      );

      if (!includeDismissed) {
        final prefs = await SharedPreferences.getInstance();
        if (prefs.getString(_dismissedVersionKey) == latest) {
          return const UpdateInfo(
            available: false, currentVersion: '', latestVersion: '',
            releaseNotes: '', apkUrl: '', apkSizeBytes: 0,
          );
        }
      }

      return UpdateInfo(
        available: true,
        currentVersion: current,
        latestVersion: latest,
        releaseNotes: (release['body'] ?? '').toString(),
        apkUrl: apkUrl,
        apkSizeBytes: apkSize,
      );
    } catch (e) {
      debugPrint('[UpdateService] update check failed: $e');
      return null;
    }
  }

  /// Remembers that the user dismissed [version] with "Later".
  Future<void> dismissVersion(String version) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_dismissedVersionKey, version);
  }

  /// Downloads the APK and hands it to the system installer.
  /// The returned stream emits progress; the Android install prompt
  /// appears automatically once the download completes.
  Stream<OtaEvent> downloadAndInstall(String apkUrl) {
    return OtaUpdate().execute(
      apkUrl,
      destinationFilename: 'shirazi-update.apk',
    );
  }

  static String _normalizeVersion(String v) {
    var s = v.trim();
    if (s.startsWith('v') || s.startsWith('V')) s = s.substring(1);
    return s.split('+').first;
  }

  /// True when [latest] is a higher semantic version than [current].
  static bool _isNewer(String latest, String current) {
    final l = _parts(latest);
    final c = _parts(current);
    for (var i = 0; i < 3; i++) {
      final li = i < l.length ? l[i] : 0;
      final ci = i < c.length ? c[i] : 0;
      if (li != ci) return li > ci;
    }
    return false;
  }

  static List<int> _parts(String v) =>
      v.split('.').map((e) => int.tryParse(e) ?? 0).toList();
}
