import 'package:flutter_test/flutter_test.dart';

import 'package:menu_flutter/services/auth_service.dart';
import '../helpers/mock_http.dart';

/// AuthService.login：POST /auth/login → {token, nickname}。
void main() {
  group('AuthService.login', () {
    test('正确路径 + body，解析 token 与 nickname', () async {
      final captor = installMock((_) => okResponse({
            'token': 'jwt-abc',
            'nickname': '张三',
          }));

      final r = await AuthService.login('admin', '123456');

      expect(captor.last!.path, '/auth/login');
      expect(captor.last!.method, 'POST');
      expect(captor.last!.data, {'username': 'admin', 'password': '123456'});
      expect(r.token, 'jwt-abc');
      expect(r.nickname, '张三');
    });

    test('nickname 缺省 → 空串', () async {
      installMock((_) => okResponse({'token': 'jwt-abc'}));

      final r = await AuthService.login('admin', '123456');

      expect(r.token, 'jwt-abc');
      expect(r.nickname, '');
    });
  });
}
