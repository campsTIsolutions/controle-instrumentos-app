import 'package:controle_instrumentos/core/utils/pagination_utils.dart';
import 'package:controle_instrumentos/core/utils/debouncer.dart';
import 'package:flutter/material.dart';
import 'package:controle_instrumentos/features/instrumentos/ui/widgets/app_drawer.dart';
import 'package:controle_instrumentos/features/historico/repository/historico_repository.dart';
import 'package:controle_instrumentos/features/historico/widgets/historico_filters.dart';
import 'package:controle_instrumentos/features/historico/widgets/historico_log_detalhes_dialog.dart';
import 'package:controle_instrumentos/features/historico/widgets/historico_logs_list.dart';
import 'package:controle_instrumentos/shared/widgets/pagination_footer.dart';
import 'package:controle_instrumentos/core/theme/theme.dart';

class HistoricoPage extends StatefulWidget {
  const HistoricoPage({super.key});

  @override
  State<HistoricoPage> createState() => _HistoricoPageState();
}

class _HistoricoPageState extends State<HistoricoPage> {
  final _historicoRepository = HistoricoRepository();
  final _searchDebouncer = Debouncer(delay: const Duration(milliseconds: 250));
  final _searchController = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  List<Map<String, dynamic>> _logs = [];
  List<Map<String, dynamic>> _logsFiltrados = [];
  bool _isLoading = true;

  int _currentPage = 1;
  final int _itensPorPagina = 10;

  bool _ordenarAlfabetico = false;
  final List<String> _filtroCategoria = [];
  final List<String> _filtroSetor = [];
  final List<String> _filtroMotivo = [];
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
  static const _motivoConfig = <String, MotivoVisual>{
    'Falta de Tempo': MotivoVisual(
      icone: Icons.schedule_outlined,
      cor: Color(0xFF2563EB),
      corFundo: Color(0xFFEFF6FF),
    ),
    'Falta de Disciplina': MotivoVisual(
      icone: Icons.rule_outlined,
      cor: Color(0xFFD97706),
      corFundo: Color(0xFFFFFBEB),
    ),
    'Falta de Interesse': MotivoVisual(
      icone: Icons.sentiment_dissatisfied_outlined,
      cor: Color(0xFF7C3AED),
      corFundo: Color(0xFFF5F3FF),
    ),
    'Outro': MotivoVisual(
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
    _searchDebouncer.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _carregarLogs() async {
    setState(() => _isLoading = true);
    try {
      final response = await _historicoRepository.listarLogs();

      setState(() {
        _logs = response.map((l) => l.toMap()).toList();
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
    return pagedSlice(
      items: _logsFiltrados,
      currentPage: _currentPage,
      itemsPerPage: _itensPorPagina,
    );
  }

  int get _totalPaginas => pageCount(
    totalItems: _logsFiltrados.length,
    itemsPerPage: _itensPorPagina,
  );

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
      await _historicoRepository.deletarLog(idLog);
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
      builder: (ctx) => HistoricoLogDetalhesDialog(log: log),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
      drawer: const AppDrawer(),
      appBar: AppBar(
        leading: IconButton(
          icon: SizedBox(
            width: 24,
            height: 24,
            child: Image.asset('assets/menu-icon.png'),
          ),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
          style: IconButton.styleFrom(
            backgroundColor: const Color.fromARGB(0, 255, 255, 255),
          ),
        ),
        title: const Text(
          'CAMPS',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 25,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Colors.grey),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Cabeçalho ──────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.xxs,
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Histórico', style: AppTextStyles.pageTitle),
                          SizedBox(height: 2),
                          Text(
                            'Alunos desligados e seus motivos',
                            style: AppTextStyles.sectionSubtitle,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceDark,
                        borderRadius: BorderRadius.circular(AppRadii.pill),
                      ),
                      child: Text(
                        '${_logs.length} registro${_logs.length != 1 ? 's' : ''}',
                        style: AppTextStyles.badge,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── Filtro de Ano ──────────────────────────────────────────────
              if (!_isLoading && _anosDisponiveis.isNotEmpty)
                FiltroAno(
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
                DashboardMotivos(
                  contagem: _contagemMotivos,
                  motivoConfig: _motivoConfig,
                  anoFiltrado: _filtroAno,
                ),

              const SizedBox(height: 12),

              // ── Campo de busca ─────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xxs,
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) {
                    _searchDebouncer.run(() {
                      if (!mounted) return;
                      _aplicarFiltros();
                    });
                  },
                  style: const TextStyle(color: Colors.black87),
                  decoration: InputDecoration(
                    hintText: 'Buscar por nome ou número...',
                    hintStyle: const TextStyle(color: AppColors.textMuted),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: AppColors.textSecondary,
                    ),
                    filled: true,
                    fillColor: AppColors.surface,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.sm,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadii.md),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // ── Filtros horizontais ────────────────────────────────────────
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FiltroChipGroup(
                      label: '',
                      children: [
                        CheckboxChipWidget(
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
                    FiltroChipGroup(
                      label: 'Motivo',
                      children: _motivos.map((m) {
                        return CheckboxChipWidget(
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
                    FiltroChipGroup(
                      label: 'Categoria',
                      children: _categorias.map((cat) {
                        return CheckboxChipWidget(
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
                    FiltroChipGroup(
                      label: 'Setor',
                      children: _setores.map((setor) {
                        return CheckboxChipWidget(
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
                HistoricoLogsList(
                  logs: _logsPaginados,
                  currentPage: _currentPage,
                  itensPorPagina: _itensPorPagina,
                  isTablet: isTablet,
                  onVerDetalhes: _verDetalhes,
                  onDeletar: (l) => _deletarLog(l['id_log'] as int),
                ),

                Container(
                  margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: PaginationFooter(
                    totalLabel:
                        '${_logsFiltrados.length} registro${_logsFiltrados.length != 1 ? 's' : ''}',
                    currentPage: _currentPage,
                    totalPages: _totalPaginas,
                    onFirstPage: () => setState(() => _currentPage = 1),
                    onPreviousPage: () => setState(
                      () => _currentPage = (_currentPage - 1).clamp(
                        1,
                        _totalPaginas,
                      ),
                    ),
                    onNextPage: () => setState(
                      () => _currentPage = (_currentPage + 1).clamp(
                        1,
                        _totalPaginas,
                      ),
                    ),
                    onLastPage: () =>
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
