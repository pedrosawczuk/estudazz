import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:estudazz_main_code/components/custom/customSnackBar.dart';
import 'package:estudazz_main_code/constants/color/constColors.dart';
import 'package:estudazz_main_code/constants/constSizedBox.dart';
import 'package:estudazz_main_code/routes/appRoutes.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

void showDeleteAccountDialog(BuildContext context) {
  final TextEditingController emailController = TextEditingController();
  final currentUser = FirebaseAuth.instance.currentUser;

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text("Confirmar Exclusão"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text.rich(
              TextSpan(
                text:
                    "Digite seu e-mail para confirmar a exclusão da conta:\n\n",
                children: [
                  TextSpan(
                    text: "${currentUser?.email ?? '[email não disponível]'}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: ConstColors.redColor,
                    ),
                  ),
                ],
                style: const TextStyle(fontSize: 16),
              ),
            ),
            ConstSizedBox.h12,
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: "E-mail",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text("Cancelar"),
            onPressed: () => Get.back(),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor:ConstColors.redColor,
              foregroundColor: ConstColors.whiteColor,
            ),
            child: const Text("Excluir"),
            onPressed: () async {
              if (emailController.text.trim() == currentUser?.email) {
                try {
                  final uid = currentUser!.uid;

                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(uid)
                      .delete();

                  await currentUser.delete();

                  FocusManager.instance.primaryFocus?.unfocus();
                  Get.back();

                  CustomSnackBar.show(
                    title: "Conta excluída com sucesso!",
                    message: "Sua conta foi excluída.",
                    backgroundColor: ConstColors.greenColor,
                  );

                  Get.offAllNamed(AppRoutes.signInPage);
                } catch (e) {
                  FocusManager.instance.primaryFocus?.unfocus();
                  Get.back();
                  CustomSnackBar.show(
                    title: "Erro ao excluir conta",
                    message: "Ocorreu um erro ao tentar excluir sua conta.",
                    backgroundColor: ConstColors.redColor,
                  );
                }
              } else {
                CustomSnackBar.show(
                  title: "E-mail incorreto",
                  message: "O e-mail digitado não corresponde ao e-mail da conta.",
                  backgroundColor:ConstColors.redColor,
                );
              }
            },
          ),
        ],
      );
    },
  );
}
