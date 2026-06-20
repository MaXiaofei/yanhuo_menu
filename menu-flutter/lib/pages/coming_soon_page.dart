import 'package:flutter/material.dart';

import '../core/theme.dart';

/// 占位页：P0 未实现的页面先指向这里，P1/P2 逐步替换为真实页面。
class ComingSoonPage extends StatelessWidget {
  final String title;
  const ComingSoonPage({super.key, required this.title});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(title)),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.construction, size: 64, color: AppColors.primary),
              const SizedBox(height: 16),
              Text('$title（开发中）',
                  style: const TextStyle(fontSize: 16, color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              const Text('该页面将在后续版本上线',
                  style: TextStyle(fontSize: 13, color: AppColors.textHint)),
            ],
          ),
        ),
      );
}
