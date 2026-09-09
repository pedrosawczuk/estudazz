import 'package:cloud_firestore/cloud_firestore.dart';

class TasksDB {
  final CollectionReference tasksCollection = FirebaseFirestore.instance
      .collection('tasks');

  Future<DocumentReference> addTask({
    required String uid,
    required String taskName,
    required String dueDate,
  }) async {
    try {
      return await tasksCollection.add({
        'uid': uid,
        'task_name': taskName,
        'created_at': DateTime.now().toIso8601String(),
        'task_completed': false,
        'due_date': dueDate,
        'task_completed_at': null,
      }).timeout(const Duration(seconds: 15));
    } catch (e) {
      throw Exception('Timeout ou erro ao adicionar tarefa: $e');
    }
  }

  Future<void> updateTask({
    required String taskId,
    required Map<String, dynamic> data,
  }) async {
    try {
      await tasksCollection.doc(taskId).update(data).timeout(const Duration(seconds: 15));
    } catch (e) {
      throw Exception('Timeout ou erro ao atualizar tarefa: $e');
    }
  }

  Future<void> deleteTask(String taskId) async {
    try {
      await tasksCollection.doc(taskId).delete().timeout(const Duration(seconds: 15));
    } catch (e) {
      throw Exception('Timeout ou erro ao apagar tarefa: $e');
    }
  }
  
  Future<DocumentSnapshot> getTask(String taskId) async {
    try {
      return await tasksCollection.doc(taskId).get().timeout(const Duration(seconds: 15));
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
