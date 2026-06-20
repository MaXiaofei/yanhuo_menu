import 'package:go_router/go_router.dart';

import '../pages/coming_soon_page.dart';
import '../pages/dish/detail_page.dart';
import '../pages/dish/list_page.dart';
import '../pages/home_page.dart';
import '../pages/login_page.dart';
import '../stores/auth_store.dart';

/// 路由表 + 登录拦截（对应小程序 401/未登录 reLaunch 到登录页）。
/// refreshListenable 绑定 AuthStore：登录态变化自动重定向。
GoRouter createRouter(AuthStore auth) {
  return GoRouter(
    refreshListenable: auth,
    initialLocation: '/',
    redirect: (context, state) {
      final loggedIn = auth.isLoggedIn;
      final atLogin = state.matchedLocation == '/login';
      if (!loggedIn && !atLogin) return '/login';
      if (loggedIn && atLogin) return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
      GoRoute(path: '/', builder: (_, __) => const HomePage()),
      GoRoute(path: '/dish', builder: (_, __) => const DishListPage()),
      // 点评放 :id 前，避免被 :id 吞掉（go_router 按精度匹配，顺序无碍，置前更直观）
      GoRoute(
        path: '/dish/:id/review',
        builder: (_, __) => const ComingSoonPage(title: '点评'),
      ),
      GoRoute(
        path: '/dish/:id',
        builder: (_, s) =>
            DishDetailPage(id: int.parse(s.pathParameters['id']!)),
      ),
      // 以下为 P1/P2 占位，后续替换为真实页面
      GoRoute(
          path: '/create-dish',
          builder: (_, __) => const ComingSoonPage(title: '录入新菜')),
      GoRoute(
          path: '/create-ingredient',
          builder: (_, __) => const ComingSoonPage(title: '录入食材')),
      GoRoute(
          path: '/ai-recommend',
          builder: (_, __) => const ComingSoonPage(title: 'AI 帮我定菜单')),
      GoRoute(
          path: '/ai-estimate',
          builder: (_, __) => const ComingSoonPage(title: 'AI 估营养')),
      GoRoute(
          path: '/mealplan',
          builder: (_, __) => const ComingSoonPage(title: '周计划')),
      GoRoute(
          path: '/pantry',
          builder: (_, __) => const ComingSoonPage(title: '食材库存')),
      GoRoute(
          path: '/shopping',
          builder: (_, __) => const ComingSoonPage(title: '采购清单')),
      GoRoute(
          path: '/dailylog',
          builder: (_, __) => const ComingSoonPage(title: '每日饮食记录')),
    ],
  );
}
