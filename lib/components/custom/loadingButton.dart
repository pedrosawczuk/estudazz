import 'package:flutter/material.dart';

enum LoadingButtonVariant { elevated, outlined, text, icon }

/// Botão para ações assíncronas: mostra um spinner enquanto `onPressed` roda
/// e ignora novos toques até terminar, mantendo a aparência do botão.
class LoadingButton extends StatefulWidget {
  final Future<void> Function()? onPressed;
  final Widget child;
  final Widget? icon;
  final ButtonStyle? style;
  final LoadingButtonVariant variant;

  const LoadingButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.icon,
    this.style,
    this.variant = LoadingButtonVariant.elevated,
  });

  /// Para `IconButton`: o `child` é o ícone.
  const LoadingButton.icon({
    super.key,
    required this.onPressed,
    required Widget icon,
    this.style,
  }) : child = icon,
       icon = null,
       variant = LoadingButtonVariant.icon;

  @override
  State<LoadingButton> createState() => _LoadingButtonState();
}

class _LoadingButtonState extends State<LoadingButton> {
  bool _loading = false;

  Future<void> _handlePressed() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      await widget.onPressed!();
    } catch (error, stack) {
      FlutterError.reportError(
        FlutterErrorDetails(exception: error, stack: stack, library: 'LoadingButton'),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _spinner() {
    return Builder(
      builder: (context) {
        // Nos botões com texto a cor do conteúdo é a do texto (foregroundColor);
        // no IconButton é a do ícone
        final color = widget.variant == LoadingButtonVariant.icon
            ? IconTheme.of(context).color
            : DefaultTextStyle.of(context).style.color;
        return SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2.5, color: color),
        );
      },
    );
  }

  Widget _swap(Widget idle) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: _loading
          ? KeyedSubtree(key: const ValueKey('loading'), child: _spinner())
          : KeyedSubtree(key: const ValueKey('idle'), child: idle),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Durante o carregamento o callback vira no-op (em vez de null) para não
    // trocar o botão para o estilo "desabilitado"
    final VoidCallback? onPressed = widget.onPressed == null
        ? null
        : (_loading ? () {} : _handlePressed);

    switch (widget.variant) {
      case LoadingButtonVariant.icon:
        return IconButton(
          onPressed: onPressed,
          style: widget.style,
          icon: _swap(widget.child),
        );
      case LoadingButtonVariant.outlined:
        return widget.icon != null
            ? OutlinedButton.icon(
                onPressed: onPressed,
                style: widget.style,
                icon: _swap(widget.icon!),
                label: widget.child,
              )
            : OutlinedButton(
                onPressed: onPressed,
                style: widget.style,
                child: _swap(widget.child),
              );
      case LoadingButtonVariant.text:
        return TextButton(
          onPressed: onPressed,
          style: widget.style,
          child: _swap(widget.child),
        );
      case LoadingButtonVariant.elevated:
        return widget.icon != null
            ? ElevatedButton.icon(
                onPressed: onPressed,
                style: widget.style,
                icon: _swap(widget.icon!),
                label: widget.child,
              )
            : ElevatedButton(
                onPressed: onPressed,
                style: widget.style,
                child: _swap(widget.child),
              );
    }
  }
}
