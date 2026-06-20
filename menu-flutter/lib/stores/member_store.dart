import 'package:flutter/foundation.dart';

import '../models/member.dart';
import '../services/member_service.dart';

/// 当前就餐成员上下文（对应 menu-mini/src/store/member.ts）。
/// currentId 同步给后端 session（@MpPerm/AI 等接口靠 session 取 memberId）。
class MemberStore extends ChangeNotifier {
  List<Member> members = [];
  int currentId = 0;

  String get currentName {
    final i = members.indexWhere((m) => m.id == currentId);
    return i >= 0 ? members[i].name : '';
  }

  Future<void> load() async {
    try {
      members = await MemberService.list();
      currentId = await MemberService.getCurrent();
      notifyListeners();
    } catch (_) {
      // 列表加载失败不阻断首页展示
    }
  }

  Future<void> switchTo(int id) async {
    await MemberService.setCurrent(id);
    currentId = id;
    notifyListeners();
  }
}
