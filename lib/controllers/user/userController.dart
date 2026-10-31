import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:estudazz_main_code/models/user/userModel.dart';
import 'package:estudazz_main_code/services/user/fetchUserDataService.dart';
import 'package:estudazz_main_code/utils/user/getUserData.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

class UserController {
  final FetchUserDataService _fetchUserDataService = FetchUserDataService();

  Future<UserModel?> fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      final uid = await GetUserData.getUserUid();
      if (uid == null) return null;

      final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
      final results = await Future.wait([
        userRef.get(),
        userRef.collection('private').doc('profile').get(),
      ]);
      final snapshot = results[0];
      final privateSnapshot = results[1];

      if (snapshot.exists && snapshot.data() != null) {
        return UserModel.fromMap(
          snapshot.data()!,
          uid,
          privateMap: privateSnapshot.data(),
        );
      }
    }

    return null;
  }

  Stream<UserModel?> streamUserData() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid);
      return userRef.snapshots().asyncMap((snapshot) async {
        if (snapshot.exists && snapshot.data() != null) {
          final privateSnapshot =
              await userRef.collection('private').doc('profile').get();
          return UserModel.fromMap(
            snapshot.data()!,
            user.uid,
            privateMap: privateSnapshot.data(),
          );
        }
        return null;
      });
    }
    return Stream.value(null);
  }

  /// Retorna `null` se o usuário cancelar a escolha da imagem.
  Future<File?> pickProfilePicture(ImageSource source) {
    return _fetchUserDataService.pickProfileImage(source);
  }

  /// Lança erro se o envio falhar.
  Future<String> uploadProfilePicture(File imageFile) {
    return _fetchUserDataService.uploadProfileImage(imageFile);
  }
}
