import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EventsDB {
  final CollectionReference eventsCollection = FirebaseFirestore.instance
      .collection('events');

  String _requireAuthenticatedUid() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      throw Exception('Usuário não autenticado.');
    }
    return uid;
  }

  Future<DocumentSnapshot> _getOwnedEvent(String eventId) async {
    final currentUid = _requireAuthenticatedUid();
    final doc = await eventsCollection.doc(eventId).get();
    if (!doc.exists) {
      throw Exception('Evento não encontrado.');
    }
    final data = doc.data() as Map<String, dynamic>?;
    if (data?['uid'] != currentUid) {
      throw Exception('Acesso negado ao evento.');
    }
    return doc;
  }

  Future<DocumentReference> addEvent({
    required String uid,
    required String eventName,
    required DateTime eventDate,
  }) async {
    final currentUid = _requireAuthenticatedUid();
    if (uid != currentUid) {
      throw Exception('Acesso negado.');
    }
    return await eventsCollection.add({
      'uid': currentUid,
      'event_name': eventName,
      'event_date': eventDate.toIso8601String(),
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<DocumentSnapshot> getEvents(String eventId) async {
    return await _getOwnedEvent(eventId);
  }

  Future<void> updateEvent({
    required String eventId,
    required String eventName,
    required DateTime eventDate,
  }) async {
    await _getOwnedEvent(eventId);
    await eventsCollection.doc(eventId).update({
      'event_name': eventName,
      'event_date': eventDate.toIso8601String(),
    });
  }

  Future<void> deleteEvent(String eventId) async {
    await _getOwnedEvent(eventId);
    await eventsCollection.doc(eventId).delete();
  }

  Stream<QuerySnapshot> getEventsByUser(String uid) {
    return eventsCollection
        .where('uid', isEqualTo: uid)
        .orderBy('created_at', descending: true)
        .snapshots();
  }
}
