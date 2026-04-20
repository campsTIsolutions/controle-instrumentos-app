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

  final List<Map<String, dynamic>> alunos;
  final int currentPage;
  final int itensPorPagina;
  final bool isTablet;
  final void Function(Map<String, dynamic>) onEditar;
  final void Function(Map<String, dynamic>) onDeletar;

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
