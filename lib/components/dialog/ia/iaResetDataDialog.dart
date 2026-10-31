import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:estudazz_main_code/components/custom/loadingButton.dart';
import 'package:estudazz_main_code/components/custom/customSnackBar.dart';
import 'package:estudazz_main_code/constants/color/constColors.dart';
import 'package:estudazz_main_code/utils/user/getUserData.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class IAResetConfirmationDialog extends StatelessWidget {
  const IAResetConfirmationDialog({super.key});

  Future<void> _deleteIAData(BuildContext context) async {
    final uid = await GetUserData.getUserUid();
    if (uid == null) return;

    try {
      await FirebaseFirestore.instance.collection('ia-data').doc(uid).delete();
    } catch (e) {
      CustomSnackBar.show(
        title: 'Erro!',
        message: 'Não foi possível resetar os dados. Verifique sua conexão.',
        backgroundColor: ConstColors.redColor,
      );
      return;
    }

    if (!context.mounted) return;
    Navigator.of(context).pop();
    CustomSnackBar.show(
      title: 'Sucesso!',
      message: 'Dados da IA foram resetados.',
      backgroundColor: ConstColors.greenColor,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Redefinir dados da IA'),
      content: const Text(
        'Tem certeza que deseja apagar os dados personalizados da IA?',
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          child: const Text('Cancelar'),
        ),
        LoadingButton(
          onPressed: () => _deleteIAData(context),
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
