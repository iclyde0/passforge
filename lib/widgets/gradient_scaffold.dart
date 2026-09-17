import 'package:flutter/material.dart';

import '../branding.dart';
import '../theme/app_theme.dart';

class GradientScaffold extends StatelessWidget {
  const GradientScaffold({
    super.key,
    required this.child,
    this.appBar,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.accent,
  });

  final Widget child;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  /// Optional exam accent. Brand screens omit this so logo violet washes apply.
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final tint = accent ?? AppColors.violet;
    final isBrand = accent == null;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isBrand
              ? [
                  Color.lerp(Colors.white, AppColors.violetLight, 0.55)!,
                  AppColors.canvas,
                  Color.lerp(AppColors.canvas, AppColors.violetDark, 0.12)!,
                ]
              : [
                  Color.lerp(Colors.white, tint, 0.16)!,
                  AppColors.canvas,
                  Color.lerp(const Color(0xFFEDE9FE), tint, 0.2)!,
                ],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: appBar,
        floatingActionButton: floatingActionButton,
        bottomNavigationBar: bottomNavigationBar,
        body: SafeArea(child: child),
      ),
    );
  }
}

class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.child,
    this.padding,
    this.accent,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final tint = accent ?? AppColors.violet;
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tint.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: (accent ?? AppBranding.logoDeep).withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class ExamColorChip extends StatelessWidget {
  const ExamColorChip({
    super.key,
    required this.label,
    required this.color,
    this.selected = false,
  });

  final String label;
  final Color color;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: selected ? 0.28 : 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: selected ? 0.9 : 0.45),
          width: selected ? 1.6 : 1,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Color.lerp(Colors.black87, color, 0.35),
        ),
      ),
    );
  }
}
