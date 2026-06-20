import '../core/api_client.dart';
import '../models/member.dart';

/// 成员服务（对应 menu-mini/src/api/member.ts + MemberController）。
///
/// 注意契约不严谨：后端 /member 返回 IPage<Member>，小程序当数组用。
/// 这里统一兼容 List 与 IPage，正确解包成 List<Member>。
class MemberService {
  static Future<List<Member>> list() async {
    final data = await ApiClient.instance.get('/member');
    if (data is List) {
      return data
          .map((e) => Member.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    if (data is Map && data['records'] is List) {
      return (data['records'] as List)
          .map((e) => Member.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// 切换当前就餐成员：POST /member/current?memberId=
  static Future<void> setCurrent(int memberId) async {
    await ApiClient.instance.post('/member/current', query: {'memberId': memberId});
  }

  /// 取当前成员：GET /member/current → Long（无则 0）。
  static Future<int> getCurrent() async {
    final data = await ApiClient.instance.get('/member/current');
    if (data == null) return 0;
    return (data as num).toInt();
  }
}
