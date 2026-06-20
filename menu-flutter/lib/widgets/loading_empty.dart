import 'package:flutter/material.dart';

import '../core/theme.dart';

/// 加载态。
class LoadingView extends StatelessWidget {
  const LoadingView({super.key});
  @override
  Widget build(BuildContext context) => const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
}

/// 空态（复刻小程序「暂无菜品」等灰字居中样式）。
class EmptyView extends StatelessWidget {
  final String text;
  const EmptyView({super.key, this.text = '暂无数据'});
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Text(text, style: const TextStyle(color: AppColors.textSecondary)),
        ),
      );
}
