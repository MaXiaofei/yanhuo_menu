import 'package:flutter/material.dart';

import '../core/theme.dart';

/// 通用卡片：白底 + 大圆角 + 柔和阴影。整个 App 卡片流的基础组件。
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final double radius;
  final VoidCallback? onTap;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 20,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) => Material(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(radius),
        elevation: 1.5,
        shadowColor: const Color(0x1A000000),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(radius),
          child: Padding(padding: padding, child: child),
        ),
      );
}
