import 'package:estudazz_main_code/services/notificationsApi/notificationsApiService.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Vincula/desvincula o aparelho ao usuário no OneSignal usando um identificador
/// opaco emitido pelo backend autenticado, e mantém a tag `updates` alinhada.
class OneSignalSession {
  static const String updatesPrefKey = 'notif_pref_updates';
  static const String _updatesTagKey = 'updates';

  static Future<void> login(String uid) async {
    try {
      final currentUid = FirebaseAuth.instance.currentUser?.uid;
      if (currentUid == null || currentUid != uid) {
        return;
      }
      final externalId =
          await NotificationsApiService().fetchOneSignalExternalId();
      await OneSignal.login(externalId);
      await syncUpdatesTag();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Erro ao vincular usuário no OneSignal: $e');
      }
    }
  }

  static Future<void> logout() async {
    try {
      await OneSignal.logout();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Erro ao desvincular usuário no OneSignal: $e');
      }
    }
  }

  static Future<void> syncUpdatesTag() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(updatesPrefKey) ?? true;
    await OneSignal.User.addTagWithKey(
      _updatesTagKey,
      enabled ? 'true' : 'false',
    );
  }
}
