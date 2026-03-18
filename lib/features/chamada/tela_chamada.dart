import 'package:flutter/material.dart';

void main() {
  runApp(const CampsApp());
}

class CampsApp extends StatelessWidget {
  const CampsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CAMPS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1976D2)),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const AttendanceScreen(),
    );
  }
}

// ─── Enums & Models ──────────────────────────────────────────────────────────

enum AttendanceStatus { presente, atestado, falta, none }

extension AttendanceStatusExt on AttendanceStatus {
  String get label {
    switch (this) {
      case AttendanceStatus.presente:
        return 'P';
      case AttendanceStatus.atestado:
        return 'A';
      case AttendanceStatus.falta:
        return 'F';
      case AttendanceStatus.none:
        return '—';
    }
  }

  Color get backgroundColor {
    switch (this) {
      case AttendanceStatus.presente:
        return const Color(0xFF4CAF50);
      case AttendanceStatus.atestado:
        return const Color(0xFFFFC107);
      case AttendanceStatus.falta:
        return const Color(0xFFE53935);
      case AttendanceStatus.none:
        return Colors.grey.shade300;
    }
  }

  Color get textColor {
    switch (this) {
      case AttendanceStatus.presente:
        return Colors.white;
      case AttendanceStatus.atestado:
        return Colors.white;
      case AttendanceStatus.falta:
        return Colors.white;
      case AttendanceStatus.none:
        return Colors.grey.shade600;
    }
  }

  /// Cicla para o próximo status ao tocar
  AttendanceStatus get next {
    switch (this) {
      case AttendanceStatus.none:
        return AttendanceStatus.presente;
      case AttendanceStatus.presente:
        return AttendanceStatus.atestado;
      case AttendanceStatus.atestado:
        return AttendanceStatus.falta;
      case AttendanceStatus.falta:
        return AttendanceStatus.none;
    }
  }
}

class StudentRecord {
  final String name;
  // Mapa de data -> lista de status (um por turma/aula do dia)
  final Map<DateTime, List<AttendanceStatus>> attendance;

  StudentRecord({required this.name, required this.attendance});
}

