import 'dart:async';

import 'package:controle_instrumentos/features/historico/historico_page.dart';
import 'package:controle_instrumentos/features/historico/models/historico_log_record.dart';
import 'package:controle_instrumentos/features/historico/repository/historico_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeHistoricoRepository implements HistoricoRepositoryContract {
  _FakeHistoricoRepository({required this.listarHandler});

  final Future<List<HistoricoLogRecord>> Function() listarHandler;

  @override
  Future<void> deletarLog(int idLog) async {}

  @override
  Future<List<HistoricoLogRecord>> listarLogs() => listarHandler();
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
  testWidgets('shows loading before first logs response resolves', (
    tester,
  ) async {
    final completer = Completer<List<HistoricoLogRecord>>();
    final repository = _FakeHistoricoRepository(
      listarHandler: () => completer.future,
    );

    await tester.pumpWidget(
      _buildTestable(HistoricoPage(repository: repository)),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    completer.complete(const []);
    await tester.pumpAndSettle();

    expect(find.text('Nenhum registro encontrado.'), findsOneWidget);
  });

  testWidgets('shows empty state when repository returns no logs', (
    tester,
  ) async {
    final repository = _FakeHistoricoRepository(
      listarHandler: () async => const [],
    );

    await tester.pumpWidget(
      _buildTestable(HistoricoPage(repository: repository)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Nenhum registro encontrado.'), findsOneWidget);
  });

  testWidgets('shows log entry when repository returns data', (tester) async {
    final repository = _FakeHistoricoRepository(
      listarHandler: () async => const [
        HistoricoLogRecord(
          idLog: 1,
          idAluno: 7,
          numeroAluno: '77',
          nomeCompleto: 'Aluno Histórico',
          setor: 'Escudo',
          categoriaUsuario: 'Kids',
          nivel: 'Intermediário',
          telefone: '11911111111',
          imagemUrl: null,
          idade: 14,
          motivoExclusao: 'Falta de Tempo',
          dataExclusao: '2026-04-20T10:00:00Z',
        ),
      ],
    );

    await tester.pumpWidget(
      _buildTestable(HistoricoPage(repository: repository)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Aluno Histórico'), findsOneWidget);
    expect(find.text('1 registro'), findsWidgets);
  });

  testWidgets('shows snackbar when initial logs load fails', (tester) async {
    final repository = _FakeHistoricoRepository(
      listarHandler: () async {
        throw Exception('falha-repo-historico');
      },
    );

    await tester.pumpWidget(
      _buildTestable(HistoricoPage(repository: repository)),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Erro ao carregar histórico:'), findsOneWidget);
  });
}
