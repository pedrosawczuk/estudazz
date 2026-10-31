import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TasksDB {
  final CollectionReference tasksCollection = FirebaseFirestore.instance
      .collection('tasks');

  String _requireAuthenticatedUid() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      throw Exception('Usuário não autenticado.');
    }
    return uid;
  }

  Future<DocumentSnapshot> _getOwnedTask(String taskId) async {
    final currentUid = _requireAuthenticatedUid();
    final doc = await tasksCollection
        .doc(taskId)
        .get()
        .timeout(const Duration(seconds: 15));
    if (!doc.exists) {
      throw Exception('Tarefa não encontrada.');
    }
    final data = doc.data() as Map<String, dynamic>?;
    if (data?['uid'] != currentUid) {
      throw Exception('Acesso negado à tarefa.');
    }
    return doc;
  }

  Future<DocumentReference> addTask({
    required String uid,
    required String taskName,
    required String dueDate,
  }) async {
    try {
      final currentUid = _requireAuthenticatedUid();
      if (uid != currentUid) {
        throw Exception('Acesso negado.');
      }
      return await tasksCollection
          .add({
            'uid': currentUid,
            'task_name': taskName,
            'created_at': DateTime.now().toIso8601String(),
            'task_completed': false,
            'due_date': dueDate,
            'task_completed_at': null,
          })
          .timeout(const Duration(seconds: 15));
    } catch (e) {
      throw Exception('Timeout ou erro ao adicionar tarefa: $e');
    }
  }

  Future<void> setTaskCompletion({
    required String taskId,
    required bool completed,
  }) async {
    try {
      await _getOwnedTask(taskId);
      await tasksCollection
          .doc(taskId)
          .update({
            'task_completed': completed,
            'task_completed_at':
                completed ? DateTime.now().toIso8601String() : null,
          })
          .timeout(const Duration(seconds: 15));
    } catch (e) {
      throw Exception('Timeout ou erro ao atualizar tarefa: $e');
    }
  }

  Future<void> deleteTask(String taskId) async {
    try {
      await _getOwnedTask(taskId);
      await tasksCollection
          .doc(taskId)
          .delete()
          .timeout(const Duration(seconds: 15));
    } catch (e) {
      throw Exception('Timeout ou erro ao apagar tarefa: $e');
    }
  }

  Future<DocumentSnapshot> getTask(String taskId) async {
    try {
      return await _getOwnedTask(taskId);
    } catch (e) {
      throw Exception('Timeout ou erro ao buscar tarefa: $e');
    }
  }

  Stream<QuerySnapshot> getTasksByUser(String uid) {
    return tasksCollection
        .where('uid', isEqualTo: uid)
        .orderBy('task_completed')
        .orderBy('created_at')
        .snapshots();
  }
}
