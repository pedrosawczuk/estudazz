import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:estudazz_main_code/components/custom/customSnackBar.dart';
import 'package:estudazz_main_code/constants/color/constColors.dart';
import 'package:estudazz_main_code/constants/constSizedBox.dart';
import 'package:estudazz_main_code/utils/user/getUserData.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class IATrainingNewDataDialog extends StatefulWidget {
  const IATrainingNewDataDialog({super.key});

  @override
  State<IATrainingNewDataDialog> createState() =>
      _IATrainingNewDataDialogState();
}

class _IATrainingNewDataDialogState extends State<IATrainingNewDataDialog> {
  final TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final _firestore = FirebaseFirestore.instance;

    final uid = await GetUserData.getUserUid();
    if (uid == null) return;

    final snapshot = await _firestore.collection('ia-data').doc(uid).get();

    if (snapshot.exists) {
      final data = snapshot.data();
      if (data != null && data['data'] != null) {
        setState(() {
          _textController.text = data['data'];
        });
      }
    }
  }

  void _confirmIANewData() async {
    final _firestore = FirebaseFirestore.instance;
    final uid = await GetUserData.getUserUid();

    final snapshot = await _firestore.collection('ia-data').doc(uid).get();

    if (uid == null) return;

    final text = _textController.text.trim();
    if (text.isNotEmpty) {
      await _firestore.collection('ia-data').doc(uid).set({
        'data': text,
        'uid': uid,
        'created_at':
            snapshot.exists
                ? snapshot['created_at']
                : DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      FocusManager.instance.primaryFocus?.unfocus();
      Get.back();

      CustomSnackBar.show(
        title: 'Sucesso!',
        message: 'Dados salvos com sucesso.',
        backgroundColor: ConstColors.greenColor,
      );

      print(text);
    } else {
      CustomSnackBar.show(
        title: 'Erro!',
        message: 'Campo não pode ficar vazio.',
        backgroundColor: ConstColors.redColor,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Treinar IA com Novos Dados'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Adicione informações para melhorar as respostas da IA.'),
          ConstSizedBox.h12,
          TextField(
            controller: _textController,
            minLines: 5,
            maxLines: null,
            keyboardType: TextInputType.multiline,
            decoration: const InputDecoration(
              hintText: 'Digite aqui...',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(onPressed: _confirmIANewData, child: const Text('Salvar')),
      ],
    );
  }
}
