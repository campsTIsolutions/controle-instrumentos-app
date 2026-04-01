// lib/features/chamada/tela_mes.dart
// Tela de um mês:
//   • Carrega alunos e aulas do Supabase
//   • Subtítulo mostra contagem REAL de aulas (atualiza ao add/remover)
//   • Adicionar / excluir alunos persiste no banco
//   • Botão "+ data" cria aula no Supabase
//   • Swipe / long-press em data para deletar aula
//   • Pills circulares de status (P / A / F)

import 'package:flutter/material.dart';
import 'models.dart';
import 'supabase_service.dart';
import 'tela_dia.dart';

class TelaMes extends StatefulWidget {
  final int ano;
  final int mes;
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
  List<AulaRecord> _aulas = [];
  List<StudentRecord> _students = [];
  bool _carregando = true;
  String? _erro;

  // Contagem dinâmica — derivada de _aulas.length
  int get _totalAulas => _aulas.length;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  // ── Carrega alunos + aulas do Supabase ───────────────────────────────────
  Future<void> _carregarDados() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final alunos = await SupabaseService.fetchAlunos();
      final aulas = await SupabaseService.fetchAulas(
        ano: widget.ano,
        mes: widget.mes,
      );

      for (final aula in aulas) {
        final chamadas = await SupabaseService.fetchChamadas(aula.id);
        for (final aluno in alunos) {
          final chamada = chamadas.firstWhere(
            (c) => c.idAluno == aluno.idAluno,
            orElse: () => ChamadaRecord(
              id: '',
              aulaId: aula.id,
              idAluno: aluno.idAluno,
              status: AttendanceStatus.none,
            ),
          );
          final dataKey =
              DateTime(aula.data.year, aula.data.month, aula.data.day);
          aluno.attendance[dataKey] = [chamada.status];
          if (chamada.comprovanteUrl != null) {
            aluno.atestadoNome[dataKey] = chamada.comprovanteUrl;
          }
        }
      }

      setState(() {
        _aulas = aulas;
        _students = alunos;
        _carregando = false;
      });
    } catch (e) {
      setState(() {
        _erro = 'Erro ao carregar dados: $e';
        _carregando = false;
      });
    }
  }

  // ── Adicionar nova data (aula) via DatePicker ────────────────────────────
  Future<void> _adicionarData() async {
    final inicial = DateTime(widget.ano, widget.mes, 1);
    final selecionada = await showDatePicker(
      context: context,
      initialDate: inicial,
      firstDate: DateTime(widget.ano, widget.mes, 1),
      lastDate: DateTime(widget.ano, widget.mes + 1, 0),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme:
              const ColorScheme.light(primary: Color(0xFF1976D2)),
        ),
        child: child!,
      ),
    );
    if (selecionada == null) return;

    final novaData =
        DateTime(selecionada.year, selecionada.month, selecionada.day);
    final jaExiste = _aulas.any((a) =>
        a.data.year == novaData.year &&
        a.data.month == novaData.month &&
        a.data.day == novaData.day);

    if (jaExiste) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Já existe chamada para esta data.'),
          backgroundColor: Colors.orange,
        ));
      }
      return;
    }

    try {
      final novaAula = await SupabaseService.inserirAula(data: novaData);
      for (final s in _students) {
        s.attendance[novaData] = [AttendanceStatus.none];
      }
      setState(() {
        _aulas.add(novaAula);
        _aulas.sort((a, b) => a.data.compareTo(b.data));
        // _totalAulas é recalculado automaticamente a partir de _aulas.length
      });
      if (mounted) _abrirDia(novaAula);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erro ao criar aula: $e'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  // ── Excluir aula ──────────────────────────────────────────────────────────
  Future<void> _excluirAula(AulaRecord aula) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir aula'),
        content: Text(
          'Deseja excluir a aula do dia ${_formatDate(aula.data)}?\n\n'
          'Todas as chamadas deste dia também serão removidas.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await SupabaseService.deletarAula(aula.id);
      final dataKey =
          DateTime(aula.data.year, aula.data.month, aula.data.day);
      setState(() {
        _aulas.removeWhere((a) => a.id == aula.id);
        for (final s in _students) {
          s.attendance.remove(dataKey);
          s.atestadoNome.remove(dataKey);
        }
        // _totalAulas atualizado automaticamente
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Aula de ${_formatDate(aula.data)} removida.'),
            backgroundColor: Colors.red.shade400,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erro ao excluir aula: $e'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  // ── Abrir TelaDia ────────────────────────────────────────────────────────
  void _abrirDia(AulaRecord aula) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TelaDia(
          aula: aula,
          students: _students,
          onChanged: () => setState(() {}),
        ),
      ),
    );
  }

  // ── Adicionar aluno ───────────────────────────────────────────────────────
  Future<void> _adicionarAluno() async {
    final nomeController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Adicionar aluno'),
        content: TextField(
          controller: nomeController,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Nome completo',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF1976D2)),
            child: const Text('Adicionar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    final nome = nomeController.text.trim();
    if (nome.isEmpty) return;

    try {
      final novoAluno =
          await SupabaseService.inserirAluno(nomeCompleto: nome);
      for (final aula in _aulas) {
        final dataKey =
            DateTime(aula.data.year, aula.data.month, aula.data.day);
        novoAluno.attendance[dataKey] = [AttendanceStatus.none];
      }
      setState(() => _students.add(novoAluno));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Aluno "$nome" adicionado!'),
            backgroundColor: const Color(0xFF4CAF50),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erro ao adicionar aluno: $e'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  // ── Excluir aluno ─────────────────────────────────────────────────────────
  Future<void> _excluirAluno(StudentRecord aluno) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir aluno'),
        content: Text(
          'Deseja excluir "${aluno.name}"?\n\n'
          'Todas as chamadas deste aluno também serão removidas.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await SupabaseService.deletarAluno(aluno.idAluno);
      setState(
          () => _students.removeWhere((s) => s.idAluno == aluno.idAluno));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Aluno "${aluno.name}" removido.'),
            backgroundColor: Colors.red.shade400,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erro ao excluir: $e'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  String _formatDate(DateTime d) {
    final dia = d.day.toString().padLeft(2, '0');
    final mes = d.month.toString().padLeft(2, '0');
    return '$dia/$mes';
  }

  List<DateTime> get _dates =>
      _aulas.map((a) => DateTime(a.data.year, a.data.month, a.data.day)).toList();

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: _buildAppBar(),
      floatingActionButton: FloatingActionButton(
        onPressed: _adicionarAluno,
        backgroundColor: const Color(0xFF1976D2),
        child: const Icon(Icons.person_add_outlined, color: Colors.white),
      ),
      body: _carregando
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF1976D2)))
          : _erro != null
              ? _buildErro()
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDatasRow(),
                    _buildSectionLabel('ALUNOS'),
                    Expanded(child: _buildAlunosList()),
                    const _AttendanceLegend(),
                    const SizedBox(height: 8),
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
                fontSize: 17),
          ),
          // Subtítulo: contagem DINÂMICA de aulas e alunos
          Text(
            '$_totalAulas data${_totalAulas != 1 ? 's' : ''} · '
            '${_students.length} aluno${_students.length != 1 ? 's' : ''}',
            style: const TextStyle(
                color: Colors.black45,
                fontSize: 11,
                fontWeight: FontWeight.normal),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.add, color: Color(0xFF1976D2)),
          tooltip: 'Adicionar data de aula',
          onPressed: _adicionarData,
        ),
      ],
    );
  }

  Widget _buildErro() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
          const SizedBox(height: 12),
          Text(_erro!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _carregarDados,
            icon: const Icon(Icons.refresh),
            label: const Text('Tentar novamente'),
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF1976D2)),
          ),
        ],
      ),
    );
  }

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
              ..._aulas.map((aula) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _DataChip(
                      label: _formatDate(aula.data),
                      onTap: () => _abrirDia(aula),
                      onDelete: () => _excluirAula(aula),
                    ),
                  )),
              // Botão "+ data"
              GestureDetector(
                onTap: _adicionarData,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: const Color(0xFF1976D2), width: 1.2),
                  ),
                  child: const Text(
                    '+ data',
                    style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF1976D2),
                        fontWeight: FontWeight.w500),
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
            letterSpacing: 0.6),
      ),
    );
  }

  Widget _buildAlunosList() {
    if (_aulas.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_today_outlined,
                size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Toque em + para adicionar\na primeira data de aula',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                  height: 1.5),
            ),
          ],
        ),
      );
    }

    if (_students.isEmpty) {
      return Center(
        child: Text('Nenhum aluno cadastrado',
            style:
                TextStyle(fontSize: 13, color: Colors.grey.shade400)),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _students.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, si) => _CardAlunoMes(
        student: _students[si],
        dates: _dates,
        onExcluir: () => _excluirAluno(_students[si]),
      ),
    );
  }
}

