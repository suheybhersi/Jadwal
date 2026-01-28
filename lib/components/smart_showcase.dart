import 'package:flutter/material.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:jadwal/services/tutorial_service.dart';
import 'package:provider/provider.dart';

/// Smart showcase wrapper that only shows if tooltip hasn't been seen
class SmartShowcase extends StatelessWidget {
  final String tooltipId;
  final String title;
  final String description;
  final Widget child;
  final GlobalKey globalKey;
  final bool showOnce;

  const SmartShowcase({
    super.key,
    required this.tooltipId,
    required this.title,
    required this.description,
    required this.child,
    required this.globalKey,
    this.showOnce = true,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<TutorialService>(
      builder: (context, tutorialService, _) {
        // Always include Showcase in tree, but only start it if not seen
        // The showcase needs to be in the widget tree for startShowCase to work
        return Showcase(
          key: globalKey,
          title: title,
          description: description,
          targetShapeBorder: const CircleBorder(),
          tooltipBackgroundColor: Theme.of(context).colorScheme.surface,
          textColor: Theme.of(context).colorScheme.inversePrimary,
          overlayColor: Colors.black.withValues(alpha: 0.7),
          disposeOnTap: true,
          onTargetClick: () {
            if (showOnce) {
              tutorialService.markTooltipSeen(tooltipId);
            }
          },
          onBarrierClick: () {
            if (showOnce) {
              tutorialService.markTooltipSeen(tooltipId);
            }
          },
          child: child,
        );
      },
    );
  }
}
