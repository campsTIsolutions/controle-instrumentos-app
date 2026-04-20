class AlunoRecord {
  const AlunoRecord({
    required this.idAluno,
    required this.numeroAluno,
    required this.nomeCompleto,
    required this.setor,
    required this.categoriaUsuario,
    required this.nivel,
    required this.telefone,
    required this.imagemUrl,
    required this.idade,
  });

  final int idAluno;
  final String numeroAluno;
  final String nomeCompleto;
  final String setor;
  final String categoriaUsuario;
  final String nivel;
  final String telefone;
  final String? imagemUrl;
  final int? idade;

  factory AlunoRecord.fromMap(Map<String, dynamic> map) {
    return AlunoRecord(
      idAluno: map['id_aluno'] as int,
      numeroAluno: map['numero_aluno']?.toString() ?? '',
      nomeCompleto: map['nome_completo']?.toString() ?? '',
      setor: map['setor']?.toString() ?? '',
      categoriaUsuario: map['categoria_usuario']?.toString() ?? '',
      nivel: map['nivel']?.toString() ?? '',
      telefone: map['telefone']?.toString() ?? '',
      imagemUrl: map['imagem_url']?.toString(),
      idade: map['idade'] is int ? map['idade'] as int : int.tryParse(map['idade']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id_aluno': idAluno,
      'numero_aluno': numeroAluno,
      'nome_completo': nomeCompleto,
      'setor': setor,
      'categoria_usuario': categoriaUsuario,
      'nivel': nivel,
      'telefone': telefone,
      'imagem_url': imagemUrl,
      'idade': idade,
    };
  }
}
