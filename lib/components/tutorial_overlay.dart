import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

/// Tutorial step data
class TutorialStep {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final GlobalKey targetKey;
  final Alignment targetAlignment;
  final String? imageAsset;

  const TutorialStep({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.targetKey,
    this.targetAlignment = Alignment.center,
    this.imageAsset,
  });
}

/// Tutorial overlay widget
class TutorialOverlay extends StatelessWidget {
  final List<TutorialStep> steps;
  final int currentStep;
  final VoidCallback onNext;
  final VoidCallback onSkip;
  final VoidCallback onComplete;

  const TutorialOverlay({
    super.key,
    required this.steps,
    required this.currentStep,
    required this.onNext,
    required this.onSkip,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    if (currentStep >= steps.length) {
      return SizedBox();
    }

    final step = steps[currentStep];
    final isLastStep = currentStep == steps.length - 1;

    return Stack(
      children: [
        // Dark overlay with hole
        _buildOverlay(context, step),
        
        // Tutorial card
        _buildTutorialCard(context, step, isLastStep),
      ],
    );
  }

  Widget _buildOverlay(BuildContext context, TutorialStep step) {
    return GestureDetector(
      onTap: onSkip,
      child: Container(
        color: Colors.black.withValues(alpha: 0.7),
        child: CustomPaint(
          painter: TutorialPainter(
            targetKey: step.targetKey,
            targetAlignment: step.targetAlignment,
          ),
        ),
      ),
    );
  }

  Widget _buildTutorialCard(
    BuildContext context,
    TutorialStep step,
    bool isLastStep,
  ) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Step indicator
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: (currentStep + 1) / steps.length,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(step.color),
                    minHeight: 4,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${currentStep + 1}/${steps.length}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Icon and title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: step.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    step.icon,
                    color: step.color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    step.title,
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.inversePrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Description
            Text(
              step.description,
              style: GoogleFonts.poppins(
                fontSize: 15,
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),

            // Buttons
            Row(
              children: [
                TextButton(
                  onPressed: onSkip,
                  child: Text(
                    'Skip',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
                const Spacer(),
                if (!isLastStep)
                  ElevatedButton(
                    onPressed: onNext,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: step.color,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: Text(
                      'Next',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  )
                else
                  ElevatedButton(
                    onPressed: onComplete,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: step.color,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: Text(
                      'Get Started',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom painter for tutorial overlay with hole
class TutorialPainter extends CustomPainter {
  final GlobalKey targetKey;
  final Alignment targetAlignment;

  TutorialPainter({
    required this.targetKey,
    required this.targetAlignment,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.7)
      ..style = PaintingStyle.fill;

    // Fill entire canvas
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // Find target widget position
    final RenderBox? renderBox =
        targetKey.currentContext?.findRenderObject() as RenderBox?;
    
    if (renderBox != null) {
      final position = renderBox.localToGlobal(Offset.zero);
      final targetSize = renderBox.size;

      // Create hole with padding
      const padding = 8.0;
      final holeRect = Rect.fromLTWH(
        position.dx - padding,
        position.dy - padding,
        targetSize.width + (padding * 2),
        targetSize.height + (padding * 2),
      );

      // Cut hole using difference
      final path = Path()
        ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
        ..addRRect(
          RRect.fromRectAndRadius(
            holeRect,
            const Radius.circular(12),
          ),
        )
        ..fillType = PathFillType.evenOdd;

      canvas.drawPath(path, Paint()..color = Colors.transparent);
      canvas.clipPath(path);
    }
  }

  @override
  bool shouldRepaint(TutorialPainter oldDelegate) {
    return oldDelegate.targetKey != targetKey ||
        oldDelegate.targetAlignment != targetAlignment;
  }
}

/// Helper function to show tutorial
Future<void> showTutorial({
  required BuildContext context,
  required List<TutorialStep> steps,
  required VoidCallback onComplete,
}) async {
  int currentStep = 0;

  await showDialog(
    context: context,
    barrierColor: Colors.transparent,
    barrierDismissible: false,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        return TutorialOverlay(
          steps: steps,
          currentStep: currentStep,
          onNext: () {
            if (currentStep < steps.length - 1) {
              setState(() => currentStep++);
            }
          },
          onSkip: () {
            Navigator.pop(context);
            onComplete();
          },
          onComplete: () {
            Navigator.pop(context);
            onComplete();
          },
        );
      },
    ),
  );
}
