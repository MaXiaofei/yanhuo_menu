import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../stores/member_store.dart';

/// 当前就餐成员切换条（首页用）。复刻 menu-mini/src/pages/index/Index.vue 的 member-bar。
class MemberBar extends StatelessWidget {
  const MemberBar({super.key});

  @override
  Widget build(BuildContext context) {
    final m = context.watch<MemberStore>();
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          const Text('当前就餐：', style: TextStyle(fontSize: 14)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.warnOrange,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              m.currentName.isEmpty ? '未选择' : m.currentName,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: () => _pickMember(context),
            child: const Text('切换'),
          ),
        ],
      ),
    );
  }

  void _pickMember(BuildContext context) {
    final store = context.read<MemberStore>();
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('选择就餐成员',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            ...store.members.map(
              (mem) => ListTile(
                title: Text(mem.name),
                trailing: mem.id == store.currentId
                    ? const Icon(Icons.check, color: AppColors.primary)
                    : null,
                onTap: () {
                  store.switchTo(mem.id);
                  Navigator.pop(ctx);
                },
              ),
            ),
            if (store.members.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Text('暂无成员，请先在后台添加',
                    style: TextStyle(color: AppColors.textSecondary)),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