// ─── Chip de data com opção de deletar (long-press) ───────────────────────────

class _DataChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _DataChip({
    required this.label,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onDelete,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade300, width: 0.8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500),
            ),
            const SizedBox(width: 4),
            Icon(Icons.close,
                size: 12, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}

// ─── Card de aluno na visão mensal ────────────────────────────────────────────

class _CardAlunoMes extends StatelessWidget {
  final StudentRecord student;
  final List<DateTime> dates;
  final VoidCallback onExcluir;

  const _CardAlunoMes({
    required this.student,
    required this.dates,
    required this.onExcluir,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200, width: 0.8),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor:
                const Color(0xFF1976D2).withOpacity(0.12),
            child: Text(
              student.name[0].toUpperCase(),
              style: const TextStyle(
                  color: Color(0xFF1976D2),
                  fontWeight: FontWeight.bold,
                  fontSize: 13),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              student.name,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87),
            ),
          ),
          const SizedBox(width: 8),
          if (dates.isEmpty)
            Text('—',
                style: TextStyle(
                    fontSize: 11, color: Colors.grey.shade400))
          else
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: dates.map((d) {
                final statuses = student.attendance[d];
                final status = (statuses != null && statuses.isNotEmpty)
                    ? statuses.first
                    : AttendanceStatus.none;
                return _StatusCircle(status: status);
              }).toList(),
            ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onExcluir,
            child: Icon(Icons.delete_outline,
                size: 20, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }
}

class _StatusCircle extends StatelessWidget {
  final AttendanceStatus status;
  const _StatusCircle({required this.status});

  @override
  Widget build(BuildContext context) {
    final isEmpty = status == AttendanceStatus.none;
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: isEmpty ? Colors.grey.shade200 : status.backgroundColor,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        isEmpty ? '' : status.label,
        style: TextStyle(
          color: isEmpty ? Colors.grey.shade500 : Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }
}

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
              label: 'Presente'),
          const SizedBox(width: 16),
          _LegendItem(
              color: AttendanceStatus.atestado.backgroundColor,
              label: 'Atestado'),
          const SizedBox(width: 16),
          _LegendItem(
              color: AttendanceStatus.falta.backgroundColor,
              label: 'Falta'),
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
            decoration:
                BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text(label,
            style: TextStyle(
                fontSize: 11, color: Colors.grey.shade600)),
      ],
    );
  }
}
