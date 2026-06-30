import 'package:flutter_test/flutter_test.dart';

import 'package:menu_flutter/services/pantry_service.dart';
import '../helpers/mock_http.dart';

/// PantryService：列表/临期/低库存/增删改/批量/扣减 + PantryVO 状态判定逻辑。
void main() {
  group('PantryService.listAll', () {
    test('后端返回数组 → 直接解析', () async {
      final captor = installMock((_) => okResponse([
            {
              'id': 1,
              'ingredientId': 10,
              'ingredientName': '鸡蛋',
              'amount': 5,
              'unitName': '个',
            },
          ]));

      final list = await PantryService.listAll();

      expect(captor.last!.path, '/pantry');
      expect(captor.last!.queryParameters['pageSize'], 1000);
      expect(list.length, 1);
      expect(list[0].ingredientName, '鸡蛋');
      expect(list[0].amount, 5);
    });

    test('后端返回 IPage{records} → 从 records 解包', () async {
      installMock((_) => okResponse({
            'records': [
              {'id': 2, 'ingredientId': 11, 'amount': 100},
            ],
          }));

      final list = await PantryService.listAll();

      expect(list.length, 1);
      expect(list[0].id, 2);
    });

    test('非预期结构 → 空列表', () async {
      installMock((_) => okResponse(null));

      expect(await PantryService.listAll(), isEmpty);
    });
  });

  group('PantryService.listExpiring', () {
    test('GET /pantry/expiring?days=3', () async {
      final captor = installMock((_) => okResponse([
            {'id': 1, 'ingredientId': 1, 'amount': 1},
          ]));

      final list = await PantryService.listExpiring(days: 5);

      expect(captor.last!.path, '/pantry/expiring');
      expect(captor.last!.queryParameters['days'], 5);
      expect(list.length, 1);
    });

    test('非 List → 空', () async {
      installMock((_) => okResponse({'records': []}));

      expect(await PantryService.listExpiring(), isEmpty);
    });
  });

  group('PantryService.listLow', () {
    test('GET /pantry/low', () async {
      final captor = installMock((_) => okResponse([]));

      await PantryService.listLow();

      expect(captor.last!.path, '/pantry/low');
    });
  });

  group('PantryService.create / update / delete', () {
    test('create POST /pantry 返回 id', () async {
      final captor = installMock((_) => okResponse(3));

      final id = await PantryService.create({'ingredientId': 1, 'amount': 2});

      expect(captor.last!.path, '/pantry');
      expect(captor.last!.method, 'POST');
      expect(id, 3);
    });

    test('update PUT /pantry body 透传', () async {
      final captor = installMock((_) => okResponse(null));

      await PantryService.update({'id': 1, 'amount': 9});

      expect(captor.last!.method, 'PUT');
      expect(captor.last!.data, {'id': 1, 'amount': 9});
    });

    test('delete DELETE /pantry/{id}', () async {
      final captor = installMock((_) => okResponse(null));

      await PantryService.delete(7);

      expect(captor.last!.method, 'DELETE');
      expect(captor.last!.path, '/pantry/7');
    });
  });

  group('PantryService.batchAdd', () {
    test('POST /pantry/batch → {count:n}', () async {
      final captor = installMock((_) => okResponse({'count': 4}));

      final count = await PantryService.batchAdd([
        {'ingredientId': 1, 'amount': 1},
        {'ingredientId': 2, 'amount': 1},
      ]);

      expect(captor.last!.path, '/pantry/batch');
      expect(count, 4);
    });

    test('无 count 字段 → 0', () async {
      installMock((_) => okResponse({}));

      expect(await PantryService.batchAdd([]), 0);
    });
  });

  group('PantryService.deduct', () {
    test('POST /pantry/{id}/deduct → {remain}', () async {
      final captor = installMock((_) => okResponse({'remain': 2.5}));

      final remain = await PantryService.deduct(8, 1.5);

      expect(captor.last!.path, '/pantry/8/deduct');
      expect(captor.last!.data, {'amount': 1.5});
      expect(remain, 2.5);
    });

    test('无 remain → 0', () async {
      installMock((_) => okResponse({}));

      expect(await PantryService.deduct(8, 1), 0);
    });
  });

  group('PantryVO.fromJson + 展示字段', () {
    test('完整字段 + displayName/displayAmount', () {
      final v = PantryVO.fromJson({
        'id': 1,
        'ingredientId': 10,
        'ingredientName': '鸡蛋',
        'amount': 5,
        'unitName': '个',
      });
      expect(v.displayName, '鸡蛋');
      expect(v.displayAmount, '5 个');
    });

    test('ingredientName 缺省 → displayName 回退 #id', () {
      final v = PantryVO.fromJson({'id': 1, 'ingredientId': 10, 'amount': 1});
      expect(v.displayName, '#10');
    });

    test('amount 小数 → 保留一位', () {
      final v = PantryVO.fromJson({
        'id': 1,
        'ingredientId': 10,
        'amount': 5.5,
        'unitName': 'kg',
      });
      expect(v.displayAmount, '5.5 kg');
    });

    test('amount 缺省 → 0', () {
      final v = PantryVO.fromJson({'id': 1, 'ingredientId': 10});
      expect(v.amount, 0);
    });
  });

  group('PantryVO.isLow', () {
    test('低于阈值 → true', () {
      final v = PantryVO.fromJson({
        'id': 1, 'ingredientId': 1, 'amount': 1, 'lowThreshold': 5,
      });
      expect(v.isLow, isTrue);
    });

    test('不低于阈值 → false', () {
      final v = PantryVO.fromJson({
        'id': 1, 'ingredientId': 1, 'amount': 10, 'lowThreshold': 5,
      });
      expect(v.isLow, isFalse);
    });

    test('阈值缺失 → false', () {
      final v = PantryVO.fromJson({'id': 1, 'ingredientId': 1, 'amount': 1});
      expect(v.isLow, isFalse);
    });

    test('阈值为 0 → false（不判低库存）', () {
      final v = PantryVO.fromJson({
        'id': 1, 'ingredientId': 1, 'amount': 0, 'lowThreshold': 0,
      });
      expect(v.isLow, isFalse);
    });
  });

  group('PantryVO.isExpiring', () {
    String daysFromNow(int d) {
      final dt = DateTime.now().add(Duration(days: d));
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    }

    test('2 天后到期 → 临期（默认 days=3）', () {
      final v = PantryVO.fromJson({
        'id': 1, 'ingredientId': 1, 'amount': 1, 'expireDate': daysFromNow(2),
      });
      expect(v.isExpiring(), isTrue);
    });

    test('10 天后到期 → 非临期', () {
      final v = PantryVO.fromJson({
        'id': 1, 'ingredientId': 1, 'amount': 1, 'expireDate': daysFromNow(10),
      });
      expect(v.isExpiring(), isFalse);
    });

    test('已过期 → 非临期', () {
      final v = PantryVO.fromJson({
        'id': 1, 'ingredientId': 1, 'amount': 1, 'expireDate': daysFromNow(-5),
      });
      expect(v.isExpiring(), isFalse);
    });

    test('无过期日 → false', () {
      final v = PantryVO.fromJson({'id': 1, 'ingredientId': 1, 'amount': 1});
      expect(v.isExpiring(), isFalse);
    });
  });

  group('PantryVO.isExpired', () {
    String daysFromNow(int d) {
      final dt = DateTime.now().add(Duration(days: d));
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    }

    test('已过日期 → true', () {
      final v = PantryVO.fromJson({
        'id': 1, 'ingredientId': 1, 'amount': 1, 'expireDate': daysFromNow(-5),
      });
      expect(v.isExpired, isTrue);
    });

    test('未来日期 → false', () {
      final v = PantryVO.fromJson({
        'id': 1, 'ingredientId': 1, 'amount': 1, 'expireDate': daysFromNow(5),
      });
      expect(v.isExpired, isFalse);
    });

    test('无过期日 → false', () {
      final v = PantryVO.fromJson({'id': 1, 'ingredientId': 1, 'amount': 1});
      expect(v.isExpired, isFalse);
    });
  });

  group('PantryVO.expireText', () {
    test('无过期日 → "无过期日"', () {
      final v = PantryVO.fromJson({'id': 1, 'ingredientId': 1, 'amount': 1});
      expect(v.expireText, '无过期日');
    });

    test('已过期 → "已过期 N 天"', () {
      final dt = DateTime.now().subtract(const Duration(days: 5));
      final ds =
          '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
      final v = PantryVO.fromJson({
        'id': 1, 'ingredientId': 1, 'amount': 1, 'expireDate': ds,
      });
      expect(v.expireText, startsWith('已过期 '));
      expect(v.expireText, endsWith(' 天'));
    });

    test('未来到期 → "剩 N 天"', () {
      final dt = DateTime.now().add(const Duration(days: 10));
      final ds =
          '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
      final v = PantryVO.fromJson({
        'id': 1, 'ingredientId': 1, 'amount': 1, 'expireDate': ds,
      });
      expect(v.expireText, startsWith('剩 '));
      expect(v.expireText, endsWith(' 天'));
    });
  });
}
