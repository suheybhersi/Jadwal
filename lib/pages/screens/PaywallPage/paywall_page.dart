import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:jadwal/services/subscription_service.dart';
import 'package:provider/provider.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class PaywallPage extends StatefulWidget {
  const PaywallPage({super.key});

  @override
  State<PaywallPage> createState() => _PaywallPageState();
}

class _PaywallPageState extends State<PaywallPage> {
  bool _yearlySelected = true;
  String? _error;
  bool _didSyncSelection = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SubscriptionService>().loadOfferings();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final sub = context.watch<SubscriptionService>();
    if (_didSyncSelection || !sub.isPro) return;
    if (!sub.isOnMonthlyPlan && !sub.isOnYearlyPlan) return;
    _didSyncSelection = true;
    final nextYearly = !sub.isOnMonthlyPlan;
    if (nextYearly != _yearlySelected) {
      setState(() => _yearlySelected = nextYearly);
    }
  }

  Future<void> _purchase() async {
    final sub = context.read<SubscriptionService>();
    final package =
        _yearlySelected ? sub.yearlyPackage : sub.monthlyPackage;
    if (package == null) {
      setState(() => _error = 'Plans are unavailable right now. Try again later.');
      return;
    }
    final selectingCurrent = (_yearlySelected && sub.isOnYearlyPlan) ||
        (!_yearlySelected && sub.isOnMonthlyPlan);
    if (selectingCurrent) return;

    setState(() => _error = null);
    final ok = await sub.purchase(package);
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop(true);
    } else if (!sub.lastPurchaseCancelled) {
      setState(() {
        _error = sub.isPro
            ? 'Could not switch plan. Try again or tap Manage.'
            : 'Purchase was not completed.';
      });
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
      Navigator.of(context).pop(true);
    } else {
      setState(() => _error = 'No active subscription found to restore.');
    }
  }

  Future<void> _manage() async {
    final uri = Uri.parse('https://apps.apple.com/account/subscriptions');
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
    final selectingCurrent = sub.isPro &&
        ((_yearlySelected && sub.isOnYearlyPlan) ||
            (!_yearlySelected && sub.isOnMonthlyPlan));

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
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
                  if (sub.isPro)
                    TextButton(
                      onPressed: _manage,
                      child: Text(
                        'Manage',
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF4979FB),
                        ),
                      ),
                    ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 40,
                      minHeight: 40,
                    ),
                    icon: Icon(Icons.close, color: textColor),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Jadwal Pro',
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Unlimited quizzes, AI fill-in-the-blank, and speech practice.',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  color: Colors.grey.shade600,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 28),
              _FeatureRow(
                icon: Iconsax.unlimited,
                title: 'Unlimited quizzes',
                subtitle: 'No daily cap on practice sessions',
              ),
              _FeatureRow(
                icon: Iconsax.document_text,
                title: 'Fill in the Blank',
                subtitle: 'AI-generated distractors for harder recall',
              ),
              _FeatureRow(
                icon: Iconsax.microphone,
                title: 'What Comes Next',
                subtitle: 'Speech-to-text recitation quizzes',
              ),
              const SizedBox(height: 28),
              if (yearly != null)
                _PlanTile(
                  title: 'Yearly',
                  price: yearly.storeProduct.priceString,
                  subtitle: sub.isOnYearlyPlan && sub.renewalLabel != null
                      ? 'Current plan · ${sub.renewalLabel}'
                      : _planSubtitle(yearly, fallback: 'Best value · billed yearly'),
                  selected: _yearlySelected,
                  isCurrent: sub.isOnYearlyPlan,
                  onTap: sub.isOnYearlyPlan
                      ? null
                      : () => setState(() => _yearlySelected = true),
                ),
              if (monthly != null) ...[
                const SizedBox(height: 12),
                _PlanTile(
                  title: 'Monthly',
                  price: monthly.storeProduct.priceString,
                  subtitle: sub.isOnMonthlyPlan && sub.renewalLabel != null
                      ? 'Current plan · ${sub.renewalLabel}'
                      : _planSubtitle(monthly, fallback: 'Billed monthly'),
                  selected: !_yearlySelected,
                  isCurrent: sub.isOnMonthlyPlan,
                  onTap: sub.isOnMonthlyPlan
                      ? null
                      : () => setState(() => _yearlySelected = false),
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
              const SizedBox(height: 24),
              SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: sub.isLoading ||
                          (yearly == null && monthly == null) ||
                          selectingCurrent
                      ? null
                      : _purchase,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4979FB),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        Colors.grey.shade300,
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
                          selectingCurrent
                              ? 'You\'re on Pro'
                              : sub.isPro
                                  ? 'Switch plan'
                                  : 'Continue',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
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
        ),
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
    required this.isCurrent,
    required this.onTap,
  });

  final String title;
  final String price;
  final String subtitle;
  final bool selected;
  final bool isCurrent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textColor = isCurrent
        ? Colors.grey.shade500
        : Theme.of(context).colorScheme.inversePrimary;
    final borderColor = isCurrent
        ? Colors.grey.withValues(alpha: 0.35)
        : selected
            ? const Color(0xFF4979FB)
            : Colors.grey.withValues(alpha: 0.25);
    final background = isCurrent
        ? Colors.grey.withValues(alpha: 0.08)
        : selected
            ? const Color(0xFF4979FB).withValues(alpha: 0.06)
            : Theme.of(context).colorScheme.surface;

    return Opacity(
      opacity: isCurrent ? 0.72 : 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: borderColor,
              width: selected && !isCurrent ? 2 : 1,
            ),
            color: background,
          ),
          child: Row(
            children: [
              Icon(
                isCurrent
                    ? Icons.check_circle_outline
                    : selected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                color: isCurrent
                    ? Colors.grey.shade500
                    : selected
                        ? const Color(0xFF4979FB)
                        : Colors.grey,
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
                        color: isCurrent
                            ? Colors.grey.shade500
                            : Colors.grey.shade600,
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
      ),
    );
  }
}
