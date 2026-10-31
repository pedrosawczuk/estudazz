import 'package:estudazz_main_code/components/custom/customSnackBar.dart';
import 'package:estudazz_main_code/constants/color/constColors.dart';
import 'package:estudazz_main_code/services/notificationsApi/notificationsApiService.dart';

/// Agenda/cancela lembretes avisando o usuário quando a API falha,
/// com opção de tentar de novo. Retorna `true` quando deu certo.
class ReminderFeedback {
  static final NotificationsApiService _api = NotificationsApiService();
  static const Duration _warningDuration = Duration(seconds: 8);

  static Future<bool> schedule({
    required String type,
    required String entityId,
    required String title,
    required String body,
    required DateTime remindAt,
    required String label,
  }) async {
    try {
      await _api.scheduleReminder(
        type: type,
        entityId: entityId,
        title: title,
        body: body,
        remindAt: remindAt,
      );
      return true;
    } on NotificationsApiException catch (e) {
      CustomSnackBar.show(
        title: 'Lembrete não agendado',
        message: '"$label" foi salvo, mas o lembrete não foi agendado. ${e.message}',
        backgroundColor: ConstColors.redColor,
        duration: _warningDuration,
        actionLabel: 'Tentar de novo',
        onAction: () => schedule(
          type: type,
          entityId: entityId,
          title: title,
          body: body,
          remindAt: remindAt,
          label: label,
        ),
      );
      return false;
    }
  }

  static Future<bool> cancel({
    required String type,
    required String entityId,
    required String label,
  }) async {
    try {
      await _api.cancelReminder(type: type, entityId: entityId);
      return true;
    } on NotificationsApiException catch (e) {
      CustomSnackBar.show(
        title: 'Lembrete não cancelado',
        message: 'O lembrete de "$label" ainda pode ser enviado. ${e.message}',
        backgroundColor: ConstColors.redColor,
        duration: _warningDuration,
        actionLabel: 'Tentar de novo',
        onAction: () => cancel(type: type, entityId: entityId, label: label),
      );
      return false;
    }
  }
}
