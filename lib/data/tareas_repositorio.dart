import '../models/tarea.dart';

/// Longitud máxima del título. Debe coincidir con la tabla en app_database.dart.
const int longitudMaximaTitulo = 120;

/// Error con un mensaje comprensible para mostrar al usuario.
class TareasException implements Exception {
  const TareasException(this.mensaje);

  final String mensaje;

  @override
  String toString() => 'TareasException: $mensaje';
}

/// Quita espacios sobrantes y valida el título.
/// Lanza [TareasException] si está vacío, solo tiene espacios o es muy largo.
String validarTitulo(String? titulo) {
  final limpio = (titulo ?? '').trim();
  if (limpio.isEmpty) {
    throw const TareasException('El título no puede estar vacío.');
  }
  if (limpio.length > longitudMaximaTitulo) {
    throw const TareasException(
      'El título no puede superar los $longitudMaximaTitulo caracteres.',
    );
  }
  return limpio;
}

/// Contrato de la capa de datos. La interfaz no conoce Drift, así que la
/// pantalla se puede probar con una implementación en memoria.
abstract class TareasRepositorio {
  /// Emite la lista completa cada vez que cambia la tabla.
  Stream<List<Tarea>> observarTareas();

  Future<Tarea> agregar(String titulo);

  Future<void> editarTitulo(int id, String titulo);

  Future<void> cambiarEstado(int id, bool completada);

  Future<void> eliminar(int id);
}
