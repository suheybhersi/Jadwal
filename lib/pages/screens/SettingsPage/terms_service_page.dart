import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

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
                        color: const Color(0xFF4979FB).withOpacity(0.2),
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
                          color: Colors.white.withOpacity(0.2),
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
                              'Last updated: March 11, 2025',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // Terms of Service Content
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
          _buildSectionTitle('1. Acceptance of Terms'),
          _buildParagraph(
            'By accessing or using our services, you agree to be bound by these Terms of Service and all applicable laws and regulations. If you do not agree with any of these terms, you are prohibited from using or accessing our services.',
          ),
          _buildSectionTitle('2. Use Licence'),
          _buildParagraph(
            'Permission is granted to temporarily download one copy of the materials (information or software) on our app for personal, non-commercial transitory viewing only. This is the grant of a licence, not a transfer of title, and under this licence you may not:',
          ),
          _buildBulletPoint('Modify or copy the materials'),
          _buildBulletPoint(
              'Use the materials for any commercial purpose or for any public display'),
          _buildBulletPoint(
              'Attempt to reverse engineer any software contained on our app'),
          _buildBulletPoint(
              'Remove any copyright or other proprietary notations from the materials'),
          _buildBulletPoint(
              'Transfer the materials to another person or "mirror" the materials on any other server'),
          _buildSectionTitle('3. User Accounts'),
          _buildParagraph(
            'To access certain features of our services, you may be required to create an account. You are responsible for maintaining the confidentiality of your account information, including your password, and for all activity that occurs under your account. You agree to notify us immediately of any unauthorised use of your account or password.',
          ),
          _buildSectionTitle('4. User Content'),
          _buildParagraph(
            'Our services may allow you to post, link, store, share and otherwise make available certain information, text, graphics, videos, or other material. You are responsible for the content that you post, including its legality, reliability, and appropriateness.',
          ),
          _buildSectionTitle('5. Prohibited Uses'),
          _buildParagraph(
            'You may use our services only for lawful purposes and in accordance with these Terms. You agree not to use our services:',
          ),
          _buildBulletPoint(
              'In any way that violates any applicable law or regulation'),
          _buildBulletPoint(
              "To engage in any conduct that restricts or inhibits anyone's use of our services"),
          _buildBulletPoint(
              'To impersonate or attempt to impersonate our company, a company employee, another user, or any other person'),
          _buildBulletPoint(
              'To engage in any activity that could harm minors in any way'),
          _buildSectionTitle('6. Changes to Terms'),
          _buildParagraph(
            'We reserve the right to modify these terms at any time. We will notify you of any changes by posting the new Terms of Service on this page. You are advised to review these Terms periodically for any changes.',
          ),
          _buildSectionTitle('7. Termination'),
          _buildParagraph(
            'We may terminate or suspend your account and bar access to our services immediately, without prior notice or liability, under our sole discretion, for any reason whatsoever, including without limitation if you breach the Terms.',
          ),
          _buildSectionTitle('8. Limitation of Liability'),
          _buildParagraph(
            'In no event shall our company, nor its directors, employees, partners, agents, suppliers, or affiliates, be liable for any indirect, incidental, special, consequential or punitive damages, including without limitation, loss of profits, data, use, goodwill, or other intangible losses, resulting from your access to or use of or inability to access or use our services.',
          ),
          _buildSectionTitle('9. Contact Us'),
          _buildParagraph(
            'If you have any questions about these Terms, please contact us at:',
          ),
          _buildContactInfo('jadwal.qrn@gmail.com'),
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
          color: Colors.black87.withOpacity(0.8),
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
                color: Colors.black87.withOpacity(0.8),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactInfo(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 0, bottom: 5, top: 5),
      child: Row(
        children: [
          Icon(
            Iconsax.sms,
            size: 16,
            color: const Color(0xFF4979FB),
          ),
          const SizedBox(width: 10),
          Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: const Color(0xFF4979FB),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
