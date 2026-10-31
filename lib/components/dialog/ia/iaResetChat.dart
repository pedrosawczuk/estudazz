import 'package:estudazz_main_code/constants/color/constColors.dart';
import 'package:estudazz_main_code/components/custom/loadingButton.dart';
import 'package:flutter/material.dart';
import 'package:estudazz_main_code/services/ia/iaChatStorageService.dart';
import 'package:estudazz_main_code/components/custom/customSnackBar.dart';
import 'package:estudazz_main_code/routes/appRoutes.dart';
import 'package:get/get.dart';

class IAResetChat extends StatelessWidget {
  const IAResetChat({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Resetar conversa da IA'),
      content: const Text(
        'Tem certeza que deseja apagar todas as mensagens da conversa com a IA?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        LoadingButton(
          onPressed: () async {
            await IaChatStorageService.clearMessages();
            CustomSnackBar.show(
              title: 'Limpeza concluída',
              message: 'Sua conversa com a IA foi apagada.',
              backgroundColor: ConstColors.greenColor,
            );
            Get.offAllNamed(AppRoutes.iaPage);
          },
          style: ElevatedButton.styleFrom(
            foregroundColor: ConstColors.whiteColor,
            backgroundColor: ConstColors.redColor,
          ),
          child: const Text('Confirmar'),
        ),
      ],
    );
  }
}
