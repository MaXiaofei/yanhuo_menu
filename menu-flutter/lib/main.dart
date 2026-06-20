import 'package:flutter/material.dart';

import 'app.dart';
import 'core/api_client.dart';
import 'stores/auth_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 全局 SnackBar key，供 ApiClient 的错误提示使用。
  final scaffoldKey = GlobalKey<ScaffoldMessengerState>();
  ApiClient.instance.init(
    onErrorToast: (msg) {
      scaffoldKey.currentState?.showSnackBar(
        SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
      );
    },
  );

  // 启动时从持久化恢复 token，并同步给 ApiClient。
  final authStore = AuthStore();
  await authStore.init();

  runApp(MenuApp(authStore: authStore, scaffoldKey: scaffoldKey));
}
