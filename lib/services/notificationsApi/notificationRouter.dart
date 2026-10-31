import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:estudazz_main_code/components/custom/customSnackBar.dart';
import 'package:estudazz_main_code/components/dialog/calendar/detailEventDialog.dart';
import 'package:estudazz_main_code/components/dialog/task/markTaskCompletedDialog.dart';
import 'package:estudazz_main_code/constants/color/constColors.dart';
import 'package:estudazz_main_code/models/studyRoom/studyRoomModel.dart';
import 'package:estudazz_main_code/routes/appRoutes.dart';
import 'package:estudazz_main_code/services/db/calendar/eventsDB.dart';
import 'package:estudazz_main_code/services/db/tasks/tasksDB.dart';
import 'package:estudazz_main_code/services/notificationsApi/notificationLink.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

/// Abre a tarefa, o evento ou a sala quando o usuário toca numa notificação.
///
/// O toque pode chegar com o app fechado, antes da splash terminar; por isso o
/// destino fica pendente até a Home avisar que está pronta (`markReady`).
class NotificationRouter {
  NotificationRouter._();

  static NotificationLink? _pending;
  // Contador (e não bool): ao trocar uma Home por outra, a antiga pode ser
  // descartada depois que a nova já avisou que está pronta
  static int _readyHomes = 0;
  static Future<void> Function(NotificationLink link) _open = _openLink;

  static void init() {
    OneSignal.Notifications.addClickListener(
      (event) => handleTap(event.notification.additionalData),
    );
  }

  static void handleTap(Map<String, dynamic>? data) {
    final link = NotificationLink.fromData(data);
    if (link == null) return;
    _pending = link;
    _flush();
  }

  /// Chamado pela Home: a partir daqui é seguro navegar.
  static void markReady() {
    _readyHomes++;
    _flush();
  }

  /// Chamado quando a Home sai da pilha (ex.: logout).
  static void markNotReady() {
    if (_readyHomes > 0) _readyHomes--;
  }

  static void _flush() {
    if (_readyHomes == 0) return;
    final link = _pending;
    _pending = null;
    if (link != null) _open(link);
  }

  @visibleForTesting
  static void debugReset({Future<void> Function(NotificationLink link)? open}) {
    _pending = null;
    _readyHomes = 0;
    _open = open ?? _openLink;
  }

  static Future<void> _openLink(NotificationLink link) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      switch (link) {
        case TaskLink(:final taskId):
          await _openTask(taskId, uid);
        case EventLink(:final eventId):
          await _openEvent(eventId, uid);
        case StudyRoomLink(:final roomId):
          await _openStudyRoom(roomId, uid);
      }
    } catch (e) {
      debugPrint('Erro ao abrir notificação: $e');
      CustomSnackBar.show(
        title: 'Não foi possível abrir',
        message: 'Verifique sua conexão e tente novamente.',
        backgroundColor: ConstColors.redColor,
      );
    }
  }

  static Future<void> _openTask(String taskId, String uid) async {
    final snapshot = await TasksDB().getTask(taskId);
    final data = snapshot.data() as Map<String, dynamic>?;
    if (!snapshot.exists || data == null || data['uid'] != uid) {
      _showNotFound('Essa tarefa não existe mais.');
      return;
    }

    await _goTo(AppRoutes.allTasksPage);
    final context = Get.context;
    if (context == null) return;
    await MarkTaskCompletedDialog().showMarkTaskCompletedDialog(
      context: context,
      taskId: taskId,
      taskName: data['task_name'] ?? '',
    );
  }

  static Future<void> _openEvent(String eventId, String uid) async {
    final snapshot = await EventsDB().getEvents(eventId);
    final data = snapshot.data() as Map<String, dynamic>?;
    final eventDate = DateTime.tryParse(data?['event_date'] ?? '');
    if (!snapshot.exists || data == null || data['uid'] != uid || eventDate == null) {
      _showNotFound('Esse evento não existe mais.');
      return;
    }

    await _goTo(AppRoutes.calendarPage);
    final context = Get.context;
    if (context == null) return;
    DetailEventDialog().showDetailEventDialog(
      context: context,
      eventId: eventId,
      eventName: data['event_name'] ?? '',
      eventDate: eventDate,
    );
  }

  static Future<void> _openStudyRoom(String roomId, String uid) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('study_rooms')
        .doc(roomId)
        .get();
    if (!snapshot.exists) {
      _showNotFound('Essa sala não existe mais.');
      return;
    }

    final room = StudyRoomModel.fromFirestore(snapshot);
    if (!room.members.contains(uid)) {
      _showNotFound('Você não participa mais dessa sala.');
      return;
    }

    Get.toNamed(AppRoutes.studyRoomDetailsPage, arguments: room);
  }

  // Abre a tela de destino (sem empilhar de novo se já estiver nela) e espera
  // o frame para o diálogo abrir por cima dela
  static Future<void> _goTo(String route) async {
    if (Get.currentRoute != route) {
      Get.toNamed(route);
      await WidgetsBinding.instance.endOfFrame;
    }
  }

  static void _showNotFound(String message) {
    CustomSnackBar.show(
      title: 'Notificação',
      message: message,
      backgroundColor: ConstColors.orangeColor,
    );
  }
}
