import 'package:controle_instrumentos/features/chamada/exportacao/chamada_exportacao.dart';
import 'package:controle_instrumentos/features/chamada/widgets/chamada_exportacao_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('oferece os três modos e retorna o mês selecionado', (
    tester,
  ) async {
    SelecaoExportacaoChamada? resultado;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () async {
                resultado = await showDialog<SelecaoExportacaoChamada>(
                  context: context,
                  builder: (_) => const ChamadaExportacaoDialog(
                    anoSelecionado: 2026,
                    anoMinimo: 2026,
                    anoMaximo: 2040,
                  ),
                );
              },
              child: const Text('Abrir'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();

    expect(find.text('Um mês específico'), findsOneWidget);
    expect(find.text('Ano completo'), findsOneWidget);
    expect(find.text('Período específico'), findsOneWidget);

    await tester.tap(find.byKey(const Key('exportacao_mes')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Agosto').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirmar_exportacao')));
    await tester.pumpAndSettle();

    expect(resultado?.tipo, TipoExportacaoChamada.mes);
    expect(resultado?.mesInicial, 8);
    expect(resultado?.anoInicial, 2026);
  });

  testWidgets('cancelar fecha o modal sem retornar seleção', (tester) async {
    SelecaoExportacaoChamada? resultado;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () async {
                resultado = await showDialog<SelecaoExportacaoChamada>(
                  context: context,
                  builder: (_) => const ChamadaExportacaoDialog(
                    anoSelecionado: 2026,
                    anoMinimo: 2026,
                    anoMaximo: 2040,
                  ),
                );
              },
              child: const Text('Abrir'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(resultado, isNull);
    expect(find.text('Exportar chamada'), findsNothing);
  });
}
