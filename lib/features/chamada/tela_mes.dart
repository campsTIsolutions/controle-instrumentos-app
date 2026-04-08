// lib/features/chamada/tela_mes.dart

import 'package:flutter/material.dart';
import 'models.dart';
import 'supabase_service.dart';
import 'tela_atestado.dart';

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
  List<DateTime> _dates = [];
  List<StudentRecord> _students = [];
  List<AulaRecord> _aulasDoMes = [];
  bool _loading = true;

  // Cores do design
  static const _azul = Color(0xFF1976D2);
  static const _verde = Color(0xFF4CAF50);
  static const _amarelo = Color(0xFFFFC107);
  static const _vermelho = Color(0xFFE53935);

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  DateTime _soData(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  Future<void> _carregarDados() async {
    if (!mounted) return;
    setState(() => _loading = true);

    try {
      final resultados = await Future.wait([
        SupabaseService.fetchAlunos(),
        SupabaseService.fetchAulas(ano: widget.ano, mes: widget.mes),
      ]);

      final listaAlunos = resultados[0] as List<StudentRecord>;
      final listaAulas = resultados[1] as List<AulaRecord>;

      for (var aula in listaAulas) {
        final chamadas = await SupabaseService.fetchChamadas(aula.id);
        for (var chamada in chamadas) {
          final aluno = listaAlunos.firstWhere(
            (a) => a.idAluno == chamada.idAluno,
            orElse: () => StudentRecord(idAluno: -1, name: '', attendance: {}),
          );
          if (aluno.idAluno != -1) {
            final dataKey = _soData(aula.data);
            aluno.attendance[dataKey] = [chamada.status];
            if (chamada.comprovanteUrl != null) {
              aluno.atestadoNome[dataKey] = chamada.comprovanteUrl;
            }
          }
        }
      }

      if (mounted) {
        setState(() {
          _students = listaAlunos;
          _aulasDoMes = listaAulas;
          _dates = listaAulas.map((a) => _soData(a.data)).toList();
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint("Erro ao carregar: $e");
      if (mounted) setState(() => _loading = false);
    }
  }

  void _adicionarData() async {
    final hoje = DateTime.now();
    final initialDate = DateTime(widget.ano, widget.mes,
        (widget.ano == hoje.year && widget.mes == hoje.month) ? hoje.day : 1);

    final dataSelecionada = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(widget.ano, widget.mes, 1),
      lastDate: DateTime(widget.ano, widget.mes + 1, 0),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: _azul),
        ),
        child: child!,
      ),
    );

    if (dataSelecionada != null) {
      // Verifica se a data já existe
      final dataKey = _soData(dataSelecionada);
      if (_dates.contains(dataKey)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Essa data já foi adicionada.")),
          );
        }
        return;
      }

      setState(() => _loading = true);
      try {
        await SupabaseService.inserirAula(data: dataKey);
        await _carregarDados();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Erro ao criar aula: $e")),
          );
          setState(() => _loading = false);
        }
      }
    }
  }

  /// Exibe diálogo de confirmação e deleta a aula do banco
  Future<void> _excluirData(DateTime date) async {
    final dataKey = _soData(date);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir data'),
        content: Text(
          'Deseja excluir a aula de ${dataKey.day.toString().padLeft(2, '0')}/${dataKey.month.toString().padLeft(2, '0')}/${dataKey.year}?\n\nTodas as presenças desta data também serão removidas.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFE53935)),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _loading = true);
    try {
      final aula = _aulasDoMes.firstWhere((a) => _soData(a.data) == dataKey);
      await SupabaseService.deletarAula(aula.id);
      await _carregarDados();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao excluir data: $e')),
        );
        setState(() => _loading = false);
      }
    }
  }

  /// Alterna o status e salva no Supabase
  Future<void> _setStatus(
      StudentRecord student, DateTime date, AttendanceStatus novoStatus) async {
    final dataKey = _soData(date);

    // Atualiza localmente antes (feedback imediato)
    setState(() {
      student.attendance[dataKey] = [novoStatus];
      if (novoStatus != AttendanceStatus.A) {
        student.atestadoNome[dataKey] = null;
      }
    });

    try {
      final aulaId =
          _aulasDoMes.firstWhere((a) => _soData(a.data) == dataKey).id;

      await SupabaseService.salvarChamada(
        aulaId: aulaId,
        idAluno: student.idAluno,
        status: novoStatus,
        comprovanteUrl: novoStatus == AttendanceStatus.A
            ? student.atestadoNome[dataKey]
            : null,
      );
    } catch (e) {
      // Reverte em caso de erro
      if (mounted) {
        setState(() {
          student.attendance[dataKey] = [AttendanceStatus.none];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro ao salvar: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
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
                fontSize: 18,
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
              onPressed: _adicionarData,
              backgroundColor: _azul,
              elevation: 0,
              child: const Icon(Icons.add, color: Colors.white),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: _azul))
          : _students.isEmpty
              ? _buildVazio()
              : _buildConteudo(),
    );
  }

  Widget _buildVazio() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.people_outline, size: 56, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'Nenhum aluno cadastrado.',
            style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildConteudo() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Chips de datas ──────────────────────────────────────────────────
        _buildSecaoTitulo('DATAS DE AULA'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ..._dates.map((d) => _ChipData(
                  dia: d.day,
                  mes: d.month,
                  cor: _azul,
                  onExcluir: () => _excluirData(d),
                )),
            _ChipAdicionar(onTap: _adicionarData),
          ],
        ),
        const SizedBox(height: 24),

        // ── Lista de alunos ─────────────────────────────────────────────────
        _buildSecaoTitulo('ALUNOS'),
        const SizedBox(height: 8),
        ..._students.map((student) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _CardAlunoMes(
                student: student,
                dates: _dates,
                aulasDoMes: _aulasDoMes,
                onSetStatus: (date, status) =>
                    _setStatus(student, date, status),
                onAnexarAtestado: (date) => _abrirAtestado(student, date),
                soData: _soData,
              ),
            )),

        const SizedBox(height: 16),
        // ── Legenda ─────────────────────────────────────────────────────────
        _buildLegenda(),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildSecaoTitulo(String titulo) {
    return Text(
      titulo,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: Colors.grey.shade500,
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _buildLegenda() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _itemLegenda(_verde, 'Presente'),
        const SizedBox(width: 16),
        _itemLegenda(_amarelo, 'Atestado'),
        const SizedBox(width: 16),
        _itemLegenda(_vermelho, 'Falta'),
      ],
    );
  }

  Widget _itemLegenda(Color cor, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: cor, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
      ],
    );
  }

  void _abrirAtestado(StudentRecord student, DateTime date) {
    final dataKey = _soData(date);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TelaAtestado(
          student: student,
          data: dataKey,
          onAnexado: (nome) async {
            try {
              final aulaId =
                  _aulasDoMes.firstWhere((a) => _soData(a.data) == dataKey).id;
              await SupabaseService.salvarChamada(
                aulaId: aulaId,
                idAluno: student.idAluno,
                status: AttendanceStatus.A,
                comprovanteUrl: nome,
              );
              setState(() => student.atestadoNome[dataKey] = nome);
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Erro ao salvar atestado: $e")),
                );
              }
            }
          },
        ),
      ),
    );
  }
}

