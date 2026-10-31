import 'package:estudazz_main_code/components/custom/loadingButton.dart';
import 'package:estudazz_main_code/utils/navigation/closeRoute.dart';
import 'package:flutter/material.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

class JoinStudyRoomDialog extends StatefulWidget {
  final Future<void> Function(String code) onJoin;

  const JoinStudyRoomDialog({super.key, required this.onJoin});

  @override
  _JoinStudyRoomDialogState createState() => _JoinStudyRoomDialogState();
}

class _JoinStudyRoomDialogState extends State<JoinStudyRoomDialog> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();

  final _maskFormatter = MaskTextInputFormatter(
    mask: '###-###',
    filter: {"#": RegExp(r'[A-Z0-9]')},
    type: MaskAutoCompletionType.lazy,
  );

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Entrar em Sala de Estudos'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _codeController,
              inputFormatters: [_maskFormatter],
              autocorrect: false,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Código da Sala',
                hintText: 'ABC-123',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor, insira o código da sala.';
                }
                if (value.length != 7) {
                  return 'O código deve ter 6 caracteres.';
                }
                return null;
              },
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
              // Entrar abre a sala por cima do diálogo; fecha só o próprio diálogo
              final route = ModalRoute.of(context);
              await widget.onJoin(_codeController.text);
              if (mounted) closeRoute(context, route);
            }
          },
          child: const Text('Entrar'),
        ),
      ],
    );
  }
}
