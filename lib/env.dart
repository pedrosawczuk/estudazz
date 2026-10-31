import 'package:envied/envied.dart';

part 'env.g.dart';

@Envied(path: '.env')
abstract class Env {
  @EnviedField(varName: 'IA_CHAT_STORAGE_KEY')
  static const String iaChatStorageKey = _Env.iaChatStorageKey;

  @EnviedField(varName: 'APP_ID_ONESIGNAL_KEY')
  static const String appIdOnesignalKey = _Env.appIdOnesignalKey;

  @EnviedField(varName: 'NOTIFICATIONS_API_BASE_URL')
  static const String notificationsApiBaseUrl = _Env.notificationsApiBaseUrl;
}
