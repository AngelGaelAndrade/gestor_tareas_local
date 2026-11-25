import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/app_database.dart';
import '../data/tareas_repositorio.dart';
import '../data/tareas_repositorio_drift.dart';
import '../models/tarea.dart';

// Pantalla con persistencia SQLite (Drift) y operaciones CRUD.
// La lista se alimenta de una suscripción creada en initState: build() solo
// dibuja _tareas y nunca consulta la base de datos.
class TareasPage extends StatefulWidget {
  const TareasPage({super.key, this.repositorio});

  /// Solo para pruebas. Si es null, la pantalla abre la base SQLite real.
  final TareasRepositorio? repositorio;

  @override
  State<TareasPage> createState() => _TareasPageState();
}

class _TareasPageState extends State<TareasPage> {
  final TextEditingController _tituloController = TextEditingController();

  late final TareasRepositorio _repositorio;
  AppDatabase? _baseDeDatos; // solo si la pantalla abrió la base ella misma
  StreamSubscription<List<Tarea>>? _suscripcion;

  List<Tarea> _tareas = [];
  bool _cargando = true;
  String? _errorCarga;

  @override
  void initState() {
    super.initState();

    final inyectado = widget.repositorio;
    if (inyectado != null) {
      _repositorio = inyectado;
    } else {
      final baseDeDatos = AppDatabase();
      _baseDeDatos = baseDeDatos;
      _repositorio = TareasRepositorioDrift(baseDeDatos);
    }

    // Cada cambio en la tabla vuelve a emitir la lista completa.
    _suscripcion = _repositorio.observarTareas().listen(
      (tareas) {
        if (!mounted) return;
        setState(() {
          _tareas = tareas;
          _cargando = false;
          _errorCarga = null;
        });
      },
      onError: (Object error) {
        if (!mounted) return;
        setState(() {
          _cargando = false;
          _errorCarga = 'No se pudieron cargar las tareas guardadas.';
        });
      },
    );
  }

  /// Ejecuta una operación y muestra un mensaje si falla.
  /// Devuelve true cuando terminó bien.
  Future<bool> _ejecutar(Future<void> Function() accion) async {
    try {
      await accion();
      return true;
    } on TareasException catch (error) {
      _mostrarMensaje(error.mensaje);
    } catch (_) {
      _mostrarMensaje('Ocurrió un error inesperado. Inténtalo de nuevo.');
    }
    return false;
  }

  Future<void> _agregarTarea() async {
    final guardada = await _ejecutar(
      () => _repositorio.agregar(_tituloController.text),
    );
    if (guardada && mounted) {
      _tituloController.clear();
    }
  }

  Future<void> _alternarCompletada(Tarea tarea, bool completada) async {
    await _ejecutar(() => _repositorio.cambiarEstado(tarea.id, completada));
  }

  Future<void> _editarTarea(Tarea tarea) async {
    final nuevoTitulo = await showDialog<String>(
      context: context,
      builder: (_) => _DialogoEditarTitulo(tituloActual: tarea.titulo),
    );
    if (nuevoTitulo == null || !mounted || nuevoTitulo == tarea.titulo) return;
    await _ejecutar(() => _repositorio.editarTitulo(tarea.id, nuevoTitulo));
  }

  Future<void> _eliminarTarea(Tarea tarea) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (contextoDialogo) => AlertDialog(
        title: const Text('Eliminar tarea'),
        content: Text('¿Eliminar "${tarea.titulo}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(contextoDialogo).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(contextoDialogo).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmado != true || !mounted) return;
    await _ejecutar(() => _repositorio.eliminar(tarea.id));
  }

  void _mostrarMensaje(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(mensaje)));
  }

  @override
  void dispose() {
    _suscripcion?.cancel();
    _tituloController.dispose();
    _baseDeDatos?.close(); // libera la conexión si la abrió esta pantalla
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gestor de tareas')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _tituloController,
              textInputAction: TextInputAction.done,
              inputFormatters: [
                LengthLimitingTextInputFormatter(longitudMaximaTitulo),
              ],
              onSubmitted: (_) => _agregarTarea(),
              decoration: const InputDecoration(
                labelText: 'Nueva tarea',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: _agregarTarea,
              icon: const Icon(Icons.add),
              label: const Text('Agregar tarea'),
            ),
            const SizedBox(height: 12),
            const Text('Mis tareas', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Expanded(
              child: _cargando
                  ? const Center(child: CircularProgressIndicator())
                  : _errorCarga != null
                      ? Center(child: Text(_errorCarga!))
                      : _tareas.isEmpty
                          ? const Center(
                              child: Text('Todavía no hay tareas guardadas'),
                            )
                          : ListView.builder(
                              itemCount: _tareas.length,
                              itemBuilder: (context, index) {
                                final tarea = _tareas[index];
                                return Card(
                                  child: ListTile(
                                    leading: Checkbox(
                                      value: tarea.completada,
                                      onChanged: (valor) {
                                        if (valor != null) {
                                          _alternarCompletada(tarea, valor);
                                        }
                                      },
                                    ),
                                    title: Text(
                                      tarea.titulo,
                                      style: TextStyle(
                                        decoration: tarea.completada
                                            ? TextDecoration.lineThrough
                                            : null,
                                      ),
                                    ),
                                    subtitle: Text(  
                                                    'ID: ${tarea.id} · ${tarea.completada ? 'Completada' : 'Pendiente'}',
                                                  ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          tooltip: 'Editar',
                                          icon: const Icon(Icons.edit),
                                          onPressed: () => _editarTarea(tarea),
                                        ),
                                        IconButton(
                                          tooltip: 'Eliminar',
                                          icon: const Icon(
                                            Icons.delete_outline,
                                          ),
                                          onPressed: () =>
                                              _eliminarTarea(tarea),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Diálogo para editar el título. Valida antes de cerrarse y devuelve el
/// título ya limpio, o null si se cancela.
class _DialogoEditarTitulo extends StatefulWidget {
  const _DialogoEditarTitulo({required this.tituloActual});

  final String tituloActual;

  @override
  State<_DialogoEditarTitulo> createState() => _DialogoEditarTituloState();
}

class _DialogoEditarTituloState extends State<_DialogoEditarTitulo> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.tituloActual);
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _guardar() {
    try {
      Navigator.of(context).pop(validarTitulo(_controller.text));
    } on TareasException catch (error) {
      setState(() => _error = error.mensaje);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar título'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        inputFormatters: [
          LengthLimitingTextInputFormatter(longitudMaximaTitulo),
        ],
        onSubmitted: (_) => _guardar(),
        decoration: InputDecoration(
          labelText: 'Título',
          errorText: _error,
          border: const OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _guardar,
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
