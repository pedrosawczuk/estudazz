import 'package:flutter/material.dart';

/// Fecha `route` (ex.: o diálogo atual) mesmo que outra tela tenha sido
/// aberta por cima dele enquanto uma ação assíncrona rodava.
void closeRoute(BuildContext context, Route<dynamic>? route) {
  if (route == null || !route.isActive) return;
  final navigator = Navigator.of(context);
  if (route.isCurrent) {
    navigator.pop();
  } else {
    navigator.removeRoute(route);
  }
}
