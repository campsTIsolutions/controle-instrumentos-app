// lib/features/chamada/tela_mes.dart
// Tela de um mês específico:
//   • Linha horizontal rolável com as datas de aula cadastradas + botão "+ data"
//   • Lista de alunos com as pills de status de cada data
//   • Ao tocar em uma data → navega para TelaDia

import 'package:flutter/material.dart';
import 'models.dart';
import 'tela_dia.dart';

class TelaMes extends StatefulWidget {
  final int ano;
  final int mes; // 1-indexado
  final String nomesMes;

  const TelaMes({
    super.key,
    required this.ano,
    required this.mes,
    required this.nomesMes,
  });

  @override
  State<TelaMes> createState() => _TelaMesState();
}

class _TelaMesState extends State<TelaMes> {
  late List<DateTime> _dates;
  late List<StudentRecord> _students;

  @override
  void initState() {
    super.initState();
    _dates = buildMockDatesForMonth(widget.ano, widget.mes);
    _students = buildMockStudents(_dates);
  }

  // ── Adicionar nova data via DatePicker ────────────────────────────────────
  Future<void> _adicionarData() async {
    final inicial = DateTime(widget.ano, widget.mes, 1);
    final selecionada = await showDatePicker(
      context: context,
      initialDate: inicial,
      firstDate: DateTime(widget.ano, widget.mes, 1),
      lastDate: DateTime(widget.ano, widget.mes + 1, 0), // último dia do mês
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFF1976D2)),
        ),
        child: child!,
      ),
    );
    if (selecionada == null) return;

    final novaData = DateTime(
        selecionada.year, selecionada.month, selecionada.day);
    final jaExiste = _dates.any((d) =>
        d.year == novaData.year &&
        d.month == novaData.month &&
        d.day == novaData.day);

    if (jaExiste) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Já existe chamada para esta data.'),
          backgroundColor: Colors.orange,
        ));
      }
      return;
    }

    setState(() {
      _dates.add(novaData);
      _dates.sort();
      // Inicializa presença dos alunos para a nova data
      final rowCount = _students.isEmpty
          ? 1
          : _students
              .map((s) =>
                  s.attendance.values.isEmpty
                      ? 1
                      : s.attendance.values
                          .map((l) => l.length)
                          .reduce((a, b) => a > b ? a : b))
              .reduce((a, b) => a > b ? a : b);
      for (final s in _students) {
        s.attendance[novaData] =
            List.filled(rowCount, AttendanceStatus.none);
      }
    });

    // Abre direto a chamada do dia recém-criado
    if (mounted) _abrirDia(novaData);
  }

  // ── Navegar para TelaDia ──────────────────────────────────────────────────
  void _abrirDia(DateTime data) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TelaDia(
          data: data,
          students: _students,
          onChanged: () => setState(() {}),
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  String _formatDate(DateTime d) {
    final dia = d.day.toString().padLeft(2, '0');
    final mes = d.month.toString().padLeft(2, '0');
    return '$dia/$mes';
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: _buildAppBar(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDatasRow(),
          _buildSectionLabel('ALUNOS'),
          Expanded(child: _buildAlunosList()),
          const _AttendanceLegend(),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black87),
        onPressed: () => Navigator.pop(context),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${widget.nomesMes} ${widget.ano}',
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          Text(
            '${_dates.length} data${_dates.length != 1 ? 's' : ''} · ${_students.length} aluno${_students.length != 1 ? 's' : ''}',
            style: const TextStyle(
              color: Colors.black45,
              fontSize: 11,
              fontWeight: FontWeight.normal,
            ),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: FloatingActionButton.small(
            heroTag: 'fab_add_data',
            onPressed: _adicionarData,
            backgroundColor: const Color(0xFF1976D2),
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ),
      ],
    );
  }

  // ── Linha de datas ────────────────────────────────────────────────────────
  Widget _buildDatasRow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('DATAS DE AULA'),
        SizedBox(
          height: 40,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            children: [
              ..._dates.map((d) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => _abrirDia(d),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.grey.shade300,
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          _formatDate(d),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  )),
              // Botão "+ data"
              GestureDetector(
                onTap: _adicionarData,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF1976D2),
                      width: 0.8,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: const Text(
                    '+ data',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF1976D2),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildSectionLabel(String texto) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: Text(
        texto,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade500,
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  // ── Lista de alunos ───────────────────────────────────────────────────────
  Widget _buildAlunosList() {
    if (_students.isEmpty) {
      return Center(
        child: Text(
          'Nenhum aluno cadastrado',
          style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _students.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, si) =>
          _CardAlunoMes(student: _students[si], dates: _dates),
    );
  }
}

// ─── Card de aluno na tela de mês ─────────────────────────────────────────────

class _CardAlunoMes extends StatelessWidget {
  final StudentRecord student;
  final List<DateTime> dates;

  const _CardAlunoMes({required this.student, required this.dates});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200, width: 0.8),
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 16,
            backgroundColor: const Color(0xFF1976D2).withOpacity(0.12),
            child: Text(
              student.name[0].toUpperCase(),
              style: const TextStyle(
                color: Color(0xFF1976D2),
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Nome
          Expanded(
            child: Text(
              student.name,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          // Pills de status por data
          if (dates.isEmpty)
            Text('—',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade400))
          else
            Row(
              mainAxisSize: MainAxisSize.min,
              children: dates.map((d) {
                final statuses = student.attendance[d];
                // Pega o primeiro status representativo do dia
                final status = (statuses != null && statuses.isNotEmpty)
                    ? statuses.first
                    : AttendanceStatus.none;
                return Padding(
                  padding: const EdgeInsets.only(left: 3),
                  child: _StatusPill(status: status),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}

// ─── Pill compacta de status ──────────────────────────────────────────────────

class _StatusPill extends StatelessWidget {
  final AttendanceStatus status;

  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final isEmpty = status == AttendanceStatus.none;
    return Container(
      width: 22,
      height: 16,
      decoration: BoxDecoration(
        color: isEmpty ? Colors.grey.shade200 : status.backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: Text(
        isEmpty ? '·' : status.label,
        style: TextStyle(
          color: isEmpty ? Colors.grey.shade500 : Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 9,
        ),
      ),
    );
  }
}

// ─── Legenda inferior ─────────────────────────────────────────────────────────

class _AttendanceLegend extends StatelessWidget {
  const _AttendanceLegend();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _LegendItem(
              color: AttendanceStatus.presente.backgroundColor,
              label: 'P (Presente)'),
          const SizedBox(width: 20),
          _LegendItem(
              color: AttendanceStatus.atestado.backgroundColor,
              label: 'A (Atestado)'),
          const SizedBox(width: 20),
          _LegendItem(
              color: AttendanceStatus.falta.backgroundColor,
              label: 'F (Falta)'),
        ],
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
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(label,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
      ],
    );
  }
}
