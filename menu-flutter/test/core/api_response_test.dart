import 'package:flutter_test/flutter_test.dart';
import 'package:menu_flutter/core/api_response.dart';

/// ApiResponse.fromJson：num→int 转换、msg 兜底空串、data 透传；
/// ok getter：code==0 为 true；ApiError.toString 返回 message。
void main() {
  group('ApiResponse.fromJson', () {
    test('正常响应：code=0、msg、data 透传', () {
      final r = ApiResponse.fromJson({
        'code': 0,
        'msg': 'ok',
        'data': {'id': 1},
      });
      expect(r.code, 0);
      expect(r.msg, 'ok');
      expect((r.data as Map)['id'], 1);
      expect(r.ok, isTrue);
    });

    test('401 未登录', () {
      final r = ApiResponse.fromJson({'code': 401, 'msg': '未登录', 'data': null});
      expect(r.code, 401);
      expect(r.ok, isFalse);
    });

    test('code 为 num 类型（如 double 形式）能正确转 int', () {
      final r = ApiResponse.fromJson({'code': 0.0, 'data': null});
      expect(r.code, 0);
      expect(r.ok, isTrue);
    });

    test('msg 缺省时兜底为空串', () {
      final r = ApiResponse.fromJson({'code': 1, 'data': null});
      expect(r.msg, '');
    });

    test('其它非 0 code：ok=false', () {
      final r = ApiResponse.fromJson({'code': 500, 'msg': '服务器错误', 'data': null});
      expect(r.ok, isFalse);
      expect(r.msg, '服务器错误');
    });
  });

  group('ApiError', () {
    test('toString 返回 message', () {
      final err = ApiError('业务失败');
      expect(err.toString(), '业务失败');
      expect(err.message, '业务失败');
    });
  });
}
