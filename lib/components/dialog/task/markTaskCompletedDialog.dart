import 'package:estudazz_main_code/components/custom/customSnackBar.dart';
import 'package:estudazz_main_code/constants/color/constColors.dart';
import 'package:estudazz_main_code/constants/constSizedBox.dart';
import 'package:estudazz_main_code/controllers/tasks/taskController.dart';
import 'package:estudazz_main_code/services/db/tasks/tasksDB.dart';
import 'package:estudazz_main_code/services/notificationsApi/notificationsApiService.dart';
import 'package:flutter/material.dart';

class MarkTaskCompletedDialog {
  final TaskController _taskController = TaskController(tasksDB: TasksDB());
  final NotificationsApiService _notificationsApiService =
      NotificationsApiService();

  Future<void> showMarkTaskCompletedDialog({
    required BuildContext context,
    required String taskId,
    required String taskName,
  }) async {
    bool isTaskCompleted = await _taskController.isTaskCompleted(taskId);
    if (isTaskCompleted) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: ConstColors.grey900Color,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            title: const Column(
              children: [
                Icon(
                  Icons.check_circle,
                  color: ConstColors.greenColor,
                  size: 60,
                ),
                ConstSizedBox.h10,
                Text(
                  "Tarefa Concluída",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: ConstColors.whiteColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            content: Text(
              "A tarefa '$taskName' já está concluída.\nDeseja desmarcá-la e voltar para pendentes?",
              textAlign: TextAlign.center,
              style: const TextStyle(color: ConstColors.white54Color),
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  "Fechar",
                  style: TextStyle(color: ConstColors.greyColor),
                ),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: ConstColors.orangeColor,
                  foregroundColor: ConstColors.whiteColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onPressed: () async {
                  try {
                    await _taskController.tasksDB.updateTask(
                      taskId: taskId,
                      data: {
                        'task_completed': false,
                        'task_completed_at': null,
                      },
                    );
                    await _notificationsApiService.cancelReminder(
                      type: 'task',
                      entityId: taskId,
                    );
                    CustomSnackBar.show(
                      title: 'Tarefa Desmarcada',
                      message: 'A tarefa "$taskName" foi desmarcada com sucesso.',
                      backgroundColor: ConstColors.greenColor,
                    );
                  } catch (e) {
                    CustomSnackBar.show(
                      title: 'Erro!',
                      message: 'Erro ao desmarcar tarefa: $e',
                      backgroundColor: ConstColors.redColor,
                    );
                  }
                  Navigator.of(context).pop();
                },
                icon: const Icon(Icons.undo),
                label: const Text('Desmarcar'),
              ),
            ],
          );
        },
      );
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: ConstColors.grey900Color,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            title: const Column(
              children: [
                Icon(Icons.task_alt, color: ConstColors.orangeColor, size: 60),
                ConstSizedBox.h10,
                Text(
                  "Ações da Tarefa",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: ConstColors.whiteColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "O que deseja fazer com a tarefa '$taskName'?",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: ConstColors.whiteColor,
                    fontSize: 16,
                  ),
                ),
                ConstSizedBox.h24,
                ElevatedButton.icon(
                  onPressed: () async {
                    try {
                      await _taskController.tasksDB.updateTask(
                        taskId: taskId,
                        data: {
                          'task_completed': true,
                          'task_completed_at': DateTime.now().toIso8601String(),
                        },
                      );
                      await _notificationsApiService.cancelReminder(
                        type: 'task',
                        entityId: taskId,
                      );
                      CustomSnackBar.show(
                        title: 'Parabéns!',
                        message: 'Tarefa marcada como concluída.',
                        backgroundColor: ConstColors.greenColor,
                      );
                    } catch (e) {
                      CustomSnackBar.show(
                        title: 'Erro!',
                        message: 'Falha ao concluir: $e',
                        backgroundColor: ConstColors.redColor,
                      );
                    }
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.check_circle_outline, size: 24),
                  label: const Text(
                    'Marcar como Concluída',
                    style: TextStyle(fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ConstColors.greenColor,
                    foregroundColor: ConstColors.whiteColor,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                ConstSizedBox.h16,
                OutlinedButton.icon(
                  onPressed: () async {
                    try {
                      await _taskController.tasksDB.deleteTask(taskId);
                      await _notificationsApiService.cancelReminder(
                        type: 'task',
                        entityId: taskId,
                      );
                      CustomSnackBar.show(
                        title: 'Tarefa Excluída',
                        message: 'A tarefa "$taskName" foi excluída.',
                        backgroundColor: ConstColors.greenColor,
                      );
                    } catch (e) {
                      CustomSnackBar.show(
                        title: 'Erro!',
                        message: 'Falha ao excluir: $e',
                        backgroundColor: ConstColors.redColor,
                      );
                    }
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.delete_outline, size: 24),
                  label: const Text(
                    'Excluir Tarefa',
                    style: TextStyle(fontSize: 16),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ConstColors.redColor,
                    side: const BorderSide(color: ConstColors.redColor),
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ],
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  "Cancelar",
                  style: TextStyle(color: ConstColors.grey400Color),
                ),
              ),
            ],
          );
        },
      );
    }
  }
}
