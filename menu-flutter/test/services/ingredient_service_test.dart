import 'package:flutter_test/flutter_test.dart';

import 'package:menu_flutter/services/ingredient_service.dart';
import '../helpers/mock_http.dart';

/// IngredientService：字典/创建/全量列表/新增字典项 + DictItem 解析。
void main() {
  group('IngredientService.listDictByGroup', () {
    test('GET /dict?group=&pageNum=1&pageSize=1000 → List<DictItem>', () async {
      final captor = installMock((_) => okResponse({
            'records': [
              {'id': 1, 'name': '克'},
              {'id': 2, 'name': '个'},
            ],
          }));

      final list = await IngredientService.listDictByGroup('unit');

      expect(captor.last!.path, '/dict');
      expect(captor.last!.queryParameters['group'], 'unit');
      expect(captor.last!.queryParameters['pageSize'], 1000);
      expect(list.length, 2);
      expect(list[0].name, '克');
    });

    test('records 非 List → 空列表', () async {
      installMock((_) => okResponse(null));

      expect(await IngredientService.listDictByGroup('unit'), isEmpty);
    });
  });

  group('IngredientService.createIngredient', () {
    test('POST /ingredient body 透传，返回 id', () async {
      final captor = installMock((_) => okResponse(99));

      final id = await IngredientService.createIngredient({'name': '土豆'});

      expect(captor.last!.path, '/ingredient');
      expect(captor.last!.data, {'name': '土豆'});
      expect(id, 99);
    });
  });

  group('IngredientService.listAll', () {
    test('GET /ingredient?pageSize=1000 → List<DictItem>', () async {
      final captor = installMock((_) => okResponse({
            'records': [
              {'id': 10, 'name': '猪肉'},
            ],
          }));

      final list = await IngredientService.listAll();

      expect(captor.last!.path, '/ingredient');
      expect(list.length, 1);
      expect(list[0].id, 10);
      expect(list[0].name, '猪肉');
    });

    test('非 IPage 结构 → 空列表', () async {
      installMock((_) => okResponse('不是分页'));

      expect(await IngredientService.listAll(), isEmpty);
    });
  });

  group('IngredientService.upsertDict', () {
    test('POST /dict body 含 name + dictGroup，返回 id', () async {
      final captor = installMock((_) => okResponse(5));

      final id = await IngredientService.upsertDict('份', 'unit');

      expect(captor.last!.path, '/dict');
      expect(captor.last!.data, {'name': '份', 'dictGroup': 'unit'});
      expect(id, 5);
    });
  });

  group('DictItem.fromJson', () {
    test('完整字段', () {
      final d = DictItem.fromJson({'id': 8, 'name': '勺'});
      expect(d.id, 8);
      expect(d.name, '勺');
    });

    test('name 缺省 → 空串', () {
      final d = DictItem.fromJson({'id': 8});
      expect(d.name, '');
    });
  });
}
