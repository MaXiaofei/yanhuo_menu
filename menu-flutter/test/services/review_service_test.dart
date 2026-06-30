import 'package:flutter_test/flutter_test.dart';

import 'package:menu_flutter/services/review_service.dart';
import '../helpers/mock_http.dart';

/// ReviewService：点评维度字典（兼容 List/IPage）+ 提交点评。
void main() {
  group('ReviewService.dimensions', () {
    test('后端返回数组 → 直接解析', () async {
      final captor = installMock((_) => okResponse([
            {'id': 1, 'name': '味道'},
            {'id': 2, 'name': '口感'},
          ]));

      final list = await ReviewService.dimensions();

      expect(captor.last!.path, '/dict');
      expect(captor.last!.queryParameters['group'], 'review_dimension');
      expect(list.length, 2);
      expect(list[0].name, '味道');
    });

    test('后端返回 IPage{records} → 从 records 解包', () async {
      installMock((_) => okResponse({
            'records': [
              {'id': 3, 'name': '外观'},
            ],
          }));

      final list = await ReviewService.dimensions();

      expect(list.length, 1);
      expect(list[0].id, 3);
    });

    test('非预期结构 → 空', () async {
      installMock((_) => okResponse(null));

      expect(await ReviewService.dimensions(), isEmpty);
    });
  });

  group('ReviewService.submitReview', () {
    test('POST /review body 透传', () async {
      final captor = installMock((_) => okResponse(null));

      await ReviewService.submitReview({'dishId': 1, 'scores': {'1': 5}});

      expect(captor.last!.path, '/review');
      expect(captor.last!.method, 'POST');
      expect(captor.last!.data, {'dishId': 1, 'scores': {'1': 5}});
    });
  });

  group('ReviewDimension.fromJson', () {
    test('完整字段', () {
      final d = ReviewDimension.fromJson({'id': 1, 'name': '味道'});
      expect(d.id, 1);
      expect(d.name, '味道');
    });

    test('name 缺省 → 空串', () {
      expect(ReviewDimension.fromJson({'id': 1}).name, '');
    });
  });
}