// ─── Chip de data ─────────────────────────────────────────────────────────────

class _ChipData extends StatelessWidget {
  final int dia;
  final int mes;
  final Color cor;
  final VoidCallback onExcluir;

  const _ChipData({
    required this.dia,
    required this.mes,
    required this.cor,
    required this.onExcluir,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cor.withOpacity(0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cor.withOpacity(0.30), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${dia.toString().padLeft(2, '0')}/${mes.toString().padLeft(2, '0')}',
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600, color: cor),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onExcluir,
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: cor.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.remove, size: 12, color: cor),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChipAdicionar extends StatelessWidget {
  final VoidCallback onTap;
  const _ChipAdicionar({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: const Color(0xFF1976D2).withOpacity(0.40),
              width: 0.8,
              style: BorderStyle.solid),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, size: 14, color: Color(0xFF1976D2)),
            SizedBox(width: 4),
            Text('+ data',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1976D2))),
          ],
        ),
      ),
    );
  }
}

// ─── Card de aluno na tela do mês ────────────────────────────────────────────

class _CardAlunoMes extends StatelessWidget {
  final StudentRecord student;
  final List<DateTime> dates;
  final List<AulaRecord> aulasDoMes;
  final void Function(DateTime date, AttendanceStatus status) onSetStatus;
  final void Function(DateTime date) onAnexarAtestado;
  final DateTime Function(DateTime) soData;

