class StoragePaths {
  StoragePaths._();

  static const bucket = 'alunos-fotos';
  static const alunosFolder = 'alunos';
  static const instrumentosFolder = 'instrumentos';
  static const atestadosFolder = 'atestados';

  static String alunoObjectPath(String safeFileName, int timestampMs) {
    return '$alunosFolder/${timestampMs}_$safeFileName';
  }

  static String instrumentoObjectPath(String safeFileName, int timestampMs) {
    return '$instrumentosFolder/${timestampMs}_$safeFileName';
  }

  static String atestadoObjectPath({
    required int idAluno,
    required String dataIso,
    required String safeFileName,
    required int timestampMs,
  }) {
    return '$atestadosFolder/$idAluno/$dataIso/${timestampMs}_$safeFileName';
  }
}
