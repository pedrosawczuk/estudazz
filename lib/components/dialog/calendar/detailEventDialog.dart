import 'package:estudazz_main_code/components/custom/customSnackBar.dart';
import 'package:estudazz_main_code/components/custom/loadingButton.dart';
import 'package:estudazz_main_code/constants/color/constColors.dart';
import 'package:estudazz_main_code/constants/constSizedBox.dart';
import 'package:estudazz_main_code/controllers/calendar/eventController.dart';
import 'package:estudazz_main_code/services/db/calendar/eventsDB.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:estudazz_main_code/components/dialog/calendar/editEventDialog.dart';

class DetailEventDialog {
  final EventController _eventController = EventController(
    eventsDB: EventsDB(),
  );

  void showDetailEventDialog({
    required BuildContext context,
    required String eventName,
    required DateTime eventDate,
    required String eventId,
  }) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: ConstColors.grey900Color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            DateFormat('dd/MM/yyyy').format(eventDate),
            style: const TextStyle(
              color: ConstColors.orangeColor,
              fontWeight: FontWeight.w900,
              fontSize: 20,
            ),
          ),
          content: Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  eventName,
                  style: const TextStyle(
                    color: ConstColors.whiteColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                ConstSizedBox.h12,
                Text(
                  DateFormat('HH:mm').format(eventDate),
                  style: const TextStyle(
                    color: ConstColors.white54Color,
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            IconButton(
              onPressed: () {
                Navigator.of(context).pop();
                EditEventDialog().showEditEventDialog(
                  context: context,
                  eventId: eventId,
                  eventName: eventName,
                  eventDate: eventDate,
                );
              },
              icon: const Icon(Icons.edit, color: ConstColors.whiteColor),
            ),
            LoadingButton.icon(
              onPressed: () async {
                final bool reminderCanceled;
                try {
                  reminderCanceled = await _eventController.deleteEvent(
                    eventId,
                    eventName: eventName,
                  );
                } catch (e) {
                  CustomSnackBar.show(
                    title: 'Erro!',
                    message: 'Não foi possível excluir o evento. Verifique sua conexão.',
                    backgroundColor: ConstColors.redColor,
                  );
                  return;
                }
                if (!context.mounted) return;
                Navigator.of(context).pop();
                // Se o lembrete não foi cancelado o aviso com "Tentar de novo" já foi exibido
                if (reminderCanceled) {
                  CustomSnackBar.show(
                    title: 'Sucesso!',
                    message: 'Evento "$eventName" excluído com sucesso!',
                    backgroundColor: ConstColors.greenColor,
                  );
                }
              },
              icon: const Icon(Icons.delete_forever, color: ConstColors.whiteColor),
            ),
            ElevatedButton(
              onPressed: () => Get.back(),
              child: const Text('Fechar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: ConstColors.orangeColor,
                foregroundColor: ConstColors.whiteColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
