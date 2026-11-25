import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

// Archivo generado por build_runner:
//   dart run build_runner build --delete-conflicting-outputs
part 'app_database.g.dart';

/// Tabla `tareas`.
///
/// - id: entero autoincremental (clave primaria).
/// - titulo: texto de 1 a 120 caracteres (la restricción también existe en SQLite).
/// - completada: booleano (SQLite lo guarda como 0/1), pendiente por defecto.
///
/// El nombre de la clase de fila se cambia a [TareaFila] para no chocar con el
/// modelo de dominio `Tarea` de lib/models.
@DataClassName('TareaFila')
class Tareas extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get titulo => text().withLength(min: 1, max: 120)();
  BoolColumn get completada => boolean().withDefault(const Constant(false))();
}

@DriftDatabase(tables: [Tareas])
class AppDatabase extends _$AppDatabase {
  /// Base persistente real (archivo nativo o SQLite WebAssembly en web).
  AppDatabase() : super(_abrirConexion());

  /// Permite inyectar otro ejecutor, por ejemplo una base en memoria en pruebas.
  AppDatabase.conExecutor(super.executor);

  @override
  int get schemaVersion => 1;

  static QueryExecutor _abrirConexion() {
    return driftDatabase(
      name: 'gestor_tareas',
      // Solo se usa en web: archivos que deben estar en la carpeta web/.
      web: DriftWebOptions(
        sqlite3Wasm: Uri.parse('sqlite3.wasm'),
        driftWorker: Uri.parse('drift_worker.dart.js'),
      ),
    );
  }
}
