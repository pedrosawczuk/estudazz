import 'package:estudazz_main_code/services/db/calendar/eventsDB.dart';
import 'package:estudazz_main_code/services/notificationsApi/reminderFeedback.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// `savedWithoutReminder`: o evento foi salvo, mas o lembrete falhou (o usuário já foi avisado).
enum AddEventResult { success, savedWithoutReminder, emptyName, pastDate, error }

class EventController {
  final EventsDB eventsDB;

  EventController({required this.eventsDB});

  Future<AddEventResult> addEvent({
    required String uid,
    required String eventName,
    required DateTime eventDate,
  }) async {
    if (eventName.isEmpty) {
      return AddEventResult.emptyName;
    }
    if (eventDate.isBefore(DateTime.now())) {
      return AddEventResult.pastDate;
    }

    final String eventId;
    try {
      final doc = await eventsDB.addEvent(
        uid: uid,
        eventName: eventName,
        eventDate: eventDate,
      );
      eventId = doc.id;
    } catch (e) {
      return AddEventResult.error;
    }

    return _scheduleReminder(
      eventId: eventId,
      eventName: eventName,
      eventDate: eventDate,
    );
  }

  Future<AddEventResult> updateEvent({
    required String eventId,
    required String eventName,
    required DateTime eventDate,
  }) async {
    if (eventName.isEmpty) {
      return AddEventResult.emptyName;
    }
    if (eventDate.isBefore(DateTime.now())) {
      return AddEventResult.pastDate;
    }

    try {
      await eventsDB.updateEvent(eventId: eventId, eventName: eventName, eventDate: eventDate);
    } catch (e) {
      return AddEventResult.error;
    }

    return _scheduleReminder(
      eventId: eventId,
      eventName: eventName,
      eventDate: eventDate,
    );
  }

  /// Retorna `false` se o evento foi excluído mas o lembrete não pôde ser cancelado.
  Future<bool> deleteEvent(String eventId, {required String eventName}) async {
    await eventsDB.deleteEvent(eventId);
    return ReminderFeedback.cancel(
      type: 'event',
      entityId: eventId,
      label: eventName,
    );
  }

  Future<AddEventResult> _scheduleReminder({
    required String eventId,
    required String eventName,
    required DateTime eventDate,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool('notif_pref_events') ?? true)) {
      return AddEventResult.success;
    }

    final scheduled = await ReminderFeedback.schedule(
      type: 'event',
      entityId: eventId,
      title: 'Evento',
      body: eventName,
      remindAt: eventDate,
      label: eventName,
    );
    return scheduled ? AddEventResult.success : AddEventResult.savedWithoutReminder;
  }
}
