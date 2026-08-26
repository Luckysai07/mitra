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

        final tagName = (data['tag_name'] as String? ?? '').replaceAll('v', '').trim();
        final releaseName = data['name'] as String? ?? 'Mitra Update';
        final releaseNotes = data['body'] as String? ?? 'Exciting new features and bug fixes!';
        final publishedAtStr = data['published_at'] as String?;
        final publishedAt = publishedAtStr != null ? DateTime.tryParse(publishedAtStr) : null;

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

        // Compare versions (semver or timestamp)
        final isNewer = _isNewerVersion(currentVersion, tagName);

        return AppUpdateInfo(
          isUpdateAvailable: isNewer,
          currentVersion: currentVersion,
          latestVersion: tagName.isNotEmpty ? tagName : 'Latest',
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

  /// Compares current version e.g. "1.0.0" vs latest version "1.0.1".
  static bool _isNewerVersion(String current, String latest) {
    if (latest.isEmpty) return false;
    if (latest.toLowerCase() == 'latest') return true;

    try {
      final currentParts = current.split('.').map((p) => int.tryParse(p) ?? 0).toList();
      final latestParts = latest.split('.').map((p) => int.tryParse(p) ?? 0).toList();

      while (currentParts.length < 3) currentParts.add(0);
      while (latestParts.length < 3) latestParts.add(0);

      for (int i = 0; i < 3; i++) {
        if (latestParts[i] > currentParts[i]) return true;
        if (latestParts[i] < currentParts[i]) return false;
      }
      return false;
    } catch (_) {
      return latest != current;
    }
  }

  /// Launches APK download link in external browser to trigger immediate mobile install.
  static Future<bool> launchDownload(String url) async {
    final targetUri = Uri.parse(url.isNotEmpty ? url : AppConstants.vercelDownloadUrl);
    try {
      return await launchUrl(
        targetUri,
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      debugPrint('Launch download error: $e');
      return false;
    }
  }
}
