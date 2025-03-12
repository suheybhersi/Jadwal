import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

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

                // Privacy Policy Content
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
          _buildSectionTitle('1. Information We Collect'),
          _buildParagraph(
            'We collect information you provide directly to us. For example, we collect information when you create an account, update your profile, use the interactive features in our app, participate in any interactive areas of our app, submit information, participate in a contest or promotion, request customer support, or otherwise communicate with us.',
          ),
          _buildSectionTitle('2. How We Use Your Information'),
          _buildParagraph(
            'We may use information about you for various purposes, including to:',
          ),
          _buildBulletPoint('Provide, maintain, and improve our app'),
          _buildBulletPoint(
              'Process transactions and send related information'),
          _buildBulletPoint(
              'Send technical notices, updates, security alerts and support messages'),
          _buildBulletPoint(
              'Respond to your comments, questions, and requests'),
          _buildBulletPoint(
              'Communicate with you about products, services, offers, and events'),
          _buildBulletPoint(
              'Monitor and analyse trends, usage, and activities in connection with our app'),
          _buildSectionTitle('3. Sharing of Information'),
          _buildParagraph(
            'We may share information about you as follows or as otherwise described in this Privacy Policy:',
          ),
          _buildBulletPoint(
              'With vendors, consultants and other service providers who need access to such information to carry out work on our behalf'),
          _buildBulletPoint(
              'In response to a request for information if we believe disclosure is in accordance with applicable law'),
          _buildBulletPoint(
              'If we believe your actions are inconsistent with the spirit or language of our user agreements or policies'),
          _buildBulletPoint(
              'To protect the rights, property and safety of our company or others'),
          _buildSectionTitle('4. Data Retention'),
          _buildParagraph(
            'We store the information we collect about you for as long as is necessary for the purpose(s) for which we originally collected it. We may retain certain information for legitimate business purposes or as required by law.',
          ),
          _buildSectionTitle('5. Your Choices'),
          _buildParagraph(
            'Account Information: You may update, correct, or delete information about you at any time by logging into your online account and modifying your information or by emailing us. If you wish to delete your account, please email us, but note that we may retain certain information as required by law or for legitimate business purposes.',
          ),
          _buildSectionTitle('6. Changes to this Policy'),
          _buildParagraph(
            'We may change this Privacy Policy from time to time. If we make changes, we will notify you by revising the date at the top of the policy and, in some cases, we may provide you with additional notice (such as adding a statement to our website homepage or sending you a notification).',
          ),
          _buildSectionTitle('7. Contact Us'),
          _buildParagraph(
            'If you have any questions about this Privacy Policy, please contact us at:',
          ),
          _buildContactInfo('privacy@jadwal.com'),
          _buildContactInfo('500 Main Street, City, State 12345'),
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
            text.contains('@') ? Iconsax.sms : Iconsax.location,
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
