import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HistoricoPage extends StatefulWidget {
  const HistoricoPage({super.key});

  @override
  State<HistoricoPage> createState() => _HistoricoPageState();
}

class _HistoricoPageState extends State<HistoricoPage> {
  final _supabase = Supabase.instance.client;
  final _searchController = TextEditingController();

  List<Map<String, dynamic>> _logs = [];
  List<Map<String, dynamic>> _logsFiltrados = [];
  bool _isLoading = true;

  int _currentPage = 1;
  final int _itensPorPagina = 10;

  bool _ordenarAlfabetico = false;
  List<String> _filtroCategoria = [];
  List<String> _filtroSetor = [];
  List<String> _filtroMotivo = [];
  int? _filtroAno; // novo

  final _categorias = [
    'Mentor(a)',
    'Kids',
    'Avançar',
    'Aprendiz',
    'Ex-Aprendiz',
  ];
  final _setores = ['Dança', 'Escudo', 'Pavilhão', 'Linha', 'Baliza'];
  final _motivos = [
    'Falta de Tempo',
    'Falta de Disciplina',
    'Falta de Interesse',
    'Outro',
  ];

  // Configurações visuais de cada motivo para o dashboard
  static const _motivoConfig = <String, _MotivoVisual>{
    'Falta de Tempo': _MotivoVisual(
      icone: Icons.schedule_outlined,
      cor: Color(0xFF2563EB),
      corFundo: Color(0xFFEFF6FF),
    ),
    'Falta de Disciplina': _MotivoVisual(
      icone: Icons.rule_outlined,
      cor: Color(0xFFD97706),
      corFundo: Color(0xFFFFFBEB),
    ),
    'Falta de Interesse': _MotivoVisual(
      icone: Icons.sentiment_dissatisfied_outlined,
      cor: Color(0xFF7C3AED),
      corFundo: Color(0xFFF5F3FF),
    ),
    'Outro': _MotivoVisual(
      icone: Icons.edit_note_outlined,
      cor: Color(0xFF059669),
      corFundo: Color(0xFFECFDF5),
    ),
  };

