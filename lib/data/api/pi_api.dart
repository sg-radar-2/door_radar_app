import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../models/models.dart';

import 'package:flutter/foundation.dart';

/// 파이 API 오류. 서버의 `{"error": "<코드>", "message": "<설명>"}` 또는 네트워크 오류.
class PiApiException implements Exception {
  const PiApiException({required this.code, required this.message, this.statusCode});

  /// 서버 코드("unauthorized", "bad_code", "not_found" …) 또는 앱 쪽 코드("network", "timeout", "bad_response")
  final String code;
  final String message;
  final int? statusCode;

  bool get isUnauthorized => statusCode == 401;
  bool get isNetwork => code == 'network' || code == 'timeout';

  factory PiApiException.fromDio(DioException e) {
    final res = e.response;
    final data = res?.data;
    if (data is Map && data['error'] is String) {
      return PiApiException(
        code: data['error'] as String,
        message: (data['message'] as String?) ?? '',
        statusCode: res?.statusCode,
      );
    }
    if (res != null) {
      return PiApiException(code: 'http_${res.statusCode}', message: '서버 오류 (${res.statusCode})', statusCode: res.statusCode);
    }
    return switch (e.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout =>
        const PiApiException(code: 'timeout', message: '응답이 없어요'),
      _ => PiApiException(code: 'network', message: e.message ?? '연결할 수 없어요'),
    };
  }

  @override
  String toString() => 'PiApiException($statusCode $code: $message)';
}


/// Cloud의 snake_case JSON을 Flutter Event 모델 형식으로 정규화한다.
Event _eventFromCloudJson(Map<String, dynamic> json) {
  // 기존 테스트 Event에는 started_at이 없을 수 있다.
  // 이런 경우에만 Event 발생 시각(t)을 임시 대체값으로 사용한다.
  final startedAt =
      json['started_at'] ?? json['startedAt'] ?? json['t'];

  final endedAt =
      json['ended_at'] ?? json['endedAt'];

  final endSituation =
      json['end_situation'] ?? json['endSituation'];

  return Event.fromJson({
    ...json,
    'startedAt': startedAt,
    'started_at': startedAt,
    'endedAt': endedAt,
    'ended_at': endedAt,
    'endSituation': endSituation,
    'end_situation': endSituation,
  });
}


/// SPEC 4장 REST. 클라우드(SPEC 9장)가 경로·필드를 그대로 제공한다.
/// `/api/pair` 외에는 토큰이 있으면 `Authorization: Bearer <토큰>` 을 인터셉터가 붙인다.
/// (`/api/info` 도 토큰과 함께 불러야 클라우드가 어느 파이인지 안다)
class PiApi {
  PiApi({required PiDevice device, this.token, Dio? dio}) : dio = dio ?? Dio() {
    this.dio.options
      ..baseUrl = device.baseUri.toString()
      ..connectTimeout = const Duration(seconds: 60)
      ..receiveTimeout = const Duration(seconds: 30)
      ..sendTimeout = const Duration(seconds: 30);

    this.dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final t = token;

          if (t != null && !_publicPaths.contains(options.path)) {
            options.headers['Authorization'] = 'Bearer $t';
          }

          debugPrint('[API 요청] ${options.method} ${options.uri}');
          handler.next(options);
        },

        onResponse: (response, handler) {
          debugPrint(
            '[API 성공] ${response.statusCode} '
            '${response.requestOptions.path}',
          );
          handler.next(response);
        },

