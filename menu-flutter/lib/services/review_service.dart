import '../core/api_client.dart';

/// 点评服务。
class ReviewService {
  /// 点评维度字典：GET /dict?group=review_dimension
  static Future<List<ReviewDimension>> dimensions() async {
    final data = await ApiClient.instance.get(
      '/dict',
      query: {'group': 'review_dimension'},
    );
    if (data is List) {
      return data
          .map((e) => ReviewDimension.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    if (data is Map && data['records'] is List) {
      return (data['records'] as List)
          .map((e) => ReviewDimension.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// 提交点评：POST /review
  static Future<void> submitReview(Map<String, dynamic> data) async {
    await ApiClient.instance.post('/review', body: data);
  }
}

/// 点评维度（如"味道""口感""外观"）。
class ReviewDimension {
  final int id;
  final String name;

  const ReviewDimension({required this.id, required this.name});

  factory ReviewDimension.fromJson(Map<String, dynamic> j) => ReviewDimension(
        id: (j['id'] as num).toInt(),
        name: (j['name'] ?? '') as String,
      );
}
