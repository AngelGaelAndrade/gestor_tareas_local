import 'dart:async';

import 'package:gestor_tareas_local/data/tareas_repositorio.dart';
import 'package:gestor_tareas_local/models/tarea.dart';

/// Repositorio falso solo para pruebas de interfaz (no usa SQLite).
/// Aplica la misma validación que la implementación real.
class RepositorioEnMemoria implements TareasRepositorio {
  final List<Tarea> _tareas = [];
  final StreamController<List<Tarea>> _cambios =
      StreamController<List<Tarea>>.broadcast();
  int _siguienteId = 1;

  void _emitir() => _cambios.add(List.unmodifiable(_tareas));

  int _indiceDe(int id) {
    final indice = _tareas.indexWhere((t) => t.id == id);
    if (indice == -1) throw const TareasException('La tarea ya no existe.');
    return indice;
  }

  @override
  Stream<List<Tarea>> observarTareas() async* {
    yield List.unmodifiable(_tareas);
    yield* _cambios.stream;
  }

  @override
  Future<Tarea> agregar(String titulo) async {
    final tarea = Tarea(
      id: _siguienteId++,
      titulo: validarTitulo(titulo),
      completada: false,
    );
    _tareas.add(tarea);
    _emitir();
    return tarea;
  }

  @override
  Future<void> editarTitulo(int id, String titulo) async {
    final limpio = validarTitulo(titulo);
    final indice = _indiceDe(id);
    final actual = _tareas[indice];
    _tareas[indice] = Tarea(
      id: actual.id,
      titulo: limpio,
      completada: actual.completada,
    );
    _emitir();
  }

  @override
  Future<void> cambiarEstado(int id, bool completada) async {
    final indice = _indiceDe(id);
    final actual = _tareas[indice];
    _tareas[indice] = Tarea(
      id: actual.id,
      titulo: actual.titulo,
      completada: completada,
    );
    _emitir();
  }

  @override
  Future<void> eliminar(int id) async {
    _tareas.removeAt(_indiceDe(id));
    _emitir();
  }
}
