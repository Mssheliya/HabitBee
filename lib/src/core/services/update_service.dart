import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';

class UpdateInfo {
  final String version;
  final String name;
  final String body;
  final String downloadUrl;

  UpdateInfo({
    required this.version,
    required this.name,
    required this.body,
    required this.downloadUrl,
  });
}

class UpdateService {
  static const String _githubUser = 'Mssheliya';
  static const String _githubRepo = 'HabitBee';
  static const String _currentVersion = '1.0.0';

  static String get currentVersion => _currentVersion;

  static Future<UpdateInfo?> checkForUpdate() async {
    try {
      final response = await http.get(
        Uri.parse('https://api.github.com/repos/$_githubUser/$_githubRepo/releases/latest'),
        headers: {'Accept': 'application/vnd.github+json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final latestVersion = data['tag_name']?.toString().replaceFirst('v', '') ?? '1.0.0';

        if (_isNewerVersion(latestVersion, _currentVersion)) {
          String downloadUrl = '';
          if (data['assets'] != null && (data['assets'] as List).isNotEmpty) {
            for (var asset in data['assets']) {
              if (asset['name']?.toString().endsWith('.apk') == true) {
                downloadUrl = asset['browser_download_url'] ?? '';
                break;
              }
            }
          }

          return UpdateInfo(
            version: latestVersion,
            name: data['name'] ?? 'New Update',
            body: data['body'] ?? '',
            downloadUrl: downloadUrl.isNotEmpty 
                ? downloadUrl 
                : 'https://github.com/$_githubUser/$_githubRepo/releases',
          );
        }
      }
    } catch (e) {
      debugPrint('Update check failed: $e');
    }
    return null;
  }

  static bool _isNewerVersion(String latest, String current) {
    final latestParts = latest.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final currentParts = current.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    for (int i = 0; i < 3; i++) {
      final l = i < latestParts.length ? latestParts[i] : 0;
      final c = i < currentParts.length ? currentParts[i] : 0;
      if (l > c) return true;
      if (l < c) return false;
    }
    return false;
  }

  static Future<void> showUpdateDialog(BuildContext context, UpdateInfo updateInfo) async {
    final theme = Theme.of(context);
    
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: theme.cardTheme.color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.system_update, color: theme.colorScheme.primary, size: 28),
            const SizedBox(width: 12),
            const Text('Update Available'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Version ${updateInfo.version} is available!',
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'You\'re using version $_currentVersion',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (updateInfo.body.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                constraints: const BoxConstraints(maxHeight: 150),
                child: SingleChildScrollView(
                  child: Text(
                    updateInfo.body,
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(
              'Later',
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _launchDownload(updateInfo.downloadUrl);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Update Now'),
          ),
        ],
      ),
    );
  }

  static Future<void> _launchDownload(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        debugPrint('Could not launch URL: $url');
      }
    } catch (e) {
      debugPrint('Error launching URL: $e');
    }
  }
}
