import 'package:dio/dio.dart';
import 'package:estudazz_main_code/env.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AiServiceException implements Exception {
  final String message;

  const AiServiceException(this.message);

  @override
  String toString() => message;
}

class AiGeminiServices {
  final Dio _dio;
  final FirebaseAuth _auth;

  AiGeminiServices({Dio? dio, FirebaseAuth? auth})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: Env.notificationsApiBaseUrl,
              connectTimeout: const Duration(seconds: 20),
              receiveTimeout: const Duration(seconds: 60),
              headers: {'Content-Type': 'application/json'},
            ),
          ),
      _auth = auth ?? FirebaseAuth.instance;

  Future<String> generateText(String userPrompt) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const AiServiceException('Usuário não está autenticado.');
    }

    final token = await user.getIdToken();
    if (token == null || token.isEmpty) {
      throw const AiServiceException(
        'Não foi possível validar sua sessão. Faça login novamente.',
      );
    }

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/ai/generate',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
        data: {'prompt': userPrompt},
      );

      final text = response.data?['text'];
      if (text is String && text.trim().isNotEmpty) {
        return text;
      }

      return 'A IA processou a requisição, mas não retornou um texto legível.';
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint('Erro ao gerar resposta da IA (${e.response?.statusCode})');
      }
      if (e.response?.statusCode == 429) {
        throw const AiServiceException(
          'Muitas mensagens enviadas em sequência. Aguarde um instante e tente novamente.',
        );
      }
      throw const AiServiceException(
        'Não foi possível gerar uma resposta da IA no momento. Tente novamente.',
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Erro inesperado na IA');
      }
      throw const AiServiceException(
        'Ocorreu um erro ao processar sua pergunta. Tente novamente.',
      );
    }
  }
}
