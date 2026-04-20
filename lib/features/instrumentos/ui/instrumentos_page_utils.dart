class InstrumentosPageUtils {
  const InstrumentosPageUtils._();

  static String texto(Map<String, dynamic> item, List<String> chaves) {
    for (final chave in chaves) {
      final valor = item[chave];
      if (valor != null) return valor.toString();
    }
    return '';
  }

  static bool boolValue(Map<String, dynamic> item, List<String> chaves) {
    for (final chave in chaves) {
      final valor = item[chave];
      if (valor is bool) return valor;
      if (valor is num) return valor != 0;
      if (valor is String) {
        final normalizado = valor.trim().toLowerCase();
        if (normalizado == 'true' ||
            normalizado == '1' ||
            normalizado == 'sim' ||
            normalizado == 'disponivel' ||
            normalizado == 'disponível') {
          return true;
        }
        if (normalizado == 'false' ||
            normalizado == '0' ||
            normalizado == 'nao' ||
            normalizado == 'não' ||
            normalizado == 'indisponivel' ||
            normalizado == 'indisponível') {
          return false;
        }
      }
    }
    return false;
  }

  static String nomeAluno(
    Map<String, dynamic> item,
    Map<int, String> nomesAlunosPorId,
  ) {
    final alunoId = item['id_aluno'];
    final id = alunoId is int
        ? alunoId
        : int.tryParse(alunoId?.toString() ?? '');
    if (id == null) return '';
    return nomesAlunosPorId[id] ?? '';
  }
}

class InstrumentoListItemData {
  const InstrumentoListItemData({
    required this.idInstrumento,
    required this.nome,
    required this.patrimonio,
    required this.status,
    required this.alunoNome,
    required this.propriedade,
    required this.levaInstrumento,
    required this.observacoes,
    required this.imageUrl,
  });

  final dynamic idInstrumento;
  final String nome;
  final String patrimonio;
  final String status;
  final String alunoNome;
  final String propriedade;
  final bool levaInstrumento;
  final String observacoes;
  final String imageUrl;

  factory InstrumentoListItemData.fromMap(
    Map<String, dynamic> item, {
    required Map<int, String> nomesAlunosPorId,
  }) {
    final disponivel = InstrumentosPageUtils.boolValue(item, ['disponivel']);
    return InstrumentoListItemData(
      idInstrumento: item['id_instrumento'],
      nome: InstrumentosPageUtils.texto(item, ['nome_instrumento']),
      patrimonio: InstrumentosPageUtils.texto(item, ['numero_patrimonio']),
      status: disponivel ? 'Disponível' : 'Indisponível',
      alunoNome: InstrumentosPageUtils.nomeAluno(item, nomesAlunosPorId),
      propriedade: InstrumentosPageUtils.texto(item, [
        'propriedade_instrumento',
      ]),
      levaInstrumento: InstrumentosPageUtils.boolValue(item, [
        'leva_instrumento',
      ]),
      observacoes: InstrumentosPageUtils.texto(item, ['observacoes']),
      imageUrl: InstrumentosPageUtils.texto(item, ['imagem_url']),
    );
  }
}
