import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:dio_http_cache_fix/dio_http_cache.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class DioSingleton {
  static Dio? dio;
  static DioCacheManager? cache;

  DioSingleton._();

  static final String certifiedPass = dotenv.env['BRICKS_CERTIFIED_PASS']!;

  static Future<Dio> getInstance() async {
    if (dio == null) {
      cache = DioCacheManager(CacheConfig(baseUrl: dotenv.env['BRICKS_URL']!));
      dio = Dio()..interceptors.add(cache!.interceptor);

      ByteData clientCertificate = await rootBundle.load(dotenv.env['BRICKS_CERTIFIED_PRIVATE_KEY']!);
      ByteData privateKey = await rootBundle.load(dotenv.env['BRICKS_CERTIFIED_CLIENT']!);

      final SecurityContext securityContext = SecurityContext();

      dio!.httpClientAdapter = IOHttpClientAdapter(
        createHttpClient: () {
          securityContext.setTrustedCertificatesBytes(clientCertificate.buffer.asUint8List(), password: certifiedPass);
          securityContext.usePrivateKeyBytes(privateKey.buffer.asUint8List(), password: certifiedPass);
          final HttpClient client = HttpClient(context: securityContext);
          client.badCertificateCallback = (cert, host, port) => true;
          return client;
        },
        validateCertificate: (clientCertificate, host, port) => true,
      );
    }
    return dio!;
  }

  static DioCacheManager? getCache() {
    return cache;
  }
}
