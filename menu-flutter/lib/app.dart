import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/api_client.dart';
import 'core/router.dart';
import 'core/theme.dart';
import 'stores/auth_store.dart';
import 'stores/member_store.dart';

/// App 根：注入 stores + 创建路由 + 绑定 401 跳登录。
class MenuApp extends StatefulWidget {
  final AuthStore authStore;
  final GlobalKey<ScaffoldMessengerState> scaffoldKey;

  const MenuApp({
    super.key,
    required this.authStore,
    required this.scaffoldKey,
  });

  @override
  State<MenuApp> createState() => _MenuAppState();
}

class _MenuAppState extends State<MenuApp> {
  late final MemberStore _memberStore = MemberStore();
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = createRouter(widget.authStore);
    // 401 未登录 → 清栈跳登录页（对应小程序 reLaunch）
    ApiClient.instance.onUnauthorized = () => _router.go('/login');
  }

  @override
  Widget build(BuildContext context) => MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: widget.authStore),
          ChangeNotifierProvider.value(value: _memberStore),
        ],
        child: MaterialApp.router(
          scaffoldMessengerKey: widget.scaffoldKey,
          title: '烟火小食单',
          theme: buildAppTheme(),
          routerConfig: _router,
          debugShowCheckedModeBanner: false,
        ),
      );
}
