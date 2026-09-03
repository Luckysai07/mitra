import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/constants/app_constants.dart';

/// Data class representing update check result.
class AppUpdateInfo {
  final bool isUpdateAvailable;
  final String currentVersion;
  final String latestVersion;
  final String releaseName;
  final String releaseNotes;
  final String downloadUrl;
  final DateTime? publishedAt;

  const AppUpdateInfo({
    required this.isUpdateAvailable,
    required this.currentVersion,
    required this.latestVersion,
    required this.releaseName,
    required this.releaseNotes,
    required this.downloadUrl,
    this.publishedAt,
  });
}

/// Service to check for new app versions on GitHub Releases and prompt user to update.
class AppUpdateService {
  AppUpdateService._();

  /// Checks GitHub Releases API to see if a newer version of Mitra is available.
  static Future<AppUpdateInfo> checkForUpdate() async {
    String currentVersion = AppConstants.appVersion;

    try {
      final pkg = await PackageInfo.fromPlatform();
      if (pkg.version.isNotEmpty) {
        currentVersion = pkg.version;
      }
    } catch (_) {}

    if (kIsWeb) {
      return AppUpdateInfo(
        isUpdateAvailable: false,
        currentVersion: currentVersion,
        latestVersion: currentVersion,
        releaseName: 'Mitra Web',
        releaseNotes: '',
        downloadUrl: AppConstants.vercelDownloadUrl,
      );
    }

    try {
      final uri = Uri.parse(AppConstants.githubReleasesApiUrl);
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 8);

      final request = await client.getUrl(uri);
      request.headers.set(HttpHeaders.userAgentHeader, 'Mitra-App');
      request.headers.set(HttpHeaders.acceptHeader, 'application/vnd.github.v3+json');

      final response = await request.close();
      if (response.statusCode == 200) {
        final responseBody = await response.transform(utf8.decoder).join();
        final Map<String, dynamic> data = jsonDecode(responseBody);

        final rawTagName = (data['tag_name'] as String? ?? '').replaceAll('v', '').trim();
        final releaseName = data['name'] as String? ?? 'Mitra Update';
        final releaseNotes = data['body'] as String? ?? 'Exciting new features and bug fixes!';
        final publishedAtStr = data['published_at'] as String?;
        final publishedAt = publishedAtStr != null ? DateTime.tryParse(publishedAtStr) : null;

        // Extract semantic version string from releaseName or rawTagName
        String resolvedLatestVersion = rawTagName;
        final semverRegex = RegExp(r'(\d+\.\d+\.\d+)');
        final match = semverRegex.firstMatch(releaseName) ?? semverRegex.firstMatch(rawTagName);
        if (match != null) {
          resolvedLatestVersion = match.group(1)!;
        }

        // Locate APK download asset
        String downloadUrl = AppConstants.vercelDownloadUrl;
        final assets = data['assets'] as List<dynamic>? ?? [];
        for (final asset in assets) {
          final assetName = asset['name'] as String? ?? '';
          if (assetName.endsWith('.apk')) {
            downloadUrl = asset['browser_download_url'] as String? ?? downloadUrl;
            break;
          }
        }

        // Compare versions strictly (returns true ONLY if latest is higher than current)
        final isNewer = _isNewerVersion(currentVersion, resolvedLatestVersion);

        return AppUpdateInfo(
          isUpdateAvailable: isNewer,
          currentVersion: currentVersion,
          latestVersion: resolvedLatestVersion.isNotEmpty ? resolvedLatestVersion : currentVersion,
          releaseName: releaseName,
          releaseNotes: releaseNotes,
          downloadUrl: downloadUrl,
          publishedAt: publishedAt,
        );
      }
    } catch (e) {
      debugPrint('Update check warning: $e');
    }

    return AppUpdateInfo(
      isUpdateAvailable: false,
      currentVersion: currentVersion,
      latestVersion: currentVersion,
      releaseName: 'Mitra',
      releaseNotes: '',
      downloadUrl: AppConstants.vercelDownloadUrl,
    );
  }

  /// Compares current version e.g. "1.0.1" vs latest version "1.0.2".
  /// Returns true ONLY if the remote version is strictly higher.
  static bool _isNewerVersion(String current, String latest) {
    if (latest.isEmpty || latest.toLowerCase() == 'latest') return false;

    try {
      final cleanCurrent = current.split('+').first.split('-').first.trim();
      final cleanLatest = latest.split('+').first.split('-').first.trim();

      if (cleanCurrent == cleanLatest) return false;

      final currentParts = cleanCurrent.split('.').map((p) => int.tryParse(p) ?? 0).toList();
      final latestParts = cleanLatest.split('.').map((p) => int.tryParse(p) ?? 0).toList();

      while (currentParts.length < 3) currentParts.add(0);
      while (latestParts.length < 3) latestParts.add(0);

      for (int i = 0; i < 3; i++) {
        if (latestParts[i] > currentParts[i]) return true;
        if (latestParts[i] < currentParts[i]) return false;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Launches APK download link in external browser to trigger immediate mobile install.
  static Future<bool> launchDownload(String url) async {
    final downloadUrlStr = url.isNotEmpty ? url : AppConstants.apkDownloadUrl;
    final targetUri = Uri.parse(downloadUrlStr);

    try {
      final launched = await launchUrl(
        targetUri,
        mode: LaunchMode.externalApplication,
      );
      if (launched) return true;
    } catch (_) {}

    // Fallback mode for web and browsers that restrict direct application launch
    try {
      return await launchUrl(
        targetUri,
        mode: LaunchMode.platformDefault,
      );
    } catch (e) {
      debugPrint('Launch download error: $e');
      return false;
    }
  }
}
