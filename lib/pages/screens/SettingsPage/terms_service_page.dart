import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:url_launcher/url_launcher.dart';

class TermsServicePage extends StatelessWidget {
  const TermsServicePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Terms of Service',
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
                          Iconsax.document_text,
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
                              'Terms of Service',
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
                _buildTermsContent(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTermsContent(BuildContext context) {
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
            'These Terms of Service (“Terms”) govern your use of the Jadwal mobile application and related services (the “Service”) operated by Jadwal.',
          ),
          _buildParagraph(
            'By creating an account or using the Service, you agree to these Terms. If you do not agree, do not use the Service.',
          ),
          _buildSectionTitle('1. The Service'),
          _buildParagraph(
            'Jadwal helps users organise Quran memorisation and revision, including scheduling, progress tracking, quizzes, and related educational features. Features may change, improve, or be discontinued over time.',
          ),
          _buildSectionTitle('2. Eligibility and Accounts'),
          _buildParagraph(
            'You must be at least 13 years old (or the minimum age in your country) to use the Service. You are responsible for:',
          ),
          _buildBulletPoint('Providing accurate registration information'),
          _buildBulletPoint('Keeping your password confidential'),
          _buildBulletPoint('All activity under your account'),
          _buildParagraph(
            'Notify us promptly if you suspect unauthorised access. We may suspend or terminate accounts that violate these Terms or put the Service or other users at risk.',
          ),
          _buildSectionTitle('3. Licence to Use the App'),
          _buildParagraph(
            'We grant you a personal, non-exclusive, non-transferable, revocable licence to use Jadwal for your own personal, non-commercial educational use, subject to these Terms.',
          ),
          _buildParagraph('You may not:'),
          _buildBulletPoint(
              'Copy, modify, distribute, sell, or lease any part of the Service except as allowed by law'),
          _buildBulletPoint(
              'Reverse engineer or attempt to extract source code except where mandatory law permits'),
          _buildBulletPoint('Circumvent security or access controls'),
          _buildBulletPoint(
              'Use the Service to harm, harass, spam, or impersonate others'),
          _buildBulletPoint(
              'Misuse APIs, automated scraping, or overload our systems'),
          _buildSectionTitle('4. Quran Content and Third-Party Materials'),
          _buildParagraph(
            'Quran text, mushaf layout, fonts, and related resources may be provided under licences from third parties (including Tanzil and QUL / related contributors). You may use that content only as presented in the app for personal study. Attribution appears in the app’s About / Credits section. We do not claim ownership of the Quranic revelation itself.',
          ),
          _buildSectionTitle('5. User Content'),
          _buildParagraph(
            'You may submit content such as profile information, memorisation plans, quiz recordings/transcriptions for assessment, feedback, and similar data (“User Content”).',
          ),
          _buildParagraph(
            'You retain ownership of your User Content. You grant us a limited licence to host, process, and use it solely to operate and improve the Service (for example storing progress, scoring quizzes, and reviewing feedback).',
          ),
          _buildParagraph(
            'You are responsible for your User Content and must not submit unlawful, abusive, or infringing material.',
          ),
          _buildSectionTitle('6. AI Features'),
          _buildParagraph(
            'Some features use artificial intelligence (speech-to-text for What Comes Next). AI output may be imperfect. Recitation assessment is a tool to support learning and is not a guarantee of correctness, religious ruling, or scholarly certification. Always verify important matters with qualified teachers where needed.',
          ),
          _buildSectionTitle('7. Notifications'),
          _buildParagraph(
            'If you enable notifications, the app may schedule local reminders on your device. You can change or disable these in Settings (and in your device settings).',
          ),
          _buildSectionTitle('8. Disclaimers'),
          _buildParagraph(
            'THE SERVICE IS PROVIDED “AS IS” AND “AS AVAILABLE” WITHOUT WARRANTIES OF ANY KIND, WHETHER EXPRESS OR IMPLIED, INCLUDING MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, AND NON-INFRINGEMENT, TO THE MAXIMUM EXTENT PERMITTED BY LAW.',
          ),
          _buildParagraph(
            'We do not warrant that the Service will be uninterrupted, error-free, or free of harmful components, or that content (including speech assessments) will be accurate or complete.',
          ),
          _buildSectionTitle('9. Limitation of Liability'),
          _buildParagraph(
            'TO THE MAXIMUM EXTENT PERMITTED BY LAW, JADWAL AND ITS OPERATORS SHALL NOT BE LIABLE FOR ANY INDIRECT, INCIDENTAL, SPECIAL, CONSEQUENTIAL, OR PUNITIVE DAMAGES, OR ANY LOSS OF PROFITS, DATA, GOODWILL, OR OTHER INTANGIBLE LOSSES, ARISING FROM YOUR USE OF OR INABILITY TO USE THE SERVICE.',
          ),
          _buildParagraph(
            'OUR TOTAL LIABILITY FOR ANY CLAIM ARISING OUT OF THESE TERMS OR THE SERVICE SHALL NOT EXCEED THE GREATER OF (A) THE AMOUNT YOU PAID US FOR THE SERVICE IN THE 12 MONTHS BEFORE THE CLAIM, OR (B) £50.',
          ),
          _buildParagraph(
            'Nothing in these Terms excludes liability that cannot be excluded under applicable law (including for death or personal injury caused by negligence, or fraud).',
          ),
          _buildSectionTitle('10. Termination'),
          _buildParagraph(
            'You may stop using the Service and delete your account at any time in the app. We may suspend or terminate access if you breach these Terms or if we discontinue the Service. Upon termination, your licence ends; sections that by nature should survive (including disclaimers, liability limits, and intellectual property) will survive.',
          ),
          _buildSectionTitle('11. Changes'),
          _buildParagraph(
            'We may update these Terms from time to time. We will update the “Last updated” date and may provide notice in the app. Continued use after changes means you accept the revised Terms.',
          ),
          _buildSectionTitle('12. Governing Law'),
          _buildParagraph(
            'These Terms are governed by the laws of England and Wales, without regard to conflict-of-law rules. Courts of England and Wales shall have exclusive jurisdiction, except where mandatory consumer protections in your country give you other rights.',
          ),
          _buildSectionTitle('13. Contact'),
          _buildParagraph(
            'Questions about these Terms:',
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
                        : Iconsax.sms,
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
