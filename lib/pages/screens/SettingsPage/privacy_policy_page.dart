import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:url_launcher/url_launcher.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Privacy Policy',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 22,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        surfaceTintColor: Theme.of(context).colorScheme.surface,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                          Iconsax.shield,
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
                              'Privacy Policy',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Last updated: 23 July 2026',
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
                _buildPolicyContent(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPolicyContent(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildParagraph(
            'Jadwal (“we”, “us”, or “our”) provides a mobile application to help users plan, track, and practise Quran memorisation (Hifdh). This Privacy Policy explains what information we collect, how we use it, and your choices.',
          ),
          _buildParagraph(
            'By creating an account or using Jadwal, you agree to this Privacy Policy. If you do not agree, please do not use the app.',
          ),
          _buildSectionTitle('1. Information We Collect'),
          _buildParagraph(
            'Account and profile information. When you register or update your profile, we collect information such as your name (first and last), username, and email address. Email is also used for authentication and password reset via Firebase Authentication.',
          ),
          _buildParagraph(
            'Usage and progress data. We store information related to your use of the app, including memorisation plans, hifdh and review history, quiz results, preferences (for example theme, usage mode, and notification settings), achievements, feedback you submit, and login activity (such as approximate time and device/platform details).',
          ),
          _buildParagraph(
            'Audio. If you use “What Comes Next” or other recitation features, we temporarily process audio you record so it can be converted to text for assessment. Audio is sent to our servers / Cloud Functions and then to our speech-processing provider for transcription. We use this to provide the quiz feature, not for advertising.',
          ),
          _buildParagraph(
            'Device and technical information. We may collect device or technical details needed to run the app securely (for example platform and OS version in login activity) and crash/diagnostic data via Firebase Crashlytics to help us fix bugs and improve stability.',
          ),
          _buildParagraph(
            'Local data. Some preferences and Quran layout/script assets are stored on your device (for example SharedPreferences and local databases/fonts) so the app can work efficiently, including offline for certain features.',
          ),
          _buildSectionTitle('2. How We Use Your Information'),
          _buildParagraph(
            'We use the information above to:',
          ),
          _buildBulletPoint(
              'Create and manage your account and authenticate you'),
          _buildBulletPoint(
              'Provide core features (plans, reviews, quizzes, mushaf reading, progress tracking)'),
          _buildBulletPoint(
              'Process speech for recitation assessment and generate quiz content where needed'),
          _buildBulletPoint(
              'Respond to support requests and in-app feedback'),
          _buildBulletPoint(
              'Maintain security (for example login activity) and prevent abuse'),
          _buildBulletPoint(
              'Diagnose crashes and improve reliability and performance'),
          _buildBulletPoint(
              'Send local device notifications you enable (for example task reminders)'),
          _buildParagraph(
            'We do not sell your personal information. We do not use your data for third-party advertising or cross-app tracking.',
          ),
          _buildSectionTitle('3. How We Share Information'),
          _buildParagraph(
            'We share information only as needed to operate Jadwal:',
          ),
          _buildBulletPoint(
              'Google Firebase (Authentication, Cloud Firestore, Cloud Functions, Crashlytics) to host accounts, store app data, run backend functions, and collect crash reports'),
          _buildBulletPoint(
              'OpenAI (via our Cloud Functions) to transcribe quiz audio and help generate certain quiz options'),
          _buildParagraph(
            'These providers process data on our behalf under their terms and to provide the services we request. We may also disclose information if required by law, or to protect the rights, safety, and security of Jadwal, our users, or others.',
          ),
          _buildParagraph(
            'Quran text and mushaf resources shown in the app are sourced from third-party libraries (including Tanzil and the Quranic Universal Library). That content is reference material, not your personal data.',
          ),
          _buildSectionTitle('4. Data Retention'),
          _buildParagraph(
            'We keep your account and progress data while your account remains active. If you delete your account in the app, we delete associated user data we control, subject to short technical delays and any data we must retain for legal, security, or dispute-resolution reasons. Crash logs and provider logs may be retained according to those providers’ retention practices.',
          ),
          _buildSectionTitle('5. Your Choices and Rights'),
          _buildBulletPoint(
              'Update profile details (name, username) in Edit Profile'),
          _buildBulletPoint(
              'Email used for login is managed through your account / authentication settings'),
          _buildBulletPoint(
              'Control notification preferences in Settings'),
          _buildBulletPoint(
              'Delete your account in Settings → Delete Account'),
          _buildBulletPoint(
              'Contact us at jadwal.qrn@gmail.com to ask questions about your data'),
          _buildParagraph(
            'Depending on where you live, you may have additional rights under applicable privacy laws (for example access or deletion). Contact us to make a request.',
          ),
          _buildSectionTitle('6. Children’s Privacy'),
          _buildParagraph(
            'Jadwal is not directed at children under 13 (or the minimum age required in your country). We do not knowingly collect personal information from children under that age. If you believe a child has provided us personal information, contact us and we will take appropriate steps.',
          ),
          _buildSectionTitle('7. Security'),
          _buildParagraph(
            'We use industry-standard services (including Firebase Authentication) and access controls to protect your information. No method of transmission or storage is 100% secure.',
          ),
          _buildSectionTitle('8. International Processing'),
          _buildParagraph(
            'Our service providers may process data in the United Kingdom, European Economic Area, United States, or other countries. Where required, we rely on appropriate safeguards offered by those providers.',
          ),
          _buildSectionTitle('9. Changes to This Policy'),
          _buildParagraph(
            'We may update this Privacy Policy from time to time. We will revise the “Last updated” date and, where appropriate, provide additional notice in the app.',
          ),
          _buildSectionTitle('10. Contact Us'),
          _buildParagraph(
            'Questions about this Privacy Policy:',
          ),
          _buildContactInfo(context, 'jadwal.qrn@gmail.com'),
          _buildContactInfo(context, 'https://www.jadwal.co.uk'),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 20),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildParagraph(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 14,
          color: Colors.black87.withValues(alpha: 0.8),
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 8),
            height: 5,
            width: 5,
            decoration: BoxDecoration(
              color: const Color(0xFF4979FB),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.black87.withValues(alpha: 0.8),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactInfo(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 0, bottom: 5, top: 5),
      child: InkWell(
        onTap: () => _openContactLink(context, text),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Icon(
                text.contains('@')
                    ? Iconsax.sms
                    : text.startsWith('http')
                        ? Iconsax.link_1
                        : Iconsax.location,
                size: 16,
                color: const Color(0xFF4979FB),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  text,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: const Color(0xFF4979FB),
                    height: 1.5,
                    decoration: TextDecoration.underline,
                    decorationColor:
                        const Color(0xFF4979FB).withValues(alpha: 0.4),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openContactLink(BuildContext context, String text) async {
    final uri = text.contains('@')
        ? Uri(scheme: 'mailto', path: text)
        : Uri.parse(text);

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open link')),
        );
      }
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open link')),
      );
    }
  }
}
