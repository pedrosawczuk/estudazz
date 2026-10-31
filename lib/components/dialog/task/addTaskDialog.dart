import 'package:estudazz_main_code/components/custom/customSnackBar.dart';
import 'package:estudazz_main_code/components/custom/loadingButton.dart';
import 'package:estudazz_main_code/constants/color/constColors.dart';
import 'package:estudazz_main_code/constants/constSizedBox.dart';
import 'package:estudazz_main_code/controllers/tasks/taskController.dart';
import 'package:flutter/material.dart';

class AddTaskDialog {
  final TextEditingController _taskNameController = TextEditingController();
  DateTime? _selectedDate;

  Future<void> showAddTaskDialog({
    required BuildContext context,
    required TaskController taskController,
    required Future<String?> Function() getUserUid,
  }) async {
    DateTime? tempSelectedDate = _selectedDate;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            String formatDate(DateTime? date) {
              if (date == null) return 'Nenhuma data selecionada';
              return '📅 ${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
            }

            return AlertDialog(
              title: const Text("Adicionar Tarefa"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _taskNameController,
                    decoration: const InputDecoration(labelText: 'Nome da Tarefa'),
                  ),
                  ConstSizedBox.h10,
                  Row(
                    children: [
                      Expanded(child: Text(formatDate(tempSelectedDate))),
                      TextButton(
                        onPressed: () async {
                          DateTime today = DateTime.now();
                          DateTime onlyDate = DateTime(
                            today.year,
                            today.month,
                            today.day,
                          );

                          DateTime? pickedDate = await showDatePicker(
                            locale: const Locale('pt', 'BR'),
                            context: context,
                            initialDate: onlyDate,
                            firstDate: onlyDate,
                            lastDate: DateTime(2100),
                          );

                          if (pickedDate != null) {
                            setStateDialog(() {
                              tempSelectedDate = pickedDate;
                            });
                          }
                        },
                        child: const Text('Selecionar Data'),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  child: const Text("Cancelar"),
                  onPressed: () {
                      Navigator.of(context).pop();
                  },
                ),
                LoadingButton(
                  child: const Text("Salvar"),
                  onPressed: () async {
                    String? uid = await getUserUid();
                    if (uid == null) {
                      CustomSnackBar.show(
                        title: 'Erro!',
                        message: 'Usuário não autenticado.',
                        backgroundColor: ConstColors.redColor,
                      );
                      return;
                    }
                    if (tempSelectedDate == null) {
                       CustomSnackBar.show(
                        title: 'Erro!',
                        message: 'Selecione uma data de vencimento.',
                        backgroundColor: ConstColors.redColor,
                      );
                      return;
                    }

                    final result = await taskController.addTask(
                      uid: uid,
                      taskName: _taskNameController.text,
                      dueDate: tempSelectedDate!,
                    );

                    if (result == AddTaskResult.success ||
                        result == AddTaskResult.savedWithoutReminder) {
                      _taskNameController.clear();
                      _selectedDate = null;
                      Navigator.of(context).pop();
                      // Sem lembrete o aviso com "Tentar de novo" já foi exibido
                      if (result == AddTaskResult.success) {
                        CustomSnackBar.show(
                          title: 'Tarefa adicionada',
                          message: 'A tarefa foi adicionada com sucesso.',
                          backgroundColor: ConstColors.greenColor,
                        );
                      }
                    } else if (result == AddTaskResult.emptyName) {
                      CustomSnackBar.show(
                        title: 'Erro!',
                        message: 'O nome da tarefa não pode ser vazio.',
                        backgroundColor: ConstColors.redColor,
                      );
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }
}
