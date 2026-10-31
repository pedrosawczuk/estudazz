import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:estudazz_main_code/services/db/tasks/tasksDB.dart';
import 'package:estudazz_main_code/services/notificationsApi/reminderFeedback.dart';
import 'package:estudazz_main_code/components/custom/customSnackBar.dart';
import 'package:estudazz_main_code/constants/color/constColors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

/// `savedWithoutReminder`: a tarefa foi salva, mas o lembrete falhou (o usuário já foi avisado).
enum AddTaskResult {
  success,
  savedWithoutReminder,
  emptyName,
  pastDueDate,
  error,
}

class TaskController {
  final TasksDB tasksDB;

  TaskController({required this.tasksDB});

  Future<AddTaskResult> addTask({
    required String uid,
    required String taskName,
    required DateTime dueDate,
  }) async {
    if (taskName.isEmpty) {
      return AddTaskResult.emptyName;
    }

    String dueDateString = dueDate.toIso8601String();

    try {
      final doc = await tasksDB.addTask(
        uid: uid,
        taskName: taskName,
        dueDate: dueDateString,
      );

      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool('notif_pref_tasks') ?? true) {
        final scheduled = await ReminderFeedback.schedule(
          type: 'task',
          entityId: doc.id,
          title: 'Tarefa pendente',
          body: taskName,
          remindAt: dueDate,
          label: taskName,
        );
        if (!scheduled) return AddTaskResult.savedWithoutReminder;
      }

      return AddTaskResult.success;
    } catch (e) {
      CustomSnackBar.show(
        title: 'Servidor Ocupado',
        message:
            'A solicitação demorou muito. Verifique sua rede e tente novamente.',
        backgroundColor: ConstColors.redColor,
      );
      return AddTaskResult.error;
    }
  }

  Future<void> setTaskCompletion({
    required String taskId,
    required bool completed,
  }) {
    return tasksDB.setTaskCompletion(taskId: taskId, completed: completed);
  }

  /// Retorna `false` se o lembrete não pôde ser cancelado (o usuário já foi avisado).
  Future<bool> cancelReminder({
    required String taskId,
    required String taskName,
  }) {
    return ReminderFeedback.cancel(
      type: 'task',
      entityId: taskId,
      label: taskName,
    );
  }

  /// Reagenda o lembrete de uma tarefa reaberta, se o prazo ainda não passou.
  /// Retorna `false` se o agendamento falhou (o usuário já foi avisado).
  Future<bool> rescheduleReminder({
    required String taskId,
    required String taskName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool('notif_pref_tasks') ?? true)) return true;

    final taskSnapshot = await tasksDB.getTask(taskId);
    final data = taskSnapshot.data() as Map<String, dynamic>?;
    final dueDate = DateTime.tryParse(data?['due_date'] ?? '');
    if (dueDate == null || dueDate.isBefore(DateTime.now())) return true;

    return ReminderFeedback.schedule(
      type: 'task',
      entityId: taskId,
      title: 'Tarefa pendente',
      body: taskName,
      remindAt: dueDate,
      label: taskName,
    );
  }

  Future<bool> isTaskCompleted(String taskId) async {
    DocumentSnapshot taskSnapshot = await tasksDB.getTask(taskId);
    return taskSnapshot['task_completed'] ?? false;
  }
}