  static const _verde = Color(0xFF4CAF50);
  static const _amarelo = Color(0xFFFFC107);
  static const _vermelho = Color(0xFFE53935);

  const _CardAlunoMes({
    required this.student,
    required this.dates,
    required this.aulasDoMes,
    required this.onSetStatus,
    required this.onAnexarAtestado,
    required this.soData,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Cabeçalho do aluno ──────────────────────────────────────────
          Row(
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
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  student.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
              // Pills de resumo
              ...dates.map((d) {
                final status =
                    student.attendance[soData(d)]?.first ??
                        AttendanceStatus.none;
                if (status == AttendanceStatus.none) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Container(
                    width: 26,
                    height: 20,
                    decoration: BoxDecoration(
                      color: status.backgroundColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      status.label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),

          if (dates.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Divider(height: 1, color: Color(0xFFF0F0F0)),
            const SizedBox(height: 12),

            // ── Linha de botões por data ────────────────────────────────
            ...dates.map((date) {
              final dataKey = soData(date);
              final status =
                  student.attendance[dataKey]?.first ?? AttendanceStatus.none;
              final temAtestado = status == AttendanceStatus.A;
              final arquivoNome = student.atestadoNome[dataKey];

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Label da data
                    Text(
                      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Botões P / F / A
                    Row(
                      children: [
                        _BotaoStatus(
                          label: 'Presente',
                          cor: _verde,
                          selecionado: status == AttendanceStatus.P,
                          onTap: () => onSetStatus(
                              date, AttendanceStatus.P),
                        ),
                        const SizedBox(width: 6),
                        _BotaoStatus(
                          label: 'Falta',
                          cor: _vermelho,
                          selecionado: status == AttendanceStatus.F,
                          onTap: () =>
                              onSetStatus(date, AttendanceStatus.F),
                        ),
                        const SizedBox(width: 6),
                        _BotaoStatus(
                          label: 'Atestado',
                          cor: _amarelo,
                          selecionado: temAtestado,
                          onTap: () =>
                              onSetStatus(date, AttendanceStatus.A),
                        ),
                      ],
                    ),
                    // Atalho para anexar comprovante
                    if (temAtestado) ...[
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () => onAnexarAtestado(date),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: _amarelo.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: _amarelo.withOpacity(0.35),
                                width: 0.8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                arquivoNome != null
                                    ? Icons.check_circle_outline
                                    : Icons.attach_file,
                                size: 14,
                                color: arquivoNome != null
                                    ? _verde
                                    : Colors.black45,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                arquivoNome ?? 'Anexar comprovante',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: arquivoNome != null
                                      ? _verde
                                      : Colors.black54,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(Icons.chevron_right,
                                  size: 14, color: Colors.grey.shade400),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}

// ─── Botão de status (Presente / Falta / Atestado) ────────────────────────────

class _BotaoStatus extends StatelessWidget {
  final String label;
  final Color cor;
  final bool selecionado;
  final VoidCallback onTap;

  const _BotaoStatus({
    required this.label,
    required this.cor,
    required this.selecionado,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: selecionado ? cor : cor.withOpacity(0.07),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selecionado ? cor : cor.withOpacity(0.25),
              width: 1.5,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: selecionado ? Colors.white : cor,
            ),
          ),
        ),
      ),
    );
  }
}