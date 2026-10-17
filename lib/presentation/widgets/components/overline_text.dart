import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

/// Tek satırlık "overline" etiketi (uppercase çağırana aittir).
class OverlineText extends StatelessWidget {
  final String text;
  final Color? color;

  const OverlineText(this.text, {super.key, this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: AppTextStyles.overline(color: color ?? AppColors.mist),
    );
  }
}
