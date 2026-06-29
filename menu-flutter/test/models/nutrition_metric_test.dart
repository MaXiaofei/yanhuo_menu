import 'package:flutter_test/flutter_test.dart';
import 'package:menu_flutter/models/nutrition_metric.dart';

/// NutritionMetric.fromJson：id/name/unit 缺省兜底。
void main() {
  group('NutritionMetric.fromJson', () {
    test('完整字段', () {
      final m = NutritionMetric.fromJson({'id': 1, 'name': 'calorie', 'unit': 'kcal'});
      expect(m.id, 1);
      expect(m.name, 'calorie');
      expect(m.unit, 'kcal');
    });

    test('name 缺省兜底空串', () {
      final m = NutritionMetric.fromJson({'id': 1, 'unit': 'g'});
      expect(m.name, '');
    });

    test('unit 缺省兜底空串', () {
      final m = NutritionMetric.fromJson({'id': 2, 'name': 'protein'});
      expect(m.unit, '');
    });
  });
}
