import 'dart:async';

import 'package:estudazz_main_code/services/auth/saveUserLocal.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:estudazz_main_code/services/notificationsApi/oneSignalSession.dart';

class AuthServices {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createNewUser(String email, String password) async {
    try {
      final UserCredential userCredential = await _firebaseAuth
          .createUserWithEmailAndPassword(email: email, password: password);

      final user = userCredential.user!;
      unawaited(OneSignalSession.login(user.uid));

      final userRef = _firestore.collection('users').doc(user.uid);
      final batch = _firestore.batch();
      batch.set(userRef, {
        'uid': user.uid,
        'profile_completed': false,
        'created_at': FieldValue.serverTimestamp(),
      });
      batch.set(userRef.collection('private').doc('profile'), {
        'uid': user.uid,
        'email': user.email ?? email,
      }, SetOptions(merge: true));
      await batch.commit();

      await SaveUserLocal.saveUser(user);
    } on FirebaseAuthException catch (e) {
      throw e;
    } on FirebaseException catch (e) {
      throw "Erro ao salvar no Firestore: ${e.message}";
    } catch (e) {
      throw "Erro desconhecido: $e";
    }
  }

  Future<void> loginUser(String email, String password) async {
    try {
      await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (_firebaseAuth.currentUser != null) {
        final user = _firebaseAuth.currentUser!;
        unawaited(OneSignalSession.login(user.uid));
        unawaited(_syncUserDocumentOnLogin(user));
        await SaveUserLocal.saveUser(user);
      }
    } catch (e) {
      rethrow;
    }
  }

  static const List<String> _legacyPrivateFields = [
    'email',
    'birth_date',
    'institution',
    'course',
    'expected_graduation',
  ];

  Future<void> _syncUserDocumentOnLogin(User user) async {
    try {
      final userRef = _firestore.collection('users').doc(user.uid);
      final snapshot = await userRef.get();
      final publicData = snapshot.data() ?? <String, dynamic>{};

      final legacyFields = _legacyPrivateFields
          .where((field) => publicData.containsKey(field))
          .toList();

      final batch = _firestore.batch();

      if (legacyFields.isNotEmpty) {
        batch.set(userRef.collection('private').doc('profile'), {
          for (final field in legacyFields)
            if (field != 'email' && publicData[field] != null)
              field: publicData[field],
          'uid': user.uid,
          if (user.email != null) 'email': user.email,
        }, SetOptions(merge: true));
      }

      batch.set(userRef, {
        'uid': user.uid,
        'last_login': FieldValue.serverTimestamp(),
        for (final field in legacyFields) field: FieldValue.delete(),
        if (!snapshot.exists) 'profile_completed': false,
        if (!snapshot.exists) 'created_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await batch.commit();
    } on FirebaseException catch (e) {
      if (kDebugMode) {
        debugPrint('Falha ao sincronizar perfil no login (${e.code})');
      }
    }
  }
}
