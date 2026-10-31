import 'package:estudazz_main_code/services/notificationsApi/notificationLink.dart';
import 'package:estudazz_main_code/services/notificationsApi/notificationRouter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late List<NotificationLink> opened;

  setUp(() {
    opened = [];
    NotificationRouter.debugReset(open: (link) async => opened.add(link));
  });

  test('toque com o app fechado espera a Home ficar pronta', () {
    NotificationRouter.handleTap({'type': 'task', 'entityId': 't1'});
    expect(opened, isEmpty);

    NotificationRouter.markReady();
    expect(opened, hasLength(1));
    expect((opened.single as TaskLink).taskId, 't1');
  });

  test('toque com o app aberto navega na hora', () {
    NotificationRouter.markReady();
    NotificationRouter.handleTap({'type': 'study_room', 'roomId': 'r1'});

    expect(opened.single, isA<StudyRoomLink>());
  });

  test('o destino é aberto uma única vez', () {
    NotificationRouter.handleTap({'type': 'event', 'entityId': 'e1'});
    NotificationRouter.markReady();
    NotificationRouter.markReady();

    expect(opened, hasLength(1));
  });

  test('vale o último toque recebido antes da Home ficar pronta', () {
    NotificationRouter.handleTap({'type': 'task', 'entityId': 't1'});
    NotificationRouter.handleTap({'type': 'event', 'entityId': 'e2'});
    NotificationRouter.markReady();

    expect(opened, hasLength(1));
    expect((opened.single as EventLink).eventId, 'e2');
  });

  test('depois do logout volta a esperar a Home', () {
    NotificationRouter.markReady();
    NotificationRouter.markNotReady();
    NotificationRouter.handleTap({'type': 'task', 'entityId': 't1'});
    expect(opened, isEmpty);

    NotificationRouter.markReady();
    expect(opened, hasLength(1));
  });

  test('trocar a Home por outra não trava a navegação', () {
    // Nova Home monta antes de a antiga ser descartada
    NotificationRouter.markReady();
    NotificationRouter.markReady();
    NotificationRouter.markNotReady();

    NotificationRouter.handleTap({'type': 'task', 'entityId': 't1'});
    expect(opened, hasLength(1));
  });

  test('notificação sem destino (broadcast) não navega', () {
    NotificationRouter.markReady();
    NotificationRouter.handleTap(null);
    NotificationRouter.handleTap({'type': 'qualquer'});

    expect(opened, isEmpty);
  });
}
