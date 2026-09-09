import 'package:estudazz_main_code/controllers/homePageController.dart';
import 'package:estudazz_main_code/routes/appRoutes.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

void checkProfileCompletion(
  HomePageController controller,
  BuildContext context,
) {
  ever(controller.profileCompleted, (bool isCompleted) {
    if (!isCompleted) {
      _showIncompleteProfileDialog(context);
    }
  });
}

void _showIncompleteProfileDialog(BuildContext context) {
  showDialog(
    context: context,
    builder:
        (context) => AlertDialog(
          title: const Text(
            "Falta Pouco!",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text(
            "Adicione algumas informações que serão úteis para sua experiência ser completa!",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Mais Tarde"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Get.toNamed(AppRoutes.myDataPage);
              },
              child: const Text("Editar Perfil"),
            ),
          ],
        ),
  );
}
