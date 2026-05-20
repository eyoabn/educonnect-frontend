import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// ── GradientHeader ────────────────────────────────────────────────────────────
class GradientHeader extends StatelessWidget {
  final LinearGradient gradient;
  final Widget child;
  final double bottomRadius;
  const GradientHeader({super.key, required this.gradient, required this.child, this.bottomRadius = 40});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      gradient: gradient,
      borderRadius: BorderRadius.only(
        bottomLeft: Radius.circular(bottomRadius),
        bottomRight: Radius.circular(bottomRadius),
      ),
      boxShadow: [BoxShadow(color: gradient.colors.first.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 8))],
    ),
    child: child,
  );
}

// ── GlassCard ─────────────────────────────────────────────────────────────────
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final double borderRadius;
  const GlassCard({super.key, required this.child, this.padding, this.onTap, this.borderRadius = 20});

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white.withOpacity(0.88),
    borderRadius: BorderRadius.circular(borderRadius),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(borderRadius),
      child: Container(
        padding: padding ?? const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(color: AppColors.border, width: 1),
          boxShadow: [BoxShadow(color: AppColors.violet.withOpacity(0.07), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: child,
      ),
    ),
  );
}

// ── GradientIconBox ───────────────────────────────────────────────────────────
class GradientIconBox extends StatelessWidget {
  final LinearGradient gradient;
  final IconData icon;
  final double size;
  final double iconSize;
  const GradientIconBox({super.key, required this.gradient, required this.icon, this.size = 52, this.iconSize = 26});

  @override
  Widget build(BuildContext context) => Container(
    width: size, height: size,
    decoration: BoxDecoration(
      gradient: gradient,
      borderRadius: BorderRadius.circular(size * 0.35),
      boxShadow: [BoxShadow(color: gradient.colors.first.withOpacity(0.35), blurRadius: 10, offset: const Offset(0, 4))],
    ),
    child: Icon(icon, color: Colors.white, size: iconSize),
  );
}

// ── GradientBadge ─────────────────────────────────────────────────────────────
class GradientBadge extends StatelessWidget {
  final String text;
  final LinearGradient gradient;
  const GradientBadge({super.key, required this.text, required this.gradient});

  @override
  Widget build(BuildContext context) => Container(
    width: 28, height: 28,
    decoration: BoxDecoration(gradient: gradient, shape: BoxShape.circle,
      boxShadow: [BoxShadow(color: gradient.colors.first.withOpacity(0.5), blurRadius: 8)]),
    child: Center(child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold))),
  );
}

// ── GradientProgressBar ───────────────────────────────────────────────────────
class GradientProgressBar extends StatelessWidget {
  final double progress;
  final LinearGradient gradient;
  final double height;
  const GradientProgressBar({super.key, required this.progress, required this.gradient, this.height = 6});

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(height),
    child: Stack(children: [
      Container(height: height, color: Colors.grey.shade200),
      FractionallySizedBox(
        widthFactor: progress.clamp(0.0, 1.0),
        child: Container(height: height, decoration: BoxDecoration(gradient: gradient, borderRadius: BorderRadius.circular(height))),
      ),
    ]),
  );
}

// ── GradientButton ────────────────────────────────────────────────────────────
class GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final LinearGradient gradient;
  final bool isLoading;
  final IconData? icon;
  const GradientButton({super.key, required this.label, required this.onPressed, required this.gradient, this.isLoading = false, this.icon});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: isLoading ? null : onPressed,
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        gradient: gradient, borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: gradient.colors.first.withOpacity(0.45), blurRadius: 14, offset: const Offset(0, 5))],
      ),
      child: Center(child: isLoading
        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
        : Row(mainAxisSize: MainAxisSize.min, children: [
            if (icon != null) ...[Icon(icon, color: Colors.white, size: 18), const SizedBox(width: 8)],
            Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ]),
      ),
    ),
  );
}

// ── FilterBar ─────────────────────────────────────────────────────────────────
class FilterBar extends StatelessWidget {
  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final LinearGradient activeGradient;
  const FilterBar({super.key, required this.labels, required this.selectedIndex, required this.onSelected, required this.activeGradient});

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(children: List.generate(labels.length, (i) {
      final active = i == selectedIndex;
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: GestureDetector(
          onTap: () => onSelected(i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              gradient: active ? activeGradient : null,
              color: active ? null : Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [BoxShadow(
                color: active ? activeGradient.colors.first.withOpacity(0.4) : Colors.black.withOpacity(0.07),
                blurRadius: 8, offset: const Offset(0, 3),
              )],
            ),
            child: Text(labels[i], style: TextStyle(
              color: active ? Colors.white : Colors.grey.shade600,
              fontWeight: FontWeight.bold, fontSize: 13,
            )),
          ),
        ),
      );
    })),
  );
}

// ── SectionHeader ─────────────────────────────────────────────────────────────
class SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;
  const SectionHeader({super.key, required this.title, this.trailing});

  @override
  Widget build(BuildContext context) => Row(children: [
    Container(width: 4, height: 22, decoration: BoxDecoration(gradient: AppGradients.violet, borderRadius: BorderRadius.circular(2))),
    const SizedBox(width: 10),
    Expanded(child: Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary))),
    if (trailing != null) trailing!,
  ]);
}

// ── EmptyState ────────────────────────────────────────────────────────────────
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final LinearGradient? gradient;
  const EmptyState({super.key, required this.icon, required this.title, required this.subtitle, this.gradient});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 80, height: 80,
        decoration: BoxDecoration(gradient: gradient ?? AppGradients.violet, borderRadius: BorderRadius.circular(28),
          boxShadow: [BoxShadow(color: AppColors.violet.withOpacity(0.35), blurRadius: 20, offset: const Offset(0, 8))]),
        child: Icon(icon, color: Colors.white, size: 38),
      ),
      const SizedBox(height: 16),
      Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
      const SizedBox(height: 4),
      Text(subtitle, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
    ]),
  );
}

// ── InfoChip ──────────────────────────────────────────────────────────────────
class InfoChip extends StatelessWidget {
  final String label;
  final Color color;
  const InfoChip({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
    child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
  );
}

// ── BackButton ────────────────────────────────────────────────────────────────
class AppBackButton extends StatelessWidget {
  final VoidCallback? onTap;
  const AppBackButton({super.key, this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap ?? () => Navigator.pop(context),
    child: Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 22),
    ),
  );
}

// ── LoadingOverlay ────────────────────────────────────────────────────────────
class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  const LoadingOverlay({super.key, required this.isLoading, required this.child});

  @override
  Widget build(BuildContext context) => Stack(children: [
    child,
    if (isLoading)
      Container(
        color: Colors.black.withOpacity(0.35),
        child: const Center(child: CircularProgressIndicator(color: Colors.white)),
      ),
  ]);
}

// ── StatCard ──────────────────────────────────────────────────────────────────
class StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final LinearGradient gradient;
  const StatCard({super.key, required this.icon, required this.label, required this.value, required this.gradient});

  @override
  Widget build(BuildContext context) => GlassCard(
    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
    child: Column(children: [
      GradientIconBox(gradient: gradient, icon: icon, size: 40, iconSize: 18),
      const SizedBox(height: 8),
      Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
      const SizedBox(height: 2),
      Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary), textAlign: TextAlign.center),
    ]),
  );
}
