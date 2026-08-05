import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:jadwal/services/subscription_service.dart';

/// Compact CTA that opens the paywall for free users. Hidden when Pro.
class ProUpgradeBanner extends StatelessWidget {
  const ProUpgradeBanner({
    super.key,
    this.title = 'Upgrade to Pro',
    this.subtitle =
        'Unlimited quizzes, Fill in the Blank & What Comes Next',
    this.margin = EdgeInsets.zero,
    this.compact = false,
  });

  final String title;
  final String subtitle;
  final EdgeInsetsGeometry margin;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Consumer<SubscriptionService>(
      builder: (context, sub, _) {
        if (sub.isPro) return const SizedBox.shrink();

        return Padding(
          padding: margin,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => sub.openPaywall(context),
              borderRadius: BorderRadius.circular(compact ? 12 : 16),
              child: Ink(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(compact ? 12 : 16),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4979FB), Color(0xFF3A5FCB)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4979FB).withValues(alpha: 0.28),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: compact ? 14 : 16,
                    vertical: compact ? 12 : 14,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(compact ? 8 : 10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Iconsax.crown_1,
                          color: Colors.white,
                          size: compact ? 18 : 22,
                        ),
                      ),
                      SizedBox(width: compact ? 10 : 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: GoogleFonts.poppins(
                                fontSize: compact ? 14 : 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            if (!compact) ...[
                              const SizedBox(height: 2),
                              Text(
                                subtitle,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.white.withValues(alpha: 0.9),
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Icon(
                        Iconsax.arrow_right_3,
                        color: Colors.white.withValues(alpha: 0.9),
                        size: compact ? 16 : 18,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Small chip for headers (e.g. Home). Hidden when Pro.
class ProUpgradeChip extends StatelessWidget {
  const ProUpgradeChip({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SubscriptionService>(
      builder: (context, sub, _) {
        if (sub.isPro) return const SizedBox.shrink();

        return GestureDetector(
          onTap: () => sub.openPaywall(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFF4979FB).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: const Color(0xFF4979FB).withValues(alpha: 0.35),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Iconsax.crown_1,
                  size: 11,
                  color: Color(0xFF4979FB),
                ),
                const SizedBox(width: 4),
                Text(
                  'Upgrade',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF4979FB),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
