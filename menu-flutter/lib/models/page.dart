/// 后端 MyBatis-Plus 分页对象 IPage<T>：`{records, total, current, size, ...}`。
/// 调用方约定取 records。对应小程序各列表页 `.records`。
class PageData<T> {
  final List<T> records;
  final int total;
  final int current;
  final int size;

  const PageData({
    required this.records,
    this.total = 0,
    this.current = 1,
    this.size = 20,
  });

  factory PageData.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic> json) fromJsonT,
  ) {
    final raw = json['records'];
    final list = raw is List
        ? raw.map((e) => fromJsonT(e as Map<String, dynamic>)).toList()
        : <T>[];
    return PageData<T>(
      records: list,
      total: (json['total'] as num?)?.toInt() ?? 0,
      current: (json['current'] as num?)?.toInt() ?? 1,
      size: (json['size'] as num?)?.toInt() ?? 20,
    );
  }
}
