import 'package:estudazz_main_code/constants/color/constColors.dart';
import 'package:estudazz_main_code/constants/constSizedBox.dart';
import 'package:flutter/material.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationPermissionDialog {
  static Future<void> _markPromptAsSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenNotificationPermissionPrompt', true);
  }

  static Future<void> showNotificationPermissionDialog({
    required BuildContext context,
  }) async {
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
                Icons.notifications_active,
                color: ConstColors.orangeColor,
                size: 60,
              ),
              ConstSizedBox.h10,
              Text(
                "Ative as Notificações",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: ConstColors.whiteColor,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          content: const Text(
            "Não perca prazos importantes! Ative as notificações para receber "
            "lembretes das suas tarefas, avisos de eventos do calendário e "
            "atualizações da sua sala de estudos.",
            textAlign: TextAlign.center,
            style: TextStyle(color: ConstColors.white54Color),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () async {
                await _markPromptAsSeen();
                if (context.mounted) Navigator.of(context).pop();
              },
              child: const Text(
                "Agora não",
                style: TextStyle(color: ConstColors.greyColor),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: ConstColors.orangeColor,
                foregroundColor: ConstColors.whiteColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onPressed: () async {
                OneSignal.Notifications.requestPermission(true);
                await _markPromptAsSeen();
                if (context.mounted) Navigator.of(context).pop();
              },
              child: const Text("Ativar Notificações"),
            ),
          ],
        );
      },
    );
  }
}
