import 'package:estudazz_main_code/components/custom/customSnackBar.dart';
import 'package:estudazz_main_code/constants/color/constColors.dart';
import 'package:estudazz_main_code/models/studyRoom/studyRoomModel.dart';
import 'package:estudazz_main_code/routes/appRoutes.dart';
import 'package:estudazz_main_code/services/db/studyRoom/studyRoomDb.dart';
import 'package:estudazz_main_code/services/notificationsApi/notificationsApiService.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StudyRoomController extends GetxController {
  final StudyRoomDB _studyRoomDB = StudyRoomDB();
  final NotificationsApiService _notificationsApiService =
      NotificationsApiService();
  final _studyRooms = <StudyRoomModel>[].obs;

  List<StudyRoomModel> get studyRooms => _studyRooms;

  @override
  void onInit() {
    super.onInit();
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        _studyRooms.bindStream(_getStudyRoomsStream(user.uid));
      } else {
        _studyRooms.clear();
      }
    });
  }

  Stream<List<StudyRoomModel>> _getStudyRoomsStream(String userId) {
    return _studyRoomDB.getStudyRoomsStream(userId).map((snapshot) {
      return snapshot.docs.map((doc) => StudyRoomModel.fromFirestore(doc)).toList();
    });
  }

  Future<void> createStudyRoom(String name, String? description) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      CustomSnackBar.show(
          title: 'Erro',
          message: 'Você precisa estar logado para criar uma sala.',
          backgroundColor: ConstColors.redColor);
      return;
    }

    if (name.isEmpty) {
      CustomSnackBar.show(
          title: 'Erro',
          message: 'O nome da sala não pode ser vazio.',
          backgroundColor: ConstColors.redColor);
      return;
    }

    try {
      final newRoomRef = await _studyRoomDB.createStudyRoom(
        name: name,
        description: description,
        creatorUid: user.uid,
      );

      final newRoomSnapshot = await newRoomRef.get();
      if (newRoomSnapshot.exists) {
        final newRoom = StudyRoomModel.fromFirestore(newRoomSnapshot);
        _studyRooms.insert(0, newRoom);
        CustomSnackBar.show(
            title: 'Sucesso!',
            message: 'A sala "$name" foi criada.',
            backgroundColor: ConstColors.greenColor);
      }
    } catch (e) {
      CustomSnackBar.show(
          title: 'Erro',
          message: 'Ocorreu um erro ao criar a sala.',
          backgroundColor: ConstColors.redColor);
    }
  }

  Future<void> joinStudyRoom(String roomCode) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      CustomSnackBar.show(
          title: 'Erro',
          message: 'Você precisa estar logado para entrar em uma sala.',
          backgroundColor: ConstColors.redColor);
      return;
    }

    try {
      final roomSnapshot = await _studyRoomDB.findRoomByCode(roomCode);

      if (roomSnapshot.docs.isEmpty) {
        CustomSnackBar.show(
            title: 'Erro',
            message: 'Nenhuma sala encontrada com este código.',
            backgroundColor: ConstColors.redColor);
        return;
      }

      final roomDoc = roomSnapshot.docs.first;
      final room = StudyRoomModel.fromFirestore(roomDoc);

      if (room.members.contains(user.uid)) {
        Get.toNamed(AppRoutes.studyRoomDetailsPage, arguments: room);
        return;
      }

      await _studyRoomDB.addUserToRoom(room.id, user.uid);

      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool('notif_pref_studyroom') ?? true) {
        await _notificationsApiService.pushToStudyRoom(
          roomId: room.id,
          recipientUids: room.members,
          title: 'Nova pessoa na sala',
          body: '${user.displayName ?? "Alguém"} entrou em "${room.name}"',
        );
      }

      final updatedRoom = room.copyWith(
        members: List<String>.from(room.members)..add(user.uid),
      );

      CustomSnackBar.show(
          title: 'Sucesso!',
          message: 'Você entrou na sala "${room.name}".',
          backgroundColor: ConstColors.greenColor);

      Get.toNamed(AppRoutes.studyRoomDetailsPage, arguments: updatedRoom);
    } catch (e) {
      CustomSnackBar.show(
          title: 'Erro',
          message: 'Ocorreu um erro ao entrar na sala.',
          backgroundColor: ConstColors.redColor);
    }
  }

  Future<void> updateRoomName(String roomId, String newName) async {
    if (newName.isEmpty) {
      CustomSnackBar.show(
          title: 'Erro',
          message: 'O nome da sala não pode ser vazio.',
          backgroundColor: ConstColors.redColor);
      return;
    }

    try {
      final index = _studyRooms.indexWhere((room) => room.id == roomId);
      if (index != -1) {
        _studyRooms[index] = _studyRooms[index].copyWith(name: newName);
      }
      
      await _studyRoomDB.updateStudyRoom(roomId: roomId, data: {'name': newName});
      CustomSnackBar.show(
          title: 'Sucesso!',
          message: 'O nome da sala foi atualizado.',
          backgroundColor: ConstColors.greenColor);
    } catch (e) {
      CustomSnackBar.show(
          title: 'Erro',
          message: 'Não foi possível atualizar o nome da sala.',
          backgroundColor: ConstColors.redColor);
    }
  }

  Future<void> deleteRoom(String roomId) async {
    try {
      _studyRooms.removeWhere((room) => room.id == roomId);
      await _studyRoomDB.deleteStudyRoom(roomId);
      CustomSnackBar.show(
          title: 'Sucesso!',
          message: 'A sala foi excluída.',
          backgroundColor: ConstColors.greenColor);
    } catch (e) {
      CustomSnackBar.show(
          title: 'Erro',
          message: 'Não foi possível excluir a sala.',
          backgroundColor: ConstColors.redColor);
    }
  }

  Future<void> leaveRoom(String roomId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      CustomSnackBar.show(
          title: 'Erro',
          message: 'Você precisa estar logado para sair de uma sala.',
          backgroundColor: ConstColors.redColor);
      return;
    }

    try {
      await _studyRoomDB.leaveStudyRoom(roomId, user.uid);
      CustomSnackBar.show(
          title: 'Sucesso!',
          message: 'Você saiu da sala.',
          backgroundColor: ConstColors.greenColor);
      Get.offNamed(AppRoutes.studyRoomPage);
    } catch (e) {
      CustomSnackBar.show(
          title: 'Erro',
          message: 'Não foi possível sair da sala.',
          backgroundColor: ConstColors.redColor);
    }
  }
}
