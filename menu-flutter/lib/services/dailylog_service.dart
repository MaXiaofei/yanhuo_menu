import '../core/api_client.dart';

/// 每日饮食记录服务。
class DailyLogService {
  /// 查某天日志：GET /dailylog?date=yyyy-MM-dd → DailyLogVO 或 null。
  static Future<DailyLogVO?> getDailyLog(String date) async {
    final data = await ApiClient.instance.get(
      '/dailylog',
      query: {'date': date},
    );
    if (data == null) return null;
    return DailyLogVO.fromJson(data as Map<String, dynamic>);
  }

  /// 提交当天日志（整体替换语义）：POST /dailylog
  static Future<void> submitDailyLog(Map<String, dynamic> body) async {
    await ApiClient.instance.post('/dailylog', body: body);
  }

  /// 日志营养汇总：GET /dailylog/{logId}/nutrition → Map<metricId, value>
  static Future<Map<int, double>> nutrition(int logId) async {
    final data = await ApiClient.instance.get('/dailylog/$logId/nutrition');
    if (data is Map) {
      return (data).map((k, v) =>
          MapEntry(int.tryParse(k.toString()) ?? 0, (v as num).toDouble()));
    }
    return {};
  }

  /// 成员营养目标：GET /member/{id}/nutrition-target
  static Future<NutritionTarget?> nutritionTarget(int memberId) async {
    final data = await ApiClient.instance.get(
      '/member/$memberId/nutrition-target',
    );
    if (data == null) return null;
    return NutritionTarget.fromJson(data as Map<String, dynamic>);
  }
}

// ===== 数据模型 =====

class DailyLogVO {
  final int id;
  final int memberId;
  final String date;
  final String? note;
  final List<DailyLogItemVO> items;

  const DailyLogVO({
    required this.id,
    required this.memberId,
    required this.date,
    this.note,
    required this.items,
  });

  factory DailyLogVO.fromJson(Map<String, dynamic> j) => DailyLogVO(
        id: (j['id'] as num).toInt(),
        memberId: (j['memberId'] as num).toInt(),
        date: (j['date'] ?? '') as String,
        note: j['note'] as String?,
        items: ((j['items'] ?? []) as List)
            .map((e) => DailyLogItemVO.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class DailyLogItemVO {
  final int? dishId;
  final int? ingredientId;
  final double amount;
  final double? servingFactor;
  final String? dishName;   // 后端可能附带
  final String? ingredientName;

  const DailyLogItemVO({
    this.dishId,
    this.ingredientId,
    required this.amount,
    this.servingFactor,
    this.dishName,
    this.ingredientName,
  });

  factory DailyLogItemVO.fromJson(Map<String, dynamic> j) => DailyLogItemVO(
        dishId: (j['dishId'] as num?)?.toInt(),
        ingredientId: (j['ingredientId'] as num?)?.toInt(),
        amount: (j['amount'] as num?)?.toDouble() ?? 0,
        servingFactor: (j['servingFactor'] as num?)?.toDouble(),
        dishName: (j['dishName'] ?? j['name']) as String?,
        ingredientName: j['ingredientName'] as String?,
      );

  String get displayName => dishName ?? ingredientName ?? '未知';
  bool get isDish => dishId != null;
}

class NutritionTarget {
  final int calorieTarget;
  final int proteinTarget;
  final int carbTarget;
  final int fatTarget;
  final String? goal;
  final int bmr;

  const NutritionTarget({
    required this.calorieTarget,
    required this.proteinTarget,
    required this.carbTarget,
    required this.fatTarget,
    this.goal,
    required this.bmr,
  });

  factory NutritionTarget.fromJson(Map<String, dynamic> j) => NutritionTarget(
        calorieTarget: (j['calorieTarget'] as num).toInt(),
        proteinTarget: (j['proteinTarget'] as num).toInt(),
        carbTarget: (j['carbTarget'] as num).toInt(),
        fatTarget: (j['fatTarget'] as num).toInt(),
        goal: j['goal'] as String?,
        bmr: (j['bmr'] as num).toInt(),
      );

  bool get isLose => goal == 'LOSE';
  bool get isGain => goal == 'GAIN';
  String get goalLabel {
    switch (goal) {
      case 'LOSE': return '减脂';
      case 'GAIN': return '增肌';
      default: return '维持';
    }
  }
}
