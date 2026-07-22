import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:jadwal/services/notification_service.dart';

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
  late bool isTaskReminderEnabled;
  late int dailyNotificationHour;
  late int dailyNotificationMinute;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    isPushNotificationsEnabled = widget.initialPushNotificationsValue;
    isTaskReminderEnabled = true;
    dailyNotificationHour = 8;
    dailyNotificationMinute = 0;
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await NotificationService.instance.loadPreferences();
    if (mounted) {
      setState(() {
        isPushNotificationsEnabled = prefs.pushNotificationsEnabled;
        isTaskReminderEnabled = prefs.taskReminderEnabled;
        dailyNotificationHour = prefs.dailyNotificationHour;
        dailyNotificationMinute = prefs.dailyNotificationMinute;
        _loading = false;
      });
    }
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
          onPressed: () => _popWithResult(),
        ),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
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
                    isLast: true,
                  ),
                ]),

                const SizedBox(height: 24),

                // Notification Timing
                _buildSectionHeader('Notification Timing'),
                const SizedBox(height: 10),
                _buildTimingCard(),

                const SizedBox(height: 30),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _saveAndPop,
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

  String get _dailyTimeFormatted {
    final h = dailyNotificationHour;
    final m = dailyNotificationMinute;
    final padM = m.toString().padLeft(2, '0');
    if (h == 0) return '12:$padM AM';
    if (h < 12) return '$h:$padM AM';
    if (h == 12) return '12:$padM PM';
    return '${h - 12}:$padM PM';
  }

  Future<void> _pickDailyTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: dailyNotificationHour.clamp(0, 23),
        minute: dailyNotificationMinute.clamp(0, 59),
      ),
    );
    if (picked != null && mounted) {
      setState(() {
        dailyNotificationHour = picked.hour;
        dailyNotificationMinute = picked.minute;
      });
    }
  }

  Future<void> _saveAndPop() async {
    final prefs = NotificationPreferences(
      pushNotificationsEnabled: isPushNotificationsEnabled,
      // Not implemented yet — always persist as off.
      emailNotificationsEnabled: false,
      taskReminderEnabled: isTaskReminderEnabled,
      eventAlertEnabled: false,
      weeklySummaryEnabled: false,
      dailyNotificationHour: dailyNotificationHour,
      dailyNotificationMinute: dailyNotificationMinute,
      weeklySummaryWeekday: 1,
    );
    await NotificationService.instance.savePreferences(prefs);
    if (mounted) _popWithResult();
  }

  void _popWithResult() {
    Navigator.pop(context, {
      'pushNotificationsEnabled': isPushNotificationsEnabled,
      'emailNotificationsEnabled': false,
    });
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
            time: _dailyTimeFormatted,
            onTap: _pickDailyTime,
          ),
        ],
      ),
    );
  }

  Widget _buildTimingRow({
    required String title,
    required String time,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            Row(
              children: [
                Text(
                  time,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.inversePrimary,
                  ),
                ),
                if (onTap != null) ...[
                  const SizedBox(width: 4),
                  Icon(
                    Iconsax.arrow_right_3,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
