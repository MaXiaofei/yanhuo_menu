/// 营养指标字典（对应后端 NutritionMetric：{id,name,unit,metricGroup,sort}）。
/// name 是英文（calorie/protein/...），渲染时经 AppConstants.metricNameCn 转中文。
class NutritionMetric {
  final int id;
  final String name;
  final String unit;

  const NutritionMetric({required this.id, required this.name, required this.unit});

  factory NutritionMetric.fromJson(Map<String, dynamic> j) => NutritionMetric(
        id: (j['id'] as num).toInt(),
        name: (j['name'] ?? '') as String,
        unit: (j['unit'] ?? '') as String,
      );
}
