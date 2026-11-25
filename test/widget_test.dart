import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestor_tareas_local/main.dart';

import 'support/repositorio_en_memoria.dart';

void main() {
  testWidgets('La pantalla inicial se muestra sin errores', (tester) async {
    // Único cambio respecto a la base: se inyecta un repositorio en memoria
    // para que la prueba no abra SQLite ni use el disco.
    await tester.pumpWidget(GestorTareasApp(repositorio: RepositorioEnMemoria()));
    expect(find.text('Gestor de tareas'), findsOneWidget);
    expect(find.text('Agregar tarea'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });
}
