import 'dart:async';

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

  static const Duration _authRestoreTimeout = Duration(seconds: 5);
  static const int _sessionMaxIdleMillis = 30 * 24 * 60 * 60 * 1000;

  Future<void> _checkSession() async {
    try {
      final destination = await _resolveDestination();
      Get.offAllNamed(destination);
    } catch (e) {
      debugPrint('Erro ao verificar sessão: $e');
      Get.offAllNamed(AppRoutes.signInPage);
    }
  }

  Future<String> _resolveDestination() async {
    final prefs = await SharedPreferences.getInstance();
    final lastActivity = prefs.getInt('lastActivity');
    final now = DateTime.now().millisecondsSinceEpoch;

    if (lastActivity != null && now - lastActivity > _sessionMaxIdleMillis) {
      final currentUid = FirebaseAuth.instance.currentUser?.uid;
      await IaChatStorageService.clearMessages(uid: currentUid);
      await FirebaseAuth.instance.signOut();
      unawaited(OneSignalSession.logout());
      await prefs.clear();
      return AppRoutes.signInPage;
    }

    await prefs.setInt('lastActivity', now);

    final user = await FirebaseAuth.instance.authStateChanges().first.timeout(
      _authRestoreTimeout,
      onTimeout: () => FirebaseAuth.instance.currentUser,
    );

    if (user == null) return AppRoutes.signInPage;

    unawaited(OneSignalSession.login(user.uid));
    return AppRoutes.homePage;
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
