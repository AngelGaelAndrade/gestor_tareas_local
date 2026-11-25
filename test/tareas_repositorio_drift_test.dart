import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestor_tareas_local/data/app_database.dart';
import 'package:gestor_tareas_local/data/tareas_repositorio.dart';
import 'package:gestor_tareas_local/data/tareas_repositorio_drift.dart';
import 'package:gestor_tareas_local/models/tarea.dart';

/// Pruebas de almacenamiento con SQLite real (en memoria o en un archivo
/// temporal), sin pasar por la interfaz.
void main() {
  group('Operaciones CRUD (SQLite en memoria)', () {
    late AppDatabase db;
    late TareasRepositorioDrift repo;

    // Lee la lista actual a través de la misma consulta que usa la interfaz.
    Future<List<Tarea>> leer() => repo.observarTareas().first;

    setUp(() {
      db = AppDatabase.conExecutor(NativeDatabase.memory());
      repo = TareasRepositorioDrift(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('agrega y consulta tareas con id único', () async {
      final a = await repo.agregar('Primera');
      final b = await repo.agregar('Segunda');

      final tareas = await leer();
      expect(tareas.map((t) => t.titulo), ['Primera', 'Segunda']);
      expect(tareas.every((t) => !t.completada), isTrue);
      expect(a.id, isNot(b.id));
    });

    test('no guarda títulos vacíos ni solo espacios', () async {
      await expectLater(repo.agregar(''), throwsA(isA<TareasException>()));
      await expectLater(repo.agregar('   '), throwsA(isA<TareasException>()));
      expect(await leer(), isEmpty);
    });

    test('guarda el título sin espacios sobrantes', () async {
      await repo.agregar('  Con espacios  ');
      expect((await leer()).single.titulo, 'Con espacios');
    });

    test('edita el título de una tarea', () async {
      final tarea = await repo.agregar('Viejo');
      await repo.editarTitulo(tarea.id, 'Nuevo');
      expect((await leer()).single.titulo, 'Nuevo');
    });

    test('no permite editar con un título vacío', () async {
      final tarea = await repo.agregar('Intacto');
      await expectLater(
        repo.editarTitulo(tarea.id, '  '),
        throwsA(isA<TareasException>()),
      );
      expect((await leer()).single.titulo, 'Intacto');
    });

    test('marca una tarea como completada y de nuevo como pendiente', () async {
      final tarea = await repo.agregar('Cambiar estado');
      await repo.cambiarEstado(tarea.id, true);
      expect((await leer()).single.completada, isTrue);
      await repo.cambiarEstado(tarea.id, false);
      expect((await leer()).single.completada, isFalse);
    });

    test('elimina solo la tarea indicada por su id', () async {
      final borrar = await repo.agregar('Borrar');
      await repo.agregar('Conservar');
      await repo.eliminar(borrar.id);
      expect((await leer()).map((t) => t.titulo), ['Conservar']);
    });

    test('operar sobre un id inexistente lanza un error comprensible',
        () async {
      await expectLater(repo.eliminar(999), throwsA(isA<TareasException>()));
      await expectLater(
        repo.editarTitulo(999, 'X'),
        throwsA(isA<TareasException>()),
      );
      await expectLater(
        repo.cambiarEstado(999, true),
        throwsA(isA<TareasException>()),
      );
    });

    test('la restricción de la tabla también rechaza títulos vacíos', () async {
      await expectLater(
        db.into(db.tareas).insert(TareasCompanion.insert(titulo: '')),
        throwsA(anything),
      );
    });
  });

  group('Persistencia tras cerrar y reabrir la base (archivo real)', () {
    late Directory carpeta;
    late File archivo;

    setUp(() async {
      carpeta = await Directory.systemTemp.createTemp('gestor_tareas_test_');
      archivo = File('${carpeta.path}/tareas.sqlite');
    });

    tearDown(() async {
      if (await carpeta.exists()) {
        await carpeta.delete(recursive: true);
      }
    });

    test('las tareas, su estado, edición y borrado sobreviven al reinicio',
        () async {
      // Primera "ejecución": se crean tres tareas y se modifican.
      var db = AppDatabase.conExecutor(NativeDatabase(archivo));
      var repo = TareasRepositorioDrift(db);
      final uno = await repo.agregar('Uno');
      final dos = await repo.agregar('Dos');
      final tres = await repo.agregar('Tres');
      await repo.cambiarEstado(uno.id, true);
      await repo.editarTitulo(dos.id, 'Dos editada');
      await repo.eliminar(tres.id);
      await db.close();

      // Segunda "ejecución": nueva conexión al mismo archivo.
      db = AppDatabase.conExecutor(NativeDatabase(archivo));
      repo = TareasRepositorioDrift(db);
      final tareas = await repo.observarTareas().first;
      await db.close();

      expect(tareas.map((t) => t.titulo), ['Uno', 'Dos editada']);
      expect(tareas[0].completada, isTrue);
      expect(tareas[1].completada, isFalse);
    });
  });
}
