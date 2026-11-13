import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class BrandMark extends StatelessWidget {
  const BrandMark({this.inverted = false, this.compact = false, super.key});

  final bool inverted;
  final bool compact;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        color: inverted ? Colors.transparent : const Color(0xFF075DA8),
        padding: inverted
            ? EdgeInsets.zero
            : const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Image.asset(
          'assets/branding/senai-white.webp',
          width: compact ? 108 : 144,
          height: compact ? 30 : 40,
          fit: BoxFit.contain,
          alignment: Alignment.centerLeft,
          semanticLabel: 'SENAI',
        ),
      ),
      const SizedBox(height: 8),
      Text(
        'Tablet de Segurança',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: inverted
              ? Colors.white.withValues(alpha: .78)
              : AppTheme.muted,
          fontSize: compact ? 10 : 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    ],
  );
}
