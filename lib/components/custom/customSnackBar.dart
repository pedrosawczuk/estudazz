import 'package:estudazz_main_code/constants/color/constColors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CustomSnackBar {
  static void show({
    required String title,
    required String message,
    required Color backgroundColor,
    Color textColor = ConstColors.whiteColor,
    SnackPosition snackPosition = SnackPosition.BOTTOM,
    Duration duration = const Duration(seconds: 3),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    if (Get.context == null && Get.overlayContext == null) return;
    try {
      Get.snackbar(
      title,
      message,
      backgroundColor: backgroundColor,
      colorText: textColor,
      snackPosition: snackPosition,
      duration: duration,
      margin: const EdgeInsets.all(10),
      borderRadius: 8,
      mainButton: actionLabel != null && onAction != null
          ? TextButton(
              onPressed: () {
                Get.closeCurrentSnackbar();
                onAction();
              },
              child: Text(
                actionLabel,
                style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
              ),
            )
          : null,
    );
    } catch (_) {}
  }
}