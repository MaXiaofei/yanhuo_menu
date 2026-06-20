import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../stores/auth_store.dart';
import '../stores/member_store.dart';
import '../widgets/member_bar.dart';

/// 首页 hub（复刻 menu-mini/src/pages/index/Index.vue）。
/// 顶部「当前就餐成员」切换条 + 一列功能按钮。保留单 hub 架构，与小程序一致。
class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    // 进入首页加载成员（对应小程序 onShow → member.load()）
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MemberStore>().load();
    });
  }

  Widget _entry(String label, VoidCallback onTap, {Color? color}) => Padding(
        padding: const EdgeInsets.only(top: 12),
        child: ElevatedButton(
          style: color != null
              ? ElevatedButton.styleFrom(backgroundColor: color)
              : null,
          onPressed: onTap,
          child: Text(label),
        ),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('小食单')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const MemberBar(),
              const SizedBox(height: 16),
              _entry('浏览菜库', () => context.push('/dish')),
              _entry('录入新菜', () => context.push('/create-dish')),
              _entry('录入食材', () => context.push('/create-ingredient'),
                  color: AppColors.warnOrange),
              _entry('AI 帮我定菜单', () => context.push('/ai-recommend'),
                  color: AppColors.warnOrange),
              _entry('AI 估营养', () => context.push('/ai-estimate'),
                  color: AppColors.warnOrange),
              _entry('退出登录', () => context.read<AuthStore>().logout(),
                  color: AppColors.warnRed),
            ],
          ),
        ),
      );
}
