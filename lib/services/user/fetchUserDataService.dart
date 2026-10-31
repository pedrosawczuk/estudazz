import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:estudazz_main_code/utils/user/getUserData.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class FetchUserDataService {
  static const int _maxUploadSizeBytes = 5 * 1024 * 1024;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  Future<DocumentSnapshot> getUserData() async {
    String uid = await GetUserData.getUserUid() ?? '';
    return await _firestore.collection('users').doc(uid).get();
  }

  /// Retorna `null` se o usuário cancelar a escolha da imagem.
  Future<File?> pickProfileImage(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(
      source: source,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 80,
    );
    return pickedFile == null ? null : File(pickedFile.path);
  }

  /// Envia a foto e salva a URL no perfil. Lança erro se o envio falhar.
  Future<String> uploadProfileImage(File imageFile) async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('Usuário não autenticado');

    final int length = await imageFile.length();
    if (length <= 0 || length > _maxUploadSizeBytes) {
      throw StateError('A imagem deve ter no máximo 5 MB.');
    }

    final String uid = user.uid;
    final Reference storageRef = _storage.ref().child('users/$uid/profile.jpg');

    try {
      await storageRef.delete();
    } on FirebaseException catch (_) {
      // Ignora caso não exista foto anterior
    }

    final UploadTask uploadTask = storageRef.putFile(
      imageFile,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    final TaskSnapshot snapshot = await uploadTask;
    final String downloadUrl = await snapshot.ref.getDownloadURL();

    await _firestore.collection('users').doc(uid).set(
      {'photoURL': downloadUrl},
      SetOptions(merge: true),
    );

    return downloadUrl;
  }
}
