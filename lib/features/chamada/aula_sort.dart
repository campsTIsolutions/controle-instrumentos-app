import 'models.dart';

/// Retorna uma nova lista de aulas em ordem cronológica crescente.
List<AulaRecord> ordenarAulasPorData(Iterable<AulaRecord> aulas) {
  return aulas.toList()..sort((primeira, segunda) {
    final comparacaoData = primeira.data.compareTo(segunda.data);
    if (comparacaoData != 0) return comparacaoData;
    return primeira.id.compareTo(segunda.id);
  });
}
