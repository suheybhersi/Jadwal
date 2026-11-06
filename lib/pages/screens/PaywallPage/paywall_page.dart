import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:jadwal/pages/screens/SettingsPage/privacy_policy_page.dart';
import 'package:jadwal/pages/screens/SettingsPage/terms_service_page.dart';
import 'package:jadwal/services/subscription_service.dart';
import 'package:provider/provider.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class PaywallPage extends StatefulWidget {
  const PaywallPage({
    super.key,
    this.softOffer = false,
    this.onFinished,
  });

  /// When true, show trial-focused copy and a "Not now" action.
  /// Used once during first-run onboarding.
  final bool softOffer;

  /// Called when the user dismisses (Not now / close) or finishes a purchase
  /// while [softOffer] is true. When null, falls back to Navigator.pop.
  final VoidCallback? onFinished;

  @override
  State<PaywallPage> createState() => _PaywallPageState();
}

class _PaywallPageState extends State<PaywallPage> {
  /// Only used for free users choosing a plan to buy.
  bool _yearlySelected = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SubscriptionService>().loadOfferings();
    });
  }

  void _finish([bool purchased = false]) {
    if (widget.softOffer && widget.onFinished != null) {
      widget.onFinished!();
      return;
    }
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop(purchased);
    } else if (widget.onFinished != null) {
      widget.onFinished!();
    }
  }

  Future<void> _purchase() async {
    final sub = context.read<SubscriptionService>();
    if (sub.isPro) return;

    final package =
        _yearlySelected ? sub.yearlyPackage : sub.monthlyPackage;
    if (package == null) {
      setState(() => _error = 'Plans are unavailable right now. Try again later.');
      return;
    }

    setState(() => _error = null);
    final ok = await sub.purchase(package);
    if (!mounted) return;

    if (ok && sub.lastPurchaseChangedProduct) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Welcome to Jadwal Pro · ${sub.activePlanLabel}'),
        ),
      );
      _finish(true);
      return;
    }

    if (ok) {
      _finish(true);
      return;
    }

    if (!sub.lastPurchaseCancelled) {
      setState(() => _error = 'Purchase was not completed.');
    }
  }

  Future<void> _restore() async {
    final sub = context.read<SubscriptionService>();
    setState(() => _error = null);
    final ok = await sub.restorePurchases();
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Subscription restored')),
      );
      _finish(true);
    } else {
      setState(() => _error = 'No active subscription found to restore.');
    }
  }

  Future<void> _manage() async {
    final uri = Platform.isAndroid
        ? Uri.parse(
            'https://play.google.com/store/account/subscriptions?package=com.suheyb.jadwal',
          )
        : Uri.parse('https://apps.apple.com/account/subscriptions');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sub = context.watch<SubscriptionService>();
    final yearly = sub.yearlyPackage;
    final monthly = sub.monthlyPackage;
    final textColor = Theme.of(context).colorScheme.inversePrimary;
    final isPro = sub.isPro;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: isPro
            ? _buildProBody(context, sub, textColor)
            : _buildFreeBody(
                context,
                sub,
                textColor,
                yearly: yearly,
                monthly: monthly,
              ),
      ),
    );
  }

  Widget _buildHeader(Color textColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF4979FB).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Iconsax.crown_1,
            color: Color(0xFF4979FB),
            size: 28,
          ),
        ),
        const Spacer(),
        IconButton(
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(
            minWidth: 40,
            minHeight: 40,
          ),
          icon: Icon(Icons.close, color: textColor),
          onPressed: () => _finish(false),
        ),
      ],
    );
  }

  Widget _buildTitleBlock(Color textColor, {required bool isPro}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.softOffer ? 'Try Jadwal Pro free' : 'Jadwal Pro',
          style: GoogleFonts.poppins(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.softOffer
              ? 'Start a 7-day free trial. Unlimited quizzes, Fill in the Blank, and speech practice.'
              : isPro
                  ? 'You have access to unlimited quizzes and Pro quiz types.'
                  : 'Unlimited quizzes, Fill in the Blank, and speech practice.',
          style: GoogleFonts.poppins(
            fontSize: 15,
            color: Colors.grey.shade600,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildFeatures() {
    return Column(
      children: const [
        _FeatureRow(
          icon: Iconsax.unlimited,
          title: 'Unlimited quizzes',
          subtitle: 'No daily cap on practice sessions',
        ),
        _FeatureRow(
          icon: Iconsax.document_text,
          title: 'Fill in the Blank',
          subtitle: 'Harder recall with Qur’anic word options',
        ),
        _FeatureRow(
          icon: Iconsax.microphone,
          title: 'What Comes Next',
          subtitle: 'Speech-to-text recitation quizzes',
        ),
      ],
    );
  }

  Widget _buildLegalLinks(BuildContext context) {
    return Text.rich(
      TextSpan(
        style: GoogleFonts.poppins(
          fontSize: 13,
          color: Colors.grey.shade600,
        ),
        children: [
          TextSpan(
            text: 'Terms of Use',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF4979FB),
              decoration: TextDecoration.underline,
              decorationColor: const Color(0xFF4979FB),
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const TermsServicePage(),
                  ),
                );
              },
          ),
          const TextSpan(text: '  ·  '),
          TextSpan(
            text: 'Privacy Policy',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF4979FB),
              decoration: TextDecoration.underline,
              decorationColor: const Color(0xFF4979FB),
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const PrivacyPolicyPage(),
                  ),
                );
              },
          ),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildPrimaryButton({
    required SubscriptionService sub,
    required bool isPro,
    Package? yearly,
    Package? monthly,
  }) {
    return SizedBox(
      height: 54,
      child: ElevatedButton(
        onPressed: sub.isLoading
            ? null
            : isPro
                ? _manage
                : (yearly == null && monthly == null)
                    ? null
                    : _purchase,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4979FB),
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey.shade300,
          disabledForegroundColor: Colors.grey.shade600,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
        child: sub.isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                isPro
                    ? 'Manage subscription'
                    : widget.softOffer
                        ? 'Start free trial'
                        : 'Continue',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
      ),
    );
  }

  /// Fixed viewport layout — no scroll, renewal pinned to bottom.
  Widget _buildProBody(
    BuildContext context,
    SubscriptionService sub,
    Color textColor,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(textColor),
          const SizedBox(height: 16),
          _buildTitleBlock(textColor, isPro: true),
          const SizedBox(height: 28),
          _buildFeatures(),
          const Spacer(),
          _RenewalCard(renewalLabel: sub.renewalLabel),
          const SizedBox(height: 16),
          _buildLegalLinks(context),
          const SizedBox(height: 12),
          _buildPrimaryButton(sub: sub, isPro: true),
          const SizedBox(height: 8),
          Text(
            'Change or cancel your plan in Apple Subscriptions.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFreeBody(
    BuildContext context,
    SubscriptionService sub,
    Color textColor, {
    required Package? yearly,
    required Package? monthly,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(textColor),
          const SizedBox(height: 16),
          _buildTitleBlock(textColor, isPro: false),
          const SizedBox(height: 28),
          _buildFeatures(),
          const SizedBox(height: 28),
          if (yearly != null)
            _PlanTile(
              title: 'Yearly',
              price: yearly.storeProduct.priceString,
              subtitle: _planSubtitle(
                yearly,
                fallback: 'Best value · billed yearly',
              ),
              selected: _yearlySelected,
              onTap: () => setState(() => _yearlySelected = true),
            ),
          if (monthly != null) ...[
            const SizedBox(height: 12),
            _PlanTile(
              title: 'Monthly',
              price: monthly.storeProduct.priceString,
              subtitle: _planSubtitle(
                monthly,
                fallback: 'Billed monthly',
              ),
              selected: !_yearlySelected,
              onTap: () => setState(() => _yearlySelected = false),
            ),
          ],
          if (yearly == null && monthly == null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                sub.isConfigured
                    ? 'Loading plans…'
                    : 'Subscriptions are available on iOS with App Store setup.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
            ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: Colors.red.shade700,
                fontSize: 13,
              ),
            ),
          ],
          const SizedBox(height: 20),
          _buildLegalLinks(context),
          const SizedBox(height: 16),
          _buildPrimaryButton(
            sub: sub,
            isPro: false,
            yearly: yearly,
            monthly: monthly,
          ),
          if (widget.softOffer) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: sub.isLoading ? null : () => _finish(false),
              child: Text(
                'Not now',
                style: GoogleFonts.poppins(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          TextButton(
            onPressed: sub.isLoading ? null : _restore,
            child: Text(
              'Restore purchases',
              style: GoogleFonts.poppins(
                color: const Color(0xFF4979FB),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Payment will be charged to your Apple ID. Subscription renews automatically unless cancelled at least 24 hours before the end of the period.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: Colors.grey.shade600,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  String _planSubtitle(Package package, {required String fallback}) {
    final intro = package.storeProduct.introductoryPrice;
    if (intro == null || intro.periodNumberOfUnits <= 0) {
      return fallback;
    }

    final period = intro.periodUnit;
    final units = intro.periodNumberOfUnits;
    final durationLabel = switch (period) {
      PeriodUnit.day => units == 1 ? '1-day' : '$units-day',
      PeriodUnit.week => units == 1 ? '1-week' : '$units-week',
      PeriodUnit.month => units == 1 ? '1-month' : '$units-month',
      PeriodUnit.year => units == 1 ? '1-year' : '$units-year',
      PeriodUnit.unknown => '$units-period',
    };

    final isFree = intro.price == 0;
    if (isFree) {
      return '$durationLabel free trial, then ${package.storeProduct.priceString}';
    }
    return '$durationLabel intro at ${intro.priceString}, then ${package.storeProduct.priceString}';
  }
}

class _RenewalCard extends StatelessWidget {
  const _RenewalCard({required this.renewalLabel});

  final String? renewalLabel;

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.inversePrimary;
    final label = renewalLabel ?? 'Active subscription';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF4979FB).withValues(alpha: 0.35),
        ),
        color: const Color(0xFF4979FB).withValues(alpha: 0.06),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle,
            color: Color(0xFF4979FB),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF4979FB).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF4979FB), size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: Theme.of(context).colorScheme.inversePrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanTile extends StatelessWidget {
  const _PlanTile({
    required this.title,
    required this.price,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String price;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.inversePrimary;
    final borderColor = selected
        ? const Color(0xFF4979FB)
        : Colors.grey.withValues(alpha: 0.25);
    final background = selected
        ? const Color(0xFF4979FB).withValues(alpha: 0.06)
        : Theme.of(context).colorScheme.surface;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: borderColor,
            width: selected ? 2 : 1,
          ),
          color: background,
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_off,
              color: selected ? const Color(0xFF4979FB) : Colors.grey,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: textColor,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              price,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
