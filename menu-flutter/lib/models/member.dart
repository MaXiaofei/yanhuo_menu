/// 家庭成员（对应后端 Member）。P0 仅用到 id/name。
class Member {
  final int id;
  final String name;

  const Member({required this.id, required this.name});

  factory Member.fromJson(Map<String, dynamic> j) => Member(
        id: (j['id'] as num).toInt(),
        name: (j['name'] ?? '') as String,
      );
}
