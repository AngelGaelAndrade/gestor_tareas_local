import 'package:flutter_test/flutter_test.dart';
import 'package:gestor_tareas_local/data/tareas_repositorio.dart';

void main() {
  group('validarTitulo', () {
    test('rechaza títulos vacíos o nulos', () {
      expect(() => validarTitulo(''), throwsA(isA<TareasException>()));
      expect(() => validarTitulo(null), throwsA(isA<TareasException>()));
    });

    test('rechaza títulos formados solo por espacios', () {
      expect(() => validarTitulo('    '), throwsA(isA<TareasException>()));
      expect(() => validarTitulo('\t \n'), throwsA(isA<TareasException>()));
    });

    test('recorta espacios al inicio y al final', () {
      expect(validarTitulo('  Leer  apuntes  '), 'Leer  apuntes');
    });

    test('acepta exactamente la longitud máxima y rechaza una más', () {
      final limite = 'a' * longitudMaximaTitulo;
      expect(validarTitulo(limite), limite);
      expect(
        () => validarTitulo('${limite}a'),
        throwsA(isA<TareasException>()),
      );
    });
  });
}
