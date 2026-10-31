import 'package:estudazz_main_code/utils/navigation/closeRoute.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('fecha só o diálogo quando outra tela foi aberta por cima', (
    tester,
  ) async {
    final navigatorKey = GlobalKey<NavigatorState>();
    late BuildContext dialogContext;
    late Route<dynamic>? dialogRoute;

    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        home: const Scaffold(body: Text('Lista de salas')),
      ),
    );

    showDialog(
      context: navigatorKey.currentContext!,
      builder: (context) {
        dialogContext = context;
        dialogRoute = ModalRoute.of(context);
        return const AlertDialog(content: Text('Entrar na sala'));
      },
    );
    await tester.pumpAndSettle();

    // Simula o controller abrindo a sala enquanto o diálogo ainda está aberto
    navigatorKey.currentState!.push(
      MaterialPageRoute(builder: (_) => const Scaffold(body: Text('Sala aberta'))),
    );
    await tester.pumpAndSettle();

    closeRoute(dialogContext, dialogRoute);
    await tester.pumpAndSettle();

    expect(find.text('Sala aberta'), findsOneWidget);
    expect(find.text('Entrar na sala'), findsNothing);

    navigatorKey.currentState!.pop();
    await tester.pumpAndSettle();
    expect(find.text('Lista de salas'), findsOneWidget);
  });

  testWidgets('fecha o diálogo normalmente quando ele está no topo', (
    tester,
  ) async {
    final navigatorKey = GlobalKey<NavigatorState>();
    late BuildContext dialogContext;
    late Route<dynamic>? dialogRoute;

    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        home: const Scaffold(body: Text('Lista de salas')),
      ),
    );

    showDialog(
      context: navigatorKey.currentContext!,
      builder: (context) {
        dialogContext = context;
        dialogRoute = ModalRoute.of(context);
        return const AlertDialog(content: Text('Criar sala'));
      },
    );
    await tester.pumpAndSettle();

    closeRoute(dialogContext, dialogRoute);
    await tester.pumpAndSettle();

    expect(find.text('Criar sala'), findsNothing);
    expect(find.text('Lista de salas'), findsOneWidget);
  });
}
