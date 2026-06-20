import '../core/api_client.dart';
import '../models/dish.dart';
import '../models/nutrition_metric.dart';
import '../models/page.dart';

/// 菜品服务（对应 menu-mini/src/api/dish.ts + DishController）。
class DishService {
  /// 多维搜索分页：GET /dish/search。
  static Future<PageData<Dish>> search({
    String? keyword,
    int pageNum = 1,
    int pageSize = 20,
  }) async {
    final data = await ApiClient.instance.get('/dish/search', query: {
      if (keyword != null && keyword.isNotEmpty) 'keyword': keyword,
      'pageNum': pageNum,
      'pageSize': pageSize,
    });
    return PageData<Dish>.fromJson(
      data as Map<String, dynamic>,
      Dish.fromJson,
    );
  }

  /// 详情：GET /dish/{id} → {dish, steps, ...}。
  static Future<DishDetail> detail(int id) async {
    final data = await ApiClient.instance.get('/dish/$id');
    return DishDetail.fromJson(data as Map<String, dynamic>);
  }

  /// 份数营养：GET /dish/{id}/nutrition?serving= → Map<metricId字符串, 值>。
  static Future<Map<String, num>> nutrition(int id, {num serving = 1}) async {
    final data = await ApiClient.instance.get(
      '/dish/$id/nutrition',
      query: {'serving': serving},
    );
    if (data == null) return {};
    return (data as Map).map((k, v) =>
        MapEntry(k.toString(), v == null ? 0 : (v as num)));
  }

  /// 标记做过：POST /cookbook/done/{dishId}?memberId=。
  static Future<void> markDone(int dishId, int memberId) async {
    await ApiClient.instance.post(
      '/cookbook/done/$dishId',
      query: {'memberId': memberId},
    );
  }

  /// 营养指标字典：GET /nutrition/metric。
  static Future<List<NutritionMetric>> metrics() async {
    final data = await ApiClient.instance.get('/nutrition/metric');
    return (data as List)
        .map((e) => NutritionMetric.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
