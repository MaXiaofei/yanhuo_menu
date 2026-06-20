/// 后端统一响应 R<T>：`{code, msg, data}`（menu-api common/R.java）。
/// code==0 成功；code==401 未登录；其它非 0 业务失败。
class ApiResponse {
  final int code;
  final String msg;
  final dynamic data;

  ApiResponse({required this.code, required this.msg, this.data});

  factory ApiResponse.fromJson(Map<String, dynamic> json) => ApiResponse(
        code: (json['code'] as num).toInt(),
        msg: (json['msg'] ?? '') as String,
        data: json['data'],
      );

  bool get ok => code == 0;
}

/// 业务错误异常（code != 0），携带后端 msg。
class ApiError implements Exception {
  final String message;
  ApiError(this.message);
  @override
  String toString() => message;
}
