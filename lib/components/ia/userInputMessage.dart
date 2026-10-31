import 'package:estudazz_main_code/components/custom/customSnackBar.dart';
import 'package:estudazz_main_code/constants/color/constColors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class UserInputMessage extends StatelessWidget {
  final String text;

  const UserInputMessage({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: GestureDetector(
        onLongPress: () async {
          await Clipboard.setData(ClipboardData(text: text));
          CustomSnackBar.show(
            title: 'Copiado!',
            message:
                'O conteúdo da mensagem foi copiado para a área de transferência.',
            backgroundColor: ConstColors.orangeColor,
          );
        },
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: ConstColors.orangeColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: MarkdownBody(
            data: text,
            sizedImageBuilder: (config) => const SizedBox.shrink(),
            onTapLink: (text, href, title) {},
            styleSheet: MarkdownStyleSheet.fromTheme(
              Theme.of(context),
            ).copyWith(p: const TextStyle(color: ConstColors.whiteColor)),
          ),
        ),
      ),
    );
  }
}