// ─── Screen ──────────────────────────────────────────────────────────────────

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  // Datas exibidas nas colunas
  final List<DateTime> _dates = [
    DateTime(2024, 4, 20),
    DateTime(2024, 4, 21),
    DateTime(2024, 4, 22),
    DateTime(2024, 4, 23),
  ];

  // Dados mockados — cada aluno tem 2 linhas (turmas diferentes no mesmo dia)
  late List<StudentRecord> _students;

  @override
  void initState() {
    super.initState();
    _students = _buildMockData();
  }

  List<StudentRecord> _buildMockData() {
    return [
      StudentRecord(
        name: 'João Silva',
        attendance: {
          DateTime(2024, 4, 20): [AttendanceStatus.presente],
          DateTime(2024, 4, 21): [AttendanceStatus.presente],
          DateTime(2024, 4, 22): [AttendanceStatus.presente],
          DateTime(2024, 4, 23): [AttendanceStatus.presente],
        },
      ),
      StudentRecord(
        name: 'Maria Oliveira',
        attendance: {
          DateTime(2024, 4, 20): [
            AttendanceStatus.presente,
            AttendanceStatus.presente
          ],
          DateTime(2024, 4, 21): [
            AttendanceStatus.presente,
            AttendanceStatus.presente
          ],
          DateTime(2024, 4, 22): [
            AttendanceStatus.presente,
            AttendanceStatus.presente
          ],
          DateTime(2024, 4, 23): [
            AttendanceStatus.atestado,
            AttendanceStatus.presente
          ],
        },
      ),
      StudentRecord(
        name: 'Pedro Santos',
        attendance: {
          DateTime(2024, 4, 20): [
            AttendanceStatus.presente,
            AttendanceStatus.presente
          ],
          DateTime(2024, 4, 21): [
            AttendanceStatus.presente,
            AttendanceStatus.presente
          ],
          DateTime(2024, 4, 22): [
            AttendanceStatus.presente,
            AttendanceStatus.presente
          ],
          DateTime(2024, 4, 23): [
            AttendanceStatus.presente,
            AttendanceStatus.presente
          ],
        },
      ),
      StudentRecord(
        name: 'Ana Costa',
        attendance: {
          DateTime(2024, 4, 20): [
            AttendanceStatus.presente,
            AttendanceStatus.presente
          ],
          DateTime(2024, 4, 21): [
            AttendanceStatus.presente,
            AttendanceStatus.presente
          ],
          DateTime(2024, 4, 22): [
            AttendanceStatus.falta,
            AttendanceStatus.falta
          ],
          DateTime(2024, 4, 23): [
            AttendanceStatus.falta,
            AttendanceStatus.falta
          ],
        },
      ),
    ];
  }

  void _cycleStatus(int studentIndex, DateTime date, int rowIndex) {
    setState(() {
      final current =
          _students[studentIndex].attendance[date]![rowIndex];
      _students[studentIndex].attendance[date]![rowIndex] = current.next;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(child: _buildAttendanceTable()),
          _buildLegend(),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  // ── AppBar ────────────────────────────────────────────────────────────────

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.menu, color: Colors.black87),
        onPressed: () {},
      ),
      title: const Text(
        'CAMPS',
        style: TextStyle(
          color: Colors.black87,
          fontWeight: FontWeight.w600,
          fontSize: 20,
          letterSpacing: 1.2,
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: FloatingActionButton.small(
            onPressed: _showAddDialog,
            backgroundColor: const Color(0xFF1976D2),
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ),
      ],
    );
  }

  // ── Table ─────────────────────────────────────────────────────────────────

  Widget _buildAttendanceTable() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: _buildTable(),
          ),
        ),
      ),
    );
  }

  Widget _buildTable() {
    // Largura de cada coluna de data
    const double dateColWidth = 72.0;
    const double nameColWidth = 130.0;

    return Table(
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      columnWidths: {
        0: const FixedColumnWidth(nameColWidth),
        for (int i = 0; i < _dates.length; i++)
          i + 1: const FixedColumnWidth(dateColWidth),
      },
      border: TableBorder(
        horizontalInside: BorderSide(color: Colors.grey.shade200, width: 0.8),
        verticalInside: BorderSide(color: Colors.grey.shade200, width: 0.8),
      ),
      children: [
        _buildHeaderRow(dateColWidth),
        ..._buildDataRows(),
      ],
    );
  }

  // Cabeçalho com datas
  TableRow _buildHeaderRow(double colWidth) {
    return TableRow(
      decoration: BoxDecoration(color: Colors.grey.shade50),
      children: [
        const SizedBox(height: 56), // célula vazia do nome
        ..._dates.map(
          (date) => _DateHeaderCell(date: date, width: colWidth),
        ),
      ],
    );
  }

  // Linhas de dados — cada aluno pode ter múltiplas linhas (1 por turma)
  List<TableRow> _buildDataRows() {
    final rows = <TableRow>[];

    for (int si = 0; si < _students.length; si++) {
      final student = _students[si];
      // Quantas linhas esse aluno ocupa (max entre as datas)
      final rowCount = _dates
          .map((d) => student.attendance[d]?.length ?? 1)
          .reduce((a, b) => a > b ? a : b);

      for (int ri = 0; ri < rowCount; ri++) {
        final isFirstRow = ri == 0;
        final isLastRow = ri == rowCount - 1;

        rows.add(
          TableRow(
            decoration: BoxDecoration(
              color: si.isEven ? Colors.white : Colors.grey.shade50,
            ),
            children: [
              // Coluna do nome — só aparece na primeira linha do aluno
              isFirstRow
                  ? _NameCell(
                      name: student.name,
                      rowSpanCount: rowCount,
                      isLast: isLastRow,
                    )
                  : const SizedBox(height: 44),

              // Colunas de status por data
              ..._dates.map((date) {
                final statuses = student.attendance[date];
                final status =
                    (statuses != null && ri < statuses.length)
                        ? statuses[ri]
                        : AttendanceStatus.none;

                return _StatusCell(
                  status: status,
                  onTap: () => _cycleStatus(si, date, ri),
                );
              }),
            ],
          ),
        );
      }
    }

    return rows;
  }

  // ── Legend ────────────────────────────────────────────────────────────────

  Widget _buildLegend() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _LegendItem(
            color: AttendanceStatus.presente.backgroundColor,
            label: 'P (Presente)',
          ),
          const SizedBox(width: 20),
          _LegendItem(
            color: AttendanceStatus.atestado.backgroundColor,
            label: 'A (Atestado)',
          ),
          const SizedBox(width: 20),
          _LegendItem(
            color: AttendanceStatus.falta.backgroundColor,
            label: 'F (Falta)',
          ),
        ],
      ),
    );
  }

  // ── Add Dialog ────────────────────────────────────────────────────────────

  void _showAddDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AddStudentSheet(),
    );
  }
}

// ─── Widgets de suporte ───────────────────────────────────────────────────────

class _DateHeaderCell extends StatelessWidget {
  final DateTime date;
  final double width;

  const _DateHeaderCell({required this.date, required this.width});

  @override
  Widget build(BuildContext context) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();

    return SizedBox(
      width: width,
      height: 56,
      child: Center(
        child: Text(
          '$day/$month/\n$year',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}

class _NameCell extends StatelessWidget {
  final String name;
  final int rowSpanCount;
  final bool isLast;

  const _NameCell({
    required this.name,
    required this.rowSpanCount,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44.0 * rowSpanCount,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            name,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusCell extends StatelessWidget {
  final AttendanceStatus status;
  final VoidCallback onTap;

  const _StatusCell({required this.status, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: Center(
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeInOut,
            width: 38,
            height: 28,
            decoration: BoxDecoration(
              color: status == AttendanceStatus.none
                  ? Colors.transparent
                  : status.backgroundColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                status == AttendanceStatus.none ? '' : status.label,
                style: TextStyle(
                  color: status.textColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
        ),
      ],
    );
  }
}

// ─── Bottom Sheet: Adicionar aluno ────────────────────────────────────────────

class _AddStudentSheet extends StatefulWidget {
  const _AddStudentSheet();

  @override
  State<_AddStudentSheet> createState() => _AddStudentSheetState();
}

class _AddStudentSheetState extends State<_AddStudentSheet> {
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Adicionar aluno',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _nameController,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Nome completo',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.pop(context),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF1976D2),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Salvar', style: TextStyle(fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }
}
