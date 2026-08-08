import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:iconsax/iconsax.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

/// Soft App Store update prompt. Compares the installed version to the
/// live store listing and asks once per newer store version.
class AppUpdateService {
  AppUpdateService._();

  static const appStoreId = '6741811055';
  static const _dismissedVersionKey = 'update_prompt_dismissed_version';
  static const _storeUrl = 'https://apps.apple.com/app/id$appStoreId';
  static const _brandBlue = Color(0xFF4979FB);

  static bool _promptShownThisSession = false;

  /// Call after the first frame when a [BuildContext] with a Navigator exists.
  static Future<void> maybePrompt(BuildContext? context) async {
    if (context == null || !context.mounted) return;
    if (_promptShownThisSession) return;
    if (kIsWeb || !Platform.isIOS) return;

    try {
      final result = await _check();
      if (result == null || !result.updateAvailable) return;

      final prefs = await SharedPreferences.getInstance();
      final dismissed = prefs.getString(_dismissedVersionKey);
      if (dismissed == result.storeVersion) return;

      if (!context.mounted) return;
      _promptShownThisSession = true;
      await _showSheet(context, result);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('App update check skipped: $e');
      }
    }
  }

  static Future<_UpdateCheckResult?> _check() async {
    final info = await PackageInfo.fromPlatform();
    final current = info.version;

    final uri = Uri.https('itunes.apple.com', '/lookup', {
      'id': appStoreId,
      'country': 'us',
    });
    final response = await http.get(uri).timeout(const Duration(seconds: 8));
    if (response.statusCode != 200) return null;

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final results = body['results'] as List<dynamic>?;
    if (results == null || results.isEmpty) return null;

    final listing = results.first as Map<String, dynamic>;
    final storeVersion = listing['version'] as String?;
    if (storeVersion == null || storeVersion.isEmpty) return null;

    final notes = listing['releaseNotes'] as String?;

    return _UpdateCheckResult(
      currentVersion: current,
      storeVersion: storeVersion,
      updateAvailable: _isNewer(storeVersion, current),
      releaseNotes: notes,
    );
  }

  /// True when [a] is a higher semver than [b] (ignores build numbers).
  static bool _isNewer(String a, String b) {
    final pa = _parse(a);
    final pb = _parse(b);
    for (var i = 0; i < 3; i++) {
      if (pa[i] > pb[i]) return true;
      if (pa[i] < pb[i]) return false;
    }
    return false;
  }

  static List<int> _parse(String version) {
    final parts = version.split('+').first.split('.');
    return List<int>.generate(3, (i) {
      if (i >= parts.length) return 0;
      return int.tryParse(parts[i]) ?? 0;
    });
  }

  static List<String> _parseNotes(String? raw) {
    if (raw == null || raw.trim().isEmpty) return const [];
    return raw
        .split(RegExp(r'[\r\n]+'))
        .map((l) => l.trim())
        .map((l) => l.replaceFirst(RegExp(r'^[-•*]\s*'), ''))
        .where((l) => l.isNotEmpty)
        .toList();
  }

  static Future<void> _showSheet(
    BuildContext context,
    _UpdateCheckResult result,
  ) async {
    final notes = _parseNotes(result.releaseNotes);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (sheetContext) {
        final bottom = MediaQuery.paddingOf(sheetContext).bottom;
        final textColor =
            Theme.of(sheetContext).colorScheme.inversePrimary;
        final surface = Theme.of(sheetContext).colorScheme.surface;

        return Padding(
          padding: EdgeInsets.only(bottom: bottom),
          child: Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [_brandBlue, Color(0xFF5C89FF)],
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Iconsax.refresh_circle,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Update available',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Version ${result.storeVersion}',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: _brandBlue,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You’re on ${result.currentVersion}',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  if (notes.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Text(
                      'What’s new',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.32,
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            for (final note in notes)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      margin: const EdgeInsets.only(top: 6),
                                      width: 6,
                                      height: 6,
                                      decoration: const BoxDecoration(
                                        color: _brandBlue,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        note,
                                        style: GoogleFonts.poppins(
                                          fontSize: 13.5,
                                          height: 1.4,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _brandBlue,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () async {
                        final uri = Uri.parse(_storeUrl);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(
                            uri,
                            mode: LaunchMode.externalApplication,
                          );
                        }
                        if (sheetContext.mounted) {
                          Navigator.pop(sheetContext);
                        }
                      },
                      child: Text(
                        'Update on the App Store',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  TextButton(
                    onPressed: () async {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setString(
                        _dismissedVersionKey,
                        result.storeVersion,
                      );
                      if (sheetContext.mounted) {
                        Navigator.pop(sheetContext);
                      }
                    },
                    child: Text(
                      'Not now',
                      style: GoogleFonts.poppins(
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _UpdateCheckResult {
  const _UpdateCheckResult({
    required this.currentVersion,
    required this.storeVersion,
    required this.updateAvailable,
    this.releaseNotes,
  });

  final String currentVersion;
  final String storeVersion;
  final bool updateAvailable;
  final String? releaseNotes;
}
