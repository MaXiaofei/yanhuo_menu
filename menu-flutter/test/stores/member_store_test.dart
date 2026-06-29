import 'package:flutter_test/flutter_test.dart';
import 'package:menu_flutter/stores/member_store.dart';
import 'package:menu_flutter/models/member.dart';

/// MemberStore.currentName：命中 currentId 返回 name，未命中(0/不存在)返回空串。
/// 纯 getter，直接构造 store 状态测试，无需 mock。
void main() {
  group('MemberStore.currentName', () {
    test('currentId 命中列表 → 返回对应 name', () {
      final store = MemberStore();
      store.members = [
        const Member(id: 1, name: '张爸爸'),
        const Member(id: 2, name: '张妈妈'),
      ];
      store.currentId = 1;
      expect(store.currentName, '张爸爸');

      store.currentId = 2;
      expect(store.currentName, '张妈妈');
    });

    test('currentId=0（未设置）→ 空串', () {
      final store = MemberStore();
      store.members = [const Member(id: 1, name: '张爸爸')];
      store.currentId = 0;
      expect(store.currentName, '');
    });

    test('currentId 不在列表中 → 空串', () {
      final store = MemberStore();
      store.members = [const Member(id: 1, name: '张爸爸')];
      store.currentId = 99;
      expect(store.currentName, '');
    });

    test('空成员列表 → 空串', () {
      final store = MemberStore();
      store.currentId = 1;
      expect(store.currentName, '');
    });

    test('初始状态 currentId=0', () {
      final store = MemberStore();
      expect(store.currentId, 0);
      expect(store.members, isEmpty);
      expect(store.currentName, '');
    });
  });
}
