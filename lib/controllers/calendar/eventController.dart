import 'package:estudazz_main_code/services/db/calendar/eventsDB.dart';
import 'package:estudazz_main_code/services/notificationsApi/notificationsApiService.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AddEventResult { success, emptyName, pastDate }

class EventController {
  final EventsDB eventsDB;
  final NotificationsApiService _notificationsApiService =
      NotificationsApiService();

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

    final doc = await eventsDB.addEvent(
      uid: uid,
      eventName: eventName,
      eventDate: eventDate,
    );

    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('notif_pref_events') ?? true) {
      await _notificationsApiService.scheduleReminder(
        type: 'event',
        entityId: doc.id,
        title: 'Evento',
        body: eventName,
        remindAt: eventDate,
      );
    }

    return AddEventResult.success;
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

    await eventsDB.updateEvent(eventId: eventId, eventName: eventName, eventDate: eventDate);

    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('notif_pref_events') ?? true) {
      await _notificationsApiService.scheduleReminder(
        type: 'event',
        entityId: eventId,
        title: 'Evento',
        body: eventName,
        remindAt: eventDate,
      );
    }

    return AddEventResult.success;
  }

  Future<void> deleteEvent(String eventId) async {
    await eventsDB.deleteEvent(eventId);
    await _notificationsApiService.cancelReminder(
      type: 'event',
      entityId: eventId,
    );
  }
}