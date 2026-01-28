import 'package:flutter/material.dart';
import 'package:jadwal/components/smart_showcase.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:jadwal/services/tutorial_service.dart';
import 'package:provider/provider.dart';

/// Button wrapper that shows a showcase tooltip on first use
class ShowcaseButton extends StatelessWidget {
  final String tooltipId;
  final String title;
  final String description;
  final Widget button;
  final bool showOnce;
  final VoidCallback? onShowcaseStart;

  const ShowcaseButton({
    super.key,
    required this.tooltipId,
    required this.title,
    required this.description,
    required this.button,
    this.showOnce = true,
    this.onShowcaseStart,
  });

  @override
  Widget build(BuildContext context) {
    final key = GlobalKey();
    
    // Start showcase if needed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final tutorialService = Provider.of<TutorialService>(context, listen: false);
      if (!tutorialService.hasSeenTooltip(tooltipId)) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (context.mounted) {
            ShowcaseView.get().startShowCase([key]);
            onShowcaseStart?.call();
          }
        });
      }
    });

    return SmartShowcase(
      tooltipId: tooltipId,
      title: title,
      description: description,
      globalKey: key,
      showOnce: showOnce,
      child: button,
    );
  }
}
