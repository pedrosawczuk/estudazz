import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:estudazz_main_code/components/studyRoom/chat/messageBubble.dart';
import 'package:estudazz_main_code/models/studyRoom/chatMessageModel.dart';
import 'package:estudazz_main_code/models/studyRoom/studyRoomModel.dart';
import 'package:estudazz_main_code/models/user/userModel.dart';
import 'package:estudazz_main_code/services/db/studyRoom/studyRoomDb.dart';
import 'package:estudazz_main_code/services/notificationsApi/notificationsApiService.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatPage extends StatefulWidget {
  final StudyRoomModel room;
  final List<UserModel> members;

  const ChatPage({super.key, required this.room, required this.members});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _textController = TextEditingController();
  final _studyRoomDB = StudyRoomDB();
  final _notificationsApiService = NotificationsApiService();
  late final Map<String, UserModel> _membersMap;

  @override
  void initState() {
    super.initState();
    _membersMap = {for (var member in widget.members) member.uid: member};
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      return;
    }

    final currentUser = FirebaseAuth.instance.currentUser;

    await _studyRoomDB.sendChatMessage(widget.room.id, text);

    final recipientUids =
        widget.room.members.where((uid) => uid != currentUser?.uid).toList();

    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('notif_pref_studyroom') ?? true) {
      await _notificationsApiService.pushToStudyRoom(
        roomId: widget.room.id,
        recipientUids: recipientUids,
        title: widget.room.name,
        body:
            '${_membersMap[currentUser?.uid]?.displayName ?? "Alguém"}: $text',
      );
    }

    _textController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Column(
      children: [
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _studyRoomDB.getChatMessagesStream(widget.room.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text('Nenhuma mensagem ainda.'));
              }

              final messages = snapshot.data!.docs;

              return ListView.builder(
                reverse: true,
                padding: const EdgeInsets.all(8.0),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final message = ChatMessageModel.fromFirestore(messages[index]);
                  final sender = _membersMap[message.senderUid];

                  if (sender == null) {
                    return const SizedBox.shrink();
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: MessageBubble(
                      message: message,
                      sender: sender,
                      isMe: message.senderUid == currentUser?.uid,
                    ),
                  );
                },
              );
            },
          ),
        ),
        _buildMessageInput(),
      ],
    );
  }

  Widget _buildMessageInput() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              decoration: const InputDecoration(
                hintText: 'Digite uma mensagem...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(24)),
                ),
              ),
              textCapitalization: TextCapitalization.sentences,
              maxLines: null, 
              keyboardType: TextInputType.multiline,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: _sendMessage,
            style: IconButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
