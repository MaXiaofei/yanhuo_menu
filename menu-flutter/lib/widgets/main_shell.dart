import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/theme.dart';

/// 底部 Tab 外壳。首页/菜库/我的 三个 tab，保持各 tab 状态。
/// 由 go_router 的 StatefulShellRoute 注入 navigationShell。
class MainShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({super.key, required this.navigationShell});

  void _goBranch(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: navigationShell,
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            boxShadow: [
              BoxShadow(
                color: const Color(0x14000000),
                blurRadius: 12,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: NavigationBar(
            selectedIndex: navigationShell.currentIndex,
            onDestinationSelected: _goBranch,
            backgroundColor: Colors.transparent,
            elevation: 0,
            indicatorColor: AppColors.primary.withValues(alpha: 0.12),
            indicatorShape: const StadiumBorder(),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home, color: AppColors.primary),
                label: '首页',
              ),
              NavigationDestination(
                icon: Icon(Icons.menu_book_outlined),
                selectedIcon: Icon(Icons.menu_book, color: AppColors.primary),
                label: '菜库',
              ),
              NavigationDestination(
                icon: Icon(Icons.apps_outlined),
                selectedIcon: Icon(Icons.apps, color: AppColors.primary),
                label: '更多',
              ),
            ],
          ),
        ),
      );
}
