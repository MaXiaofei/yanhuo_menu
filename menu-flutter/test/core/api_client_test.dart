import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:menu_flutter/core/api_client.dart';
import '../helpers/mock_http.dart';

/// ApiClient 拦截器契约（对应小程序 utils/request.ts）：
/// - token 注入：有 token → 请求头 `Authorization: <裸token>`（无 Bearer）
/// - 解包：code==0 → 返回 data；响应非 {code} 结构 → 原样透传
/// - 401：清 token + onUnauthorized + reject
/// - 业务错误：code!=0 → onErrorToast(msg)（空 msg 兜底"请求失败"）+ reject
/// - 网络错误：onErrorToast("网络连接失败...")
void main() {
  group('ApiClient 拦截器 - token 注入', () {
    test('有 token 时请求头带裸 token（无 Bearer 前缀）', () async {
      String? authHeader;
      installMock((options) {
        authHeader = options.headers['Authorization'] as String?;
        return okResponse({});
      });
      ApiClient.instance.token = 'abc123';

      await ApiClient.instance.get('/anything');
      expect(authHeader, 'abc123');
    });

    test('token 为 null 时不带 Authorization 头', () async {
      String? authHeader;
      installMock((options) {
        authHeader = options.headers['Authorization'] as String?;
        return okResponse({});
      });
      ApiClient.instance.token = null;

      await ApiClient.instance.get('/anything');
      expect(authHeader, isNull);
    });

    test('token 为空串时不带 Authorization 头', () async {
      String? authHeader;
      installMock((options) {
        authHeader = options.headers['Authorization'] as String?;
        return okResponse({});
      });
      ApiClient.instance.token = '';

      await ApiClient.instance.get('/anything');
      expect(authHeader, isNull);
    });
  });

  group('ApiClient 拦截器 - 响应解包', () {
    test('code==0 时 data 被解包返回', () async {
      installMock((_) => okResponse({'k': 'v', 'n': 42}));

      final result = await ApiClient.instance.get('/x');
      expect(result, {'k': 'v', 'n': 42});
    });

    test('响应体不含 code 字段 → 原样透传', () async {
      installMock((_) => {'raw': 'data', 'no': 'code'});

      final result = await ApiClient.instance.get('/x');
      expect(result, {'raw': 'data', 'no': 'code'});
    });

    test('POST body 透传到请求', () async {
      dynamic sentBody;
      installMock((options) {
        sentBody = options.data;
        return okResponse(1);
      });

      final result = await ApiClient.instance.post('/x', body: {'a': 1});
      expect(sentBody, {'a': 1});
      expect(result, 1);
    });
  });

  group('ApiClient 拦截器 - 401 未登录', () {
    test('code==401 → 清 token + 调 onUnauthorized + 抛异常', () async {
      var unauthorizedCalled = false;
      installMock(
        (_) => errResponse(401, '未登录'),
        onUnauthorized: () => unauthorizedCalled = true,
      );
      ApiClient.instance.token = 'will-be-cleared';

      await expectLater(
        ApiClient.instance.get('/x'),
        throwsA(isA<DioException>()),
      );
      expect(ApiClient.instance.token, isNull);
      expect(unauthorizedCalled, isTrue);
    });
  });

  group('ApiClient 拦截器 - 业务错误', () {
    test('code!=0 → onErrorToast(msg) + 抛异常', () async {
      String? toasted;
      installMock(
        (_) => errResponse(500, '菜品不存在'),
        onErrorToast: (m) => toasted = m,
      );

      await expectLater(
        ApiClient.instance.get('/x'),
        throwsA(isA<DioException>()),
      );
      expect(toasted, '菜品不存在');
    });

    test('code!=0 且 msg 空 → toast 兜底"请求失败"', () async {
      String? toasted;
      installMock(
        (_) => {'code': 500, 'msg': '', 'data': null},
        onErrorToast: (m) => toasted = m,
      );

      await expectLater(
        ApiClient.instance.get('/x'),
        throwsA(isA<DioException>()),
      );
      expect(toasted, '请求失败');
    });
  });

  group('ApiClient 拦截器 - 网络层错误', () {
    test('连接超时等网络错误 → onErrorToast("网络连接失败...")', () async {
      String? toasted;
      installMock(
        (_) => okResponse({}),
        onErrorToast: (m) => toasted = m,
      );
      // 替换为抛网络异常的 adapter
      ApiClient.instance.dio.httpClientAdapter = _ThrowingAdapter(
        DioExceptionType.connectionTimeout,
      );

      await expectLater(
        ApiClient.instance.get('/x'),
        throwsA(isA<DioException>()),
      );
      expect(toasted, '网络连接失败，请检查后端是否可达');
    });
  });
}

/// 始终抛出指定类型 [DioException] 的 adapter，用于模拟网络层错误。
class _ThrowingAdapter implements HttpClientAdapter {
  _ThrowingAdapter(this.type);
  final DioExceptionType type;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    throw DioException(
      requestOptions: options,
      type: type,
      message: '',
    );
  }

  @override
  void close({bool force = false}) {}
}
