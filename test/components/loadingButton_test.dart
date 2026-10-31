import 'dart:async';

import 'package:estudazz_main_code/components/custom/loadingButton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(home: Scaffold(body: Center(child: child)));
  }

  testWidgets('mostra spinner durante a ação e ignora toques repetidos', (
    tester,
  ) async {
    final completer = Completer<void>();
    var calls = 0;

    await tester.pumpWidget(
      wrap(
        LoadingButton(
          onPressed: () {
            calls++;
            return completer.future;
          },
          child: const Text('Salvar'),
        ),
      ),
    );

    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Salvar'), findsNothing);

    await tester.tap(find.byType(ElevatedButton));
    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();
    expect(calls, 1);

    completer.complete();
    await tester.pumpAndSettle();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Salvar'), findsOneWidget);
  });

  testWidgets('volta ao normal mesmo quando a ação falha', (tester) async {
    var calls = 0;

    await tester.pumpWidget(
      wrap(
        LoadingButton(
          onPressed: () async {
            calls++;
            throw Exception('falhou');
          },
          child: const Text('Salvar'),
        ),
      ),
    );

    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isA<Exception>());

    expect(find.text('Salvar'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();
    tester.takeException();
    expect(calls, 2);
  });

  testWidgets('mantém o estilo habilitado durante o carregamento', (
    tester,
  ) async {
    final completer = Completer<void>();

    await tester.pumpWidget(
      wrap(
        LoadingButton(
          onPressed: () => completer.future,
          child: const Text('Salvar'),
        ),
      ),
    );

    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();

    final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(button.onPressed, isNotNull);

    completer.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('variante de ícone troca o ícone pelo spinner', (tester) async {
    final completer = Completer<void>();

    await tester.pumpWidget(
      wrap(
        LoadingButton.icon(
          onPressed: () => completer.future,
          icon: const Icon(Icons.send),
        ),
      ),
    );

    expect(find.byIcon(Icons.send), findsOneWidget);

    await tester.tap(find.byType(IconButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byIcon(Icons.send), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    completer.complete();
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.send), findsOneWidget);
  });

  testWidgets('sem onPressed o botão fica desabilitado', (tester) async {
    await tester.pumpWidget(
      wrap(const LoadingButton(onPressed: null, child: Text('Salvar'))),
    );

    final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(button.onPressed, isNull);
  });
}
