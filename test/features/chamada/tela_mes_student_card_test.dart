import 'package:controle_instrumentos/features/chamada/models.dart';
import 'package:controle_instrumentos/features/chamada/widgets/tela_mes_student_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('exibe indicadores abaixo do nome em tela estreita', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final datas = List.generate(12, (index) => DateTime(2026, 6, 13 + index));
    const statuses = [
      AttendanceStatus.P,
      AttendanceStatus.A,
      AttendanceStatus.F,
    ];
    final student = StudentRecord(
      idAluno: 1,
      name: 'Jefferson do Espírito Santo Ribeiro de Almeida',
      attendance: {
        for (var i = 0; i < datas.length; i++) datas[i]: [statuses[i % 3]],
      },
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: CardAlunoMes(
              student: student,
              dates: datas,
              aulasDoMes: const [],
              onSetStatus: (_, __) {},
              onAnexarAtestado: (_) {},
              soData: (date) => DateTime(date.year, date.month, date.day),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);

    final nome = find.text(student.name);
    final indicadorP = find.text('P');
    final indicadorA = find.text('A');

    expect(nome, findsOneWidget);
    expect(indicadorP, findsNWidgets(4));
    expect(indicadorA, findsNWidgets(4));
    expect(find.text('F'), findsNWidgets(4));
    expect(
      tester.getTopLeft(indicadorP.first).dy,
      greaterThan(tester.getBottomLeft(nome).dy),
    );
  });
}
