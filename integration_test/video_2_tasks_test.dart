import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:estudazz_main_code/main.dart' as app;

Future<void> stealthTap(WidgetTester tester, Finder finder) async {
  final widget = tester.firstWidget(finder);
  if (widget is ElevatedButton) {
    widget.onPressed?.call();
  } else if (widget is TextButton) {
    widget.onPressed?.call();
  } else if (widget is IconButton) {
    widget.onPressed?.call();
  } else if (widget is GestureDetector) {
    widget.onTap?.call();
  } else if (widget is InkWell) {
    widget.onTap?.call();
  } else {
    await tester.tap(finder); 
  }
}

Future<void> typeTextLikeHuman(WidgetTester tester, Finder finder, String text) async {
  await tester.tap(finder);
  await tester.pump(const Duration(milliseconds: 300));
  await tester.testTextInput.receiveAction(TextInputAction.done);
  
  for (int i = 1; i <= text.length; i++) {
    await tester.enterText(finder, text.substring(0, i));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Video 2: Criação e Gerenciamento de Tarefas', (WidgetTester tester) async {
    app.main();
    await tester.pumpAndSettle(const Duration(seconds: 6));

    final btnSignInCheck = find.widgetWithText(ElevatedButton, 'Entrar');
    if (btnSignInCheck.evaluate().isNotEmpty) {
      final signInEmailInput = find.widgetWithText(TextFormField, 'Email');
      final signInPasswordInput = find.widgetWithText(TextFormField, 'Senha');
      await typeTextLikeHuman(tester, signInEmailInput, 'usuario@gmail.com');
      await Future.delayed(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      await typeTextLikeHuman(tester, signInPasswordInput, 'Senha112233@');
      await Future.delayed(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      
      await stealthTap(tester, btnSignInCheck);
      await Future.delayed(const Duration(seconds: 4));
      await tester.pumpAndSettle();
    }

    final btnTarefas = find.ancestor(of: find.text('Minhas Tarefas'), matching: find.byType(GestureDetector));
    if (btnTarefas.evaluate().isNotEmpty) {
      await stealthTap(tester, btnTarefas.first);
    } else {
      await tester.tap(find.text('Minhas Tarefas'));
    }
    await Future.delayed(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    final fabAdd = find.byType(FloatingActionButton);
    expect(fabAdd, findsOneWidget);
    await tester.tap(fabAdd);
    await Future.delayed(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    final titleInput = find.widgetWithText(TextFormField, 'Título');
    final subjectInput = find.widgetWithText(TextFormField, 'Matéria');

    await typeTextLikeHuman(tester, titleInput, 'Estudar Flutter');
    await Future.delayed(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    
    await typeTextLikeHuman(tester, subjectInput, 'TCC');
    await Future.delayed(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    
    final btnSaveTask = find.widgetWithText(ElevatedButton, 'Salvar Tarefa');
    await stealthTap(tester, btnSaveTask);
    
    await Future.delayed(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    final taskItem = find.ancestor(of: find.text('Estudar Flutter'), matching: find.byType(InkWell));
    if (taskItem.evaluate().isNotEmpty) {
      await stealthTap(tester, taskItem.first);
      await Future.delayed(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      final editTitleInput = find.widgetWithText(TextFormField, 'Título');
      if (editTitleInput.evaluate().isNotEmpty) {
         await typeTextLikeHuman(tester, editTitleInput, 'Estudar Flutter e Firebase');
         await Future.delayed(const Duration(milliseconds: 500));
         await tester.pumpAndSettle();
         
         final btnEditSave = find.widgetWithText(ElevatedButton, 'Atualizar Tarefa');
         if(btnEditSave.evaluate().isNotEmpty) {
           await stealthTap(tester, btnEditSave);
         } else {
           final btnFallbackSave = find.widgetWithText(ElevatedButton, 'Salvar Tarefa');
           if (btnFallbackSave.evaluate().isNotEmpty) {
              await stealthTap(tester, btnFallbackSave);
           }
         }
         await Future.delayed(const Duration(seconds: 3));
         await tester.pumpAndSettle();
      }
    }

    final taskItemEdited = find.text('Estudar Flutter e Firebase');
    if (taskItemEdited.evaluate().isNotEmpty) {
       final checkBox = find.byType(Checkbox).last;
       if (checkBox.evaluate().isNotEmpty) {
          await tester.tap(checkBox);
          await Future.delayed(const Duration(seconds: 2));
          await tester.pumpAndSettle();
          
          final btnDelete = find.widgetWithText(ElevatedButton, 'Excluir Tarefa');
          if (btnDelete.evaluate().isNotEmpty) {
            await stealthTap(tester, btnDelete);
            await Future.delayed(const Duration(seconds: 3));
            await tester.pumpAndSettle();
          }
       }
    }
  });
}
