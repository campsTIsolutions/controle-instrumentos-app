class HistoricoLogRecord {
  const HistoricoLogRecord({
    required this.idLog,
    required this.idAluno,
    required this.numeroAluno,
    required this.nomeCompleto,
    required this.setor,
    required this.categoriaUsuario,
    required this.nivel,
    required this.telefone,
    required this.imagemUrl,
    required this.idade,
    required this.motivoExclusao,
    required this.dataExclusao,
  });

  final int idLog;
  final int? idAluno;
  final String numeroAluno;
  final String nomeCompleto;
  final String setor;
  final String categoriaUsuario;
  final String nivel;
  final String telefone;
  final String? imagemUrl;
  final int? idade;
  final String motivoExclusao;
  final String? dataExclusao;

  factory HistoricoLogRecord.fromMap(Map<String, dynamic> map) {
    return HistoricoLogRecord(
      idLog: map['id_log'] as int,
      idAluno: map['id_aluno'] is int ? map['id_aluno'] as int : int.tryParse(map['id_aluno']?.toString() ?? ''),
      numeroAluno: map['numero_aluno']?.toString() ?? '',
      nomeCompleto: map['nome_completo']?.toString() ?? '',
      setor: map['setor']?.toString() ?? '',
      categoriaUsuario: map['categoria_usuario']?.toString() ?? '',
      nivel: map['nivel']?.toString() ?? '',
      telefone: map['telefone']?.toString() ?? '',
      imagemUrl: map['imagem_url']?.toString(),
      idade: map['idade'] is int ? map['idade'] as int : int.tryParse(map['idade']?.toString() ?? ''),
      motivoExclusao: map['motivo_exclusao']?.toString() ?? '',
      dataExclusao: map['data_exclusao']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id_log': idLog,
      'id_aluno': idAluno,
      'numero_aluno': numeroAluno,
      'nome_completo': nomeCompleto,
      'setor': setor,
      'categoria_usuario': categoriaUsuario,
      'nivel': nivel,
      'telefone': telefone,
      'imagem_url': imagemUrl,
      'idade': idade,
      'motivo_exclusao': motivoExclusao,
      'data_exclusao': dataExclusao,
    };
  }
}
