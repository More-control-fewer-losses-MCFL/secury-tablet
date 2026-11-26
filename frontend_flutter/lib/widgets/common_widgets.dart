import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

class SectionCard extends StatelessWidget {
  const SectionCard({
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.accent,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  /// Optional top strip that marks a card needing attention. Meaning is
  /// always repeated in text; the color is never the only signal.
  final Color? accent;

  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: accent == null ? Clip.none : Clip.antiAlias,
    child: accent == null
        ? Padding(padding: padding, child: child)
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              ColoredBox(color: accent!, child: const SizedBox(height: 3)),
              Padding(padding: padding, child: child),
            ],
          ),
  );
}

/// Metric card: discreet label, large tabular number, short caption.
class MetricCard extends StatelessWidget {
  const MetricCard({
    required this.label,
    required this.value,
    this.caption,
    this.color,
    super.key,
  });

  final String label;
  final String value;
  final String? caption;

  /// Semantic dot next to the label (the label itself carries the meaning).
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SectionCard(
      padding: const EdgeInsets.all(AppSpacing.md + AppSpacing.xxs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (color != null) ...[
                ExcludeSemantics(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                    child: const SizedBox.square(dimension: 8),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
              ],
              Flexible(
                child: Text(
                  label,
                  style: textTheme.bodyMedium?.copyWith(color: AppTheme.muted),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: textTheme.displaySmall?.copyWith(
              fontSize: 40,
              height: 1,
              fontFeatures: AppTheme.tabularFigures,
            ),
          ),
          if (caption != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(caption!, style: textTheme.bodySmall),
          ],
        ],
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {this.action, super.key});

  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final titleWidget = Semantics(
        header: true,
        child: Text(title, style: Theme.of(context).textTheme.titleMedium),
      );
      if (action != null &&
          (constraints.maxWidth < 480 ||
              MediaQuery.textScalerOf(context).scale(1) > 1.3)) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            titleWidget,
            const SizedBox(height: AppSpacing.xs),
            action!,
          ],
        );
      }
      return Row(
        children: [
          Expanded(child: titleWidget),
          if (action != null) ...[
            const SizedBox(width: AppSpacing.sm),
            action!,
          ],
        ],
      );
    },
  );
}

/// Empty/success states inside a card.
class StateMessage extends StatelessWidget {
  const StateMessage({
    required this.message,
    this.icon = Icons.info_outline,
    this.color = AppTheme.muted,
    super.key,
  });

  final String message;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(
      vertical: AppSpacing.lg,
      horizontal: AppSpacing.sm,
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 28, color: color),
        const SizedBox(height: AppSpacing.sm),
        Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    ),
  );
}

/// Quiet, static explanation shown at the end of a page (not a live alert).
class HintNote extends StatelessWidget {
  const HintNote(this.message, {this.icon = Icons.info_outline, super.key});

  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: const BoxDecoration(
      color: AppTheme.surfaceMuted,
      borderRadius: AppRadius.card,
      border: Border.fromBorderSide(BorderSide(color: AppTheme.border)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ExcludeSemantics(child: Icon(icon, size: 20, color: AppTheme.muted)),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(message, style: Theme.of(context).textTheme.bodySmall),
        ),
      ],
    ),
  );
}

class StatusPill extends StatelessWidget {
  const StatusPill(this.label, {required this.color, super.key});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 6),
    decoration: BoxDecoration(
      // Opaque tint: keeps the validated contrast on glass and dark surfaces.
      color: Color.alphaBlend(color.withValues(alpha: .08), Colors.white),
      border: Border.all(color: color.withValues(alpha: .18)),
      borderRadius: AppRadius.control,
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ExcludeSemantics(
          child: DecoratedBox(
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: const SizedBox.square(dimension: 6),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}

/// One strong title per screen, with a discreet subtitle.
class PageHeading extends StatelessWidget {
  const PageHeading(this.title, this.subtitle, {super.key});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(title, style: textTheme.headlineSmall),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            subtitle,
            style: textTheme.bodyMedium?.copyWith(color: AppTheme.muted),
          ),
        ],
      ),
    );
  }
}

class ErrorPanel extends StatelessWidget {
  const ErrorPanel({required this.message, this.onRetry, super.key});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => SectionCard(
    padding: const EdgeInsets.all(AppSpacing.lg),
    child: Column(
      children: [
        InlineNotice(
          title: 'Não foi possível carregar',
          message: message,
          icon: Icons.cloud_off_outlined,
        ),
        if (onRetry != null) ...[
          const SizedBox(height: AppSpacing.md),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_outlined),
            label: const Text('Tentar novamente'),
          ),
        ],
      ],
    ),
  );
}

/// Compact, persistent feedback near the control that caused it.
class InlineNotice extends StatelessWidget {
  const InlineNotice({
    required this.message,
    this.title,
    this.hint,
    this.color = AppTheme.danger,
    this.icon = Icons.error_outline,
    this.live = true,
    super.key,
  });

  /// Announce changes to assistive technology (false for static notes).
  final bool live;

  /// Optional heading; without it the message itself is the notice.
  final String? title;
  final String message;
  final String? hint;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: live,
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Color.alphaBlend(color.withValues(alpha: .06), Colors.white),
        border: Border.all(color: color.withValues(alpha: .22)),
        borderRadius: AppRadius.card,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExcludeSemantics(child: Icon(icon, size: 22, color: color)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null) ...[
                  Text(
                    title!,
                    style: TextStyle(color: color, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                ],
                // Explicit colors: the opaque fill stays light even when the
                // notice sits on dark glass with a white text theme.
                Text(
                  message,
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: AppTheme.text),
                ),
                if (hint != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    hint!,
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: AppTheme.muted),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
