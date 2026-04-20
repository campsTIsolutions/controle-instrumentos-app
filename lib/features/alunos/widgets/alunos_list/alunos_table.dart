import 'package:controle_instrumentos/shared/widgets/person_avatar.dart';
import 'package:controle_instrumentos/shared/widgets/table_action_button.dart';
import 'package:controle_instrumentos/shared/widgets/top_rounded_panel.dart';
import 'package:flutter/material.dart';

class AlunosTable extends StatelessWidget {
  const AlunosTable({
    super.key,
    required this.alunos,
    required this.currentPage,
    required this.itensPorPagina,
    required this.onEditar,
    required this.onDeletar,
  });

  final List<Map<String, dynamic>> alunos;
  final int currentPage;
  final int itensPorPagina;
  final void Function(Map<String, dynamic>) onEditar;
  final void Function(Map<String, dynamic>) onDeletar;

  @override
  Widget build(BuildContext context) {
    return TopRoundedPanel(
      child: Column(
        children: [
          const _TabelaHeader(),
          const Divider(height: 1),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: alunos.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (ctx, i) {
              final aluno = alunos[i];
              final numero = (currentPage - 1) * itensPorPagina + i + 1;
              return _TabelaLinha(
                numero: numero,
                aluno: aluno,
                onEditar: () => onEditar(aluno),
                onDeletar: () => onDeletar(aluno),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _TabelaHeader extends StatelessWidget {
  const _TabelaHeader();

  static const _s = TextStyle(
    fontWeight: FontWeight.w600,
    color: Color(0xFF6B7280),
    fontSize: 12,
  );

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          SizedBox(width: 28, child: Text('#', style: _s)),
          SizedBox(width: 48, child: Text('Nº', style: _s)),
          SizedBox(width: 44, child: Text('Foto', style: _s)),
          SizedBox(width: 130, child: Text('Nome', style: _s)),
          SizedBox(width: 40, child: Text('Idade', style: _s)),
          SizedBox(width: 70, child: Text('Setor', style: _s)),
          SizedBox(width: 90, child: Text('Categoria', style: _s)),
          SizedBox(width: 100, child: Text('Nível', style: _s)),
          Expanded(child: Text('Telefone', style: _s)),
          SizedBox(width: 72),
        ],
      ),
    );
  }
}

class _TabelaLinha extends StatelessWidget {
  const _TabelaLinha({
    required this.numero,
    required this.aluno,
    required this.onEditar,
    required this.onDeletar,
  });

  final int numero;
  final Map<String, dynamic> aluno;
  final VoidCallback onEditar;
  final VoidCallback onDeletar;

  static const _c = TextStyle(fontSize: 12, color: Color(0xFF111827));

  @override
  Widget build(BuildContext context) {
    final imagemUrl = aluno['imagem_url'] as String?;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '$numero',
              style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12),
            ),
          ),
          SizedBox(
            width: 48,
            child: Text(aluno['numero_aluno']?.toString() ?? '', style: _c),
          ),
          SizedBox(
            width: 44,
            child: PersonAvatar(
              imageUrl: imagemUrl,
              size: 32,
              radius: 6,
              backgroundColor: const Color(0xFFEFF6FF),
              iconColor: const Color(0xFF2563EB),
              iconSize: 16,
            ),
          ),
          SizedBox(
            width: 130,
            child: Text(
              aluno['nome_completo']?.toString() ?? '',
              style: _c,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            width: 40,
            child: Text(
              aluno['idade'] != null ? '${aluno['idade']}' : '-',
              style: _c,
            ),
          ),
          SizedBox(
            width: 70,
            child: Text(aluno['setor']?.toString() ?? '', style: _c),
          ),
          SizedBox(
            width: 90,
            child: Text(
              aluno['categoria_usuario']?.toString() ?? '',
              style: _c,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            width: 100,
            child: Text(
              aluno['nivel']?.toString() ?? '',
              style: _c,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            child: Text(
              aluno['telefone']?.toString() ?? '-',
              style: _c,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            width: 72,
            child: Row(
              children: [
                TableActionButton(
                  icon: Icons.edit,
                  color: const Color(0xFF2563EB),
                  onTap: onEditar,
                ),
                const SizedBox(width: 6),
                TableActionButton(
                  icon: Icons.delete,
                  color: const Color(0xFFB91C1C),
                  onTap: onDeletar,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
