import 'package:flutter/material.dart';

import 'space.dart';
import 'surface.dart';
import 'tokens.dart';

/// Serif page title with an optional muted subtitle.
class PageHeading extends StatelessWidget {
  const PageHeading(this.title, {super.key, this.subtitle, this.center = false});

  final String title;
  final String? subtitle;
  final bool center;

  @override
  Widget build(BuildContext context) {
    final t = context.ui;
    final align = center ? TextAlign.center : TextAlign.start;
    return Column(
      crossAxisAlignment: center ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Text(title, textAlign: align, style: Theme.of(context).textTheme.headlineMedium),
        if (subtitle != null) ...[
          const SizedBox(height: 6),
          Text(subtitle!, textAlign: align, style: TextStyle(fontSize: 17, color: t.textMuted, height: 1.35)),
        ],
      ],
    );
  }
}

/// Serif section heading ("Next steps").
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key, this.trailing});
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: Space.section, bottom: Space.gap),
        child: Row(
          children: [
            Expanded(child: Text(title, style: Theme.of(context).textTheme.titleLarge)),
            if (trailing != null) trailing!,
          ],
        ),
      );
}

/// Label, value and a rounded bar showing [fraction] (0–1).
class ProgressRow extends StatelessWidget {
  const ProgressRow({
    super.key,
    required this.label,
    required this.value,
    required this.fraction,
    this.color,
  });

  final String label;
  final String value;
  final double fraction;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final t = context.ui;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: Text(label, style: TextStyle(fontSize: 16, color: t.text))),
            Text(value, style: TextStyle(fontSize: 16, color: t.text, fontFeatures: const [FontFeature.tabularFigures()])),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: Stack(
            children: [
              Container(height: 6, color: t.track),
              FractionallySizedBox(
                widthFactor: fraction.clamp(0.0, 1.0),
                child: Container(height: 6, color: color ?? t.chartPrimary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A notice with an info icon, title, detail and chevron.
class InfoCard extends StatelessWidget {
  const InfoCard({
    super.key,
    required this.title,
    this.detail,
    this.onTap,
    this.icon = Icons.info_outline,
    this.iconColor,
  });

  final String title;
  final String? detail;
  final VoidCallback? onTap;
  final IconData icon;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final t = context.ui;
    return Surface(
      flat: true,
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, color: iconColor ?? t.info, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: t.text)),
                if (detail != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(detail!, style: TextStyle(fontSize: 14, color: t.textMuted, height: 1.35)),
                  ),
              ],
            ),
          ),
          if (onTap != null) Icon(Icons.chevron_right, color: t.textMuted),
        ],
      ),
    );
  }
}

/// Pale mint circle behind an icon.
class IconWell extends StatelessWidget {
  const IconWell({super.key, required this.icon, this.size = 44});
  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    final t = context.ui;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: t.tint, shape: BoxShape.circle),
      child: Icon(icon, color: t.onTint, size: size * 0.5),
    );
  }
}

/// Text link with a dotted underline.
class DottedLink extends StatelessWidget {
  const DottedLink(this.label, {super.key, required this.onTap, this.color});
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final t = context.ui;
    final c = color ?? t.text;
    return Semantics(
      link: true,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 15,
              color: c,
              decoration: TextDecoration.underline,
              decorationStyle: TextDecorationStyle.dotted,
              decorationColor: c,
              decorationThickness: 2,
            ),
          ),
        ),
      ),
    );
  }
}

/// "How we got these numbers" with a question-mark icon.
class HelpLink extends StatelessWidget {
  const HelpLink(this.label, {super.key, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.ui;
    return Center(
      child: TextButton.icon(
        onPressed: onTap,
        style: TextButton.styleFrom(foregroundColor: t.text, minimumSize: const Size(0, 44)),
        icon: const Icon(Icons.help_outline, size: 20),
        label: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      ),
    );
  }
}

/// Half-width suggestion card: icon well, sentence, dotted link.
class ActionTile extends StatelessWidget {
  const ActionTile({
    super.key,
    required this.icon,
    required this.text,
    required this.linkLabel,
    required this.onTap,
  });

  final IconData icon;
  final String text;
  final String linkLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.ui;
    return Surface(
      flat: true,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconWell(icon: icon),
          const SizedBox(height: 12),
          Text(text, style: TextStyle(fontSize: 16, color: t.text, height: 1.3)),
          const SizedBox(height: 6),
          DottedLink(linkLabel, onTap: onTap),
        ],
      ),
    );
  }
}

/// Label on the left, amount on the right, optional section reference.
class LedgerRow extends StatelessWidget {
  const LedgerRow({
    super.key,
    required this.label,
    required this.amount,
    this.note,
    this.bold = false,
    this.color,
  });

  final String label;
  final String amount;
  final String? note;
  final bool bold;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final t = context.ui;
    final w = bold ? FontWeight.w700 : FontWeight.w400;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: bold ? 17 : 16, fontWeight: w, color: t.text)),
                if (note != null)
                  Text(note!, style: TextStyle(fontSize: 13, color: t.textMuted)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            amount,
            style: TextStyle(
              fontSize: bold ? 17 : 16,
              fontWeight: w,
              color: color ?? t.text,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
