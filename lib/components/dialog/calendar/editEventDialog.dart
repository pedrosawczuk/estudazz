import 'package:estudazz_main_code/components/custom/customSnackBar.dart';
import 'package:estudazz_main_code/components/custom/loadingButton.dart';
import 'package:estudazz_main_code/constants/color/constColors.dart';
import 'package:estudazz_main_code/constants/constSizedBox.dart';
import 'package:estudazz_main_code/controllers/calendar/eventController.dart';
import 'package:estudazz_main_code/services/db/calendar/eventsDB.dart';
import 'package:flutter/material.dart';

class EditEventDialog {
  final EventController _eventController = EventController(
    eventsDB: EventsDB(),
  );

  Future<void> showEditEventDialog({
    required BuildContext context,
    required String eventId,
    required String eventName,
    required DateTime eventDate,
  }) async {
    final TextEditingController _eventNameController = TextEditingController(
      text: eventName,
    );

    TimeOfDay? selectedTime = TimeOfDay(hour: eventDate.hour, minute: eventDate.minute);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text("Editar Evento"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _eventNameController,
                    decoration: const InputDecoration(labelText: 'Nome do Evento'),
                  ),
                  ConstSizedBox.h16,
                  TextButton(
                    onPressed: () async {
                      final pickedTime = await showTimePicker(
                        context: context,
                        initialTime: selectedTime ?? TimeOfDay.now(),
                      );

                      if (pickedTime != null) {
                        setStateDialog(() {
                          selectedTime = pickedTime;
                        });
                      }
                    },
                    child: Row(
                      children: [
                        selectedTime == null
                            ? const Text('Selecionar Horário')
                            : Text(
                                'Horário: ${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                LoadingButton(
                  onPressed: () async {
                    if (selectedTime == null) {
                      CustomSnackBar.show(
                        title: 'Erro!',
                        message: 'Selecione um horário para o evento.',
                        backgroundColor: ConstColors.redColor,
                      );
                      return;
                    }

                    final DateTime fullDateTime = DateTime(
                      eventDate.year,
                      eventDate.month,
                      eventDate.day,
                      selectedTime!.hour,
                      selectedTime!.minute,
                    );

                    final result = await _eventController.updateEvent(
                      eventId: eventId,
                      eventName: _eventNameController.text,
                      eventDate: fullDateTime,
                    );

                    if (result == AddEventResult.success ||
                        result == AddEventResult.savedWithoutReminder) {
                      _eventNameController.clear();
                      Navigator.of(context).pop();
                      // Sem lembrete o aviso com "Tentar de novo" já foi exibido
                      if (result == AddEventResult.success) {
                        CustomSnackBar.show(
                          title: 'Evento Atualizado',
                          message: 'O evento foi atualizado com sucesso.',
                          backgroundColor: ConstColors.greenColor,
                        );
                      }
                    } else if (result == AddEventResult.emptyName) {
                      CustomSnackBar.show(
                        title: 'Erro!',
                        message: 'O nome do evento não pode ser vazio.',
                        backgroundColor: ConstColors.redColor,
                      );
                    } else if (result == AddEventResult.pastDate) {
                      CustomSnackBar.show(
                        title: 'Erro!',
                        message: 'A hora do evento não pode ser no passado.',
                        backgroundColor: ConstColors.redColor,
                      );
                    } else if (result == AddEventResult.error) {
                      CustomSnackBar.show(
                        title: 'Erro!',
                        message: 'Não foi possível salvar o evento. Verifique sua conexão.',
                        backgroundColor: ConstColors.redColor,
                      );
                    }
                  },
                  child: const Text('Salvar Alterações'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
