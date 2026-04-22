import 'dart:async';

import 'package:controle_instrumentos/features/historico/historico_page.dart';
import 'package:controle_instrumentos/features/historico/models/historico_log_record.dart';
import 'package:controle_instrumentos/features/historico/repository/historico_repository.dart';
import 'package:controle_instrumentos/features/historico/widgets/historico_filters/filtro_chip_group.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeHistoricoRepository implements HistoricoRepositoryContract {
  _FakeHistoricoRepository(this.logs);

  final List<HistoricoLogRecord> logs;
  final List<int> deletedIds = [];

  @override
  Future<void> deletarLog(int idLog) async {
    deletedIds.add(idLog);
    logs.removeWhere((l) => l.idLog == idLog);
  }

  @override
  Future<List<HistoricoLogRecord>> listarLogs() async {
    return List<HistoricoLogRecord>.from(logs);
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
  testWidgets('shows loading before first logs response resolves', (
    tester,
  ) async {
    final completer = Completer<List<HistoricoLogRecord>>();
    final repository = _CompleterHistoricoRepository(() => completer.future);

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
    final repository = _FakeHistoricoRepository([]);

    await tester.pumpWidget(
      _buildTestable(HistoricoPage(repository: repository)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Nenhum registro encontrado.'), findsOneWidget);
  });

  testWidgets('shows log entry when repository returns data', (tester) async {
    final repository = _FakeHistoricoRepository([
      const HistoricoLogRecord(
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
    ]);

    await tester.pumpWidget(
      _buildTestable(HistoricoPage(repository: repository)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Aluno Histórico'), findsOneWidget);
    expect(find.text('1 registro'), findsWidgets);
  });

  testWidgets('search filters visible logs locally', (tester) async {
    final repository = _FakeHistoricoRepository([
      const HistoricoLogRecord(
        idLog: 1,
        idAluno: 1,
        numeroAluno: '01',
        nomeCompleto: 'João Teste',
        setor: 'Linha',
        categoriaUsuario: 'Kids',
        nivel: 'Iniciante',
        telefone: '',
        imagemUrl: null,
        idade: null,
        motivoExclusao: 'Falta de Tempo',
        dataExclusao: '2026-04-20T10:00:00Z',
      ),
      const HistoricoLogRecord(
        idLog: 2,
        idAluno: 2,
        numeroAluno: '02',
        nomeCompleto: 'Maria Teste',
        setor: 'Escudo',
        categoriaUsuario: 'Aprendiz',
        nivel: 'Intermediário',
        telefone: '',
        imagemUrl: null,
        idade: null,
        motivoExclusao: 'Falta de Disciplina',
        dataExclusao: '2026-04-19T10:00:00Z',
      ),
    ]);

    await tester.pumpWidget(
      _buildTestable(HistoricoPage(repository: repository)),
    );
    await tester.pumpAndSettle();

    expect(find.text('João Teste'), findsOneWidget);
    expect(find.text('Maria Teste'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'maria');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(find.text('Maria Teste'), findsOneWidget);
    expect(find.text('João Teste'), findsNothing);
  });

  testWidgets('motivo filter keeps only matching logs', (tester) async {
    final repository = _FakeHistoricoRepository([
      const HistoricoLogRecord(
        idLog: 1,
        idAluno: 1,
        numeroAluno: '01',
        nomeCompleto: 'Tempo Registro',
        setor: 'Linha',
        categoriaUsuario: 'Kids',
        nivel: 'Iniciante',
        telefone: '',
        imagemUrl: null,
        idade: null,
        motivoExclusao: 'Falta de Tempo',
        dataExclusao: '2026-04-20T10:00:00Z',
      ),
      const HistoricoLogRecord(
        idLog: 2,
        idAluno: 2,
        numeroAluno: '02',
        nomeCompleto: 'Disciplina Registro',
        setor: 'Escudo',
        categoriaUsuario: 'Aprendiz',
        nivel: 'Intermediário',
        telefone: '',
        imagemUrl: null,
        idade: null,
        motivoExclusao: 'Falta de Disciplina',
        dataExclusao: '2026-04-19T10:00:00Z',
      ),
    ]);

    await tester.pumpWidget(
      _buildTestable(HistoricoPage(repository: repository)),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.widgetWithText(CheckboxChipWidget, 'Falta de Disciplina').first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Disciplina Registro'), findsOneWidget);
    expect(find.text('Tempo Registro'), findsNothing);
  });

  testWidgets('setor filter keeps only matching logs', (tester) async {
    final repository = _FakeHistoricoRepository([
      const HistoricoLogRecord(
        idLog: 1,
        idAluno: 1,
        numeroAluno: '01',
        nomeCompleto: 'Log Escudo',
        setor: 'Escudo',
        categoriaUsuario: 'Kids',
        nivel: 'Iniciante',
        telefone: '',
        imagemUrl: null,
        idade: null,
        motivoExclusao: 'Falta de Tempo',
        dataExclusao: '2026-04-20T10:00:00Z',
      ),
      const HistoricoLogRecord(
        idLog: 2,
        idAluno: 2,
        numeroAluno: '02',
        nomeCompleto: 'Log Baliza',
        setor: 'Baliza',
        categoriaUsuario: 'Aprendiz',
        nivel: 'Intermediário',
        telefone: '',
        imagemUrl: null,
        idade: null,
        motivoExclusao: 'Falta de Disciplina',
        dataExclusao: '2026-04-19T10:00:00Z',
      ),
    ]);

    await tester.pumpWidget(
      _buildTestable(HistoricoPage(repository: repository)),
    );
    await tester.pumpAndSettle();

    final balizaChip = find.widgetWithText(CheckboxChipWidget, 'Baliza').first;
    await tester.ensureVisible(balizaChip);
    await tester.tap(balizaChip);
    await tester.pumpAndSettle();

    expect(find.text('Log Baliza'), findsOneWidget);
    expect(find.text('Log Escudo'), findsNothing);
  });

  testWidgets('A-Z toggle sorts visible logs alphabetically', (tester) async {
    final repository = _FakeHistoricoRepository([
      const HistoricoLogRecord(
        idLog: 1,
        idAluno: 1,
        numeroAluno: '01',
        nomeCompleto: 'Zeta Nome',
        setor: 'Escudo',
        categoriaUsuario: 'Kids',
        nivel: 'Iniciante',
        telefone: '',
        imagemUrl: null,
        idade: null,
        motivoExclusao: 'Falta de Tempo',
        dataExclusao: '2026-04-20T10:00:00Z',
      ),
      const HistoricoLogRecord(
        idLog: 2,
        idAluno: 2,
        numeroAluno: '02',
        nomeCompleto: 'Alfa Nome',
        setor: 'Baliza',
        categoriaUsuario: 'Aprendiz',
        nivel: 'Intermediário',
        telefone: '',
        imagemUrl: null,
        idade: null,
        motivoExclusao: 'Falta de Disciplina',
        dataExclusao: '2026-04-19T10:00:00Z',
      ),
    ]);

    await tester.pumpWidget(
      _buildTestable(HistoricoPage(repository: repository)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('A-Z').first);
    await tester.pumpAndSettle();

    final alfaY = tester.getTopLeft(find.text('Alfa Nome').first).dy;
    final zetaY = tester.getTopLeft(find.text('Zeta Nome').first).dy;
    expect(alfaY, lessThan(zetaY));
  });

  testWidgets('delete flow confirms and calls repository delete', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final repository = _FakeHistoricoRepository([
      const HistoricoLogRecord(
        idLog: 10,
        idAluno: 1,
        numeroAluno: '01',
        nomeCompleto: 'Registro Removível',
        setor: 'Linha',
        categoriaUsuario: 'Kids',
        nivel: 'Iniciante',
        telefone: '',
        imagemUrl: null,
        idade: null,
        motivoExclusao: 'Falta de Interesse',
        dataExclusao: '2026-04-20T10:00:00Z',
      ),
    ]);

    await tester.pumpWidget(
      _buildTestable(HistoricoPage(repository: repository)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Registro Removível'), findsOneWidget);

    await tester.ensureVisible(find.byIcon(Icons.delete_outline).first);
    await tester.tap(find.byIcon(Icons.delete_outline).first);
    await tester.pumpAndSettle();

    expect(find.text('Remover Registro'), findsOneWidget);
    await tester.tap(find.text('Remover').last);
    await tester.pumpAndSettle();

    expect(repository.deletedIds, [10]);
    expect(find.text('Registro Removível'), findsNothing);
  });

  testWidgets('shows snackbar when initial logs load fails', (tester) async {
    final repository = _CompleterHistoricoRepository(() async {
      throw Exception('falha-repo-historico');
    });

    await tester.pumpWidget(
      _buildTestable(HistoricoPage(repository: repository)),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Erro ao carregar histórico:'), findsOneWidget);
  });
}

class _CompleterHistoricoRepository implements HistoricoRepositoryContract {
  _CompleterHistoricoRepository(this.listarHandler);

  final Future<List<HistoricoLogRecord>> Function() listarHandler;

  @override
  Future<void> deletarLog(int idLog) async {}

  @override
  Future<List<HistoricoLogRecord>> listarLogs() => listarHandler();
}
