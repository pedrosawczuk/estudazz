import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:estudazz_main_code/components/custom/customAppBar.dart';
import 'package:estudazz_main_code/components/custom/customSnackBar.dart';
import 'package:estudazz_main_code/components/custom/loadingButton.dart';
import 'package:estudazz_main_code/constants/color/constColors.dart';
import 'package:estudazz_main_code/controllers/studyRoom/studyRoomController.dart';
import 'package:estudazz_main_code/models/studyRoom/studyRoomModel.dart';
import 'package:estudazz_main_code/models/user/userModel.dart';
import 'package:estudazz_main_code/services/db/studyRoom/studyRoomDb.dart';
import 'package:estudazz_main_code/views/studyRoom/chatPage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class StudyRoomDetailsPage extends StatefulWidget {
  final StudyRoomModel room;

  const StudyRoomDetailsPage({super.key, required this.room});

  @override
  State<StudyRoomDetailsPage> createState() => _StudyRoomDetailsPageState();
}

class _StudyRoomDetailsPageState extends State<StudyRoomDetailsPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final StudyRoomDB _studyRoomDB = StudyRoomDB();
  StreamSubscription? _roomSubscription;
  late StudyRoomModel _currentRoom;
  String _ownerRoomCode = '';
  List<UserModel> _members = [];
  bool _isLoading = true;
  late bool _canChat;

  @override
  void initState() {
    super.initState();
    _currentRoom = widget.room;
    _ownerRoomCode = widget.room.roomCode;
    _canChat = _currentRoom.members.length > 1;
    _tabController = TabController(length: _canChat ? 2 : 1, vsync: this);
    _fetchMembersData();
    _loadOwnerRoomCode();
    _listenToRoomChanges();
  }

  Future<void> _loadOwnerRoomCode() async {
    final isOwner =
        FirebaseAuth.instance.currentUser?.uid == _currentRoom.creatorUid;
    if (!isOwner) return;

    final code = await _studyRoomDB.getRoomCodeForOwner(
      _currentRoom.id,
      fallback: _currentRoom.roomCode,
    );
    if (mounted && code.isNotEmpty) {
      setState(() {
        _ownerRoomCode = code;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _roomSubscription?.cancel();
    super.dispose();
  }

  void _listenToRoomChanges() {
    _roomSubscription = _studyRoomDB.getStudyRoomStream(_currentRoom.id).listen(
      (snapshot) {
        if (snapshot.exists && mounted) {
          final updatedRoom = StudyRoomModel.fromFirestore(snapshot);
          final canChatNow = updatedRoom.members.length > 1;

          setState(() {
            _currentRoom = updatedRoom;
          });

          if (canChatNow != _canChat) {
            _canChat = canChatNow;
            final newIndex = _tabController.index;
            _tabController.dispose();
            _tabController = TabController(
              length: canChatNow ? 2 : 1,
              vsync: this,
              initialIndex: newIndex > 0 && !canChatNow ? 0 : newIndex,
            );
          }

          if (_currentRoom.members.length != _members.length) {
            _fetchMembersData();
          }
        }
      },
    );
  }

  Future<void> _fetchMembersData() async {
    try {
      final List<UserModel> members = [];
      for (final uid in _currentRoom.members) {
        final userDoc =
            await FirebaseFirestore.instance.collection('users').doc(uid).get();
        if (userDoc.exists) {
          members.add(UserModel.fromMap(userDoc.data()!, uid));
        }
      }
      if (mounted) {
        setState(() {
          _members = members;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        CustomSnackBar.show(
          title: 'Erro',
          message: 'Não foi possível carregar os membros da sala.',
          backgroundColor: ConstColors.redColor,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        titleAppBar: _currentRoom.name,
        bottom:
            _canChat
                ? TabBar(
                  controller: _tabController,
                  tabs: const [Tab(text: 'Chat'), Tab(text: 'Detalhes')],
                )
                : null,
      ),
      body: TabBarView(
        controller: _tabController,
        children:
            _canChat
                ? [
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ChatPage(room: _currentRoom, members: _members),
                  _buildDetailsTab(),
                ]
                : [_buildDetailsTab()],
      ),
    );
  }

  Widget _buildDetailsTab() {
    final isOwner =
        FirebaseAuth.instance.currentUser?.uid == _currentRoom.creatorUid;
    final formattedDate = DateFormat(
      'dd/MM/yyyy',
    ).format(_currentRoom.createdAt.toDate());
    final controller = Get.find<StudyRoomController>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isOwner) ...[
            const Text(
              'Código da Sala:',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _ownerRoomCode,
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed: () {
                    Clipboard.setData(
                      ClipboardData(text: _ownerRoomCode),
                    );
                    CustomSnackBar.show(
                      title: 'Copiado!',
                      message:
                          'Código da sala copiado para a área de transferência.',
                      backgroundColor: ConstColors.greenColor,
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 32),
          ],
          Text(
            'Criado em: $formattedDate',
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          const Text(
            'Membros:',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _members.length,
                  itemBuilder: (context, index) {
                    final member = _members[index];
                    return ListTile(
                      leading: ClipOval(
                        child: member.photoUrl.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: member.photoUrl,
                                placeholder: (context, url) =>
                                    const CircularProgressIndicator(),
                                errorWidget: (context, url, error) =>
                                    Image.asset(
                                  'assets/images/no-profile-photo.png',
                                  fit: BoxFit.cover,
                                  width: 40,
                                  height: 40,
                                ),
                                fit: BoxFit.cover,
                                width: 40,
                                height: 40,
                              )
                            : Image.asset(
                                'assets/images/no-profile-photo.png',
                                fit: BoxFit.cover,
                                width: 40,
                                height: 40,
                              ),
                      ),
                      title: Text(member.displayName),
                      subtitle: Text(
                        member.username.isNotEmpty ? '@${member.username}' : '',
                      ),
                    );
                  },
                ),
          if (!isOwner) ...[
            const SizedBox(height: 32),
            LoadingButton(
              onPressed: () => controller.leaveRoom(_currentRoom.id),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('Sair da Sala'),
            ),
          ],
        ],
      ),
    );
  }
}
