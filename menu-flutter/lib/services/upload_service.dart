import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

import '../core/api_client.dart';

/// 上传返回（后端 /file/upload 新响应格式）。
class UploadResult {
  /// 原图 URL（如 /gudu/uploads/original/123.jpg）。
  final String url;

  /// 缩略图 URL（如 /gudu/uploads/thumbnail/123.jpg）。
  final String thumbnailUrl;

  /// 原始文件名。
  final String name;

  const UploadResult({
    required this.url,
    required this.thumbnailUrl,
    required this.name,
  });
}

/// 图片上传服务：压缩 → 上传 → 返回原图 + 缩略图 URL。
///
/// 策略：
/// - 选图后立刻压缩（长边 ≤ 1920px，JPEG 80%），删原图。
/// - 上传到后端，后端同时生成原图 + 400px 缩略图。
/// - 返回 {url（原图）, thumbnailUrl（缩略图）, name}。
/// - 本地临时文件上传后自动删除。
class UploadService {
  UploadService._();

  /// 压缩图片文件。缩尺寸 + 降质量，输出 JPEG。
  ///
  /// [maxSize] 长边最大像素，默认 1920；
  /// [quality] JPEG 质量 1-100，默认 80。
  static Future<File> compress(
    File file, {
    int maxSize = 1920,
    int quality = 80,
  }) async {
    final outPath =
        '${file.parent.path}/cpr_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      outPath,
      quality: quality,
      minWidth: maxSize,
      minHeight: maxSize,
      format: CompressFormat.jpeg,
    );
    if (result == null) {
      throw Exception('图片压缩失败');
    }
    return File(result.path);
  }

  /// 压缩 + 上传单张图片。返回 [UploadResult]（含原图 URL 和缩略图 URL）。
  ///
  /// 上传完成后自动删除压缩临时文件。
  static Future<UploadResult> uploadOne(File file) async {
    final compressed = await compress(file);
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          compressed.path,
          filename: 'upload.jpg',
        ),
      });

      // 直接调 dio 以覆盖默认 application/json Content-Type
      final response = await ApiClient.instance.dio.post(
        '/file/upload',
        data: formData,
        options: Options(
          headers: {'Content-Type': 'multipart/form-data'},
        ),
      );

      // 拦截器已解包 {code,msg,data}，response.data 即 data 对象
      final data = response.data;
      if (data is Map) {
        return UploadResult(
          url: (data['url'] ?? '') as String,
          thumbnailUrl: (data['thumbnailUrl'] ?? data['url'] ?? '') as String,
          name: (data['name'] ?? '') as String,
        );
      }
      throw Exception('上传响应格式异常');
    } finally {
      // 清理压缩临时文件
      try {
        if (compressed.existsSync()) compressed.deleteSync();
      } catch (_) {}
    }
  }
}
