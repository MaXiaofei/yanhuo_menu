import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../stores/auth_store.dart';
import '../stores/member_store.dart';
import '../widgets/app_card.dart';

/// 「设置」页（首页右上角设置图标进入）：用户信息 + 设置项 + 退出登录。
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthStore>();
    final member = context.watch<MemberStore>();
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text('设置')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            // 用户头部卡
            AppCard(
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: const BoxDecoration(
                      gradient: AppGradients.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person, color: Colors.white),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(auth.nickname.isNotEmpty ? auth.nickname : '掌勺人',
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary)),
                        const SizedBox(height: 4),
                        Text(
                          member.currentName.isNotEmpty
                              ? '当前就餐：${member.currentName}'
                              : '未选择就餐成员',
                          style: const TextStyle(
                              fontSize: 13, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // 功能项
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _SettingTile(
                    icon: Icons.people_outline,
                    label: '家庭成员',
                    onTap: () {},
                  ),
                  const Divider(height: 1, indent: 56),
                  _SettingTile(
                    icon: Icons.palette_outlined,
                    label: '主题外观',
                    onTap: () {},
                  ),
                  const Divider(height: 1, indent: 56),
                  _SettingTile(
                    icon: Icons.info_outline,
                    label: '关于小食单',
                    value: 'v1.0.0',
                    onTap: () {},
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // 退出登录
            AppCard(
              padding: EdgeInsets.zero,
              child: ListTile(
                leading: const Icon(Icons.logout,
                    color: AppColors.warnRed),
                title: const Text('退出登录',
                    style: TextStyle(color: AppColors.warnRed)),
                trailing: const Icon(Icons.chevron_right,
                    color: AppColors.textSecondary),
                onTap: () => auth.logout(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final VoidCallback onTap;

  const _SettingTile({
    required this.icon,
    required this.label,
    this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(label),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (value != null)
              Text(value!,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 13)),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
        onTap: onTap,
      );
}
