/// Destino de uma notificação tocada, a partir do `data` enviado pela API.
sealed class NotificationLink {
  const NotificationLink();

  /// Retorna `null` quando a notificação não aponta para uma tela específica
  /// (ex.: broadcast de novidades), e o app só abre normalmente.
  static NotificationLink? fromData(Map<String, dynamic>? data) {
    if (data == null) return null;

    final type = data['type'];
    final entityId = _nonEmptyString(data['entityId']);
    final roomId = _nonEmptyString(data['roomId']);

    if (type == 'task' && entityId != null) return TaskLink(entityId);
    if (type == 'event' && entityId != null) return EventLink(entityId);
    if (type == 'study_room' && roomId != null) return StudyRoomLink(roomId);
    return null;
  }

  static String? _nonEmptyString(Object? value) {
    return value is String && value.isNotEmpty ? value : null;
  }
}

class TaskLink extends NotificationLink {
  final String taskId;
  const TaskLink(this.taskId);
}

class EventLink extends NotificationLink {
  final String eventId;
  const EventLink(this.eventId);
}

class StudyRoomLink extends NotificationLink {
  final String roomId;
  const StudyRoomLink(this.roomId);
}
