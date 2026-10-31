import 'package:estudazz_main_code/services/notificationsApi/notificationLink.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('lembrete de tarefa abre a tarefa', () {
    final link = NotificationLink.fromData({'type': 'task', 'entityId': 't1'});
    expect(link, isA<TaskLink>());
    expect((link as TaskLink).taskId, 't1');
  });

  test('lembrete de evento abre o evento', () {
    final link = NotificationLink.fromData({'type': 'event', 'entityId': 'e1'});
    expect(link, isA<EventLink>());
    expect((link as EventLink).eventId, 'e1');
  });

  test('push de sala abre a sala', () {
    final link = NotificationLink.fromData({
      'type': 'study_room',
      'roomId': 'r1',
      'extra': 'ignorado',
    });
    expect(link, isA<StudyRoomLink>());
    expect((link as StudyRoomLink).roomId, 'r1');
  });

  test('broadcast, reengajamento e lembretes antigos sem data não navegam', () {
    expect(NotificationLink.fromData(null), isNull);
    expect(NotificationLink.fromData({}), isNull);
    expect(NotificationLink.fromData({'type': 'desconhecido', 'entityId': 'x'}), isNull);
  });

  test('ids ausentes, vazios ou com tipo errado não navegam', () {
    expect(NotificationLink.fromData({'type': 'task'}), isNull);
    expect(NotificationLink.fromData({'type': 'task', 'entityId': ''}), isNull);
    expect(NotificationLink.fromData({'type': 'event', 'entityId': 42}), isNull);
    expect(NotificationLink.fromData({'type': 'study_room', 'entityId': 'r1'}), isNull);
  });
}
