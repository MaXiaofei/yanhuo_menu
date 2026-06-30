import 'package:flutter_test/flutter_test.dart';

import 'package:menu_flutter/services/member_service.dart';
import '../helpers/mock_http.dart';

/// MemberService：
/// - list()：兼容 List 与 IPage{records}（后端契约不严谨）
/// - setCurrent() / getCurrent()
void main() {
  group('MemberService.list', () {
    test('后端返回数组 → 直接解析', () async {
      final captor = installMock((_) => okResponse([
            {'id': 1, 'name': '爸爸'},
            {'id': 2, 'name': '妈妈'},
          ]));

      final list = await MemberService.list();

      expect(captor.last!.path, '/member');
      expect(list.length, 2);
      expect(list[0].id, 1);
      expect(list[0].name, '爸爸');
      expect(list[1].name, '妈妈');
    });

    test('后端返回 IPage{records} → 从 records 解包', () async {
      installMock((_) => okResponse({
            'records': [
              {'id': 3, 'name': '宝宝'},
            ],
            'total': 1,
          }));

      final list = await MemberService.list();

      expect(list.length, 1);
      expect(list[0].id, 3);
      expect(list[0].name, '宝宝');
    });

    test('name 缺省 → 空串', () async {
      installMock((_) => okResponse([
            {'id': 1},
          ]));

      final list = await MemberService.list();

      expect(list.single.name, '');
    });

    test('既非 List 也非 IPage → 空列表', () async {
      installMock((_) => okResponse(null));

      final list = await MemberService.list();

      expect(list, isEmpty);
    });
  });

  group('MemberService.setCurrent', () {
    test('POST /member/current?memberId=', () async {
      final captor = installMock((_) => okResponse(null));

      await MemberService.setCurrent(5);

      expect(captor.last!.path, '/member/current');
      expect(captor.last!.method, 'POST');
      expect(captor.last!.queryParameters['memberId'], 5);
    });
  });

  group('MemberService.getCurrent', () {
    test('返回 Long → int', () async {
      installMock((_) => okResponse(7));

      expect(await MemberService.getCurrent(), 7);
    });

    test('data 为 null → 0', () async {
      installMock((_) => okResponse(null));

      expect(await MemberService.getCurrent(), 0);
    });
  });
}
