import 'dart:async';

import 'package:controle_instrumentos/features/alunos/alunos_page.dart';
import 'package:controle_instrumentos/features/alunos/models/aluno_record.dart';
import 'package:controle_instrumentos/features/alunos/repository/alunos_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAlunosRepository implements AlunosRepositoryContract {
  _FakeAlunosRepository({required this.listarHandler});

  final Future<AlunosPageResult> Function({
    required int page,
    required int itemsPerPage,
    required String query,
    required List<String> categorias,
    required List<String> setores,
    required bool ordenarAlfabetico,
  })
  listarHandler;

  @override
  Future<AlunosPageResult> listarAlunosPaginados({
    required int page,
    required int itemsPerPage,
    String query = '',
    List<String> categorias = const [],
    List<String> setores = const [],
    bool ordenarAlfabetico = false,
  }) {
    return listarHandler(
      page: page,
      itemsPerPage: itemsPerPage,
      query: query,
      categorias: categorias,
      setores: setores,
      ordenarAlfabetico: ordenarAlfabetico,
    );
  }

  @override
  Future<void> registrarExclusaoEDeletar({
    required AlunoRecord aluno,
    required String motivoExclusao,
  }) async {}

  @override
  Future<void> salvarAluno({
    required Map<String, dynamic> dados,
    int? idAluno,
  }) async {}

  @override
  Future<String> uploadFotoAluno({
    required List<int> bytes,
    required String originalFileName,
  }) async {
    return 'https://example.com/foto.png';
  }
}

Widget _buildTestable(Widget child) {
  return MaterialApp(
    routes: {
      '/instrumentos': (_) => const Scaffold(body: Text('Instrumentos')),
      '/chamada': (_) => const Scaffold(body: Text('Chamada')),
      '/alunos': (_) => const Scaffold(body: Text('Alunos')),
      '/historico': (_) => const Scaffold(body: Text('Historico')),
    },
    home: child,
  );
}

void main() {
  testWidgets('shows loading before first response resolves', (tester) async {
    final completer = Completer<AlunosPageResult>();
    final repository = _FakeAlunosRepository(
      listarHandler:
          ({
            required page,
            required itemsPerPage,
            required query,
            required categorias,
            required setores,
            required ordenarAlfabetico,
          }) => completer.future,
    );

    await tester.pumpWidget(_buildTestable(AlunosPage(repository: repository)));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    completer.complete(const AlunosPageResult(items: [], total: 0, page: 1));
    await tester.pumpAndSettle();

    expect(find.text('Nenhum aluno encontrado.'), findsOneWidget);
  });

  testWidgets('shows empty state when repository returns no students', (
    tester,
  ) async {
    final repository = _FakeAlunosRepository(
      listarHandler:
          ({
            required page,
            required itemsPerPage,
            required query,
            required categorias,
            required setores,
            required ordenarAlfabetico,
          }) async => const AlunosPageResult(items: [], total: 0, page: 1),
    );

    await tester.pumpWidget(_buildTestable(AlunosPage(repository: repository)));
    await tester.pumpAndSettle();

    expect(find.text('Nenhum aluno encontrado.'), findsOneWidget);
  });

  testWidgets('shows list item when repository returns data', (tester) async {
    final repository = _FakeAlunosRepository(
      listarHandler:
          ({
            required page,
            required itemsPerPage,
            required query,
            required categorias,
            required setores,
            required ordenarAlfabetico,
          }) async => const AlunosPageResult(
            items: [
              AlunoRecord(
                idAluno: 1,
                numeroAluno: '101',
                nomeCompleto: 'Maria Teste',
                setor: 'Dança',
                categoriaUsuario: 'Aprendiz',
                nivel: 'Iniciante',
                telefone: '11999999999',
                imagemUrl: null,
                idade: 15,
              ),
            ],
            total: 1,
            page: 1,
          ),
    );

    await tester.pumpWidget(_buildTestable(AlunosPage(repository: repository)));
    await tester.pumpAndSettle();

    expect(find.text('Maria Teste'), findsOneWidget);
    expect(find.text('1 alunos'), findsOneWidget);
  });

  testWidgets('shows snackbar when initial load fails', (tester) async {
    final repository = _FakeAlunosRepository(
      listarHandler:
          ({
            required page,
            required itemsPerPage,
            required query,
            required categorias,
            required setores,
            required ordenarAlfabetico,
          }) async {
            throw Exception('falha-repo-alunos');
          },
    );

    await tester.pumpWidget(_buildTestable(AlunosPage(repository: repository)));
    await tester.pumpAndSettle();

    expect(find.textContaining('Erro ao carregar alunos:'), findsOneWidget);
  });
}
