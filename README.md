# Gestor de tareas con SQLite (Flutter, multiplataforma)

Aplicación Flutter que administra tareas con una base de datos **SQLite local**, sin servidor, sin MySQL y sin conexión a internet. Práctica de Programación de Dispositivos Móviles (UAA, Ingeniería en Sistemas Computacionales).

Funciones: agregar, listar, editar el título, marcar como completada/pendiente y eliminar tareas. Los datos se conservan al cerrar y volver a abrir la aplicación.

## Tecnología de persistencia elegida

Se eligió **Drift** con **drift_flutter**:

- Con una sola base de código, `drift_flutter` abre SQLite nativo en Android, iOS, Windows, Linux y macOS, y SQLite compilado a WebAssembly en web.
- La tabla se define en Dart y Drift genera el código de acceso tipado (con `build_runner`).
- Alternativas como `sqflite` requieren paquetes distintos para escritorio y web.

Versiones usadas: Flutter 3.47.4, drift 2.35.4, drift_flutter 0.3.1, sqlite3 3.5.2.

## Diseño de la tabla

Tabla `tareas`. Cada registro se identifica con `id`, un entero autoincremental (clave primaria) que nunca se reutiliza.

| Campo           | Tipo en SQLite  | Restricciones                                          |
|---              |---              |---                                                     |
| `id`            | INTEGER         | Clave primaria, autoincremental                        |
| `titulo`        | TEXT            | NOT NULL, longitud de 1 a 120 (CHECK)                  |
| `completada`    | INTEGER (0/1)   | NOT NULL, por defecto 0 (pendiente), CHECK IN (0, 1)   |

Validación del título: se recortan espacios al inicio y al final, y se rechazan los títulos vacíos, los formados solo por espacios y los de más de 120 caracteres. La validación se aplica en la interfaz (límite de caracteres), en el repositorio (`validarTitulo`) y en la propia tabla (CHECK).

## Decisiones de diseño

- **Capa de datos separada de la interfaz** (`lib/data/`). La pantalla depende de una interfaz (`TareasRepositorio`), no de Drift, lo que permite probarla con un repositorio en memoria.
- **Consulta reactiva (Stream):** la pantalla se suscribe en `initState` a `watch()` de Drift y la lista se actualiza sola tras cada escritura. No hay consultas dentro de `build()`.
- **Errores de almacenamiento:** se convierten en mensajes comprensibles (`TareasException`) y se muestran con un aviso.
- **Recursos:** la base se abre al crear la pantalla y se cierra en `dispose()`.

## Estructura del proyecto

```text
lib/
  main.dart                          Arranque de la aplicación y tema
  models/tarea.dart                  Modelo de dominio (id, título, completada)
  data/
    app_database.dart                Tabla Tareas y apertura de la base (Drift)
    app_database.g.dart              Código generado por build_runner (incluido en el repo)
    tareas_repositorio.dart          Interfaz del repositorio, validación y errores
    tareas_repositorio_drift.dart    Implementación del CRUD sobre SQLite
  screens/tareas_page.dart           Pantalla: alta, lista, edición, estado y borrado
test/
  widget_test.dart                   Prueba básica de arranque
  tareas_page_test.dart              Pruebas de interfaz (repositorio en memoria)
  validacion_titulo_test.dart        Pruebas de validación de títulos
  tareas_repositorio_drift_test.dart Pruebas de CRUD y persistencia con SQLite real
  support/repositorio_en_memoria.dart Repositorio falso para pruebas de interfaz
web/
  drift_worker.dart                  Código fuente del worker de Drift
  drift_worker.dart.js               Worker compilado
  sqlite3.wasm                       SQLite en WebAssembly
```

## Cómo ejecutarlo

Requisitos: Flutter instalado (`flutter doctor -v`). Para Windows se necesita Visual Studio con la carga "Desarrollo para el escritorio con C++".

```bash
git clone https://github.com/AngelGaelAndrade/gestor_tareas_local.git
cd gestor_tareas_local
flutter pub get
```

Ejecutar en escritorio (Windows):

```bash
flutter run -d windows
```

Ejecutar en web (puerto fijo para que los datos del navegador no cambien de origen entre ejecuciones; abrir `http://localhost:5000` en Chrome):

```bash
flutter run -d web-server --web-port=5000
```

También sirve `flutter run -d chrome`, aunque ese modo abre un navegador temporal con un puerto distinto cada vez.

`app_database.g.dart` ya viene incluido. Solo si se modifica la tabla hay que regenerarlo:

```bash
dart run build_runner build
```

## Configuración de web

La base en el navegador necesita dos archivos en `web/`, que ya están en el repositorio:

- `drift_worker.dart.js`: worker de Drift, compilado a partir de `web/drift_worker.dart` con la versión de drift instalada:

  ```bash
  dart compile js -O4 web/drift_worker.dart -o web/drift_worker.dart.js
  ```

- `sqlite3.wasm`: debe corresponder a la versión del paquete **`sqlite3`** que aparece en `pubspec.lock` (aquí 3.5.2). Se descarga de los releases de `sqlite3.dart` (por ejemplo, la etiqueta `sqlite3-3.5.2`).

  Un `.wasm` más nuevo que el paquete instalado produce el error `LinkError: ... "xFileSize64": function import requires a callable`, que apareció durante el desarrollo.

## Pruebas automatizadas

```bash
flutter analyze
flutter test
```

Cubren: validación de títulos (vacío, solo espacios, recorte y límite de 120); CRUD sobre SQLite en memoria (incluidos ids inexistentes y la restricción de la tabla); persistencia al cerrar y reabrir un archivo de base de datos real; e interfaz con un repositorio en memoria (alta, validación, cambio de estado, edición y eliminación).

## Pruebas manuales P1 a P6

| ID  | Acción                                                                            | Resultado esperado       |
|---  |---                                                                                |---                       |
| P1  | Agregar tres tareas, cerrar completamente la app y abrirla de nuevo               | Permanecen las tres      |
| P2  | Marcar una como completada y reiniciar                                            | Se conserva el estado    |
| P3  | Cambiar el título de una tarea y reiniciar                                        | Aparece el nuevo título  |
| P4  | Eliminar una tarea y reiniciar                                                    | No reaparece             |
| P5  | Intentar agregar un título vacío                                                  | No se registra la tarea  |
| P6  | En el navegador: recargar y cerrar/abrir la pestaña, en el mismo origen y perfil  | Los datos permanecen     |


## Plataformas

- **Verificadas:** Windows y Chrome. empleando Chrome que pese a ser una plataforma web, se adapto la pantalla para simular la vista de una pantalla telefonica convencional.
- **Previstas por el diseño, no probadas:** Android (almenos en android studio), iOS, macOS y Linux

iOS y macOS se compilan solo en macOS con Xcode, Windows solo desde Windows y Linux desde Linux.

## Limitaciones

- Los datos son locales a cada instalación y plataforma; no hay sincronización entre dispositivos.
- En web, los datos pertenecen al origen (incluido el puerto) y al perfil del navegador, y se pierden en modo incógnito o al borrar los datos del sitio.

## Referencias

- https://drift.simonbinder.eu/
- https://drift.simonbinder.eu/platforms/web/
- https://pub.dev/packages/drift_flutter
- https://docs.flutter.dev/data-and-backend/persistence/sqlite