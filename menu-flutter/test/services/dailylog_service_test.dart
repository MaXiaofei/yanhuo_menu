import 'package:flutter_test/flutter_test.dart';

import 'package:menu_flutter/services/dailylog_service.dart';
import '../helpers/mock_http.dart';

/// DailyLogService：日志查询/提交/营养汇总/成员目标 + 模型逻辑。
void main() {
  group('DailyLogService.getDailyLog', () {
    test('GET /dailylog?date= → 解析 items', () async {
      final captor = installMock((_) => okResponse({
            'id': 1,
            'memberId': 2,
            'date': '2026-06-30',
            'note': '今天吃多了',
            'items': [
              {'dishId': 5, 'amount': 1, 'servingFactor': 1.5, 'dishName': '红烧肉'},
              {'ingredientId': 10, 'amount': 100, 'ingredientName': '米饭'},
            ],
          }));

      final log = await DailyLogService.getDailyLog('2026-06-30');

      expect(captor.last!.path, '/dailylog');
      expect(captor.last!.queryParameters['date'], '2026-06-30');
      expect(log, isNotNull);
      expect(log!.id, 1);
      expect(log.memberId, 2);
      expect(log.date, '2026-06-30');
      expect(log.note, '今天吃多了');
      expect(log.items.length, 2);
      expect(log.items[0].dishName, '红烧肉');
      expect(log.items[0].servingFactor, 1.5);
      expect(log.items[1].ingredientName, '米饭');
    });

    test('data 为 null → 返回 null', () async {
      installMock((_) => okResponse(null));

      expect(await DailyLogService.getDailyLog('2026-06-30'), isNull);
    });

    test('items 缺省 → 空数组', () async {
      installMock((_) => okResponse({'id': 1, 'memberId': 2, 'date': '2026-06-30'}));

      final log = await DailyLogService.getDailyLog('2026-06-30');

      expect(log!.items, isEmpty);
    });
  });

  group('DailyLogService.submitDailyLog', () {
    test('POST /dailylog body 透传', () async {
      final captor = installMock((_) => okResponse(null));

      await DailyLogService.submitDailyLog({'date': '2026-06-30', 'items': []});

      expect(captor.last!.path, '/dailylog');
      expect(captor.last!.method, 'POST');
      expect(captor.last!.data, {'date': '2026-06-30', 'items': []});
    });
  });

  group('DailyLogService.nutrition', () {
    test('GET /dailylog/{logId}/nutrition → Map<int,double>', () async {
      final captor = installMock((_) => okResponse({
            '1': 1800,
            '2': 75.5,
          }));

      final m = await DailyLogService.nutrition(5);

      expect(captor.last!.path, '/dailylog/5/nutrition');
      expect(m.length, 2);
      expect(m[1], 1800.0);
      expect(m[2], 75.5);
    });

    test('非 Map → 空', () async {
      installMock((_) => okResponse(null));

      expect(await DailyLogService.nutrition(5), isEmpty);
    });
  });

  group('DailyLogService.nutritionTarget', () {
    test('GET /member/{id}/nutrition-target → NutritionTarget', () async {
      final captor = installMock((_) => okResponse({
            'calorieTarget': 1800,
            'proteinTarget': 90,
            'carbTarget': 200,
            'fatTarget': 60,
            'goal': 'LOSE',
            'bmr': 1500,
          }));

      final t = await DailyLogService.nutritionTarget(3);

      expect(captor.last!.path, '/member/3/nutrition-target');
      expect(t, isNotNull);
      expect(t!.calorieTarget, 1800);
      expect(t.proteinTarget, 90);
      expect(t.carbTarget, 200);
      expect(t.fatTarget, 60);
      expect(t.bmr, 1500);
      expect(t.goal, 'LOSE');
      expect(t.isLose, isTrue);
      expect(t.goalLabel, '减脂');
    });

    test('data 为 null → 返回 null', () async {
      installMock((_) => okResponse(null));

      expect(await DailyLogService.nutritionTarget(3), isNull);
    });
  });

  group('NutritionTarget', () {
    test('isGain + goalLabel', () {
      final t = NutritionTarget.fromJson({
        'calorieTarget': 2200,
        'proteinTarget': 120,
        'carbTarget': 250,
        'fatTarget': 70,
        'goal': 'GAIN',
        'bmr': 1600,
      });
      expect(t.isGain, isTrue);
      expect(t.isLose, isFalse);
      expect(t.goalLabel, '增肌');
    });

    test('goal 为空 → goalLabel "维持"', () {
      final t = NutritionTarget.fromJson({
        'calorieTarget': 1800,
        'proteinTarget': 80,
        'carbTarget': 200,
        'fatTarget': 60,
        'bmr': 1500,
      });
      expect(t.isLose, isFalse);
      expect(t.isGain, isFalse);
      expect(t.goalLabel, '维持');
    });
  });

  group('DailyLogItemVO', () {
    test('isDish: dishId 非空 → true', () {
      final v = DailyLogItemVO.fromJson({'dishId': 5, 'amount': 1, 'dishName': '红烧肉'});
      expect(v.isDish, isTrue);
      expect(v.displayName, '红烧肉');
    });

    test('isDish: 仅 ingredientId → false，displayName 回退 ingredientName', () {
      final v = DailyLogItemVO.fromJson({'ingredientId': 10, 'amount': 100, 'ingredientName': '米饭'});
      expect(v.isDish, isFalse);
      expect(v.displayName, '米饭');
    });

    test('displayName: 都缺省 → "未知"', () {
      final v = DailyLogItemVO.fromJson({'amount': 1});
      expect(v.displayName, '未知');
    });

    test('amount 缺省 → 0', () {
      final v = DailyLogItemVO.fromJson({'dishId': 1});
      expect(v.amount, 0);
    });
  });
}
