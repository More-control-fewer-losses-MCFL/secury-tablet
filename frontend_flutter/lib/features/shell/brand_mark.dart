import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class BrandMark extends StatelessWidget {
  const BrandMark({this.inverted = false, this.compact = false, super.key});

  final bool inverted;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final foreground = inverted ? Colors.white : AppTheme.navy;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: compact ? 34 : 40,
          height: compact ? 34 : 40,
          decoration: BoxDecoration(
            color: inverted ? Colors.white : AppTheme.paleBlue,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Icon(
            Icons.shield_outlined,
            color: inverted ? AppTheme.blue : AppTheme.blue,
            size: compact ? 20 : 24,
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'SENAI',
                style: TextStyle(
                  color: foreground,
                  fontSize: compact ? 13 : 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
              Text(
                'Tablet de Segurança',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: foreground.withValues(alpha: inverted ? 0.78 : 0.72),
                  fontSize: compact ? 10 : 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
