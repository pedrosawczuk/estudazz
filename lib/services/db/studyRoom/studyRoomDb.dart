import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StudyRoomDB {
  final CollectionReference studyRoomsCollection =
      FirebaseFirestore.instance.collection('study_rooms');
  final CollectionReference roomCodesCollection =
      FirebaseFirestore.instance.collection('study_room_codes');

  String _generateRoomCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();
    final part1 = String.fromCharCodes(
      Iterable.generate(3, (_) => chars.codeUnitAt(random.nextInt(chars.length))),
    );
    final part2 = String.fromCharCodes(
      Iterable.generate(3, (_) => chars.codeUnitAt(random.nextInt(chars.length))),
    );
    return '$part1-$part2';
  }

  Future<String> _generateUniqueRoomCode() async {
    for (int attempt = 0; attempt < 5; attempt++) {
      final candidate = _generateRoomCode();
      final codeDoc = await roomCodesCollection.doc(candidate).get();
      if (!codeDoc.exists) {
        return candidate;
      }
    }
    throw StateError('Não foi possível gerar um código único para a sala.');
  }

  Future<DocumentReference> createStudyRoom({
    required String name,
    String? description,
    required String creatorUid,
  }) async {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null || currentUid != creatorUid) {
      throw StateError('Usuário não autenticado.');
    }

    final roomCode = await _generateUniqueRoomCode();
    final roomRef = studyRoomsCollection.doc();
    final now = Timestamp.now();

    final batch = FirebaseFirestore.instance.batch();
    batch.set(roomRef, {
      'name': name.trim(),
      'description': description?.trim(),
      'creatorUid': creatorUid,
      'members': [creatorUid],
      'createdAt': now,
    });
    batch.set(roomRef.collection('private').doc('config'), {
      'roomCode': roomCode,
      'creatorUid': creatorUid,
    });
    batch.set(roomCodesCollection.doc(roomCode), {
      'roomId': roomRef.id,
      'creatorUid': creatorUid,
      'createdAt': now,
    });
    await batch.commit();

    return roomRef;
  }

  Future<DocumentSnapshot?> findRoomDocumentByCode(String roomCode) async {
    final normalizedCode = roomCode.trim().toUpperCase();
    if (normalizedCode.isEmpty) return null;

    final codeDoc = await roomCodesCollection.doc(normalizedCode).get();
    if (!codeDoc.exists) return null;

    final data = codeDoc.data() as Map<String, dynamic>?;
    final roomId = data?['roomId'] as String?;
    if (roomId == null || roomId.isEmpty) return null;

    final roomDoc = await studyRoomsCollection.doc(roomId).get();
    return roomDoc.exists ? roomDoc : null;
  }

  Future<String> getRoomCodeForOwner(
    String roomId, {
    String fallback = '',
  }) async {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null) return fallback;

    try {
      final configDoc = await studyRoomsCollection
          .doc(roomId)
          .collection('private')
          .doc('config')
          .get();
      if (configDoc.exists) {
        final code = configDoc.data()?['roomCode'];
        if (code is String && code.isNotEmpty) {
          return code;
        }
      }
    } catch (_) {}

    return fallback;
  }

  Future<void> addUserToRoom(String roomId, String userId) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null || currentUid != userId) {
      throw StateError('Operação não permitida.');
    }
    return studyRoomsCollection.doc(roomId).update({
      'members': FieldValue.arrayUnion([userId]),
    });
  }

  Future<void> leaveStudyRoom(String roomId, String userId) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null || currentUid != userId) {
      throw StateError('Operação não permitida.');
    }
    return studyRoomsCollection.doc(roomId).update({
      'members': FieldValue.arrayRemove([userId]),
    });
  }

  Stream<QuerySnapshot> getStudyRoomsStream(String userId) {
    return studyRoomsCollection
        .where('members', arrayContains: userId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Stream<DocumentSnapshot> getStudyRoomStream(String roomId) {
    return studyRoomsCollection.doc(roomId).snapshots();
  }

  Future<void> updateStudyRoomName({
    required String roomId,
    required String name,
  }) async {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null) {
      throw StateError('Usuário não autenticado.');
    }
    final roomDoc = await studyRoomsCollection.doc(roomId).get();
    final roomData = roomDoc.data() as Map<String, dynamic>?;
    if (!roomDoc.exists || roomData?['creatorUid'] != currentUid) {
      throw StateError('Apenas o criador da sala pode renomeá-la.');
    }
    await studyRoomsCollection.doc(roomId).update({'name': name.trim()});
  }

  Future<void> deleteStudyRoom(String roomId) async {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null) {
      throw StateError('Usuário não autenticado.');
    }

    final roomRef = studyRoomsCollection.doc(roomId);
    final roomDoc = await roomRef.get();
    if (!roomDoc.exists) return;

    final roomData = roomDoc.data() as Map<String, dynamic>?;
    if (roomData?['creatorUid'] != currentUid) {
      throw StateError('Apenas o criador da sala pode excluí-la.');
    }

    final roomCode = await getRoomCodeForOwner(
      roomId,
      fallback: (roomData?['roomCode'] as String?) ?? '',
    );

    while (true) {
      final messagesSnapshot =
          await roomRef.collection('messages').limit(200).get();
      if (messagesSnapshot.docs.isEmpty) break;

      final batch = FirebaseFirestore.instance.batch();
      for (final messageDoc in messagesSnapshot.docs) {
        batch.delete(messageDoc.reference);
      }
      await batch.commit();
    }

    final batch = FirebaseFirestore.instance.batch();
    if (roomCode.isNotEmpty) {
      batch.delete(roomCodesCollection.doc(roomCode));
    }
    batch.delete(roomRef.collection('private').doc('config'));
    batch.delete(roomRef);
    await batch.commit();
  }

  Stream<QuerySnapshot> getChatMessagesStream(String roomId) {
    return studyRoomsCollection
        .doc(roomId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Stream<Map<String, int>> getParticipatedStudyRoomsStats(String userId) {
    return studyRoomsCollection
        .where('members', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
          return {'total': snapshot.docs.length};
        });
  }

  Future<void> sendChatMessage(String roomId, String text) async {
    final user = FirebaseAuth.instance.currentUser;
    final trimmed = text.trim();
    if (user == null || trimmed.isEmpty) {
      return;
    }
    await studyRoomsCollection.doc(roomId).collection('messages').add({
      'senderUid': user.uid,
      'text': trimmed,
      'createdAt': Timestamp.now(),
    });
  }
}
