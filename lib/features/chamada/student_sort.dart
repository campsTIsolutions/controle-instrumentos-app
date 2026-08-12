import 'models.dart';

/// Retorna uma nova lista de alunos em ordem alfabética pelo nome.
///
/// A comparação ignora caixa e os acentos mais comuns em nomes em português,
/// para que, por exemplo, "Álvaro" seja agrupado com os nomes iniciados por A.
List<StudentRecord> ordenarAlunosPorNome(Iterable<StudentRecord> alunos) {
  return alunos.toList()..sort(compararAlunosPorNome);
}

int compararAlunosPorNome(StudentRecord primeiro, StudentRecord segundo) {
  final comparacao = _chaveAlfabetica(
    primeiro.name,
  ).compareTo(_chaveAlfabetica(segundo.name));

  if (comparacao != 0) return comparacao;
  return primeiro.idAluno.compareTo(segundo.idAluno);
}

String _chaveAlfabetica(String nome) {
  const comAcento = 'àáâãäåÀÁÂÃÄÅèéêëÈÉÊËìíîïÌÍÎÏòóôõöÒÓÔÕÖùúûüÙÚÛÜçÇñÑýÿÝ';
  const semAcento = 'aaaaaaAAAAAAeeeeEEEEiiiiIIIIoooooOOOOOuuuuUUUUcCnNyyY';

  var resultado = nome.trim().toLowerCase();
  for (var i = 0; i < comAcento.length; i++) {
    resultado = resultado.replaceAll(comAcento[i], semAcento[i]);
  }
  return resultado;
}
