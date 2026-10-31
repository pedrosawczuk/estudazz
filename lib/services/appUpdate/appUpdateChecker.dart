import 'package:estudazz_main_code/components/custom/customSnackBar.dart';
import 'package:estudazz_main_code/constants/color/constColors.dart';
import 'package:flutter/foundation.dart';
import 'package:in_app_update/in_app_update.dart';

enum AppUpdateAction { none, startFlexible, startImmediate, promptRestart }

/// Decide o que fazer com a resposta da Play Store.
/// Preferimos a atualização flexível: baixa em segundo plano sem travar o app.
AppUpdateAction decideAppUpdateAction(AppUpdateInfo info) {
  if (info.installStatus == InstallStatus.downloaded) {
    return AppUpdateAction.promptRestart;
  }
  if (info.updateAvailability != UpdateAvailability.updateAvailable) {
    return AppUpdateAction.none;
  }
  if (info.flexibleUpdateAllowed) return AppUpdateAction.startFlexible;
  if (info.immediateUpdateAllowed) return AppUpdateAction.startImmediate;
  return AppUpdateAction.none;
}

/// Avisa dentro do app quando há versão nova na Play Store.
/// Só funciona em builds de release instalados pela Play Store (Android).
class AppUpdateChecker {
  AppUpdateChecker._();

  static bool _checked = false;

  /// Verifica uma vez por execução do app.
  static Future<void> checkOnce() async {
    if (_checked || kIsWeb || !kReleaseMode) return;
    if (defaultTargetPlatform != TargetPlatform.android) return;
    _checked = true;

    try {
      final info = await InAppUpdate.checkForUpdate();
      switch (decideAppUpdateAction(info)) {
        case AppUpdateAction.none:
          return;
        case AppUpdateAction.promptRestart:
          _showRestartPrompt();
        case AppUpdateAction.startFlexible:
          // A Play Store mostra o aviso; o Future termina quando o download acaba
          final result = await InAppUpdate.startFlexibleUpdate();
          if (result == AppUpdateResult.success) _showRestartPrompt();
        case AppUpdateAction.startImmediate:
          await InAppUpdate.performImmediateUpdate();
      }
    } catch (e) {
      // Ex.: app instalado fora da Play Store; não é erro para o usuário
      debugPrint('Verificação de atualização indisponível: $e');
    }
  }

  static void _showRestartPrompt() {
    CustomSnackBar.show(
      title: 'Atualização pronta',
      message: 'A nova versão do Estudazz foi baixada.',
      backgroundColor: ConstColors.greenColor,
      duration: const Duration(seconds: 15),
      actionLabel: 'Reiniciar',
      onAction: () {
        InAppUpdate.completeFlexibleUpdate().catchError((e) {
          debugPrint('Falha ao instalar atualização: $e');
        });
      },
    );
  }
}
