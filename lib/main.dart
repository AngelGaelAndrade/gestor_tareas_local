import 'package:flutter/material.dart';
import 'data/tareas_repositorio.dart';
import 'screens/tareas_page.dart';

void main() {
  runApp(const GestorTareasApp());
}

/// Punto de entrada de la aplicación.
/// La base SQLite (Drift) la abre y la cierra TareasPage. Solo en pruebas se
/// inyecta un [repositorio] alterno para no depender del disco.
class GestorTareasApp extends StatelessWidget {
  const GestorTareasApp({super.key, this.repositorio});

  final TareasRepositorio? repositorio;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gestor de tareas',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: TareasPage(repositorio: repositorio),
    );
  }
}
