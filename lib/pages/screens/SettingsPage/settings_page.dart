import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:jadwal/pages/auth/auth_page.dart';
import 'package:jadwal/pages/onboarding/onboarding.dart';
import 'package:jadwal/pages/screens/SettingsPage/about_app_page.dart';
import 'package:jadwal/pages/screens/SettingsPage/delete_account_page.dart';
import 'package:jadwal/pages/screens/ProfilePage/edit_profile_page.dart';
import 'package:jadwal/pages/screens/SettingsPage/feedback_page.dart';
import 'package:jadwal/pages/screens/SettingsPage/help_support_page.dart';
import 'package:jadwal/pages/screens/SettingsPage/password_security_page.dart';
import 'package:jadwal/pages/screens/SettingsPage/notifications_page.dart';
import 'package:jadwal/pages/screens/SettingsPage/privacy_policy_page.dart';
import 'package:jadwal/pages/screens/SettingsPage/terms_service_page.dart';
import 'package:jadwal/pages/screens/SettingsPage/usage_mode_page.dart';
import 'package:jadwal/pages/screens/PaywallPage/paywall_page.dart';
import 'package:jadwal/services/notification_service.dart';
import 'package:jadwal/services/subscription_service.dart';
import 'package:provider/provider.dart';
import 'package:jadwal/themes/theme_provider.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool isPushNotificationsEnabled = true;
  bool isEmailNotificationsEnabled = false;
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _loadNotificationPrefs();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (!mounted) return;
      setState(() => _appVersion = info.version);
    } catch (_) {
      // Keep empty — tile falls back to generic copy.
    }
  }

  Future<void> _loadNotificationPrefs() async {
    final prefs = await NotificationService.instance.loadPreferences();
    if (mounted) {
      setState(() {
        isPushNotificationsEnabled = prefs.pushNotificationsEnabled;
        isEmailNotificationsEnabled = prefs.emailNotificationsEnabled;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        title: Text(
          'Settings',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 22,
            color: Theme.of(context).colorScheme.inversePrimary,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
              color: Theme.of(context).colorScheme.inversePrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // App Settings Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4979FB), Color(0xFF5C89FF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4979FB).withValues(alpha: 0.2),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Icon container
                      Container(
                        height: 50,
                        width: 50,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Iconsax.setting_3,
                          size: 28,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 20),
                      // Text content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'App Settings',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Customise your app experience',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // Profile Section
                _buildSectionHeader('Profile', Iconsax.user),
                const SizedBox(height: 10),
                _buildSettingCard([
                  _buildSettingTile(
                    icon: Iconsax.edit,
                    title: 'Edit Profile',
                    description: 'Update your personal information',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const EditProfilePage(),
                        ),
                      );
                    },
                  ),
                  _buildSettingTile(
                    icon: Iconsax.lock,
                    title: 'Password & Security',
                    description: 'Manage your account security',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PasswordSecurityPage(),
                        ),
                      );
                    },
                  ),
                  _buildSettingTile(
                    icon: Iconsax.message_text,
                    title: 'Send Feedback',
                    description: 'Help us improve the app',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const FeedbackPage(),
                        ),
                      );
                    },
                    isLast: true,
                  ),
                ]),

                const SizedBox(height: 24),

                // Subscription Section
                _buildSectionHeader('Subscription', Iconsax.crown_1),
                const SizedBox(height: 10),
                Consumer<SubscriptionService>(
                  builder: (context, sub, _) => _buildSettingCard([
                    _buildSettingTile(
                      icon: Iconsax.crown_1,
                      title: sub.isPro ? 'Jadwal Pro' : 'Upgrade to Pro',
                      description: sub.isPro
                          ? (sub.renewalLabel ??
                              'Unlimited quizzes and Pro quiz types')
                          : 'Unlock Fill in the Blank, speech quizzes & more',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PaywallPage(),
                          ),
                        );
                      },
                    ),
                    _buildSettingTile(
                      icon: Iconsax.refresh,
                      title: 'Restore purchases',
                      description: 'Recover a previous Pro subscription',
                      onTap: () async {
                        final ok = await sub.restorePurchases();
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              ok
                                  ? 'Subscription restored'
                                  : 'No active subscription found',
                            ),
                          ),
                        );
                      },
                      isLast: true,
                    ),
                  ]),
                ),

                const SizedBox(height: 24),

                // Preferences Section
                _buildSectionHeader('Preferences', Iconsax.setting),
                const SizedBox(height: 10),
                _buildSettingCard([
                  _buildSettingTile(
                    icon: Iconsax.chart,
                    title: 'Memorisation Mode',
                    description: 'Choose how structured your experience is',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const UsageModePage(),
                        ),
                      );
                    },
                    trailing: Icon(
                      Iconsax.arrow_right_3,
                      size: 16,
                      color: Colors.grey[400],
                    ),
                  ),
                  _buildSettingTile(
                    icon: Iconsax.notification,
                    title: 'Notifications',
                    description: 'Configure app alerts',
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => NotificationsPage(
                            initialPushNotificationsValue:
                                isPushNotificationsEnabled,
                            initialEmailNotificationsValue:
                                isEmailNotificationsEnabled,
                          ),
                        ),
                      );

                      if (result != null && result is Map) {
                        setState(() {
                          isPushNotificationsEnabled =
                              result['pushNotificationsEnabled'] as bool? ??
                                  isPushNotificationsEnabled;
                          isEmailNotificationsEnabled =
                              result['emailNotificationsEnabled'] as bool? ??
                                  isEmailNotificationsEnabled;
                        });
                      }
                    },
                    trailing: Icon(
                      Iconsax.arrow_right_3,
                      size: 16,
                      color: Colors.grey[400],
                    ),
                  ),
                  _buildSettingTile(
                    icon: Iconsax.moon,
                    title: 'Theme Mode',
                    description: themeProvider.useSystemTheme
                        ? 'Automatic (follows system)'
                        : themeProvider.isDarkMode
                            ? 'Dark mode'
                            : 'Light mode',
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Automatic theme toggle
                        GestureDetector(
                          onTap: () {
                            if (themeProvider.useSystemTheme) {
                              // Switch to manual mode with current theme
                              themeProvider.setSystemTheme(false);
                            } else {
                              // Switch to automatic mode
                              themeProvider.setSystemTheme(true);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: themeProvider.useSystemTheme
                                  ? const Color(0xFF4979FB)
                                  : Colors.grey[300],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Auto',
                              style: GoogleFonts.poppins(
                                color: themeProvider.useSystemTheme
                                    ? Colors.white
                                    : Colors.grey[700],
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Manual light/dark toggle (only enabled in manual mode)
                        if (!themeProvider.useSystemTheme)
                          Switch(
                            value: themeProvider.isDarkMode,
                            onChanged: (value) {
                              themeProvider.toggleTheme();
                            },
                            activeThumbColor: const Color(0xFF4979FB),
                            inactiveThumbColor: Colors.grey[300],
                            trackOutlineColor: WidgetStateProperty.all(
                              themeProvider.isDarkMode
                                  ? Colors.transparent
                                  : Colors.grey[300],
                            ),
                          ),
                      ],
                    ),
                    isLast: true,
                  ),
                ]),

                const SizedBox(height: 24),

                // Support & About Section
                _buildSectionHeader('Support & About', Iconsax.info_circle),
                const SizedBox(height: 10),
                _buildSettingCard([
                  _buildSettingTile(
                    icon: Iconsax.teacher,
                    title: 'Onboarding Tour',
                    description: 'Replay the intro walkthrough',
                    onTap: () {
                      OnboardingScreen.resetController();
                      Get.to(() => const OnboardingScreen(isReplay: true));
                    },
                  ),
                  _buildSettingTile(
                    icon: Iconsax.message_question,
                    title: 'Help & Support',
                    description: 'Get assistance with the app',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const HelpSupportPage(),
                        ),
                      );
                    },
                  ),
                  _buildSettingTile(
                    icon: Iconsax.shield,
                    title: 'Privacy Policy',
                    description: 'View our privacy policy',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PrivacyPolicyPage(),
                        ),
                      );
                    },
                  ),
                  _buildSettingTile(
                    icon: Iconsax.document_text,
                    title: 'Terms of Service',
                    description: 'View our terms of service',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const TermsServicePage(),
                        ),
                      );
                    },
                  ),
                  _buildSettingTile(
                    icon: Iconsax.information,
                    title: 'About App',
                    description: _appVersion.isEmpty
                        ? 'App information'
                        : 'Version $_appVersion',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AboutAppPage(),
                        ),
                      );
                    },
                    isLast: true,
                  ),
                ]),

                const SizedBox(height: 30),

                // Account actions
                _buildAccountActionButtons(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: const Color(0xFF4979FB),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.inversePrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.3),
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String description,
    Widget? trailing,
    VoidCallback? onTap,
    bool isLast = false,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4979FB).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: const Color(0xFF4979FB),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.inversePrimary,
                        ),
                      ),
                      Text(
                        description,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (trailing != null)
                  trailing
                else if (onTap != null)
                  Icon(
                    Iconsax.arrow_right_3,
                    size: 16,
                    color: Colors.grey[400],
                  ),
              ],
            ),
          ),
        ),
        if (!isLast)
          Divider(
              height: 1,
              thickness: 1,
              indent: 16,
              endIndent: 16,
              color: Theme.of(context).colorScheme.tertiary),
      ],
    );
  }

  Widget _buildAccountActionButtons() {
    return Column(
      children: [
        // Sign Out Button
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.3),
                blurRadius: 12,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                _showSignOutDialog();
              },
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Iconsax.logout,
                      size: 20,
                      color: const Color(0xFF4979FB),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Sign Out',
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF4979FB),
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Delete Account Button
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.3),
                blurRadius: 12,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DeleteAccountPage(),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Iconsax.trash,
                      size: 20,
                      color: Colors.red[400],
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Delete Account',
                      style: GoogleFonts.poppins(
                        color: Colors.red[400],
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showSignOutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Sign Out',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Are you sure you want to sign out?',
          style: GoogleFonts.poppins(),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(
                color: Colors.grey[700],
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4979FB),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            onPressed: () async {
              Navigator.pop(context); // Close dialog first
              await AuthPage.signOutToOnboarding(context);
            },
            child: Text(
              'Sign Out',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