        onError: (e, handler) {
          debugPrint(
            '[API 실패] ${e.requestOptions.path} '
            'type=${e.type}, '
            'status=${e.response?.statusCode}, '
            'message=${e.message}',
          );

          handler.next(
            e.copyWith(error: PiApiException.fromDio(e)),
          );
        },
      ),
    );
  }

  final Dio dio;

  /// `/api/pair` 가 성공하면 채워진다
  String? token;

  static const _publicPaths = {'/api/pair'};

  /// 사진 등 다른 HTTP 클라이언트(cached_network_image)에 붙일 헤더
  Map<String, String> get authHeaders => token == null ? const {} : {'Authorization': 'Bearer $token'};

  // ---------------------------------------------------------------- 인증 없음

  /// 페어링한 파이의 정보 (토큰 필요, SPEC 9.1)
  Future<DeviceInfo> info() => _guard(() async {
        final res = await dio.get<Map<String, dynamic>>('/api/info');
        return DeviceInfo.fromJson(res.data!);
      });

  /// 6자리 코드로 토큰을 받는다. 받은 토큰은 이 인스턴스에도 바로 쓴다.
  Future<String> pair(String code) => _guard(() async {
        final res = await dio.post<Map<String, dynamic>>('/api/pair', data: {'code': code});
        return token = res.data!['token'] as String;
      });

  // ---------------------------------------------------------------- 인증 필요

  /// 레이더 다시 연결 시도 (SPEC 8장). 돌려받는 건 `{"radar": "connecting"}`.
  Future<void> radarReconnect() => _guard(() async {
        await dio.post<Map<String, dynamic>>('/api/radar/reconnect');
      });

  Future<DeviceStatus> status() => _guard(() async {
        final res = await dio.get<Map<String, dynamic>>('/api/status');
        return DeviceStatus.fromJson(res.data!);
      });

  /// 최신순. [since] 는 서버가 준 ISO 문자열(마지막으로 받은 이벤트의 `t`) 그대로.
  Future<List<Event>> events({String? since, int? limit, bool? abnormal}) => _guard(() async {
        final res = await dio.get<List<dynamic>>('/api/events', queryParameters: {
          'since': ?since,
          'limit': ?limit,
          'abnormal': ?abnormal,
        });
        return res.data!
          .map((e) => _eventFromCloudJson(e as Map<String, dynamic>))
          .toList();
      });

  Future<Event> event(int id) => _guard(() async {
        final res = await dio.get<Map<String, dynamic>>('/api/events/$id');
        return _eventFromCloudJson(res.data!);
      });

  /// 사진 URL (cached_network_image 에 [authHeaders] 와 함께 넘긴다)
  String photoUrl(int id, {bool thumb = false}) => '${dio.options.baseUrl}/api/events/$id/photo${thumb ? '?thumb=1' : ''}';

  /// 사진 JPEG 원본/썸네일 바이트 (폰 보관용)
  Future<Uint8List> photo(int id, {bool thumb = false}) => _guard(() async {
        final res = await dio.get<List<int>>(
          '/api/events/$id/photo',
          queryParameters: {if (thumb) 'thumb': 1},
          options: Options(responseType: ResponseType.bytes),
        );
        return Uint8List.fromList(res.data!);
      });

  /// 이 폰(토큰)이 아직 안 받은 사진의 이벤트 id
  Future<List<int>> pendingPhotos() => _guard(() async {
        final res = await dio.get<Map<String, dynamic>>('/api/photos/pending');
        return (res.data!['ids'] as List).map((e) => (e as num).toInt()).toList();
      });

  Future<void> ackPhotos(List<int> ids) => _guard(() async {
        await dio.post<dynamic>('/api/photos/ack', data: {'ids': ids});
      });

  /// 정답 표시. 서버는 바뀐 이벤트(목록 형식)를 돌려준다.
  /// 정답 표시. [situation] 이 null 이면 정답을 지운다("되돌리기").
  Future<Event> label(int id, String? situation) => _guard(() async {
        final res = await dio.post<Map<String, dynamic>>('/api/events/$id/label', data: {'situation': situation});
        return Event.fromJson(res.data!);
      });

  Future<PiSettings> settings() => _guard(() async {
        final res = await dio.get<Map<String, dynamic>>('/api/settings');
        return PiSettings.fromJson(res.data!);
      });

  /// 바꿀 키만 보낸다. `region`, `device_keep_days` 는 읽기 전용이라 보내지 않는다.
  Future<PiSettings> updateSettings({List<String>? notify, bool? cameraOn, double? cameraProb, double? cameraHoldS}) =>
      _guard(() async {
        final res = await dio.put<Map<String, dynamic>>('/api/settings', data: {
          'notify': ?notify,
          'camera_on': ?cameraOn,
          'camera_prob': ?cameraProb,
          'camera_hold_s': ?cameraHoldS,
        });
        return PiSettings.fromJson(res.data!);
      });

  /// 이 폰의 FCM 토큰 등록 (클라우드만, SPEC 9.1). 앱 토큰마다 하나.
  Future<void> pushToken(String fcmToken) => _guard(() async {
        await dio.put<dynamic>('/api/push_token', data: {'token': fcmToken});
      });

  void close() => dio.close(force: true);

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      final err = e.error;
      throw err is PiApiException ? err : PiApiException.fromDio(e);
    } on TypeError catch (e) {
      // 응답 JSON 이 명세와 다를 때 (필드 누락·타입 불일치)
      throw PiApiException(code: 'bad_response', message: '응답 형식이 달라요: $e');
    }
  }
}
