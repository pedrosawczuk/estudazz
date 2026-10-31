import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:estudazz_main_code/components/custom/loadingButton.dart';
import 'package:estudazz_main_code/components/custom/customSnackBar.dart';
import 'package:estudazz_main_code/constants/color/constColors.dart';
import 'package:estudazz_main_code/constants/constSizedBox.dart';
import 'package:estudazz_main_code/routes/appRoutes.dart';
import 'package:estudazz_main_code/services/auth/saveUserLocal.dart';
import 'package:estudazz_main_code/services/db/studyRoom/studyRoomDb.dart';
import 'package:estudazz_main_code/services/ia/iaChatStorageService.dart';
import 'package:estudazz_main_code/services/notificationsApi/notificationsApiService.dart';
import 'package:estudazz_main_code/services/notificationsApi/oneSignalSession.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

Future<void> _deleteUserOwnedData(String uid) async {
  final firestore = FirebaseFirestore.instance;
  final notificationsApi = NotificationsApiService();
  final studyRoomDB = StudyRoomDB();

  final tasksSnapshot =
      await firestore.collection('tasks').where('uid', isEqualTo: uid).get();
  for (final doc in tasksSnapshot.docs) {
    try {
      await notificationsApi.cancelReminder(type: 'task', entityId: doc.id);
    } catch (_) {}
    await doc.reference.delete();
  }

  final eventsSnapshot =
      await firestore.collection('events').where('uid', isEqualTo: uid).get();
  for (final doc in eventsSnapshot.docs) {
    try {
      await notificationsApi.cancelReminder(type: 'event', entityId: doc.id);
    } catch (_) {}
    await doc.reference.delete();
  }

  final roomsSnapshot = await firestore
      .collection('study_rooms')
      .where('members', arrayContains: uid)
      .get();
  for (final roomDoc in roomsSnapshot.docs) {
    final data = roomDoc.data();
    if (data['creatorUid'] == uid) {
      await studyRoomDB.deleteStudyRoom(roomDoc.id);
    } else {
      await studyRoomDB.leaveStudyRoom(roomDoc.id, uid);
    }
  }

  try {
    await firestore.collection('ia-data').doc(uid).delete();
  } catch (_) {}

  try {
    await FirebaseStorage.instance.ref('users/$uid/profile.jpg').delete();
  } on FirebaseException catch (_) {}

  try {
    await firestore
        .collection('users')
        .doc(uid)
        .collection('private')
        .doc('profile')
        .delete();
  } catch (_) {}

  await firestore.collection('users').doc(uid).delete();
}

void showDeleteAccountDialog(BuildContext context) {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final currentUser = FirebaseAuth.instance.currentUser;

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text("Confirmar Exclusão"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text.rich(
              TextSpan(
                text:
                    "Confirme seu e-mail e sua senha para excluir permanentemente sua conta e seus dados:\n\n",
                children: [
                  TextSpan(
                    text: currentUser?.email ?? '[email não disponível]',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: ConstColors.redColor,
                    ),
                  ),
                ],
                style: const TextStyle(fontSize: 16),
              ),
            ),
            ConstSizedBox.h12,
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: "E-mail",
                border: OutlineInputBorder(),
              ),
            ),
            ConstSizedBox.h12,
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Senha atual",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text("Cancelar"),
            onPressed: () => Get.back(),
          ),
          LoadingButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: ConstColors.redColor,
              foregroundColor: ConstColors.whiteColor,
            ),
            child: const Text("Excluir"),
            onPressed: () async {
              final email = currentUser?.email;
              final password = passwordController.text;

              if (email == null || emailController.text.trim() != email) {
                CustomSnackBar.show(
                  title: "E-mail incorreto",
                  message:
                      "O e-mail digitado não corresponde ao e-mail da conta.",
                  backgroundColor: ConstColors.redColor,
                );
                return;
              }

              if (password.isEmpty) {
                CustomSnackBar.show(
                  title: "Senha obrigatória",
                  message: "Digite sua senha atual para confirmar a exclusão.",
                  backgroundColor: ConstColors.redColor,
                );
                return;
              }

              try {
                final uid = currentUser!.uid;
                final credential = EmailAuthProvider.credential(
                  email: email,
                  password: password,
                );
                await currentUser.reauthenticateWithCredential(credential);

                await _deleteUserOwnedData(uid);
                await currentUser.delete();

                await IaChatStorageService.clearMessages(uid: uid);
                await OneSignalSession.logout();
                await SaveUserLocal.clearUser();

                FocusManager.instance.primaryFocus?.unfocus();
                Get.back();

                CustomSnackBar.show(
                  title: "Conta excluída com sucesso!",
                  message: "Sua conta e seus dados foram excluídos.",
                  backgroundColor: ConstColors.greenColor,
                );

                Get.offAllNamed(AppRoutes.signInPage);
              } on FirebaseAuthException catch (e) {
                final message =
                    (e.code == 'wrong-password' ||
                        e.code == 'invalid-credential')
                    ? "Senha incorreta. Verifique e tente novamente."
                    : "Não foi possível validar suas credenciais.";
                CustomSnackBar.show(
                  title: "Erro de autenticação",
                  message: message,
                  backgroundColor: ConstColors.redColor,
                );
              } catch (e) {
                FocusManager.instance.primaryFocus?.unfocus();
                Get.back();
                CustomSnackBar.show(
                  title: "Erro ao excluir conta",
                  message: "Ocorreu um erro ao tentar excluir sua conta.",
                  backgroundColor: ConstColors.redColor,
                );
              }
            },
          ),
        ],
      );
    },
  );
}
