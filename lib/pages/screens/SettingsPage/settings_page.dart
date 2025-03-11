import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage>
    with SingleTickerProviderStateMixin {
  bool isDarkMode = false;
  bool isPushNotificationsEnabled = true;
  bool isEmailNotificationsEnabled = false;

  @override
  Widget build(BuildContext context) {
    // Get current theme mode
    isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // App's primary blue color - CHANGE THIS TO MATCH YOUR APP'S BLUE
    final primaryBlue = const Color(
        0xFF1976D2); // Material Blue 700, replace with your app's blue

    // Derived colors based on primary blue
    final cardColor = Colors.white;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.only(top: 20.0, left: 20.0, right: 20.0),
        physics: const BouncingScrollPhysics(),
        children: [
          // Main Settings Section
          _buildSettingsGroups(context, primaryBlue, cardColor),

          // Sign Out Button
          const SizedBox(height: 40),
          _buildSignOutButton(context),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSettingsGroups(
      BuildContext context, Color primaryBlue, Color cardColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Appearance Section
        _buildSettingsHeader(Icons.palette_outlined, 'Appearance', primaryBlue),
        const SizedBox(height: 12),
        _buildSettingsCard(
          context,
          [
            _buildSwitchTile(
              context,
              title: 'Dark Mode',
              subtitle: 'Switch between light and dark themes',
              icon: Icons.dark_mode_outlined,
              value: isDarkMode,
              accentColor: primaryBlue,
              onChanged: (value) {
                setState(() {
                  isDarkMode = value;
                  // Implement theme switching logic here
                });
              },
            ),
            _buildDivider(),
            _buildNavigationTile(
              context,
              title: 'Text Size',
              subtitle: 'Adjust the application text size',
              icon: Icons.text_fields_outlined,
              accentColor: primaryBlue,
              onTap: () {
                // Navigate to text size settings
              },
            ),
            _buildDivider(),
            _buildNavigationTile(
              context,
              title: 'App Color',
              subtitle: 'Choose your favorite color theme',
              icon: Icons.color_lens_outlined,
              accentColor: primaryBlue,
              onTap: () {
                // Navigate to color theme settings
              },
            ),
          ],
          cardColor: cardColor,
        ),
        const SizedBox(height: 24),

        // Notifications Section
        _buildSettingsHeader(
            Icons.notifications_none_rounded, 'Notifications', primaryBlue),
        const SizedBox(height: 12),
        _buildSettingsCard(
          context,
          [
            _buildSwitchTile(
              context,
              title: 'Push Notifications',
              subtitle: 'Receive app alerts and updates',
              icon: Icons.notifications_active_outlined,
              value: isPushNotificationsEnabled,
              accentColor: primaryBlue,
              onChanged: (value) {
                setState(() {
                  isPushNotificationsEnabled = value;
                });
              },
            ),
            _buildDivider(),
            _buildSwitchTile(
              context,
              title: 'Email Notifications',
              subtitle: 'Receive emails about activity',
              icon: Icons.email_outlined,
              value: isEmailNotificationsEnabled,
              accentColor: primaryBlue,
              onChanged: (value) {
                setState(() {
                  isEmailNotificationsEnabled = value;
                });
              },
            ),
            _buildDivider(),
            _buildNavigationTile(
              context,
              title: 'Notification Preferences',
              subtitle: 'Customise notification types',
              icon: Icons.tune_outlined,
              accentColor: primaryBlue,
              onTap: () {
                // Navigate to notification preferences
              },
            ),
          ],
          cardColor: cardColor,
        ),
        const SizedBox(height: 24),

        // Privacy & Security Section
        _buildSettingsHeader(
            Icons.shield_outlined, 'Privacy & Security', primaryBlue),
        const SizedBox(height: 12),
        _buildSettingsCard(
          context,
          [
            _buildNavigationTile(
              context,
              title: 'Change Password',
              subtitle: 'Update your account password',
              icon: Icons.lock_outline,
              accentColor: primaryBlue,
              onTap: () {
                // Navigate to password change
              },
            ),
            _buildDivider(),
            _buildNavigationTile(
              context,
              title: 'Data Privacy',
              subtitle: 'Manage data sharing options',
              icon: Icons.security_outlined,
              accentColor: primaryBlue,
              onTap: () {
                // Navigate to data privacy settings
              },
            ),
            _buildDivider(),
            _buildNavigationTile(
              context,
              title: 'Biometric Authentication',
              subtitle: 'Secure your app with fingerprint or face ID',
              icon: Icons.fingerprint,
              accentColor: primaryBlue,
              onTap: () {
                // Navigate to biometric settings
              },
            ),
          ],
          cardColor: cardColor,
        ),
        const SizedBox(height: 24),

        // About Section
        _buildSettingsHeader(Icons.info_outline, 'About', primaryBlue),
        const SizedBox(height: 12),
        _buildSettingsCard(
          context,
          [
            _buildInfoTile(
              context,
              title: 'App Version',
              subtitle: 'v1.0.0',
              icon: Icons.new_releases_outlined,
              accentColor: primaryBlue,
            ),
            _buildDivider(),
            _buildNavigationTile(
              context,
              title: 'Terms of Service',
              icon: Icons.description_outlined,
              accentColor: primaryBlue,
              onTap: () {
                // Navigate to terms of service
              },
            ),
            _buildDivider(),
            _buildNavigationTile(
              context,
              title: 'Privacy Policy',
              icon: Icons.privacy_tip_outlined,
              accentColor: primaryBlue,
              onTap: () {
                // Navigate to privacy policy
              },
            ),
            _buildDivider(),
            _buildNavigationTile(
              context,
              title: 'Help & Support',
              icon: Icons.support_agent_outlined,
              accentColor: primaryBlue,
              onTap: () {
                // Navigate to help page
              },
            ),
          ],
          cardColor: cardColor,
        ),
      ],
    );
  }

  Widget _buildSettingsHeader(IconData icon, String title, Color accentColor) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: accentColor,
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: accentColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard(BuildContext context, List<Widget> children,
      {Color? cardColor}) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor ?? Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildSwitchTile(
    BuildContext context, {
    required String title,
    String? subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
    required Color accentColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: accentColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          CupertinoSwitch(
            value: value,
            activeTrackColor: accentColor,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationTile(
    BuildContext context, {
    required String title,
    String? subtitle,
    required IconData icon,
    required VoidCallback onTap,
    required Color accentColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: accentColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    ),
                  ),
                  if (subtitle != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(
    BuildContext context, {
    required String title,
    String? subtitle,
    required IconData icon,
    required Color accentColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: accentColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 56,
      endIndent: 16,
      color: Colors.grey.shade200,
    );
  }

  Widget _buildSignOutButton(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.redAccent,
            Colors.red.shade700,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            FirebaseAuth.instance.signOut();
            Navigator.pop(context);
          },
          borderRadius: BorderRadius.circular(16),
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.logout_rounded,
                  color: Colors.white,
                ),
                SizedBox(width: 8),
                Text(
                  'Sign Out',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
