import 'dart:async';

import 'package:controle_instrumentos/features/alunos/alunos_page.dart';
import 'package:controle_instrumentos/features/alunos/models/aluno_record.dart';
import 'package:controle_instrumentos/features/alunos/repository/alunos_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAlunosRepository implements AlunosRepositoryContract {
  _FakeAlunosRepository({required this.listarHandler});

  final List<_ListarCall> calls = [];

  final Future<AlunosPageResult> Function(_ListarCall call) listarHandler;

  @override
  Future<AlunosPageResult> listarAlunosPaginados({
    required int page,
    required int itemsPerPage,
    String query = '',
    List<String> categorias = const [],
    List<String> setores = const [],
    bool ordenarAlfabetico = false,
  }) {
    final call = _ListarCall(
      page: page,
      itemsPerPage: itemsPerPage,
      query: query,
      categorias: categorias,
      setores: setores,
      ordenarAlfabetico: ordenarAlfabetico,
    );
    calls.add(call);
    return listarHandler(call);
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

class _ListarCall {
  const _ListarCall({
    required this.page,
    required this.itemsPerPage,
    required this.query,
    required this.categorias,
    required this.setores,
    required this.ordenarAlfabetico,
  });

  final int page;
  final int itemsPerPage;
  final String query;
  final List<String> categorias;
  final List<String> setores;
  final bool ordenarAlfabetico;
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
      listarHandler: (_) => completer.future,
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
      listarHandler: (_) async =>
          const AlunosPageResult(items: [], total: 0, page: 1),
    );

    await tester.pumpWidget(_buildTestable(AlunosPage(repository: repository)));
    await tester.pumpAndSettle();

    expect(find.text('Nenhum aluno encontrado.'), findsOneWidget);
  });

  testWidgets('shows list item when repository returns data', (tester) async {
    final repository = _FakeAlunosRepository(
      listarHandler: (_) async => const AlunosPageResult(
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

  testWidgets('search triggers repository call with debounced query', (
    tester,
  ) async {
    final repository = _FakeAlunosRepository(
      listarHandler: (_) async =>
          const AlunosPageResult(items: [], total: 0, page: 1),
    );

    await tester.pumpWidget(_buildTestable(AlunosPage(repository: repository)));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'maria');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(repository.calls.length, greaterThanOrEqualTo(2));
    expect(repository.calls.last.query, 'maria');
    expect(repository.calls.last.page, 1);
  });

  testWidgets('pagination next page fetches and renders new results', (
    tester,
  ) async {
    final repository = _FakeAlunosRepository(
      listarHandler: (call) async {
        if (call.page == 1) {
          return const AlunosPageResult(
            items: [
              AlunoRecord(
                idAluno: 1,
                numeroAluno: '1',
                nomeCompleto: 'Aluno Página 1',
                setor: 'Linha',
                categoriaUsuario: 'Kids',
                nivel: 'Iniciante',
                telefone: '',
                imagemUrl: null,
                idade: null,
              ),
            ],
            total: 11,
            page: 1,
          );
        }

        return const AlunosPageResult(
          items: [
            AlunoRecord(
              idAluno: 2,
              numeroAluno: '2',
              nomeCompleto: 'Aluno Página 2',
              setor: 'Escudo',
              categoriaUsuario: 'Aprendiz',
              nivel: 'Intermediário',
              telefone: '',
              imagemUrl: null,
              idade: null,
            ),
          ],
          total: 11,
          page: 2,
        );
      },
    );

    await tester.pumpWidget(_buildTestable(AlunosPage(repository: repository)));
    await tester.pumpAndSettle();

    expect(find.text('Aluno Página 1'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.chevron_right).first);
    await tester.pumpAndSettle();

    expect(find.text('Aluno Página 2'), findsOneWidget);
    expect(repository.calls.map((c) => c.page), containsAll([1, 2]));
  });

  testWidgets('category filter sends selected category to repository', (
    tester,
  ) async {
    final repository = _FakeAlunosRepository(
      listarHandler: (_) async =>
          const AlunosPageResult(items: [], total: 0, page: 1),
    );

    await tester.pumpWidget(_buildTestable(AlunosPage(repository: repository)));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Kids').first);
    await tester.pumpAndSettle();

    expect(repository.calls.last.categorias, contains('Kids'));
    expect(repository.calls.last.page, 1);
  });

  testWidgets('setor filter sends selected setor to repository', (
    tester,
  ) async {
    final repository = _FakeAlunosRepository(
      listarHandler: (_) async =>
          const AlunosPageResult(items: [], total: 0, page: 1),
    );

    await tester.pumpWidget(_buildTestable(AlunosPage(repository: repository)));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Baliza').first);
    await tester.tap(find.text('Baliza').first);
    await tester.pumpAndSettle();

    expect(repository.calls.last.setores, contains('Baliza'));
    expect(repository.calls.last.page, 1);
  });

  testWidgets('A-Z toggle sends ordenarAlfabetico=true to repository', (
    tester,
  ) async {
    final repository = _FakeAlunosRepository(
      listarHandler: (_) async =>
          const AlunosPageResult(items: [], total: 0, page: 1),
    );

    await tester.pumpWidget(_buildTestable(AlunosPage(repository: repository)));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(Checkbox).first);
    await tester.pumpAndSettle();

    expect(repository.calls.last.ordenarAlfabetico, isTrue);
    expect(repository.calls.last.page, 1);
  });

  testWidgets('shows snackbar when initial load fails', (tester) async {
    final repository = _FakeAlunosRepository(
      listarHandler: (_) async {
        throw Exception('falha-repo-alunos');
      },
    );

    await tester.pumpWidget(_buildTestable(AlunosPage(repository: repository)));
    await tester.pumpAndSettle();

    expect(find.textContaining('Erro ao carregar alunos:'), findsOneWidget);
  });
}
