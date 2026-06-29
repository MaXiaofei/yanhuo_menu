import 'constants.dart';

/// 图片 URL 工具：绝对 URL 拼接 + 缩略图替换。
///
/// 规则：
/// - 原图：{baseUrl}/uploads/original/xxx.jpg（已含 /gudu context-path → 不重复拼）
/// - 缩略图：{baseUrl}/uploads/thumbnail/xxx.jpg（字符串替换 /original/ → /thumbnail/）
/// - 兜底：图片无 /original/ 路径时，不替换（保持原 URL 作为缩略图）。
class ImageHelper {
  ImageHelper._();

  /// 将后端返回的相对路径转为可直连的绝对 URL。
  ///
  /// 后端路径已含 /gudu 前缀（如 /gudu/uploads/original/1.jpg），
  /// 不可再拼 baseUrl（baseUrl 本身以 /gudu 结尾），否则双前缀。
  /// 已是 http(s) 绝对路径的直接返回。
  static String toAbsolute(String u) {
    if (u.isEmpty) return '';
    if (u.startsWith('http')) return u;
    return u.startsWith('/gudu') ? u : '${AppConstants.baseUrl}$u';
  }

  /// 从原图 URL 推导缩略图 URL（/original/ → /thumbnail/）。
  ///
  /// 如果 URL 不含 /original/，返回原 URL（兜底，可能是旧格式）。
  static String toThumbnail(String originalUrl) {
    if (originalUrl.contains('/original/')) {
      return originalUrl.replaceFirst('/original/', '/thumbnail/');
    }
    // 兜底：旧格式或未知格式，直接用原图
    return originalUrl;
  }

  /// 同时返回绝对化的原图 URL 和缩略图 URL。
  static ({String original, String thumbnail}) resolve(String url) {
    final abs = toAbsolute(url);
    return (original: abs, thumbnail: toThumbnail(abs));
  }
}
