import 'dart:convert';
import 'dart:io';

import 'package:estudazz_main_code/services/notificationsApi/notificationsApiService.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late HttpServer server;
  late int requestCount;
  late String? lastAuthorization;
  late int responseStatus;
  late Map<String, dynamic>? responseBody;

  setUp(() async {
    requestCount = 0;
    lastAuthorization = null;
    responseStatus = 201;
    responseBody = null;

    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      requestCount++;
      lastAuthorization = request.headers.value('authorization');
      await utf8.decoder.bind(request).join();
      request.response.statusCode = responseStatus;
      if (responseBody != null) {
        request.response.headers.contentType = ContentType.json;
        request.response.write(jsonEncode(responseBody));
      }
      await request.response.close();
    });
  });

  tearDown(() => server.close(force: true));

  NotificationsApiService buildService({
    Future<String?> Function()? idTokenProvider,
    String? baseUrl,
  }) {
    return NotificationsApiService(
      baseUrl: baseUrl ?? 'http://${server.address.host}:${server.port}',
      idTokenProvider: idTokenProvider ?? () async => 'token-de-teste',
      retryDelay: Duration.zero,
    );
  }

  Future<void> schedule(NotificationsApiService service) {
    return service.scheduleReminder(
      type: 'task',
      entityId: 'abc',
      title: 'Tarefa pendente',
      body: 'Estudar',
      remindAt: DateTime.now().add(const Duration(hours: 1)),
    );
  }

  Future<String> errorMessageOf(Future<void> future) async {
    try {
      await future;
    } on NotificationsApiException catch (e) {
      return e.message;
    }
    fail('Era esperado NotificationsApiException');
  }

  test('agenda com sucesso enviando o token do usuário', () async {
    await schedule(buildService());

    expect(requestCount, 1);
    expect(lastAuthorization, 'Bearer token-de-teste');
  });

  test('sem destinatário inscrito pede para ativar notificações e não repete', () async {
    responseStatus = 502;
    responseBody = {
      'error': 'onesignal_no_recipients',
      'message': 'Nenhum destinatário inscrito para receber a notificação.',
    };

    final message = await errorMessageOf(schedule(buildService()));

    expect(message, contains('Ative as notificações'));
    expect(requestCount, 1);
  });

  test('sessão expirada (401) avisa para entrar novamente', () async {
    responseStatus = 401;
    responseBody = {'error': 'unauthorized', 'message': 'Não autorizado.'};

    final message = await errorMessageOf(schedule(buildService()));

    expect(message, contains('sessão expirou'));
  });

  test('erro do servidor (500) avisa indisponibilidade e não repete', () async {
    responseStatus = 500;
    responseBody = {'error': 'internal_error', 'message': 'Erro.'};

    final message = await errorMessageOf(schedule(buildService()));

    expect(message, contains('indisponível'));
    expect(requestCount, 1);
  });

  test('cancelamento com falha também lança erro', () async {
    responseStatus = 503;

    final message = await errorMessageOf(
      buildService().cancelReminder(type: 'task', entityId: 'abc'),
    );

    expect(message, contains('indisponível'));
  });

  test('sem conexão tenta de novo uma vez e avisa sobre a internet', () async {
    final closedServer = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final closedPort = closedServer.port;
    await closedServer.close(force: true);

    var attempts = 0;
    final service = buildService(
      baseUrl: 'http://127.0.0.1:$closedPort',
      idTokenProvider: () async {
        attempts++;
        return 'token-de-teste';
      },
    );

    final message = await errorMessageOf(schedule(service));

    expect(message, contains('Sem conexão'));
    expect(attempts, 2);
  });

  test('falha ao obter o token vira erro de conexão em vez de travar', () async {
    final service = buildService(
      idTokenProvider: () async => throw Exception('offline'),
    );

    final message = await errorMessageOf(schedule(service));

    expect(message, contains('Sem conexão'));
    expect(requestCount, 0);
  });
}
