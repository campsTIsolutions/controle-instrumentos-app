// lib/features/chamada/tela_dia.dart
// Tela de detalhe de um dia: lista de alunos com botões P / F / A
// Carrega alunos do Supabase ao inicializar.
// Tem botão "Salvar" que persiste as chamadas no Supabase.

import 'package:flutter/material.dart';
import 'package:controle_instrumentos/features/instrumentos/ui/widgets/app_drawer.dart';
import 'models.dart';
import 'widgets.dart';
import 'supabase_service.dart';
import 'tela_atestado.dart';

class TelaDia extends StatefulWidget {
  final AulaRecord aula;

  /// [students] é opcional — se não informado, a tela busca do Supabase.
  final List<StudentRecord>? students;
  final VoidCallback? onChanged;

  const TelaDia({
    super.key,
    required this.aula,
    this.students,
    this.onChanged,
  });

  @override
  State<TelaDia> createState() => _TelaDiaState();
}

class _TelaDiaState extends State<TelaDia> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  bool _salvando = false;
  bool _temAlteracoes = false;
  bool _carregando = true;
  String? _erro;

  late List<StudentRecord> _students;

  /// Normaliza qualquer DateTime para meia-noite local (sem hora/fuso).
  /// Garante que datas do banco (UTC) e do app sejam iguais como chave de Map.
  DateTime _soData(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  /// Data da aula sempre normalizada — usada como chave em todos os Maps.
  DateTime get _dataKey => _soData(widget.aula.data);

  @override
  void initState() {
    super.initState();
    if (widget.students != null) {
      _students = widget.students!;
      _carregando = false;
    } else {
      _carregarAlunos();
    }
  }

  // ── Carrega alunos do Supabase e mescla chamadas existentes ──────────────
  Future<void> _carregarAlunos() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final alunos = await SupabaseService.fetchAlunos();
      final chamadas = await SupabaseService.fetchChamadas(widget.aula.id);

      for (final aluno in alunos) {
        final chamada = chamadas.firstWhere(
          (c) => c.idAluno == aluno.idAluno,
          orElse: () => ChamadaRecord(
            id: '',
            aulaId: widget.aula.id,
            idAluno: aluno.idAluno,
            status: AttendanceStatus.none,
          ),
        );
        // FIX: usa _dataKey normalizado como chave do Map
        aluno.attendance[_dataKey] = [chamada.status];
        if (chamada.comprovanteUrl != null) {
          aluno.atestadoNome[_dataKey] = chamada.comprovanteUrl;
        }
      }

      setState(() {
        _students = alunos;
        _carregando = false;
      });
    } catch (e) {
      setState(() {
        _erro = 'Erro ao carregar alunos: $e';
        _carregando = false;
      });
    }
  }

  // ── Alterar status de um aluno ────────────────────────────────────────────
  void _setStatus(int si, int ri, AttendanceStatus novoStatus) {
    setState(() {
      // FIX: usa _dataKey normalizado em vez de _data diretamente
      _students[si].attendance[_dataKey]![ri] = novoStatus;
      if (novoStatus != AttendanceStatus.A) {
        _students[si].atestadoNome[_dataKey] = null;
      }
      _temAlteracoes = true;
    });
    widget.onChanged?.call();
  }

  // ── Abrir tela de atestado ────────────────────────────────────────────────
  void _abrirAtestado(int si) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TelaAtestado(
          student: _students[si],
          data: _dataKey, // FIX: passa _dataKey normalizado
          onAnexado: (nomeArquivo) {
            setState(() {
              // FIX: usa _dataKey normalizado
              _students[si].atestadoNome[_dataKey] = nomeArquivo;
              _temAlteracoes = true;
            });
            widget.onChanged?.call();
          },
        ),
      ),
    );
  }

  // ── Salvar no Supabase ────────────────────────────────────────────────────
  Future<void> _salvar() async {
    setState(() => _salvando = true);
    try {
      await SupabaseService.salvarTodasChamadas(
        aulaId: widget.aula.id,
        alunos: _students,
        data: _dataKey, // FIX: passa _dataKey normalizado
      );
      setState(() {
        _salvando = false;
        _temAlteracoes = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text('Chamada salva com sucesso!'),
              ],
            ),
            backgroundColor: Color(0xFF4CAF50),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() => _salvando = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatDate(DateTime d) {
    final dia = d.day.toString().padLeft(2, '0');
    final mes = d.month.toString().padLeft(2, '0');
    return '$dia/$mes/${d.year}';
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: const AppDrawer(),
      backgroundColor: Colors.grey.shade100,
      appBar: _buildAppBar(),
      body: _carregando
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1976D2)))
          : _erro != null
              ? _buildErro()
              : Column(
                  children: [
                    Expanded(
                      child: _students.isEmpty
                          ? _buildVazio()
                          : ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: _students.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (context, si) => _CardAluno(
                                student: _students[si],
                                data: _dataKey, // FIX: passa _dataKey normalizado
                                onSetStatus: (ri, status) =>
                                    _setStatus(si, ri, status),
                                onAbrirAtestado: () => _abrirAtestado(si),
                              ),
                            ),
                    ),
                    _buildBotaoSalvar(),
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
        icon: const Icon(Icons.menu, color: Colors.black87),
        onPressed: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Chamada do dia',
            style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 16),
          ),
          Text(
            _formatDate(_dataKey),
            style: const TextStyle(
                color: Colors.black45,
                fontSize: 11,
                fontWeight: FontWeight.normal),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () {
            if (_temAlteracoes) {
              _mostrarDialogSairSemSalvar();
            } else {
              Navigator.pop(context);
            }
          },
        ),
        if (_temAlteracoes)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFFC107).withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
                border:
                    Border.all(color: const Color(0xFFFFC107), width: 0.8),
              ),
              child: const Text(
                'Não salvo',
                style: TextStyle(
                    fontSize: 10,
                    color: Color(0xFFE65100),
                    fontWeight: FontWeight.w600),
              ),
            ),
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
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _carregarAlunos,
            icon: const Icon(Icons.refresh),
            label: const Text('Tentar novamente'),
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF1976D2)),
          ),
        ],
      ),
    );
  }

  Widget _buildVazio() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.people_outline, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'Nenhum aluno cadastrado.\nCadastre alunos na tela do mês.',
            textAlign: TextAlign.center,
            style:
                TextStyle(fontSize: 14, color: Colors.grey.shade500, height: 1.5),
          ),
        ],
      ),
    );
  }

  // ── Diálogo ao tentar sair sem salvar ─────────────────────────────────────
  Future<void> _mostrarDialogSairSemSalvar() async {
    final acao = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Alterações não salvas'),
        content: const Text(
            'Você tem alterações que não foram salvas. O que deseja fazer?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'descartar'),
            child: const Text('Descartar',
                style: TextStyle(color: Colors.red)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'cancelar'),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, 'salvar'),
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF1976D2)),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );

    if (acao == 'salvar') {
      await _salvar();
      if (mounted) Navigator.pop(context);
    } else if (acao == 'descartar') {
      if (mounted) Navigator.pop(context);
    }
  }

  // ── Rodapé com botão Salvar ───────────────────────────────────────────────
  Widget _buildBotaoSalvar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: _salvando ? null : _salvar,
          icon: _salvando
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.save_outlined, size: 18),
          label: Text(
            _salvando ? 'Salvando...' : 'Salvar chamada',
            style: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.w600),
          ),
          style: FilledButton.styleFrom(
            backgroundColor: _temAlteracoes
                ? const Color(0xFF1976D2)
                : Colors.grey.shade400,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Card de aluno ────────────────────────────────────────────────────────────

class _CardAluno extends StatelessWidget {
  final StudentRecord student;
  final DateTime data;
  final void Function(int ri, AttendanceStatus status) onSetStatus;
  final VoidCallback onAbrirAtestado;

  const _CardAluno({
    required this.student,
    required this.data,
    required this.onSetStatus,
    required this.onAbrirAtestado,
  });

  @override
  Widget build(BuildContext context) {
    // data já chega normalizado via _dataKey, sem risco de fuso
    final statuses = student.attendance[data] ?? [AttendanceStatus.none];
    final temAtestado = statuses.contains(AttendanceStatus.A);
    final arquivoNome = student.atestadoNome[data];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 2)),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Nome + pills de status ────────────────────────────────────────
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
                      fontSize: 14),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  student.name,
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87),
                ),
              ),
              // Pills de resumo dos status selecionados
              ...statuses
                  .where((s) => s != AttendanceStatus.none)
                  .map((s) => Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Container(
                          width: 28,
                          height: 20,
                          decoration: BoxDecoration(
                              color: s.backgroundColor,
                              borderRadius: BorderRadius.circular(10)),
                          alignment: Alignment.center,
                          child: Text(
                            s.label,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 11),
                          ),
                        ),
                      )),
            ],
          ),
          const SizedBox(height: 14),

          // ── Botões P / F / A por aula ─────────────────────────────────────
          ...List.generate(
            statuses.length,
            (ri) => Padding(
              padding: EdgeInsets.only(
                  bottom: ri < statuses.length - 1 ? 10 : 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (statuses.length > 1)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text('Aula ${ri + 1}',
                          style: const TextStyle(
                              fontSize: 11, color: Colors.black45)),
                    ),
                  Row(
                    children: [
                      BotaoStatus(
                        label: 'P',
                        cor: const Color(0xFF4CAF50),
                        selecionado:
                            statuses[ri] == AttendanceStatus.P,
                        onTap: () =>
                            onSetStatus(ri, AttendanceStatus.P),
                      ),
                      const SizedBox(width: 8),
                      BotaoStatus(
                        label: 'F',
                        cor: const Color(0xFFE53935),
                        selecionado:
                            statuses[ri] == AttendanceStatus.F,
                        onTap: () =>
                            onSetStatus(ri, AttendanceStatus.F),
                      ),
                      const SizedBox(width: 8),
                      BotaoStatus(
                        label: 'Atestado',
                        cor: const Color(0xFFFFC107),
                        selecionado:
                            statuses[ri] == AttendanceStatus.A,
                        onTap: () =>
                            onSetStatus(ri, AttendanceStatus.A),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ── Atalho para anexar atestado ───────────────────────────────────
          if (temAtestado) ...[
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  arquivoNome != null
                      ? Icons.check_circle_outline
                      : Icons.attachment,
                  size: 16,
                  color: arquivoNome != null
                      ? const Color(0xFF4CAF50)
                      : Colors.black45,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    arquivoNome ?? 'Nenhum comprovante anexado',
                    style: TextStyle(
                        fontSize: 12,
                        color: arquivoNome != null
                            ? const Color(0xFF4CAF50)
                            : Colors.black45),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton(
                  onPressed: onAbrirAtestado,
                  style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFFFC107),
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8)),
                  child: Text(
                    arquivoNome != null ? 'Trocar' : 'Anexar',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
