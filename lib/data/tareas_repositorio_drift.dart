import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

import '../models/tarea.dart';
import 'app_database.dart';
import 'tareas_repositorio.dart';

/// Implementación del repositorio sobre SQLite mediante Drift.
class TareasRepositorioDrift implements TareasRepositorio {
  TareasRepositorioDrift(this._db);

  final AppDatabase _db;

  Tarea _aModelo(TareaFila fila) => Tarea(
        id: fila.id,
        titulo: fila.titulo,
        completada: fila.completada,
      );

  /// Convierte cualquier fallo de almacenamiento en un mensaje comprensible.
  Future<T> _proteger<T>(String mensaje, Future<T> Function() accion) async {
    try {
      return await accion();
    } on TareasException {
      rethrow;
    } catch (error, pila) {
      debugPrint('Error de almacenamiento: $error\n$pila');
      throw TareasException('$mensaje [$error]');    }
  }

  @override
  Stream<List<Tarea>> observarTareas() {
    final consulta = _db.select(_db.tareas)
      ..orderBy([(t) => OrderingTerm.asc(t.id)]);
    return consulta.watch().map((filas) => filas.map(_aModelo).toList());
  }

  @override
  Future<Tarea> agregar(String titulo) async {
    final limpio = validarTitulo(titulo);
    return _proteger('No se pudo guardar la tarea.', () async {
      final id = await _db
          .into(_db.tareas)
          .insert(TareasCompanion.insert(titulo: limpio));
      return Tarea(id: id, titulo: limpio, completada: false);
    });
  }

  @override
  Future<void> editarTitulo(int id, String titulo) async {
    final limpio = validarTitulo(titulo);
    await _proteger('No se pudo actualizar el título.', () async {
      final filas = await (_db.update(_db.tareas)
            ..where((t) => t.id.equals(id)))
          .write(TareasCompanion(titulo: Value(limpio)));
      if (filas == 0) {
        throw const TareasException('La tarea ya no existe.');
      }
    });
  }

  @override
  Future<void> cambiarEstado(int id, bool completada) {
    return _proteger('No se pudo cambiar el estado de la tarea.', () async {
      final filas = await (_db.update(_db.tareas)
            ..where((t) => t.id.equals(id)))
          .write(TareasCompanion(completada: Value(completada)));
      if (filas == 0) {
        throw const TareasException('La tarea ya no existe.');
      }
    });
  }

  @override
  Future<void> eliminar(int id) {
    return _proteger('No se pudo eliminar la tarea.', () async {
      final filas =
          await (_db.delete(_db.tareas)..where((t) => t.id.equals(id))).go();
      if (filas == 0) {
        throw const TareasException('La tarea ya no existe.');
      }
    });
  }
}
