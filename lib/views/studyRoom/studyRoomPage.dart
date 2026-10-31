import 'dart:math';
import 'package:estudazz_main_code/components/custom/customAppBar.dart';
import 'package:estudazz_main_code/components/custom/loadingButton.dart';
import 'package:estudazz_main_code/components/dialog/studyRoom/createStudyRoomDialog.dart';
import 'package:estudazz_main_code/components/dialog/studyRoom/editStudyRoomDialog.dart';
import 'package:estudazz_main_code/components/dialog/studyRoom/joinStudyRoomDialog.dart';
import 'package:estudazz_main_code/controllers/studyRoom/studyRoomController.dart';
import 'package:estudazz_main_code/models/studyRoom/studyRoomModel.dart';
import 'package:estudazz_main_code/routes/appRoutes.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class StudyRoomPage extends StatefulWidget {
  const StudyRoomPage({super.key});

  @override
  State<StudyRoomPage> createState() => _StudyRoomPageState();
}

class _StudyRoomPageState extends State<StudyRoomPage> {
  final StudyRoomController _studyRoomController = Get.put(
    StudyRoomController(),
  );

  void _showCreateStudyRoomDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return CreateStudyRoomDialog(
          onCreate: (name, description) =>
              _studyRoomController.createStudyRoom(name, description),
        );
      },
    );
  }

  void _showJoinStudyRoomDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return JoinStudyRoomDialog(
          onJoin: (code) => _studyRoomController.joinStudyRoom(code),
        );
      },
    );
  }

  void _showStudyRoomOptionsModal() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.add),
                title: const Text('Criar sala de estudos'),
                onTap: () {
                  Navigator.pop(context);
                  _showCreateStudyRoomDialog();
                },
              ),
              ListTile(
                leading: const Icon(Icons.group_add),
                title: const Text('Entrar em sala de estudos'),
                onTap: () {
                  Navigator.pop(context);
                  _showJoinStudyRoomDialog();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(titleAppBar: 'Sala de Estudos'),
      body: Obx(() {
        if (_studyRoomController.studyRooms.isEmpty) {
          return const Center(child: Text('Nenhuma sala de estudos criada.'));
        }
        return GridView.builder(
          padding: const EdgeInsets.all(16.0),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16.0,
            mainAxisSpacing: 16.0,
            childAspectRatio: 1.2,
          ),
          itemCount: _studyRoomController.studyRooms.length,
          itemBuilder: (context, index) {
            return _StudyRoomCard(
              room: _studyRoomController.studyRooms[index],
              controller: _studyRoomController,
            );
          },
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: _showStudyRoomOptionsModal,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _StudyRoomCard extends StatelessWidget {
  final StudyRoomModel room;
  final StudyRoomController controller;

  const _StudyRoomCard({required this.room, required this.controller});

  void _showEditNameDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => EditStudyRoomDialog(
            currentName: room.name,
            onSave: (newName) => controller.updateRoomName(room.id, newName),
          ),
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Excluir Sala'),
            content: Text(
              'Você tem certeza que deseja excluir a sala "${room.name}"? Esta ação não pode ser desfeita.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              LoadingButton(
                variant: LoadingButtonVariant.text,
                onPressed: () async {
                  await controller.deleteRoom(room.id);
                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text(
                  'Excluir',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }

  void _showAdminActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Editar nome'),
                onTap: () {
                  Navigator.pop(context);
                  _showEditNameDialog(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text(
                  'Excluir sala',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmationDialog(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getColorFromId(String id) {
    final random = Random(id.hashCode);
    return Color.fromRGBO(
      random.nextInt(200),
      random.nextInt(200),
      random.nextInt(200),
      1,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isOwner = room.creatorUid == FirebaseAuth.instance.currentUser?.uid;

    return Card(
      color: _getColorFromId(room.id),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          Get.toNamed(AppRoutes.studyRoomDetailsPage, arguments: room);
        },
        onLongPress: isOwner ? () => _showAdminActions(context) : null,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                room.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.group, color: Colors.white, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '${room.members.length} membro(s)',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}