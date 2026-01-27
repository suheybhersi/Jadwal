import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

class NotificationsPage extends StatefulWidget {
  final bool initialPushNotificationsValue;
  final bool initialEmailNotificationsValue;

  const NotificationsPage({
    super.key,
    this.initialPushNotificationsValue = true,
    this.initialEmailNotificationsValue = false,
  });

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  late bool isPushNotificationsEnabled;
  late bool isEmailNotificationsEnabled;
  bool isTaskReminderEnabled = true;
  bool isEventAlertEnabled = true;
  bool isWeeklySummaryEnabled = false;

  @override
  void initState() {
    super.initState();
    isPushNotificationsEnabled = widget.initialPushNotificationsValue;
    isEmailNotificationsEnabled = widget.initialEmailNotificationsValue;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        title: Text(
          'Notifications',
          style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 22,
              color: Theme.of(context).colorScheme.inversePrimary),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
              color: Theme.of(context).colorScheme.inversePrimary),
          onPressed: () {
            // Return the updated values to the previous screen
            Navigator.pop(context, {
              'pushNotificationsEnabled': isPushNotificationsEnabled,
              'emailNotificationsEnabled': isEmailNotificationsEnabled,
            });
          },
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
                // Header
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
                      Container(
                        height: 50,
                        width: 50,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Iconsax.notification,
                          size: 28,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Notification Settings',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Manage how you receive notifications',
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

                // Global Notification Settings
                _buildSectionHeader('Notification Channels'),
                const SizedBox(height: 10),
                _buildSettingCard([
                  _buildSettingTile(
                    icon: Iconsax.mobile,
                    title: 'Push Notifications',
                    description: 'Receive notifications on your device',
                    trailing: Switch(
                      value: isPushNotificationsEnabled,
                      onChanged: (value) {
                        setState(() {
                          isPushNotificationsEnabled = value;
                        });
                      },
                      activeThumbColor: const Color(0xFF4979FB),
                      inactiveThumbColor:
                          Theme.of(context).colorScheme.tertiary,
                      trackOutlineColor: WidgetStateProperty.all(
                        isPushNotificationsEnabled
                            ? Colors.transparent
                            : Theme.of(context).colorScheme.tertiary,
                      ),
                    ),
                  ),
                  _buildSettingTile(
                    icon: Iconsax.sms,
                    title: 'Email Notifications',
                    description: 'Receive notifications via email',
                    trailing: Switch(
                      value: isEmailNotificationsEnabled,
                      onChanged: (value) {
                        setState(() {
                          isEmailNotificationsEnabled = value;
                        });
                      },
                      activeThumbColor: const Color(0xFF4979FB),
                      inactiveThumbColor:
                          Theme.of(context).colorScheme.tertiary,
                      trackOutlineColor: WidgetStateProperty.all(
                        isEmailNotificationsEnabled
                            ? Colors.transparent
                            : Theme.of(context).colorScheme.tertiary,
                      ),
                    ),
                    isLast: true,
                  ),
                ]),

                const SizedBox(height: 24),

                // Notification Types
                _buildSectionHeader('Notification Types'),
                const SizedBox(height: 10),
                _buildSettingCard([
                  _buildSettingTile(
                    icon: Iconsax.task_square,
                    title: 'Task Reminders',
                    description: 'Notifications for upcoming tasks',
                    trailing: Switch(
                      value: isTaskReminderEnabled,
                      onChanged: isPushNotificationsEnabled
                          ? (value) {
                              setState(() {
                                isTaskReminderEnabled = value;
                              });
                            }
                          : null,
                      activeThumbColor: const Color(0xFF4979FB),
                      inactiveThumbColor:
                          Theme.of(context).colorScheme.tertiary,
                      trackOutlineColor: WidgetStateProperty.all(
                        isTaskReminderEnabled
                            ? Colors.transparent
                            : Theme.of(context).colorScheme.tertiary,
                      ),
                    ),
                  ),
                  _buildSettingTile(
                    icon: Iconsax.calendar,
                    title: 'Event Alerts',
                    description: 'Notifications for calendar events',
                    trailing: Switch(
                      value: isEventAlertEnabled,
                      onChanged: isPushNotificationsEnabled
                          ? (value) {
                              setState(() {
                                isEventAlertEnabled = value;
                              });
                            }
                          : null,
                      activeThumbColor: const Color(0xFF4979FB),
                      inactiveThumbColor:
                          Theme.of(context).colorScheme.tertiary,
                      trackOutlineColor: WidgetStateProperty.all(
                        isEventAlertEnabled
                            ? Colors.transparent
                            : Theme.of(context).colorScheme.tertiary,
                      ),
                    ),
                  ),
                  _buildSettingTile(
                    icon: Iconsax.chart,
                    title: 'Weekly Summary',
                    description: 'Weekly activity and progress reports',
                    trailing: Switch(
                      value: isWeeklySummaryEnabled,
                      onChanged: isPushNotificationsEnabled
                          ? (value) {
                              setState(() {
                                isWeeklySummaryEnabled = value;
                              });
                            }
                          : null,
                      activeThumbColor: const Color(0xFF4979FB),
                      inactiveThumbColor:
                          Theme.of(context).colorScheme.tertiary,
                      trackOutlineColor: WidgetStateProperty.all(
                        isWeeklySummaryEnabled
                            ? Colors.transparent
                            : Theme.of(context).colorScheme.tertiary,
                      ),
                    ),
                    isLast: true,
                  ),
                ]),

                const SizedBox(height: 24),

                // Notification Timing
                _buildSectionHeader('Notification Timing'),
                const SizedBox(height: 10),
                _buildTimingCard(),

                const SizedBox(height: 24),

                // Do Not Disturb
                _buildSectionHeader('Do Not Disturb'),

                const SizedBox(height: 30),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // Save settings and return to previous screen
                      Navigator.pop(context, {
                        'pushNotificationsEnabled': isPushNotificationsEnabled,
                        'emailNotificationsEnabled':
                            isEmailNotificationsEnabled,
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4979FB),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Save Settings',
                      style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.white),
                    ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
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
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.inversePrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (trailing != null) trailing,
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
            color: Theme.of(context).colorScheme.tertiary,
          ),
      ],
    );
  }

  Widget _buildTimingCard() {
    return Container(
      padding: const EdgeInsets.all(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Notification Timing',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.inversePrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildTimingRow(
            title: 'Daily Notification Time',
            time: '08:00 AM',
          ),
          const SizedBox(height: 16),
          _buildTimingRow(
            title: 'Weekly Summary Day',
            time: 'Monday',
          ),
        ],
      ),
    );
  }

  Widget _buildTimingRow({
    required String title,
    required String time,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
        Text(
          time,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.inversePrimary,
          ),
        ),
      ],
    );
  }
}
