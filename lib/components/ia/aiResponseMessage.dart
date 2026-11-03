import 'dart:async';
import 'package:estudazz_main_code/constants/color/constColors.dart';
import 'package:estudazz_main_code/components/custom/customSnackBar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class AIResponseMessage extends StatefulWidget {
  final String text;
  final bool animate;
  final VoidCallback? onTypingComplete;

  const AIResponseMessage({
    super.key,
    required this.text,
    this.animate = false,
    this.onTypingComplete,
  });

  @override
  State<AIResponseMessage> createState() => _AIResponseMessageState();
}

class _AIResponseMessageState extends State<AIResponseMessage> {
  static const Duration _typingTick = Duration(milliseconds: 40);
  static const int _typingTotalTicks = 40;

  int _visibleLength = 0;
  Timer? _timer;

  String get _displayedText => widget.text.substring(0, _visibleLength);

  @override
  void initState() {
    super.initState();
    _startTyping();
  }

  @override
  void didUpdateWidget(covariant AIResponseMessage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _startTyping();
    }
  }

  void _startTyping() {
    _timer?.cancel();

    if (!widget.animate) {
      _visibleLength = widget.text.length;
      return;
    }

    _visibleLength = 0;
    final charsPerTick = (widget.text.length / _typingTotalTicks).ceil().clamp(
      1,
      widget.text.length + 1,
    );

    _timer = Timer.periodic(_typingTick, (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      final nextLength = _visibleLength + charsPerTick;
      if (nextLength >= widget.text.length) {
        timer.cancel();
        setState(() => _visibleLength = widget.text.length);
        widget.onTypingComplete?.call();
        return;
      }
      setState(() => _visibleLength = nextLength);
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
            message:
                'O conteúdo da mensagem foi copiado para a área de transferência.',
            backgroundColor: ConstColors.orangeColor,
          );
        },
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: ConstColors.grey900Color,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: ConstColors.orangeColor.withValues(alpha: 0.3),
            ),
          ),
          child: MarkdownBody(
            data: _displayedText,
            sizedImageBuilder: (config) => const SizedBox.shrink(),
            onTapLink: (text, href, title) {},
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
