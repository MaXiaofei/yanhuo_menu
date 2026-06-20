import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../core/theme.dart';
import '../models/nutrition_metric.dart';

/// 营养展示：把 metrics(字典) + values(指标id→值) 合成「中文指标 | 值(橙粗) | 单位(灰)」列表。
/// 复刻 menu-mini/src/pages/dish/Detail.vue 的 nutritionDisplay + nutrition-row 样式。
class NutritionGrid extends StatelessWidget {
  final List<NutritionMetric> metrics;
  final Map<String, num> values; // metricId(字符串) → 值

  const NutritionGrid({super.key, required this.metrics, required this.values});

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (final m in metrics) {
      final v = values[m.id.toString()];
      if (v == null) continue;
      rows.add(Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.rowDivider)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                AppConstants.metricNameCn(m.name),
                style: const TextStyle(fontSize: 14, color: Color(0xFF333333)),
              ),
            ),
            Text(
              _fmt(v),
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 6),
            SizedBox(
              width: 60,
              child: Text(
                m.unit,
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      ));
    }
    if (rows.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(children: rows),
    );
  }

  String _fmt(num v) {
    if (v == v.roundToDouble()) return v.toInt().toString();
    return v.toStringAsFixed(1);
  }
}
