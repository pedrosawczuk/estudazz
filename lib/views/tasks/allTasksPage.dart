import 'package:estudazz_main_code/components/dialog/task/markTaskCompletedDialog.dart';
import 'package:estudazz_main_code/constants/color/constColors.dart';
import 'package:estudazz_main_code/constants/constSizedBox.dart';
import 'package:estudazz_main_code/controllers/tasks/taskController.dart';
import 'package:estudazz_main_code/components/dialog/task/addTaskDialog.dart';
import 'package:estudazz_main_code/components/custom/customAppBar.dart';
import 'package:estudazz_main_code/models/tasks/taskModel.dart';
import 'package:estudazz_main_code/services/db/tasks/tasksDB.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AllTasksPage extends StatefulWidget {
  const AllTasksPage({super.key});

  @override
  State<AllTasksPage> createState() => _AllTasksPageState();
}

class _AllTasksPageState extends State<AllTasksPage> {
  final TaskController _taskController = TaskController(tasksDB: TasksDB());
  final TasksDB _tasksDB = TasksDB();

  late Future<String?> _userUidFuture;

  @override
  void initState() {
    super.initState();
    _userUidFuture = _getUserUid();
  }

  Future<String?> _getUserUid() async {
    User? user = FirebaseAuth.instance.currentUser;
    return user?.uid;
  }

  void _showMarkTaskCompletedDialog(String taskId, String taskName) {
    MarkTaskCompletedDialog().showMarkTaskCompletedDialog(
      context: context,
      taskId: taskId,
      taskName: taskName,
    );
  }

  void _showAddTaskDialog() {
    AddTaskDialog().showAddTaskDialog(
      context: context,
      taskController: _taskController,
      getUserUid: _getUserUid,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(titleAppBar: 'Minhas Tarefas'),
      body: FutureBuilder<String?>(
        future: _userUidFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text("Erro ao carregar UID do usuário."));
          }

          String uid = snapshot.data!;

          return StreamBuilder<QuerySnapshot>(
            stream: _tasksDB.getTasksByUser(uid),
            builder: (context, taskSnapshot) {
              if (taskSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (taskSnapshot.hasError) {
                return Center(
                  child: Text(
                    "Erro ao carregar tarefas: ${taskSnapshot.error} \n Contacte o suporte.",
                  ),
                );
              }

              if (!taskSnapshot.hasData || taskSnapshot.data!.docs.isEmpty) {
                return const Center(child: Text("Nenhuma tarefa encontrada."));
              }

              final tasks =
                  taskSnapshot.data!.docs.map((doc) {
                    return TaskModel.fromDocument(
                      doc.data() as Map<String, dynamic>,
                      doc.id,
                    );
                  }).toList();

              return Column(
                children: [
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: ConstColors.grey900Color,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: ConstColors.orangeColor.withValues(alpha: 0.5)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.lightbulb_outline, color: ConstColors.orangeColor),
                        ConstSizedBox.w8,
                        Expanded(
                          child: Text(
                            "Dica: Pressione e segure em uma tarefa para marcá-la como concluída ou reabri-la.",
                            style: TextStyle(color: ConstColors.whiteColor, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: tasks.length,
                      itemBuilder: (context, index) {
                  final task = tasks[index];

                  final formattedDueDate = DateFormat(
                    "dd/MM/yyyy",
                  ).format(task.dueDate);

                  bool isOverdue =
                      !task.taskCompleted &&
                      task.dueDate.isBefore(DateTime.now());

                  String statusText;
                  IconData statusIcon;
                  Color statusColor;

                  if (task.taskCompleted) {
                    statusText = "Tarefa Concluída";
                    statusIcon = Icons.check_circle;
                    statusColor = ConstColors.greenColor;
                  } else if (isOverdue) {
                    statusText = "Tarefa Atrasada";
                    statusIcon = Icons.cancel;
                    statusColor = ConstColors.redColor;
                  } else {
                    statusText = "Tarefa Pendente";
                    statusIcon = Icons.warning_amber_rounded;
                    statusColor = ConstColors.yellowColor;
                  }

                  return Opacity(
                    opacity: task.taskCompleted ? 0.5 : 1.0,
                    child: GestureDetector(
                      onLongPress: () {
                        _showMarkTaskCompletedDialog(task.id, task.taskName);
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            const BoxShadow(
                              color: ConstColors.black54Color,
                              blurRadius: 4,
                              offset: Offset(2, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        "$statusText: ",
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        task.taskName,
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                    ],
                                  ),
                                  ConstSizedBox.h4,
                                  Text(
                                    "Prazo: $formattedDueDate",
                                    style: const TextStyle(
                                      color: ConstColors.greyColor,
                                      fontSize: 14,
                                    ),
                                  ),
                                  ConstSizedBox.h4,
                                  Text(
                                    "Pressione e segure para opções",
                                    style: TextStyle(
                                      color: ConstColors.greyColor.withValues(alpha: 0.8),
                                      fontSize: 11,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(statusIcon, color: statusColor, size: 32),
                          ],
                        ),
                      ),
                    ),
                  );
                },
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: ConstColors.orangeColor,
        foregroundColor: ConstColors.whiteColor,
        onPressed: _showAddTaskDialog,
        icon: const Icon(Icons.add),
        label: const Text('Adicionar Tarefa'),
      ),
    );
  }
}

