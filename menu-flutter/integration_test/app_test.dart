import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:menu_flutter/app.dart';
import 'package:menu_flutter/core/api_client.dart';
import 'package:menu_flutter/stores/auth_store.dart';

/// 集成测试（冒烟）：启动 App → 验证未登录态重定向到登录页 + 登录页正常渲染。
///
/// 运行方式（需模拟器/设备）：
///   flutter test integration_test/app_test.dart
///
/// 说明：未登录态下 go_router 直接重定向到 /login，不发网络请求，故无需真实后端。
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('未登录启动 → 重定向到登录页并渲染', (tester) async {
    // 清空持久化，确保未登录
    SharedPreferences.setMockInitialValues({});
    ApiClient.instance.token = null;

    final scaffoldKey = GlobalKey<ScaffoldMessengerState>();
    ApiClient.instance.init(
      onErrorToast: (msg) {},
    );
    final authStore = AuthStore();
    await authStore.init();

    await tester.pumpWidget(MenuApp(
      authStore: authStore,
      scaffoldKey: scaffoldKey,
    ));
    // 等待路由重定向 + 第一帧渲染
    await tester.pumpAndSettle();

    // 登录页应已渲染：页面含「登录」相关文本
    expect(find.textContaining('登录'), findsWidgets);
  });
}
