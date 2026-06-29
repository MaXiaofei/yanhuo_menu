import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:menu_flutter/stores/auth_store.dart';
import 'package:menu_flutter/core/api_client.dart';
import 'package:menu_flutter/core/constants.dart';

/// AuthStore：
/// - init()：从 SharedPreferences 恢复 token → isLoggedIn、ApiClient.token 同步
/// - logout()：清 token、持久化、ApiClient.token
/// - isLoggedIn getter：token 非空为 true
///
/// login() 依赖静态 AuthService.login（无法用 mocktail 隔离），由集成测试覆盖。
/// 用 init() 从持久化恢复来驱动「已登录态」，从而间接覆盖 isLoggedIn=true 分支。
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ApiClient.instance.token = null;
  });

  group('AuthStore.init', () {
    test('持久化无 token → isLoggedIn=false、ApiClient.token=null', () async {
      final store = AuthStore();
      await store.init();
      expect(store.token, '');
      expect(store.isLoggedIn, isFalse);
      expect(ApiClient.instance.token, isNull);
    });

    test('持久化有 token → 恢复后 isLoggedIn=true、ApiClient.token 同步', () async {
      SharedPreferences.setMockInitialValues({AppConstants.tokenKey: 'saved-token'});
      final store = AuthStore();
      await store.init();
      expect(store.token, 'saved-token');
      expect(store.isLoggedIn, isTrue);
      expect(ApiClient.instance.token, 'saved-token');
    });
  });

  group('AuthStore.logout', () {
    test('logout 后 token 清空、isLoggedIn=false、ApiClient.token=null、持久化已清', () async {
      // 先 init 到登录态
      SharedPreferences.setMockInitialValues({AppConstants.tokenKey: 'saved-token'});
      final store = AuthStore();
      await store.init();
      expect(store.isLoggedIn, isTrue); // 前置确认

      await store.logout();

      expect(store.token, '');
      expect(store.isLoggedIn, isFalse);
      expect(store.nickname, '');
      expect(ApiClient.instance.token, isNull);
      final sp = await SharedPreferences.getInstance();
      expect(sp.getString(AppConstants.tokenKey), isNull);
    });
  });
}
