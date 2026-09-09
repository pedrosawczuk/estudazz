import 'dart:async';
import 'package:estudazz_main_code/constants/color/constColors.dart';
import 'package:estudazz_main_code/components/custom/customSnackBar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class AIResponseMessage extends StatefulWidget {
  final String text;

  const AIResponseMessage({super.key, required this.text});

  @override
  State<AIResponseMessage> createState() => _AIResponseMessageState();
}

class _AIResponseMessageState extends State<AIResponseMessage> {
  String displayedText = '';
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTyping();
  }

  @override
  void didUpdateWidget(covariant AIResponseMessage oldWidget) {
    if (oldWidget.text != widget.text) {
      _startTyping();
    }
    super.didUpdateWidget(oldWidget);
  }

  void _startTyping() {
    _timer?.cancel();
    displayedText = '';
    int index = 0;
    
    _timer = Timer.periodic(const Duration(milliseconds: 10), (timer) {
      if (index < widget.text.length) {
        setState(() {
          displayedText += widget.text[index];
          index++;
        });
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: () async {
          await Clipboard.setData(ClipboardData(text: widget.text));
          CustomSnackBar.show(
            title: 'Copiado!',
            message: 'O conteúdo da mensagem foi copiado para a área de transferência.',
            backgroundColor: ConstColors.orangeColor,
          );
        },
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: ConstColors.grey900Color,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: ConstColors.orangeColor.withValues(alpha: 0.3)),
          ),
          child: MarkdownBody(
            data: displayedText,
            styleSheet: MarkdownStyleSheet.fromTheme(
              Theme.of(context),
            ).copyWith(
              p: const TextStyle(
                color: ConstColors.whiteColor,
                fontSize: 16,
                height: 1.5,
                fontWeight: FontWeight.w400,
              ),
              a: const TextStyle(
                color: ConstColors.orangeColor,
                decoration: TextDecoration.underline,
                fontWeight: FontWeight.w600,
              ),
              code: const TextStyle(
                color: ConstColors.orangeColor,
                backgroundColor: ConstColors.blackColor,
                fontFamily: 'SourceCodePro',
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
