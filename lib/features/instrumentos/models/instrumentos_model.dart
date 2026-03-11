class Instrumentos {
  final int? id_instrumento;
  final String numero_patrimonio;
  final String nome_instrumento;
  final String disponibilidade;
  final String propriedade_instrumento;
  final bool emprestimo;
  final String foto_url;
  final String? observacao;

  Instrumentos({
    this.id_instrumento,
    required this.numero_patrimonio,
    required this.nome_instrumento,
    required this.disponibilidade,
    required this.propriedade_instrumento,
    required this.emprestimo,
    required this.foto_url,
    this.observacao,
  });

  // Converte o JSON do Supabase para o objeto Dart
  factory Instrumentos.fromJson(Map<String, dynamic> json) {
    return Instrumentos(
      id_instrumento: json['id_instrumento'],
      numero_patrimonio: json['numero_patrimonio'] ?? '',
      nome_instrumento: json['nome_instrumento'] ?? '',
      disponibilidade: json['disponibilidade'] ?? '',
      propriedade_instrumento: json['propriedade_instrumento'] ?? '',
      emprestimo: json['emprestimo'] ?? false,
      foto_url: json['foto_url'] ?? '',
      observacao: json['observacao'],
    );
  }

  // Converte o objeto Dart para JSON (para enviar ao Supabase)
  Map<String, dynamic> toJson() {
    return {
      if (id_instrumento != null) 'id_instrumento': id_instrumento,
      'numero_patrimonio': numero_patrimonio,
      'nome_instrumento': nome_instrumento,
      'disponibilidade': disponibilidade,
      'propriedade_instrumento': propriedade_instrumento,
      'emprestimo': emprestimo,
      'foto_url': foto_url,
      'observacao': observacao,
    };
  }
}