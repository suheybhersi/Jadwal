import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

/// Interactive celebration widget for completion events
class CelebrationWidget extends StatefulWidget {
  final String title;
  final String message;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final List<StatisticItem>? statistics;
  final VoidCallback? onContinue;
  final String? continueText;

  const CelebrationWidget({
    super.key,
    required this.title,
    required this.message,
    this.subtitle,
    this.icon = Iconsax.tick_circle,
    this.color = const Color(0xFF4979FB),
    this.statistics,
    this.onContinue,
    this.continueText = 'Continue',
  });

  @override
  State<CelebrationWidget> createState() => _CelebrationWidgetState();
}

class _CelebrationWidgetState extends State<CelebrationWidget>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _fadeController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  bool _continuing = false;

  @override
  void initState() {
    super.initState();

    // Scale animation for icon
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );

    // Fade animation for content
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );

    // Start animations
    _scaleController.forward();
    _fadeController.forward();
  }

  void _handleContinue() {
    if (_continuing) return;
    setState(() => _continuing = true);
    (widget.onContinue ?? () => Navigator.pop(context))();
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.9,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.3),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Animated icon
                AnimatedBuilder(
              animation: _scaleAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: widget.color.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      widget.icon,
                      size: 40,
                      color: widget.color,
                    ),
                  ),
                );
              },
                ),
                const SizedBox(height: 24),

                // Title
                FadeTransition(
              opacity: _fadeAnimation,
              child: Text(
                widget.title,
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.inversePrimary,
                ),
                textAlign: TextAlign.center,
              ),
                ),
                const SizedBox(height: 8),

                // Message
                FadeTransition(
              opacity: _fadeAnimation,
              child: Text(
                widget.message,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                textAlign: TextAlign.center,
              ),
                ),

                // Subtitle if provided
                if (widget.subtitle != null) ...[
                  const SizedBox(height: 8),
                  FadeTransition(
                opacity: _fadeAnimation,
                child: Text(
                  widget.subtitle!,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                  ),
                ],

                // Statistics if provided
                if (widget.statistics != null && widget.statistics!.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  FadeTransition(
                opacity: _fadeAnimation,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: widget.color.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: widget.statistics!.map((stat) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Row(
                                children: [
                                  Icon(
                                    stat.icon,
                                    size: 20,
                                    color: widget.color,
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      stat.label,
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .inversePrimary,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                stat.value,
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: widget.color,
                                ),
                                textAlign: TextAlign.end,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
                  ),
                ],

                const SizedBox(height: 24),

                // Continue button
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _continuing ? null : _handleContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.color,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        widget.color.withValues(alpha: 0.6),
                    disabledForegroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    widget.continueText!,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
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

/// Statistics item for celebration widget
class StatisticItem {
  final String label;
  final String value;
  final IconData icon;

  const StatisticItem({
    required this.label,
    required this.value,
    required this.icon,
  });
}

/// Helper function to show celebration dialog
Future<void> showCelebrationDialog({
  required BuildContext context,
  required String title,
  required String message,
  String? subtitle,
  IconData icon = Iconsax.tick_circle,
  Color? color,
  List<StatisticItem>? statistics,
  VoidCallback? onContinue,
  String? continueText,
}) async {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => CelebrationWidget(
      title: title,
      message: message,
      subtitle: subtitle,
      icon: icon,
      color: color ?? const Color(0xFF4979FB),
      statistics: statistics,
      onContinue: onContinue ?? () => Navigator.pop(context),
      continueText: continueText,
    ),
  );
}
