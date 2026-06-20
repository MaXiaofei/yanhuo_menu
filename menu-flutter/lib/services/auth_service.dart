import '../core/api_client.dart';

/// 鉴权服务（对应 menu-mini/src/api 的登录 + AuthController）。
class AuthService {
  /// 登录：POST /auth/login {username,password} → {token, nickname}。
  static Future<({String token, String nickname})> login(
    String username,
    String password,
  ) async {
    final data = await ApiClient.instance.post(
      '/auth/login',
      body: {'username': username, 'password': password},
    ) as Map<String, dynamic>;
    return (
      token: data['token'] as String,
      nickname: (data['nickname'] ?? '') as String,
    );
  }
}
