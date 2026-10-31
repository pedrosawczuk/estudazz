import 'package:estudazz_main_code/services/auth/saveUserLocal.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:estudazz_main_code/services/notificationsApi/oneSignalSession.dart';

class AuthServices {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createNewUser(String email, String password) async {
    try {
      final UserCredential userCredential = await _firebaseAuth
          .createUserWithEmailAndPassword(email: email, password: password);

      final user = userCredential.user!;
      await OneSignalSession.login(user.uid);

      final userRef = _firestore.collection('users').doc(user.uid);
      final batch = _firestore.batch();
      batch.set(userRef, {
        'uid': user.uid,
        'profile_completed': false,
        'created_at': FieldValue.serverTimestamp(),
      });
      batch.set(
        userRef.collection('private').doc('profile'),
        {
          'uid': user.uid,
          'email': user.email ?? email,
        },
        SetOptions(merge: true),
      );
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
        await OneSignalSession.login(user.uid);
        await _firestore.collection('users').doc(user.uid).update({
          'last_login': FieldValue.serverTimestamp(),
        });
        await SaveUserLocal.saveUser(user);
      }
    } catch (e) {
      rethrow;
    }
  }
}
