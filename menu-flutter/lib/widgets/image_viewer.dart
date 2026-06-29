import 'package:flutter/material.dart';

import '../core/theme.dart';

/// 全屏图片查看器。
///
/// - 先快速展示缩略图，原图后台加载完成后无缝切换。
/// - 支持双指缩放 + 拖拽（InteractiveViewer）。
/// - 点击背景或左上角返回关闭。
class ImageViewer extends StatefulWidget {
  final String thumbnailUrl;
  final String originalUrl;

  const ImageViewer({
    super.key,
    required this.thumbnailUrl,
    required this.originalUrl,
  });

  @override
  State<ImageViewer> createState() => _ImageViewerState();
}

class _ImageViewerState extends State<ImageViewer> {
  ImageStream? _originalStream;
  bool _originalReady = false;

  @override
  void initState() {
    super.initState();
    // 预加载原图
    final originalProvider = NetworkImage(widget.originalUrl);
    _originalStream = originalProvider.resolve(ImageConfiguration.empty);
    _originalStream!.addListener(ImageStreamListener(
      (_, __) {
        if (mounted) setState(() => _originalReady = true);
      },
      onError: (_, __) {
        // 原图加载失败，保持缩略图
        if (mounted) setState(() => _originalReady = true);
      },
    ));
  }

  @override
  void dispose() {
    _originalStream = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Center(
          child: InteractiveViewer(
            minScale: 1.0,
            maxScale: 5.0,
            child: _originalReady
                ? Image.network(
                    widget.originalUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Image.network(
                      widget.thumbnailUrl,
                      fit: BoxFit.contain,
                    ),
                    loadingBuilder: (_, child, progress) {
                      if (progress == null) return child;
                      // 原图还在加载时不闪，继续显示缩略图
                      return Image.network(
                        widget.thumbnailUrl,
                        fit: BoxFit.contain,
                      );
                    },
                  )
                : Image.network(
                    widget.thumbnailUrl,
                    fit: BoxFit.contain,
                    loadingBuilder: (_, child, progress) {
                      if (progress == null) return child;
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      );
                    },
                  ),
          ),
        ),
      ),
    );
  }
}
