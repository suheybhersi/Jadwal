import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Brand blue used across Settings, paywall, and auth.
const Color kAuthBrandBlue = Color(0xFF4979FB);
const Color kAuthBrandBlueLight = Color(0xFF5C89FF);

/// Clean white surface — matches Settings' calm light feel.
class AuthGradientScaffold extends StatelessWidget {
  const AuthGradientScaffold({
    super.key,
    required this.child,
    this.resizeToAvoidBottomInset = true,
  });

  final Widget child;
  final bool resizeToAvoidBottomInset;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      body: SafeArea(child: child),
    );
  }
}

/// Brand-first header: logo + Jadwal name, optional title + subtitle.
class AuthHeader extends StatelessWidget {
  const AuthHeader({
    super.key,
    this.title,
    this.subtitle,
    this.logoHeight = 72,
    this.centered = true,
  });

  final String? title;
  final String? subtitle;
  final double logoHeight;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.inversePrimary;
    final cross = centered ? CrossAxisAlignment.center : CrossAxisAlignment.start;
    final align = centered ? TextAlign.center : TextAlign.start;

    return Column(
      crossAxisAlignment: cross,
      children: [
        Image(
          height: logoHeight,
          image: const AssetImage('assets/app_logo.png'),
        ),
        const SizedBox(height: 12),
        Text(
          'Jadwal',
          style: GoogleFonts.poppins(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: textColor,
            letterSpacing: -0.3,
          ),
          textAlign: align,
        ),
        if (title != null) ...[
          const SizedBox(height: 8),
          Text(
            title!,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
            textAlign: align,
          ),
        ],
        if (subtitle != null) ...[
          const SizedBox(height: 6),
          Text(
            subtitle!,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Colors.grey.shade600,
              height: 1.4,
            ),
            textAlign: align,
          ),
        ],
      ],
    );
  }
}

/// Soft blue-wash icon tile (Settings-style).
class AuthIconTile extends StatelessWidget {
  const AuthIconTile({
    super.key,
    required this.icon,
    this.size = 88,
    this.iconSize = 40,
  });

  final IconData icon;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            kAuthBrandBlue.withValues(alpha: 0.12),
            kAuthBrandBlueLight.withValues(alpha: 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: kAuthBrandBlue.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Icon(icon, size: iconSize, color: kAuthBrandBlue),
    );
  }
}

/// Full-width primary CTA matching paywall / settings actions.
class AuthPrimaryButton extends StatelessWidget {
  const AuthPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.enabled = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: enabled
              ? kAuthBrandBlue
              : kAuthBrandBlue.withValues(alpha: 0.45),
          foregroundColor: Colors.white,
          disabledBackgroundColor: kAuthBrandBlue.withValues(alpha: 0.45),
          disabledForegroundColor: Colors.white.withValues(alpha: 0.9),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

/// Bottom switch link: "Don't have an account? Sign up"
class AuthSwitchPrompt extends StatelessWidget {
  const AuthSwitchPrompt({
    super.key,
    required this.prompt,
    required this.actionLabel,
    required this.onTap,
  });

  final String prompt;
  final String actionLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          prompt,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(width: 4),
        GestureDetector(
          onTap: onTap,
          child: Text(
            actionLabel,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: kAuthBrandBlue,
            ),
          ),
        ),
      ],
    );
  }
}

/// Page dots for onboarding carousel.
class AuthPageIndicator extends StatelessWidget {
  const AuthPageIndicator({
    super.key,
    required this.count,
    required this.index,
  });

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 8,
          width: active ? 22 : 8,
          decoration: BoxDecoration(
            color: active
                ? kAuthBrandBlue
                : kAuthBrandBlue.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
        );
      }),
    );
  }
}

void showAuthAlertDialog(
  BuildContext context, {
  required String title,
  required String message,
  String actionLabel = 'Close',
}) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      content: Text(
        message,
        style: GoogleFonts.poppins(
          fontSize: 14,
          color: Colors.grey.shade700,
          height: 1.4,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            actionLabel,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              color: kAuthBrandBlue,
            ),
          ),
        ),
      ],
    ),
  );
}
