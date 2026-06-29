import '../core/api_client.dart';

/// AI 服务。
class AiService {
  /// AI 补全食材营养：输入食材名 → 返回 6 项 per100g 营养值。
  ///
  /// 返回示例：{ "nutrition": [{"metricId":1,"value":74}, ...], "source": "deepseek" }
  static Future<AiNutritionFillResult> aiFillNutrition(String name) async {
    final data = await ApiClient.instance.post(
      '/ai/nutrition/fill',
      body: {'name': name},
    );
    return AiNutritionFillResult.fromJson(data as Map<String, dynamic>);
  }
}

class AiNutritionFillResult {
  final List<AiNutritionItem> nutrition;
  final String source;

  const AiNutritionFillResult({
    required this.nutrition,
    required this.source,
  });

  factory AiNutritionFillResult.fromJson(Map<String, dynamic> j) {
    return AiNutritionFillResult(
      nutrition: ((j['nutrition'] ?? []) as List)
          .map((e) => AiNutritionItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      source: (j['source'] ?? '') as String,
    );
  }

  /// metricId → value 的 Map，方便表单回填。
  Map<int, num> get valueMap {
    final m = <int, num>{};
    for (final it in nutrition) {
      m[it.metricId] = it.value;
    }
    return m;
  }
}

class AiNutritionItem {
  final int metricId;
  final num value;

  const AiNutritionItem({required this.metricId, required this.value});

  factory AiNutritionItem.fromJson(Map<String, dynamic> j) => AiNutritionItem(
        metricId: (j['metricId'] as num).toInt(),
        value: (j['value'] as num),
      );
}
