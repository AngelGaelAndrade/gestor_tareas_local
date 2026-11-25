import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestor_tareas_local/main.dart';

import 'support/repositorio_en_memoria.dart';

/// Pruebas de interfaz con un repositorio en memoria (sin SQLite ni disco).
/// La persistencia real se prueba en tareas_repositorio_drift_test.dart.
void main() {
  Future<void> abrirApp(WidgetTester tester) async {
    await tester.pumpWidget(GestorTareasApp(repositorio: RepositorioEnMemoria()));
    await tester.pumpAndSettle();
  }

  Future<void> agregarTarea(WidgetTester tester, String titulo) async {
    await tester.enterText(find.byType(TextField), titulo);
    await tester.tap(find.text('Agregar tarea'));
    await tester.pumpAndSettle();
  }

  testWidgets('Sin tareas muestra el mensaje de lista vacía', (tester) async {
    await abrirApp(tester);
    expect(find.text('Todavía no hay tareas guardadas'), findsOneWidget);
  });

  testWidgets('Agrega una tarea, la lista y limpia el campo', (tester) async {
    await abrirApp(tester);
    await agregarTarea(tester, '  Comprar leche  ');

    expect(find.text('Comprar leche'), findsOneWidget);
    expect(find.text('Todavía no hay tareas guardadas'), findsNothing);
    final campo = tester.widget<TextField>(find.byType(TextField));
    expect(campo.controller!.text, isEmpty);
  });

  testWidgets('No agrega un título vacío o de solo espacios', (tester) async {
    await abrirApp(tester);
    await agregarTarea(tester, '   ');

    expect(find.byType(Card), findsNothing);
    expect(find.text('El título no puede estar vacío.'), findsOneWidget);
  });

  testWidgets('Marca una tarea como completada', (tester) async {
    await abrirApp(tester);
    await agregarTarea(tester, 'Estudiar Drift');

    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isFalse);
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isTrue);
  });

  testWidgets('Edita el título de una tarea', (tester) async {
    await abrirApp(tester);
    await agregarTarea(tester, 'Titulo viejo');

    await tester.tap(find.byTooltip('Editar'));
    await tester.pumpAndSettle();
    final campoDialogo = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(TextField),
    );
    await tester.enterText(campoDialogo, 'Título nuevo');
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    expect(find.text('Título nuevo'), findsOneWidget);
    expect(find.text('Titulo viejo'), findsNothing);
  });

  testWidgets('Elimina una tarea tras confirmar', (tester) async {
    await abrirApp(tester);
    await agregarTarea(tester, 'Tarea temporal');

    await tester.tap(find.byTooltip('Eliminar'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Eliminar'));
    await tester.pumpAndSettle();

    expect(find.text('Tarea temporal'), findsNothing);
    expect(find.text('Todavía no hay tareas guardadas'), findsOneWidget);
  });
}
