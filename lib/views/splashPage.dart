import 'package:estudazz_main_code/routes/appRoutes.dart';
import 'package:estudazz_main_code/services/ia/iaChatStorageService.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:estudazz_main_code/services/notificationsApi/oneSignalSession.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    final prefs = await SharedPreferences.getInstance();
    final lastActivity = prefs.getInt('lastActivity');
    final now = DateTime.now().millisecondsSinceEpoch;

    if (lastActivity != null) {
      final thirtyDaysInMillis = 30 * 24 * 60 * 60 * 1000;
      if (now - lastActivity > thirtyDaysInMillis) {
        final currentUid = FirebaseAuth.instance.currentUser?.uid;
        await IaChatStorageService.clearMessages(uid: currentUid);
        await FirebaseAuth.instance.signOut();
        await OneSignalSession.logout();
        await prefs.clear();
        Get.offAllNamed(AppRoutes.signInPage);
        return;
      }
    }

    await prefs.setInt('lastActivity', now);

    FirebaseAuth.instance.authStateChanges().first.then((user) async {
      if (user != null) {
        await OneSignalSession.login(user.uid);
        Get.offAllNamed(AppRoutes.homePage);
      } else {
        Get.offAllNamed(AppRoutes.signInPage);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
