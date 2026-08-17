import 'dart:convert';
import 'package:flutter/material.dart';

class LuxuryImage extends StatelessWidget {
  const LuxuryImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.kenBurns = false,
  });

  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final bool kenBurns;

  @override
  Widget build(BuildContext context) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return const SizedBox.shrink();

    Widget image;
    if (trimmed.startsWith('data:image/')) {
      try {
        final commaIndex = trimmed.indexOf(',');
        if (commaIndex != -1) {
          final bytes = base64Decode(trimmed.substring(commaIndex + 1));
          image = Image.memory(
            bytes,
            fit: fit,
            width: width,
            height: height,
            filterQuality: FilterQuality.low,
            errorBuilder: (_, _, _) => const SizedBox.shrink(),
          );
        } else {
          return const SizedBox.shrink();
        }
      } catch (_) {
        return const SizedBox.shrink();
      }
    } else if (trimmed.startsWith('assets/')) {
      image = Image.asset(
        trimmed,
        fit: fit,
        width: width,
        height: height,
        gaplessPlayback: true,
        filterQuality: FilterQuality.medium,
        errorBuilder: (_, _, _) => const SizedBox.shrink(),
      );
    } else {
      image = Image.network(
        trimmed,
        fit: fit,
        width: width,
        height: height,
        filterQuality: FilterQuality.high,
        errorBuilder: (_, _, _) => const SizedBox.shrink(),
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return ColoredBox(
            color: Colors.black26,
            child: Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  value: progress.expectedTotalBytes == null
                      ? null
                      : progress.cumulativeBytesLoaded /
                          progress.expectedTotalBytes!,
                ),
              ),
            ),
          );
        },
      );
    }

    if (!kenBurns) return image;
    return ClipRect(
      child: RepaintBoundary(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 1, end: 1.08),
          duration: const Duration(seconds: 18),
          curve: Curves.easeInOut,
          builder: (context, scale, child) {
            return Transform.scale(scale: scale, child: child);
          },
          child: image,
        ),
      ),
    );
  }
}
