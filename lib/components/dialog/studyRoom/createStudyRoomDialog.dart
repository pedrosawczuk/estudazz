import 'package:estudazz_main_code/components/custom/loadingButton.dart';
import 'package:estudazz_main_code/utils/navigation/closeRoute.dart';
import 'package:flutter/material.dart';

class CreateStudyRoomDialog extends StatefulWidget {
  final Future<void> Function(String name, String? description) onCreate;

  const CreateStudyRoomDialog({super.key, required this.onCreate});

  @override
  _CreateStudyRoomDialogState createState() => _CreateStudyRoomDialogState();
}

class _CreateStudyRoomDialogState extends State<CreateStudyRoomDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Criar Sala de Estudos'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nome da Sala',
                hintText: 'Ex: Grupo de Cálculo I',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor, insira um nome para a sala.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Descrição (opcional)',
                hintText: 'Ex: Encontros às segundas-feiras',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        LoadingButton(
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              final route = ModalRoute.of(context);
              await widget.onCreate(
                _nameController.text,
                _descriptionController.text.isNotEmpty
                    ? _descriptionController.text
                    : null,
              );
              if (mounted) closeRoute(context, route);
            }
          },
          child: const Text('Criar'),
        ),
      ],
    );
  }
}