  @override
  void initState() {
    super.initState();
    _carregarLogs();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _carregarLogs() async {
    setState(() => _isLoading = true);
    try {
      final response = await _supabase
          .from('logs')
          .select(
            'id_log, id_aluno, numero_aluno, nome_completo, setor, '
            'categoria_usuario, nivel, telefone, imagem_url, idade, '
            'motivo_exclusao, data_exclusao',
          )
          .order('data_exclusao', ascending: false);

      setState(() {
        _logs = List<Map<String, dynamic>>.from(response);
        _aplicarFiltros();
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar histórico: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Anos únicos presentes nos logs, ordenados do mais recente.
  List<int> get _anosDisponiveis {
    final anos = <int>{};
    for (final l in _logs) {
      final raw = l['data_exclusao']?.toString();
      if (raw == null) continue;
      try {
        anos.add(DateTime.parse(raw).year);
      } catch (_) {}
    }
    return anos.toList()..sort((a, b) => b.compareTo(a));
  }

  /// Contagem de cada motivo considerando apenas o filtro de ano
  /// (o dashboard reflete o ano, não os demais filtros).
  Map<String, int> get _contagemMotivos {
    final base = _filtroAno == null
        ? _logs
        : _logs.where((l) {
            final raw = l['data_exclusao']?.toString();
            if (raw == null) return false;
            try {
              return DateTime.parse(raw).year == _filtroAno;
            } catch (_) {
              return false;
            }
          }).toList();

    final contagem = {for (final m in _motivos) m: 0};
    for (final log in base) {
      final m = log['motivo_exclusao']?.toString() ?? '';
      for (final motivo in _motivos) {
        final match = motivo == 'Outro' ? m.startsWith('Outro') : m == motivo;
        if (match) {
          contagem[motivo] = contagem[motivo]! + 1;
          break;
        }
      }
    }
    return contagem;
  }

  void _aplicarFiltros() {
    List<Map<String, dynamic>> resultado = List.from(_logs);

    // Filtro de ano
    if (_filtroAno != null) {
      resultado = resultado.where((l) {
        final raw = l['data_exclusao']?.toString();
        if (raw == null) return false;
        try {
          return DateTime.parse(raw).year == _filtroAno;
        } catch (_) {
          return false;
        }
      }).toList();
    }

    final query = _searchController.text.toLowerCase();
    if (query.isNotEmpty) {
      resultado = resultado
          .where(
            (l) =>
                l['nome_completo'].toString().toLowerCase().contains(query) ||
                l['numero_aluno'].toString().contains(query),
          )
          .toList();
    }

    if (_filtroCategoria.isNotEmpty) {
      resultado = resultado
          .where((l) => _filtroCategoria.contains(l['categoria_usuario']))
          .toList();
    }

    if (_filtroSetor.isNotEmpty) {
      resultado = resultado
          .where((l) => _filtroSetor.contains(l['setor']))
          .toList();
    }

    if (_filtroMotivo.isNotEmpty) {
      resultado = resultado.where((l) {
        final m = l['motivo_exclusao']?.toString() ?? '';
        return _filtroMotivo.any(
          (fm) => fm == 'Outro' ? m.startsWith('Outro') : m == fm,
        );
      }).toList();
    }

    if (_ordenarAlfabetico) {
      resultado.sort(
        (a, b) => (a['nome_completo'] as String).compareTo(
          b['nome_completo'] as String,
        ),
      );
    }

    setState(() {
      _logsFiltrados = resultado;
      _currentPage = 1;
    });
  }

  List<Map<String, dynamic>> get _logsPaginados {
    final inicio = (_currentPage - 1) * _itensPorPagina;
    final fim = inicio + _itensPorPagina;
    return _logsFiltrados.sublist(
      inicio.clamp(0, _logsFiltrados.length),
      fim.clamp(0, _logsFiltrados.length),
    );
  }

  int get _totalPaginas =>
      (_logsFiltrados.length / _itensPorPagina).ceil().clamp(1, 9999);

  Future<void> _deletarLog(int idLog) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Remover Registro',
          style: TextStyle(color: Colors.white, fontSize: 17),
        ),
        content: const Text(
          'Deseja remover permanentemente este registro do histórico?',
          style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFB91C1C),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Remover', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      await _supabase.from('logs').delete().eq('id_log', idLog);
      _carregarLogs();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registro removido do histórico.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao remover: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _verDetalhes(Map<String, dynamic> log) {
    showDialog(
      context: context,
      builder: (ctx) => _LogDetalhesDialog(log: log),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F3F5),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Cabeçalho ──────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
                child: Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Histórico',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1A2E),
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Alunos desligados e seus motivos',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A2E),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_logs.length} registro${_logs.length != 1 ? 's' : ''}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── Filtro de Ano ──────────────────────────────────────────────
              if (!_isLoading && _anosDisponiveis.isNotEmpty)
                _FiltroAno(
                  anos: _anosDisponiveis,
                  anoSelecionado: _filtroAno,
                  onChanged: (ano) {
                    setState(() => _filtroAno = ano);
                    _aplicarFiltros();
                  },
                ),

              const SizedBox(height: 12),

              // ── Dashboard de Motivos ───────────────────────────────────────
              if (!_isLoading && _logs.isNotEmpty)
                _DashboardMotivos(
                  contagem: _contagemMotivos,
                  motivoConfig: _motivoConfig,
                  anoFiltrado: _filtroAno,
                ),

              const SizedBox(height: 12),

              // ── Campo de busca ─────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => _aplicarFiltros(),
                  style: const TextStyle(color: Colors.black87),
                  decoration: InputDecoration(
                    hintText: 'Buscar por nome ou número...',
                    hintStyle: const TextStyle(color: Colors.black38),
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // ── Filtros horizontais ────────────────────────────────────────
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FiltroChipGroup(
                      label: '',
                      children: [
                        _CheckboxChip(
                          texto: 'A-Z',
                          selecionado: _ordenarAlfabetico,
                          onChanged: (v) {
                            setState(() => _ordenarAlfabetico = v);
                            _aplicarFiltros();
                          },
                        ),
                      ],
                    ),
                    const SizedBox(width: 10),
                    _FiltroChipGroup(
                      label: 'Motivo',
                      children: _motivos.map((m) {
                        return _CheckboxChip(
                          texto: m,
                          selecionado: _filtroMotivo.contains(m),
                          onChanged: (v) {
                            setState(() {
                              v
                                  ? _filtroMotivo.add(m)
                                  : _filtroMotivo.remove(m);
                            });
                            _aplicarFiltros();
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(width: 10),
                    _FiltroChipGroup(
                      label: 'Categoria',
                      children: _categorias.map((cat) {
                        return _CheckboxChip(
                          texto: cat,
                          selecionado: _filtroCategoria.contains(cat),
                          onChanged: (v) {
                            setState(() {
                              v
                                  ? _filtroCategoria.add(cat)
                                  : _filtroCategoria.remove(cat);
                            });
                            _aplicarFiltros();
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(width: 10),
                    _FiltroChipGroup(
                      label: 'Setor',
                      children: _setores.map((setor) {
                        return _CheckboxChip(
                          texto: setor,
                          selecionado: _filtroSetor.contains(setor),
                          onChanged: (v) {
                            setState(() {
                              v
                                  ? _filtroSetor.add(setor)
                                  : _filtroSetor.remove(setor);
                            });
                            _aplicarFiltros();
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // ── Lista / Tabela ─────────────────────────────────────────────
              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_logsFiltrados.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.history, size: 48, color: Color(0xFFD1D5DB)),
                        SizedBox(height: 12),
                        Text(
                          'Nenhum registro encontrado.',
                          style: TextStyle(color: Color(0xFF9CA3AF)),
                        ),
                      ],
                    ),
                  ),
                )
              else ...[
                if (isTablet)
                  _TabelaDesktop(
                    logs: _logsPaginados,
                    currentPage: _currentPage,
                    itensPorPagina: _itensPorPagina,
                    onVerDetalhes: _verDetalhes,
                    onDeletar: (l) => _deletarLog(l['id_log'] as int),
                  )
                else
                  _ListaCards(
                    logs: _logsPaginados,
                    currentPage: _currentPage,
                    itensPorPagina: _itensPorPagina,
                    onVerDetalhes: _verDetalhes,
                    onDeletar: (l) => _deletarLog(l['id_log'] as int),
                  ),

                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: _RodapePaginacao(
                    totalItens: _logsFiltrados.length,
                    currentPage: _currentPage,
                    totalPaginas: _totalPaginas,
                    onPrimeiraPagina: () => setState(() => _currentPage = 1),
                    onPaginaAnterior: () => setState(
                      () => _currentPage = (_currentPage - 1).clamp(
                        1,
                        _totalPaginas,
                      ),
                    ),
                    onProximaPagina: () => setState(
                      () => _currentPage = (_currentPage + 1).clamp(
                        1,
                        _totalPaginas,
                      ),
                    ),
                    onUltimaPagina: () =>
                        setState(() => _currentPage = _totalPaginas),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Modelo visual de motivo ──────────────────────────────────────────────────

class _MotivoVisual {
  const _MotivoVisual({
    required this.icone,
    required this.cor,
    required this.corFundo,
  });

  final IconData icone;
  final Color cor;
  final Color corFundo;
}

// ─── Filtro de Ano ────────────────────────────────────────────────────────────

class _FiltroAno extends StatelessWidget {
  const _FiltroAno({
    required this.anos,
    required this.anoSelecionado,
    required this.onChanged,
  });

  final List<int> anos;
  final int? anoSelecionado;
  final void Function(int?) onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ano',
            style: TextStyle(
              fontSize: 12,
              color: Colors.black54,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _AnoChip(
                  label: 'Todos',
                  selecionado: anoSelecionado == null,
                  onTap: () => onChanged(null),
                ),
                ...anos.map(
                  (ano) => Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: _AnoChip(
                      label: '$ano',
                      selecionado: anoSelecionado == ano,
                      onTap: () => onChanged(ano),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AnoChip extends StatelessWidget {
  const _AnoChip({
    required this.label,
    required this.selecionado,
    required this.onTap,
  });

  final String label;
  final bool selecionado;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selecionado ? const Color(0xFF1A1A2E) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selecionado
                ? const Color(0xFF1A1A2E)
                : const Color(0xFFE5E7EB),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selecionado ? Colors.white : const Color(0xFF6B7280),
          ),
        ),
      ),
    );
  }
}

// ─── Dashboard de Motivos ─────────────────────────────────────────────────────

class _DashboardMotivos extends StatelessWidget {
  const _DashboardMotivos({
    required this.contagem,
    required this.motivoConfig,
    required this.anoFiltrado,
  });

  final Map<String, int> contagem;
  final Map<String, _MotivoVisual> motivoConfig;
  final int? anoFiltrado;

  @override
  Widget build(BuildContext context) {
    final total = contagem.values.fold(0, (a, b) => a + b);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título + badge do ano
          Row(
            children: [
              const Text(
                'Motivos de Desligamento',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              const Spacer(),
              if (anoFiltrado != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$anoFiltrado',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF2563EB),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Todos os anos',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF6B7280),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 10),

          // Cards de contagem — 4 cards em linha
          Row(
            children: contagem.entries.toList().asMap().entries.map((entry) {
              final i = entry.key;
              final e = entry.value;
              final config = motivoConfig[e.key]!;
              final pct = total == 0 ? 0.0 : e.value / total;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(left: i == 0 ? 0 : 8),
                  child: _MotivoCard(
                    motivo: e.key,
                    quantidade: e.value,
                    percentual: pct,
                    visual: config,
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 10),

          // Barra de proporção
          if (total > 0)
            _BarraProporcao(contagem: contagem, motivoConfig: motivoConfig),
        ],
      ),
    );
  }
}

// ─── Card individual de motivo ────────────────────────────────────────────────

class _MotivoCard extends StatelessWidget {
  const _MotivoCard({
    required this.motivo,
    required this.quantidade,
    required this.percentual,
    required this.visual,
  });

  final String motivo;
  final int quantidade;
  final double percentual;
  final _MotivoVisual visual;

  String get _abrev {
    switch (motivo) {
      case 'Falta de Tempo':
        return 'Tempo';
      case 'Falta de Disciplina':
        return 'Disciplina';
      case 'Falta de Interesse':
        return 'Interesse';
      default:
        return motivo;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: visual.corFundo,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(visual.icone, size: 18, color: visual.cor),
          ),
          const SizedBox(height: 8),
          Text(
            '$quantidade',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: visual.cor,
            ),
          ),
          Text(
            _abrev,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            '${(percentual * 100).toStringAsFixed(0)}%',
            style: TextStyle(
              fontSize: 11,
              color: visual.cor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Barra de proporção ───────────────────────────────────────────────────────

class _BarraProporcao extends StatelessWidget {
  const _BarraProporcao({required this.contagem, required this.motivoConfig});

  final Map<String, int> contagem;
  final Map<String, _MotivoVisual> motivoConfig;

  @override
  Widget build(BuildContext context) {
    final total = contagem.values.fold(0, (a, b) => a + b);
    if (total == 0) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Barra segmentada
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            height: 8,
            child: Row(
              children: contagem.entries.map((e) {
                final flex = (e.value * 1000 ~/ total).clamp(1, 1000);
                return Expanded(
                  flex: flex,
                  child: Container(
                    color: motivoConfig[e.key]?.cor ?? Colors.grey,
                  ),
                );
              }).toList(),
            ),
          ),
        ),

        const SizedBox(height: 8),

        // Legenda inline
        Wrap(
          spacing: 14,
          runSpacing: 4,
          children: contagem.entries.map((e) {
            final cor = motivoConfig[e.key]?.cor ?? Colors.grey;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: cor, shape: BoxShape.circle),
                ),
                const SizedBox(width: 4),
                Text(
                  e.key,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ─── Grupo de filtros com label ───────────────────────────────────────────────

class _FiltroChipGroup extends StatelessWidget {
  const _FiltroChipGroup({required this.label, required this.children});

  final String? label;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label ?? '',
          style: const TextStyle(
            fontSize: 12,
            color: Colors.black,
            fontWeight: FontWeight.w500,
          ),
        ),
        Wrap(spacing: 8, children: children),
      ],
    );
  }
}

// ─── Checkbox chip reutilizável ───────────────────────────────────────────────

class _CheckboxChip extends StatelessWidget {
  const _CheckboxChip({
    required this.texto,
    required this.selecionado,
    required this.onChanged,
  });

  final String texto;
  final bool selecionado;
  final void Function(bool) onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!selecionado),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selecionado
                ? const Color(0xFF2563EB)
                : const Color(0xFFE5E7EB),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Checkbox(
              value: selecionado,
              onChanged: (v) => onChanged(v ?? false),
              activeColor: const Color(0xFF2563EB),
              checkColor: Colors.white,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            Text(
              texto,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Tabela Desktop (tablet >= 600dp) ────────────────────────────────────────

class _TabelaDesktop extends StatelessWidget {
  const _TabelaDesktop({
    required this.logs,
    required this.currentPage,
    required this.itensPorPagina,
    required this.onVerDetalhes,
    required this.onDeletar,
  });

  final List<Map<String, dynamic>> logs;
  final int currentPage;
  final int itensPorPagina;
  final void Function(Map<String, dynamic>) onVerDetalhes;
  final void Function(Map<String, dynamic>) onDeletar;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4),
        ],
      ),
      child: Column(
        children: [
          const _TabelaHeader(),
          const Divider(height: 1),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: logs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (ctx, i) {
              final log = logs[i];
              final numero = (currentPage - 1) * itensPorPagina + i + 1;
              return _TabelaLinha(
                numero: numero,
                log: log,
                onVerDetalhes: () => onVerDetalhes(log),
                onDeletar: () => onDeletar(log),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ─── Lista de Cards (mobile < 600dp) ─────────────────────────────────────────

class _ListaCards extends StatelessWidget {
  const _ListaCards({
    required this.logs,
    required this.currentPage,
    required this.itensPorPagina,
    required this.onVerDetalhes,
    required this.onDeletar,
  });

  final List<Map<String, dynamic>> logs;
  final int currentPage;
  final int itensPorPagina;
  final void Function(Map<String, dynamic>) onVerDetalhes;
  final void Function(Map<String, dynamic>) onDeletar;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: logs.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (ctx, i) {
          final log = logs[i];
          final numero = (currentPage - 1) * itensPorPagina + i + 1;
          return _LogCard(
            numero: numero,
            log: log,
            onVerDetalhes: () => onVerDetalhes(log),
            onDeletar: () => onDeletar(log),
          );
        },
      ),
    );
  }
}

// ─── Card de Log (mobile) ─────────────────────────────────────────────────────

class _LogCard extends StatelessWidget {
  const _LogCard({
    required this.numero,
    required this.log,
    required this.onVerDetalhes,
    required this.onDeletar,
  });

  final int numero;
  final Map<String, dynamic> log;
  final VoidCallback onVerDetalhes;
  final VoidCallback onDeletar;

  @override
  Widget build(BuildContext context) {
    final imagemUrl = log['imagem_url'] as String?;
    final motivo = log['motivo_exclusao']?.toString() ?? '-';
    final dataExclusao = _formatarData(log['data_exclusao']?.toString());

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24,
            child: Text(
              '$numero',
              style: const TextStyle(
                color: Color(0xFF9CA3AF),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Container(
            width: 44,
            height: 44,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: const Color(0xFFFEF2F2),
            ),
            clipBehavior: Clip.antiAlias,
            child: imagemUrl != null && imagemUrl.isNotEmpty
                ? Image.network(
                    imagemUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.person,
                      color: Color(0xFFB91C1C),
                      size: 24,
                    ),
                  )
                : const Icon(Icons.person, color: Color(0xFFB91C1C), size: 24),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        log['nome_completo']?.toString() ?? '',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF111827),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '#${log['numero_aluno']}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF6B7280),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    if (log['setor'] != null)
                      _Chip(
                        label: log['setor'],
                        cor: const Color(0xFFF3F4F6),
                        textoCor: const Color(0xFF374151),
                      ),
                    if (log['categoria_usuario'] != null)
                      _Chip(
                        label: log['categoria_usuario'],
                        cor: const Color(0xFFEDE9FE),
                        textoCor: const Color(0xFF5B21B6),
                      ),
                    if (log['nivel'] != null)
                      _Chip(
                        label: log['nivel'],
                        cor: const Color(0xFFECFDF5),
                        textoCor: const Color(0xFF065F46),
                      ),
                    if (log['idade'] != null)
                      _Chip(
                        label: '${log['idade']} anos',
                        cor: const Color(0xFFFFF7ED),
                        textoCor: const Color(0xFF9A3412),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      size: 13,
                      color: Color(0xFFEF4444),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        motivo,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFFB91C1C),
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 12,
                      color: Color(0xFF9CA3AF),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      dataExclusao,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            children: [
              _BotaoAcao(
                icone: Icons.visibility_outlined,
                cor: const Color(0xFF2563EB),
                onTap: onVerDetalhes,
              ),
              const SizedBox(height: 6),
              _BotaoAcao(
                icone: Icons.delete_outline,
                cor: const Color(0xFFB91C1C),
                onTap: onDeletar,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Cabeçalho da Tabela (tablet only) ───────────────────────────────────────

class _TabelaHeader extends StatelessWidget {
  const _TabelaHeader();

  static const _s = TextStyle(
    fontWeight: FontWeight.w600,
    color: Color(0xFF6B7280),
    fontSize: 12,
  );

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          SizedBox(width: 28, child: Text('#', style: _s)),
          SizedBox(width: 44, child: Text('Foto', style: _s)),
          SizedBox(width: 48, child: Text('Nº', style: _s)),
          SizedBox(width: 140, child: Text('Nome', style: _s)),
          SizedBox(width: 70, child: Text('Setor', style: _s)),
          SizedBox(width: 90, child: Text('Categoria', style: _s)),
          SizedBox(width: 120, child: Text('Motivo', style: _s)),
          Expanded(child: Text('Data Exclusão', style: _s)),
          SizedBox(width: 72),
        ],
      ),
    );
  }
}

// ─── Linha da Tabela (tablet only) ───────────────────────────────────────────

class _TabelaLinha extends StatelessWidget {
  const _TabelaLinha({
    required this.numero,
    required this.log,
    required this.onVerDetalhes,
    required this.onDeletar,
  });

  final int numero;
  final Map<String, dynamic> log;
  final VoidCallback onVerDetalhes;
  final VoidCallback onDeletar;

  static const _c = TextStyle(fontSize: 12, color: Color(0xFF111827));

  @override
  Widget build(BuildContext context) {
    final imagemUrl = log['imagem_url'] as String?;
    final motivo = log['motivo_exclusao']?.toString() ?? '-';
    final dataExclusao = _formatarData(log['data_exclusao']?.toString());

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '$numero',
              style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12),
            ),
          ),
          SizedBox(
            width: 44,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                color: const Color(0xFFFEF2F2),
              ),
              clipBehavior: Clip.antiAlias,
              child: imagemUrl != null && imagemUrl.isNotEmpty
                  ? Image.network(
                      imagemUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.person,
                        color: Color(0xFFB91C1C),
                        size: 16,
                      ),
                    )
                  : const Icon(
                      Icons.person,
                      color: Color(0xFFB91C1C),
                      size: 16,
                    ),
            ),
          ),
          SizedBox(
            width: 48,
            child: Text(log['numero_aluno']?.toString() ?? '', style: _c),
          ),
          SizedBox(
            width: 140,
            child: Text(
              log['nome_completo']?.toString() ?? '',
              style: _c,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            width: 70,
            child: Text(log['setor']?.toString() ?? '', style: _c),
          ),
          SizedBox(
            width: 90,
            child: Text(
              log['categoria_usuario']?.toString() ?? '',
              style: _c,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            width: 120,
            child: Text(
              motivo,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFFB91C1C),
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            child: Text(
              dataExclusao,
              style: _c,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            width: 72,
            child: Row(
              children: [
                _BotaoAcao(
                  icone: Icons.visibility_outlined,
                  cor: const Color(0xFF2563EB),
                  onTap: onVerDetalhes,
                ),
                const SizedBox(width: 6),
                _BotaoAcao(
                  icone: Icons.delete_outline,
                  cor: const Color(0xFFB91C1C),
                  onTap: onDeletar,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Dialog de Detalhes do Log ────────────────────────────────────────────────

class _LogDetalhesDialog extends StatelessWidget {
  const _LogDetalhesDialog({required this.log});

  final Map<String, dynamic> log;

  @override
  Widget build(BuildContext context) {
    final imagemUrl = log['imagem_url'] as String?;
    final motivo = log['motivo_exclusao']?.toString() ?? '-';
    final dataExclusao = _formatarData(log['data_exclusao']?.toString());

    return Dialog(
      backgroundColor: const Color(0xFF1E1E2E),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF374151),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.history,
                    color: Colors.white70,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Detalhes do Registro',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Informações do aluno desligado',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF9CA3AF),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white54),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: const Color(0xFF2A2A3E),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: imagemUrl != null && imagemUrl.isNotEmpty
                      ? Image.network(
                          imagemUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.person,
                            color: Color(0xFF9CA3AF),
                            size: 32,
                          ),
                        )
                      : const Icon(
                          Icons.person,
                          color: Color(0xFF9CA3AF),
                          size: 32,
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        log['nome_completo']?.toString() ?? '-',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Nº ${log['numero_aluno'] ?? '-'}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF9CA3AF),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(color: Color(0xFF2A2A3E)),
            const SizedBox(height: 16),
            _InfoGrid(log: log),
            const SizedBox(height: 16),
            const Divider(color: Color(0xFF2A2A3E)),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFB91C1C).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFFEF4444).withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: Color(0xFFEF4444),
                        size: 16,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Motivo do Desligamento',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFEF4444),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    motivo,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 12,
                        color: Color(0xFF9CA3AF),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Desligado em $dataExclusao',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF9CA3AF),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2A2A3E),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Fechar',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Grid de informações ──────────────────────────────────────────────────────

class _InfoGrid extends StatelessWidget {
  const _InfoGrid({required this.log});

  final Map<String, dynamic> log;

  @override
  Widget build(BuildContext context) {
    final itens = [
      _InfoItem(
        icone: Icons.group_outlined,
        label: 'Setor',
        valor: log['setor']?.toString() ?? '-',
      ),
      _InfoItem(
        icone: Icons.badge_outlined,
        label: 'Categoria',
        valor: log['categoria_usuario']?.toString() ?? '-',
      ),
      _InfoItem(
        icone: Icons.military_tech_outlined,
        label: 'Nível',
        valor: log['nivel']?.toString() ?? '-',
      ),
      _InfoItem(
        icone: Icons.cake_outlined,
        label: 'Idade',
        valor: log['idade'] != null ? '${log['idade']} anos' : '-',
      ),
      _InfoItem(
        icone: Icons.phone_outlined,
        label: 'Telefone',
        valor: log['telefone']?.toString().isNotEmpty == true
            ? log['telefone'].toString()
            : '-',
      ),
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: itens
          .map(
            (item) => SizedBox(
              width: (MediaQuery.of(context).size.width - 104) / 2,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(item.icone, size: 16, color: const Color(0xFF6B7280)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.label,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.valor,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _InfoItem {
  const _InfoItem({
    required this.icone,
    required this.label,
    required this.valor,
  });

  final IconData icone;
  final String label;
  final String valor;
}

// ─── Chip de badge/tag ────────────────────────────────────────────────────────

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.cor, required this.textoCor});

  final String label;
  final Color cor;
  final Color textoCor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: cor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: textoCor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

// ─── Botão de Ação ────────────────────────────────────────────────────────────

class _BotaoAcao extends StatelessWidget {
  const _BotaoAcao({
    required this.icone,
    required this.cor,
    required this.onTap,
  });

  final IconData icone;
  final Color cor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: cor,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icone, color: Colors.white, size: 16),
      ),
    );
  }
}

// ─── Rodapé com Paginação ─────────────────────────────────────────────────────

class _RodapePaginacao extends StatelessWidget {
  const _RodapePaginacao({
    required this.totalItens,
    required this.currentPage,
    required this.totalPaginas,
    required this.onPrimeiraPagina,
    required this.onPaginaAnterior,
    required this.onProximaPagina,
    required this.onUltimaPagina,
  });

  final int totalItens;
  final int currentPage;
  final int totalPaginas;
  final VoidCallback onPrimeiraPagina;
  final VoidCallback onPaginaAnterior;
  final VoidCallback onProximaPagina;
  final VoidCallback onUltimaPagina;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Flexible(
            child: Text(
              '$totalItens registro${totalItens != 1 ? 's' : ''}',
              style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Spacer(),
          _BotaoPagina(
            icone: Icons.first_page,
            onTap: currentPage > 1 ? onPrimeiraPagina : null,
          ),
          _BotaoPagina(
            icone: Icons.chevron_left,
            onTap: currentPage > 1 ? onPaginaAnterior : null,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              '$currentPage / $totalPaginas',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
          _BotaoPagina(
            icone: Icons.chevron_right,
            onTap: currentPage < totalPaginas ? onProximaPagina : null,
          ),
          _BotaoPagina(
            icone: Icons.last_page,
            onTap: currentPage < totalPaginas ? onUltimaPagina : null,
          ),
        ],
      ),
    );
  }
}

class _BotaoPagina extends StatelessWidget {
  const _BotaoPagina({required this.icone, this.onTap});

  final IconData icone;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Icon(
        icone,
        size: 20,
        color: onTap != null
            ? const Color(0xFF374151)
            : const Color(0xFFD1D5DB),
      ),
    );
  }
}

// ─── Utilitário: formatar data ISO 8601 ──────────────────────────────────────

String _formatarData(String? isoString) {
  if (isoString == null) return '-';
  try {
    final dt = DateTime.parse(isoString).toLocal();
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final y = dt.year;
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$d/$m/$y às $h:$min';
  } catch (_) {
    return isoString;
  }
}
