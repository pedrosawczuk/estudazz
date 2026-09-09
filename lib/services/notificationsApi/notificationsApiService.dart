import 'package:dio/dio.dart';
import 'package:estudazz_main_code/env.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class NotificationsApiService {
  final Dio _dio = Dio(
    BaseOptions(baseUrl: Env.notificationsApiBaseUrl),
  )..interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
        if (idToken != null) {
          options.headers['Authorization'] = 'Bearer $idToken';
        }
        handler.next(options);
      },
    ),
  );

  Future<void> scheduleReminder({
    required String type,
    required String entityId,
    required String title,
    required String body,
    required DateTime remindAt,
  }) async {
    try {
      await _dio.post(
        '/notifications/reminders',
        data: {
          'type': type,
          'entityId': entityId,
          'title': title,
          'body': body,
          'remindAt': remindAt.toUtc().toIso8601String(),
        },
      );
    } catch (e) {
      debugPrint('Erro ao agendar lembrete de notificação: $e');
    }
  }

  Future<void> cancelReminder({
    required String type,
    required String entityId,
  }) async {
    try {
      await _dio.delete('/notifications/reminders/$type/$entityId');
    } catch (e) {
      debugPrint('Erro ao cancelar lembrete de notificação: $e');
    }
  }

  Future<void> pushToStudyRoom({
    required String roomId,
    required List<String> recipientUids,
    required String title,
    required String body,
  }) async {
    try {
      await _dio.post(
        '/notifications/study-rooms/$roomId/push',
        data: {
          'recipientUids': recipientUids,
          'title': title,
          'body': body,
        },
      );
    } catch (e) {
      debugPrint('Erro ao enviar push da sala de estudo: $e');
    }
  }
}
