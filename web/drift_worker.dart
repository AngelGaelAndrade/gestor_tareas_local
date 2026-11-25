import 'package:drift/wasm.dart';

// Worker de Drift para web. Se compila a JavaScript con:
//   dart compile js -O4 web/drift_worker.dart -o web/drift_worker.dart.js
// Compilarlo con la versión instalada de drift evita incompatibilidades.
void main() => WasmDatabase.workerMainForOpen();
