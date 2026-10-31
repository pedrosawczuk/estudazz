import 'package:estudazz_main_code/services/appUpdate/appUpdateChecker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_update/in_app_update.dart';

AppUpdateInfo info({
  UpdateAvailability availability = UpdateAvailability.updateNotAvailable,
  bool flexible = false,
  bool immediate = false,
  InstallStatus status = InstallStatus.unknown,
}) {
  return AppUpdateInfo(
    updateAvailability: availability,
    immediateUpdateAllowed: immediate,
    immediateAllowedPreconditions: null,
    flexibleUpdateAllowed: flexible,
    flexibleAllowedPreconditions: null,
    availableVersionCode: 15,
    installStatus: status,
    packageName: 'com.estudazz',
    clientVersionStalenessDays: null,
    updatePriority: 0,
  );
}

void main() {
  test('sem versão nova não faz nada', () {
    expect(decideAppUpdateAction(info()), AppUpdateAction.none);
  });

  test('versão nova com atualização flexível baixa em segundo plano', () {
    expect(
      decideAppUpdateAction(
        info(
          availability: UpdateAvailability.updateAvailable,
          flexible: true,
          immediate: true,
        ),
      ),
      AppUpdateAction.startFlexible,
    );
  });

  test('só imediata permitida usa a atualização imediata', () {
    expect(
      decideAppUpdateAction(
        info(availability: UpdateAvailability.updateAvailable, immediate: true),
      ),
      AppUpdateAction.startImmediate,
    );
  });

  test('versão nova sem nenhum tipo permitido não faz nada', () {
    expect(
      decideAppUpdateAction(info(availability: UpdateAvailability.updateAvailable)),
      AppUpdateAction.none,
    );
  });

  test('download já concluído em outra abertura oferece reiniciar', () {
    expect(
      decideAppUpdateAction(info(status: InstallStatus.downloaded)),
      AppUpdateAction.promptRestart,
    );
  });
}
