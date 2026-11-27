import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Configuração personalizada do [CacheManager] para armazenar arquivos SVG
/// no cache local por pelo menos 7 dias.
class CustomSvgCacheManager {
  static const key = 'customWeatherSvgCacheKey';

  static final CacheManager instance = CacheManager(
    Config(
      key,
      stalePeriod: const Duration(days: 7), // Cache mantido por 7 dias
      maxNrOfCacheObjects: 200,
      repo: JsonCacheInfoRepository(databaseName: key),
      fileService: HttpFileService(),
    ),
  );
}

/// Widget reutilizável para exibição de arquivos SVG remotos com cache local.
/// Evita erros de rede (ex: SocketException) quando o dispositivo está offline,
/// utilizando o arquivo previamente salvo no cache.
class CustomWeatherSvg extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final CacheManager? cacheManager;

  const CustomWeatherSvg({
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.placeholder,
    this.errorWidget,
    this.cacheManager,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl.trim().isEmpty) {
      return errorWidget ?? _defaultErrorWidget();
    }

    final manager = cacheManager ?? CustomSvgCacheManager.instance;

    return FutureBuilder<File>(
      future: manager.getSingleFile(imageUrl),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
          return SvgPicture.file(
            snapshot.data!,
            width: width,
            height: height,
            fit: fit,
          );
        }

        if (snapshot.hasError) {
          return errorWidget ?? _defaultErrorWidget();
        }

        return placeholder ??
            SizedBox(
              width: width,
              height: height,
              child: const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF7693FF),
                  ),
                ),
              ),
            );
      },
    );
  }

  Widget _defaultErrorWidget() {
    return SizedBox(
      width: width,
      height: height,
      child: Icon(
        Icons.cloud_off,
        color: Colors.grey,
        size: height ?? 28,
      ),
    );
  }
}
