import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class BrandMark extends StatelessWidget {
  const BrandMark({
    this.inverted = false,
    this.compact = false,
    this.tagline = true,
    super.key,
  });

  final bool inverted;
  final bool compact;

  /// Shows "Tablet de Segurança" below the logo.
  final bool tagline;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        decoration: inverted
            ? null
            : const BoxDecoration(
                color: AppTheme.blue,
                borderRadius: AppRadius.control,
              ),
        padding: inverted
            ? EdgeInsets.zero
            : const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
        child: Image.asset(
          'assets/branding/senai-white.webp',
          width: compact ? 108 : 144,
          height: compact ? 30 : 40,
          fit: BoxFit.contain,
          alignment: Alignment.centerLeft,
          semanticLabel: 'SENAI',
        ),
      ),
      if (tagline) ...[
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Tablet de Segurança',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: inverted ? AppTheme.onBrandMuted : AppTheme.muted,
            fontSize: compact ? 10 : 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ],
  );
}
