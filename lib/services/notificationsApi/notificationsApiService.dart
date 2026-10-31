import 'package:dio/dio.dart';
import 'package:estudazz_main_code/env.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Erro de comunicação com a API de notificações, com mensagem pronta para o usuário.
class NotificationsApiException implements Exception {
  final String message;

  NotificationsApiException(this.message);

  @override
  String toString() => message;
}

class NotificationsApiService {
  static const int _maxAttempts = 2;

  final Dio _dio;
  final Duration _retryDelay;

  NotificationsApiService({
    String? baseUrl,
    Future<String?> Function()? idTokenProvider,
    Duration retryDelay = const Duration(seconds: 2),
  }) : _retryDelay = retryDelay,
       _dio = Dio(
         BaseOptions(
           baseUrl: baseUrl ?? Env.notificationsApiBaseUrl,
           connectTimeout: const Duration(seconds: 10),
           sendTimeout: const Duration(seconds: 10),
           receiveTimeout: const Duration(seconds: 15),
         ),
       ) {
    final getIdToken =
        idTokenProvider ??
        () async => FirebaseAuth.instance.currentUser?.getIdToken();

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          try {
            final idToken = await getIdToken();
            if (idToken != null) {
              options.headers['Authorization'] = 'Bearer $idToken';
            }
            handler.next(options);
          } catch (e) {
            handler.reject(
              DioException(
                requestOptions: options,
                type: DioExceptionType.connectionError,
                error: e,
              ),
            );
          }
        },
      ),
    );
  }

  Future<String> fetchOneSignalExternalId() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/notifications/session',
    );
    final externalId = response.data?['externalId'];
    if (externalId is String && externalId.isNotEmpty) {
      return externalId;
    }
    throw NotificationsApiException('Identificador de sessão inválido.');
  }

  Future<void> scheduleReminder({
    required String type,
    required String entityId,
    required String title,
    required String body,
    required DateTime remindAt,
  }) {
    return _send(
      () => _dio.post(
        '/notifications/reminders',
        data: {
          'type': type,
          'entityId': entityId,
          'title': title,
          'body': body,
          'remindAt': remindAt.toUtc().toIso8601String(),
        },
      ),
    );
  }

  Future<void> cancelReminder({
    required String type,
    required String entityId,
  }) {
    final encodedType = Uri.encodeComponent(type);
    final encodedEntityId = Uri.encodeComponent(entityId);
    return _send(
      () =>
          _dio.delete('/notifications/reminders/$encodedType/$encodedEntityId'),
    );
  }

  Future<void> deleteAllReminders() {
    return _send(() => _dio.delete('/notifications/reminders'));
  }

  Future<void> pushToStudyRoom({
    required String roomId,
    required List<String> recipientUids,
    required String title,
    required String body,
  }) {
    final encodedRoomId = Uri.encodeComponent(roomId);
    return _send(
      () => _dio.post(
        '/notifications/study-rooms/$encodedRoomId/push',
        data: {
          'recipientUids': recipientUids,
          'title': title,
          'body': body,
        },
      ),
    );
  }

  // Repete uma vez falhas de rede; erros de resposta da API não são repetidos
  Future<void> _send(Future<Response<dynamic>> Function() request) async {
    for (var attempt = 1; ; attempt++) {
      try {
        await request();
        return;
      } on DioException catch (e) {
        if (_isNetworkError(e) && attempt < _maxAttempts) {
          await Future.delayed(_retryDelay);
          continue;
        }
        throw NotificationsApiException(_messageFor(e));
      }
    }
  }

  bool _isNetworkError(DioException e) {
    return e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError;
  }

  String _messageFor(DioException e) {
    if (_isNetworkError(e)) {
      return 'Sem conexão com o servidor. Verifique sua internet.';
    }

    final status = e.response?.statusCode;
    final data = e.response?.data;
    final errorCode = data is Map ? data['error'] : null;

    if (errorCode == 'onesignal_no_recipients') {
      return 'Ative as notificações do Estudazz neste celular para receber lembretes.';
    }
    if (status == 401) {
      return 'Sua sessão expirou. Entre novamente na sua conta.';
    }
    if (status == 400) {
      return 'Os dados do lembrete são inválidos.';
    }
    return 'O servidor de notificações está indisponível. Tente novamente mais tarde.';
  }
}
