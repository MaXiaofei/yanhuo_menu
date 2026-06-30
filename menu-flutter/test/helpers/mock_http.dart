import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import 'package:menu_flutter/core/api_client.dart';

/// 后端统一成功响应壳：`{code:0, msg, data}`。
/// ApiClient 拦截器检测到 `code` 字段会解包出 `data` 交给调用方。
Map<String, dynamic> okResponse(dynamic data, {String msg = 'success'}) =>
    {'code': 0, 'msg': msg, 'data': data};

/// 业务失败响应壳：`{code:非0, msg}`。拦截器会 toast + reject。
Map<String, dynamic> errResponse(int code, String msg) =>
    {'code': code, 'msg': msg, 'data': null};

/// 按 RequestOptions 决定返回内容的闭包签名。
/// 返回值会被 JSON 编码后作为响应体；通常返回 [okResponse]/[errResponse] 包裹的结构。
typedef MockResponder = dynamic Function(RequestOptions options);

/// 替换 [Dio.httpClientAdapter] 的内存适配器：不发起真实网络请求，
/// 而是按 [responder] 闭包返回预设 JSON 响应。
///
/// 用法：
/// ```dart
/// RequestOptions? captured;
/// ApiClient.instance.init();
/// ApiClient.instance.dio.httpClientAdapter = MockAdapter((options) {
///   captured = options;            // 捕获请求用于断言 path/query/body
///   return okResponse({...});      // 返回预设响应
/// });
/// ```
class MockAdapter implements HttpClientAdapter {
  MockAdapter(this.responder);

  final MockResponder responder;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final result = responder(options);
    final body = jsonEncode(result);
    return ResponseBody.fromString(body, 200, headers: {
      Headers.contentTypeHeader: ['application/json'],
    });
  }

  @override
  void close({bool force = false}) {}
}

/// 持有一次（或多次）被捕获的请求，供测试在 service 调用后断言 path/query/body。
class RequestCaptor {
  RequestOptions? last;
  final List<RequestOptions> all = [];
}

/// 快捷安装：初始化 ApiClient（幂等，同一 isolate 内 [ApiClient.dio] 是 late final
/// 只能赋值一次，故二次调用仅刷新回调与 adapter）、重置 token、挂上 [MockAdapter]，
/// 返回 [RequestCaptor]。
///
/// 调用方在 service 调用后读取 `captor.last` 来断言请求细节
///（path、queryParameters、data、method）。
///
/// ```dart
/// final captor = installMock((_) => okResponse({...}));
/// await DishService.search();
/// expect(captor.last!.path, '/dish/search');
/// ```
RequestCaptor installMock(
  MockResponder responder, {
  void Function()? onUnauthorized,
  void Function(String)? onErrorToast,
}) {
  final captor = RequestCaptor();
  try {
    ApiClient.instance.init(
      onUnauthorized: onUnauthorized,
      onErrorToast: onErrorToast,
    );
  } catch (_) {
    // dio 已赋值（同 isolate 跨测试复用），仅刷新回调
    ApiClient.instance.onUnauthorized = onUnauthorized;
    ApiClient.instance.onErrorToast = onErrorToast;
  }
  ApiClient.instance.token = null;
  ApiClient.instance.dio.httpClientAdapter = MockAdapter((options) {
    captor.last = options;
    captor.all.add(options);
    return responder(options);
  });
  return captor;
}
