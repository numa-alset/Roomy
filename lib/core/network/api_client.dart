import 'package:dio/dio.dart';
import 'package:dio_smart_retry/dio_smart_retry.dart';
import 'package:flutter/foundation.dart'; // for kDebugMode
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

typedef TokenProvider = Future<String?> Function();

class DioClient {
  final Dio dio;
  DioClient._(this.dio);

  factory DioClient({
    required String baseUrl,
    required TokenProvider getToken,
    Duration connectTimeout = const Duration(seconds: 10),
    Duration receiveTimeout = const Duration(seconds: 30),
  }) {
    final dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: connectTimeout,
      receiveTimeout: receiveTimeout,
      // validate HTTP status manually -> treat 4xx/5xx as errors in interceptor
      validateStatus: (_) => true,
    ));

    // Attach JWT on every request (read fresh token each time)
    dio.interceptors.add(InterceptorsWrapper(onRequest: (opts, handler) async {
      final tk = await getToken();
      if (tk != null && tk.isNotEmpty) {
        opts.headers['authorization'] = 'Bearer $tk';
      }
      return handler.next(opts);
    }, onResponse: (res, handler) {
      final code = res.statusCode ?? 0;
      if (code >= 200 && code < 300) return handler.next(res);
      return handler.reject(DioException(
        requestOptions: res.requestOptions,
        response: res,
        type: DioExceptionType.badResponse,
        error: 'HTTP $code',
      ));
    }));

    // Simple retry policy on network-ish failures & 5xx
    dio.interceptors.add(RetryInterceptor(
      dio: dio,
      logPrint: kDebugMode ? print : null,
      retries: 2,
      retryDelays: const [Duration(milliseconds: 300), Duration(seconds: 1)],
      retryEvaluator: (error, attempt) {
        final code = error.response?.statusCode ?? 0;
        // Retry on 429/503 + transient errors
        return code == 429 ||
            code >= 500 ||
            error.type == DioExceptionType.connectionError;
      },
    ));

    if (kDebugMode) {
      dio.interceptors.add(PrettyDioLogger(
          requestHeader: true,
          requestBody: true,
          responseBody: false,
          responseHeader: false,
          compact: true));
    }

    return DioClient._(dio);
  }

  Future<Map<String, dynamic>> postJson(String path, Map<String, dynamic> body,
      {CancelToken? cancelToken}) async {
    final r = await dio.post(path, data: body, cancelToken: cancelToken);
    final data = r.data;
    if (data is Map<String, dynamic>) return data;
    return Map<String, dynamic>.from(data);
  }

  Future<Map<String, dynamic>> postMultipart(
    String path, {
    required String fieldName,
    required String filePath,
    Map<String, String>? fields,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
  }) async {
    final form = FormData.fromMap({
      ...(fields ?? {}),
      fieldName: await MultipartFile.fromFile(filePath),
    });
    final r = await dio.post(path,
        data: form, cancelToken: cancelToken, onSendProgress: onSendProgress);
    final data = r.data;
    if (data is Map<String, dynamic>) return data;
    return Map<String, dynamic>.from(data);
  }
}
