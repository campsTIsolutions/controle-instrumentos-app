import 'package:controle_instrumentos/features/alunos/models/aluno_record.dart';
import 'package:controle_instrumentos/features/alunos/widgets/alunos_list/alunos_cards.dart';
import 'package:controle_instrumentos/features/alunos/widgets/alunos_list/alunos_table.dart';
import 'package:flutter/material.dart';

class AlunosList extends StatelessWidget {
  const AlunosList({
    super.key,
    required this.alunos,
    required this.currentPage,
    required this.itensPorPagina,
    required this.isTablet,
    required this.onEditar,
    required this.onDeletar,
  });

  final List<AlunoRecord> alunos;
  final int currentPage;
  final int itensPorPagina;
  final bool isTablet;
  final void Function(AlunoRecord) onEditar;
  final void Function(AlunoRecord) onDeletar;

  @override
  Widget build(BuildContext context) {
    return isTablet
        ? AlunosTable(
            alunos: alunos,
            currentPage: currentPage,
            itensPorPagina: itensPorPagina,
            onEditar: onEditar,
            onDeletar: onDeletar,
          )
        : AlunosCards(
            alunos: alunos,
            currentPage: currentPage,
            itensPorPagina: itensPorPagina,
            onEditar: onEditar,
            onDeletar: onDeletar,
          );
  }
}
