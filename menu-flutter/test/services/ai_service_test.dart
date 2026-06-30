import 'package:flutter_test/flutter_test.dart';

import 'package:menu_flutter/services/ai_service.dart';
import '../helpers/mock_http.dart';

/// AiService：AI 补全食材营养 + valueMap 回填。
void main() {
  group('AiService.aiFillNutrition', () {
    test('POST /ai/nutrition/fill body 含 name，解析 nutrition + source', () async {
      final captor = installMock((_) => okResponse({
            'nutrition': [
              {'metricId': 1, 'value': 74},
              {'metricId': 2, 'value': 12.5},
            ],
            'source': 'deepseek',
          }));

      final r = await AiService.aiFillNutrition('鸡蛋');

      expect(captor.last!.path, '/ai/nutrition/fill');
      expect(captor.last!.data, {'name': '鸡蛋'});
      expect(r.source, 'deepseek');
      expect(r.nutrition.length, 2);
      expect(r.nutrition[0].metricId, 1);
      expect(r.nutrition[0].value, 74);
      expect(r.nutrition[1].value, 12.5);
    });

    test('nutrition 缺省 → 空列表', () async {
      installMock((_) => okResponse({'source': 'deepseek'}));

      final r = await AiService.aiFillNutrition('土豆');

      expect(r.nutrition, isEmpty);
      expect(r.source, 'deepseek');
    });

    test('source 缺省 → 空串', () async {
      installMock((_) => okResponse({'nutrition': []}));

      final r = await AiService.aiFillNutrition('土豆');

      expect(r.source, '');
    });
  });

  group('AiNutritionFillResult.valueMap', () {
    test('metricId → value 映射，方便表单回填', () {
      final r = AiNutritionFillResult.fromJson({
        'nutrition': [
          {'metricId': 1, 'value': 74},
          {'metricId': 3, 'value': 5},
        ],
      });

      final m = r.valueMap;

      expect(m.length, 2);
      expect(m[1], 74);
      expect(m[3], 5);
    });
  });
}
