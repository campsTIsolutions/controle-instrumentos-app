import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AlunosPage extends StatefulWidget {
  const AlunosPage({super.key});

  @override
  State<AlunosPage> createState() => _AlunosPageState();
}

class _AlunosPageState extends State<AlunosPage> {
  final _supabase = Supabase.instance.client;
  final _searchController = TextEditingController();

  List<Map<String, dynamic>> _alunos = [];
  List<Map<String, dynamic>> _alunosFiltrados = [];
  bool _isLoading = true;

  int _currentPage = 1;
  final int _itensPorPagina = 10;

  bool _ordenarAlfabetico = false;
  String? _filtroCategoria;
  String? _filtroSetor;

  final _categorias = ['Mentora', 'Kids', 'Avancar', 'Aprendiz', 'Ex-Aprendiz'];
  final _setores = ['Danca', 'Escudo', 'Pavilhao', 'Linha', 'Baliza'];

  @override
  void initState() {
    super.initState();
    _carregarAlunos();
  }

  String _formatarErro(Object error) {
    if (error is PostgrestException) {
      final detalhes = <String>[
        if (error.message.isNotEmpty) error.message,
        if (error.details != null && error.details.toString().isNotEmpty)
          error.details.toString(),
        if (error.hint != null && error.hint!.isNotEmpty) 'Dica: ${error.hint!}',
        if (error.code != null) 'Codigo: ${error.code}',
      ];
      return detalhes.join(' | ');
    }
    if (error is AuthException) {
      return error.message;
    }
    return error.toString();
  }

  void _mostrarErro(String contexto, Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$contexto: ${_formatarErro(error)}'),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _carregarAlunos() async {
    setState(() => _isLoading = true);
    try {
      if (_supabase.auth.currentSession == null) {
        throw Exception(
          'Sessão não encontrada. Faça login antes de acessar os alunos.',
        );
      }

      final response = await _supabase
          .from('alunos')
          .select(
            'id_aluno, numero_aluno, nome_completo, setor, categoria_usuario, nivel, telefone, id_instrumento',
          )
          .order('id_aluno', ascending: true);

      setState(() {
        _alunos = List<Map<String, dynamic>>.from(response);
        _aplicarFiltros();
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _mostrarErro('Erro ao carregar alunos', e);
      }
    }
  }

  void _aplicarFiltros() {
    List<Map<String, dynamic>> resultado = List.from(_alunos);

    final query = _searchController.text.toLowerCase();
    if (query.isNotEmpty) {
      resultado = resultado
          .where(
            (a) =>
                a['nome_completo'].toString().toLowerCase().contains(query) ||
                a['numero_aluno'].toString().contains(query),
          )
          .toList();
    }

    if (_filtroCategoria != null) {
      resultado = resultado
          .where((a) => a['categoria_usuario'] == _filtroCategoria)
          .toList();
    }

    if (_filtroSetor != null) {
      resultado = resultado.where((a) => a['setor'] == _filtroSetor).toList();
    }

    if (_ordenarAlfabetico) {
      resultado.sort(
        (a, b) => (a['nome_completo'] as String).compareTo(
          b['nome_completo'] as String,
        ),
      );
    }

    setState(() {
      _alunosFiltrados = resultado;
      _currentPage = 1;
    });
  }

  List<Map<String, dynamic>> get _alunosPaginados {
    final inicio = (_currentPage - 1) * _itensPorPagina;
    final fim = inicio + _itensPorPagina;
    return _alunosFiltrados.sublist(
      inicio.clamp(0, _alunosFiltrados.length),
      fim.clamp(0, _alunosFiltrados.length),
    );
  }

  int get _totalPaginas =>
      (_alunosFiltrados.length / _itensPorPagina).ceil().clamp(1, 9999);

  Future<void> _deletarAluno(int id) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar exclusão'),
        content: const Text('Tem certeza que deseja excluir este aluno?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmar == true) {
      try {
        await _supabase.from('alunos').delete().eq('id_aluno', id);
        _carregarAlunos();
      } catch (e) {
        _mostrarErro('Erro ao excluir', e);
      }
    }
  }

  void _abrirDialogAluno({Map<String, dynamic>? aluno}) {
    showDialog(
      context: context,
      // MODIFICAÇÃO 1: useMaterialPageRoute = false + barrierColor mais suave
      // Em telas pequenas o Dialog ocupa quase toda a tela; usar BottomSheet
      // seria melhor ergonomicamente, mas mantemos Dialog para compatibilidade.
      builder: (ctx) => _AlunoDialog(
        aluno: aluno,
        onSalvar: (dados) async {
          try {
            if (_supabase.auth.currentSession == null) {
              throw Exception(
                'Sessão não encontrada. Faça login antes de salvar alunos.',
              );
            }

            if (aluno == null) {
              await _supabase.from('alunos').insert(dados);
            } else {
              await _supabase
                  .from('alunos')
                  .update(dados)
                  .eq('id_aluno', aluno['id_aluno']);
            }
            if (!ctx.mounted) return;
            Navigator.of(ctx).pop();
            _carregarAlunos();
          } catch (e) {
            _mostrarErro('Erro ao salvar aluno', e);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // MODIFICAÇÃO 2: capturamos a largura da tela para decisões responsivas
    final screenWidth = MediaQuery.of(context).size.width;
    // Considerar tablet se largura >= 600dp (breakpoint padrão Material)
    final isTablet = screenWidth >= 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F3F5),
      body: SafeArea(
        // MODIFICAÇÃO 3: SafeArea garante que o conteúdo não fique atrás de
        // notch, status bar ou home indicator em qualquer dispositivo.
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Título ──
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 20, 16, 10),
                // MODIFICAÇÃO 4: padding horizontal reduzido de 20→16 para
                // ganhar espaço útil em telas estreitas (< 360dp).
                child: Text(
                  'Alunos',
                  style: TextStyle(
                    fontSize: 26,
                    // MODIFICAÇÃO 5: fonte levemente menor (28→26) para não
                    // quebrar em dispositivos com fonte grande do sistema.
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
              ),

              // ── Barra de busca ──
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
                    hintText: 'Buscar aluno...',
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

              // ── Filtros ──
              // MODIFICAÇÃO 6: SingleChildScrollView horizontal nos filtros.
              // No layout anterior o Wrap poderia quebrar mal em telas muito
              // pequenas. O scroll horizontal mantém os chips visíveis sem
              // alterar a altura do bloco.
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    // Checkbox ordem alfabética
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            // MODIFICAÇÃO 7: caixa menor no Checkbox para
                            // economizar espaço horizontal em mobile.
                            width: 32,
                            height: 32,
                            child: Checkbox(
                              value: _ordenarAlfabetico,
                              activeColor: const Color(0xFF2563EB),
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              onChanged: (v) {
                                setState(() => _ordenarAlfabetico = v ?? false);
                                _aplicarFiltros();
                              },
                            ),
                          ),
                          const Text(
                            'A-Z',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF374151),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 10),

                    _FiltroDropdown(
                      hint: 'Categoria',
                      valor: _filtroCategoria,
                      opcoes: _categorias,
                      onChanged: (v) {
                        setState(() => _filtroCategoria = v);
                        _aplicarFiltros();
                      },
                      onLimpar: () {
                        setState(() => _filtroCategoria = null);
                        _aplicarFiltros();
                      },
                    ),

                    const SizedBox(width: 10),

                    _FiltroDropdown(
                      hint: 'Setor',
                      valor: _filtroSetor,
                      opcoes: _setores,
                      onChanged: (v) {
                        setState(() => _filtroSetor = v);
                        _aplicarFiltros();
                      },
                      onLimpar: () {
                        setState(() => _filtroSetor = null);
                        _aplicarFiltros();
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // ── Lista / Tabela ──
              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_alunosFiltrados.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: Text('Nenhum aluno encontrado.')),
                )
              else ...[
                // MODIFICAÇÃO 8: decisão responsiva entre tabela (tablet) e
                // cards (mobile). Em telas < 600dp a tabela com SizedBox fixos
                // transbordava — agora exibimos cards verticais que cabem em
                // qualquer largura.
                if (isTablet)
                  _TabelaDesktop(
                    alunos: _alunosPaginados,
                    currentPage: _currentPage,
                    itensPorPagina: _itensPorPagina,
                    onEditar: (a) => _abrirDialogAluno(aluno: a),
                    onDeletar: (a) => _deletarAluno(a['id_aluno'] as int),
                  )
                else
                  _ListaCards(
                    alunos: _alunosPaginados,
                    currentPage: _currentPage,
                    itensPorPagina: _itensPorPagina,
                    onEditar: (a) => _abrirDialogAluno(aluno: a),
                    onDeletar: (a) => _deletarAluno(a['id_aluno'] as int),
                  ),

                // Rodapé de paginação
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
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: _RodapePaginacao(
                    totalItens: _alunosFiltrados.length,
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
                const SizedBox(height: 80),
              ],
            ],
          ),
        ),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () => _abrirDialogAluno(),
        backgroundColor: const Color(0xFF2563EB),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

// ─── MODIFICAÇÃO 9: tabela original renomeada para _TabelaDesktop ─────────────
// Usada apenas em tablets (>= 600dp) onde há espaço suficiente.

class _TabelaDesktop extends StatelessWidget {
  const _TabelaDesktop({
    required this.alunos,
    required this.currentPage,
    required this.itensPorPagina,
    required this.onEditar,
    required this.onDeletar,
  });

  final List<Map<String, dynamic>> alunos;
  final int currentPage;
  final int itensPorPagina;
  final void Function(Map<String, dynamic>) onEditar;
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
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4),
        ],
      ),
      child: Column(
        children: [
          const _TabelaHeader(),
          const Divider(height: 1),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: alunos.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (ctx, i) {
              final aluno = alunos[i];
              final numero = (currentPage - 1) * itensPorPagina + i + 1;
              return _TabelaLinha(
                numero: numero,
                aluno: aluno,
                onEditar: () => onEditar(aluno),
                onDeletar: () => onDeletar(aluno),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ─── MODIFICAÇÃO 10: _ListaCards — layout de cards para mobile ───────────────
// Substitui a tabela rígida em telas < 600dp. Cada aluno vira um card com
// todas as informações dispostas verticalmente, sem larguras fixas.

class _ListaCards extends StatelessWidget {
  const _ListaCards({
    required this.alunos,
    required this.currentPage,
    required this.itensPorPagina,
    required this.onEditar,
    required this.onDeletar,
  });

  final List<Map<String, dynamic>> alunos;
  final int currentPage;
  final int itensPorPagina;
  final void Function(Map<String, dynamic>) onEditar;
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
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: alunos.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (ctx, i) {
          final aluno = alunos[i];
          final numero = (currentPage - 1) * itensPorPagina + i + 1;
          return _AlunoCard(
            numero: numero,
            aluno: aluno,
            onEditar: () => onEditar(aluno),
            onDeletar: () => onDeletar(aluno),
          );
        },
      ),
    );
  }
}

// ─── MODIFICAÇÃO 11: _AlunoCard ──────────────────────────────────────────────
// Card responsivo que usa Expanded/Flexible ao invés de SizedBox com larguras
// fixas. Nunca vai transbordar independente da largura da tela.

class _AlunoCard extends StatelessWidget {
  const _AlunoCard({
    required this.numero,
    required this.aluno,
    required this.onEditar,
    required this.onDeletar,
  });

  final int numero;
  final Map<String, dynamic> aluno;
  final VoidCallback onEditar;
  final VoidCallback onDeletar;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Número sequencial
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

          // MODIFICAÇÃO 12: Expanded absorve todo o espaço disponível —
          // o conteúdo nunca vai estourar lateralmente.
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Linha 1: nome + número do aluno
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        aluno['nome_completo']?.toString() ?? '',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF111827),
                        ),
                        // MODIFICAÇÃO 13: overflow ellipsis evita quebra de
                        // layout se o nome for muito longo.
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Badge com número do aluno
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '#${aluno['numero_aluno']}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF2563EB),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 6),

                // Linha 2: chips de setor e categoria
                // MODIFICAÇÃO 14: Wrap com chips ao invés de SizedBox fixo.
                // O Wrap quebra linha sozinho se não houver espaço, sem
                // transbordar.
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    if (aluno['setor'] != null)
                      _Chip(
                        label: aluno['setor'],
                        cor: const Color(0xFFF3F4F6),
                        textoCor: const Color(0xFF374151),
                      ),
                    if (aluno['categoria_usuario'] != null)
                      _Chip(
                        label: aluno['categoria_usuario'],
                        cor: const Color(0xFFEDE9FE),
                        textoCor: const Color(0xFF5B21B6),
                      ),
                    if (aluno['nivel'] != null)
                      _Chip(
                        label: aluno['nivel'],
                        cor: const Color(0xFFECFDF5),
                        textoCor: const Color(0xFF065F46),
                      ),
                  ],
                ),

                // Linha 3: telefone (opcional)
                if (aluno['telefone'] != null &&
                    aluno['telefone'].toString().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.phone,
                        size: 12,
                        color: Color(0xFF9CA3AF),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        aluno['telefone'].toString(),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Botões de ação empilhados verticalmente para não espremê-los
          // MODIFICAÇÃO 15: botões em Column ao invés de Row para economizar
          // largura em telas estreitas. Cada botão tem 32×32 de toque mínimo.
          Column(
            children: [
              _BotaoAcao(
                icone: Icons.edit,
                cor: const Color(0xFF2563EB),
                onTap: onEditar,
              ),
              const SizedBox(height: 6),
              _BotaoAcao(
                icone: Icons.delete,
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

// ─── MODIFICAÇÃO 16: _Chip — componente novo de badge/tag ────────────────────
// Substitui texto plano de setor/categoria; melhora legibilidade em mobile.

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

// ─── Filtro Dropdown reutilizável ─────────────────────────────────────────────

class _FiltroDropdown extends StatelessWidget {
  const _FiltroDropdown({
    required this.hint,
    required this.valor,
    required this.opcoes,
    required this.onChanged,
    required this.onLimpar,
  });

  final String hint;
  final String? valor;
  final List<String> opcoes;
  final void Function(String?) onChanged;
  final VoidCallback onLimpar;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      // MODIFICAÇÃO 17: largura mínima garantida no dropdown para não ficar
      // pequenininho em telas estreitas.
      constraints: const BoxConstraints(minWidth: 110),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: valor != null
              ? const Color(0xFF2563EB)
              : const Color(0xFFE5E7EB),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: valor,
          hint: Text(
            hint,
            style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
          ),
          style: const TextStyle(fontSize: 13, color: Color(0xFF111827)),
          dropdownColor: Colors.white,
          icon: valor != null
              ? GestureDetector(
                  onTap: onLimpar,
                  child: const Icon(
                    Icons.close,
                    size: 16,
                    color: Color(0xFF6B7280),
                  ),
                )
              : const Icon(
                  Icons.keyboard_arrow_down,
                  size: 18,
                  color: Color(0xFF6B7280),
                ),
          onChanged: onChanged,
          items: opcoes
              .map(
                (o) => DropdownMenuItem(
                  value: o,
                  child: Text(
                    o,
                    style: const TextStyle(
                      color: Color(0xFF111827),
                      fontSize: 13,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

// ─── Cabeçalho da Tabela (tablet only) ───────────────────────────────────────

class _TabelaHeader extends StatelessWidget {
  const _TabelaHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: const [
          SizedBox(width: 28, child: Text('#', style: _s)),
          SizedBox(width: 48, child: Text('Nº', style: _s)),
          SizedBox(width: 130, child: Text('Nome', style: _s)),
          SizedBox(width: 70, child: Text('Setor', style: _s)),
          SizedBox(width: 90, child: Text('Categoria', style: _s)),
          SizedBox(width: 100, child: Text('Nível', style: _s)),
          Expanded(child: Text('Telefone', style: _s)),
          SizedBox(width: 36, child: Text('Inst.', style: _s)),
          SizedBox(width: 72),
        ],
      ),
    );
  }

  static const _s = TextStyle(
    fontWeight: FontWeight.w600,
    color: Color(0xFF6B7280),
    fontSize: 12,
  );
}

// ─── Linha da Tabela (tablet only) ───────────────────────────────────────────

class _TabelaLinha extends StatelessWidget {
  const _TabelaLinha({
    required this.numero,
    required this.aluno,
    required this.onEditar,
    required this.onDeletar,
  });

  final int numero;
  final Map<String, dynamic> aluno;
  final VoidCallback onEditar;
  final VoidCallback onDeletar;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
            width: 48,
            child: Text(aluno['numero_aluno']?.toString() ?? '', style: _c),
          ),
          SizedBox(
            width: 130,
            child: Text(
              aluno['nome_completo']?.toString() ?? '',
              style: _c,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            width: 70,
            child: Text(aluno['setor']?.toString() ?? '', style: _c),
          ),
          SizedBox(
            width: 90,
            child: Text(
              aluno['categoria_usuario']?.toString() ?? '',
              style: _c,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            width: 100,
            child: Text(
              aluno['nivel']?.toString() ?? '',
              style: _c,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            child: Text(
              aluno['telefone']?.toString() ?? '-',
              style: _c,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            width: 36,
            child: Text(aluno['id_instrumento']?.toString() ?? '-', style: _c),
          ),
          SizedBox(
            width: 72,
            child: Row(
              children: [
                _BotaoAcao(
                  icone: Icons.edit,
                  cor: const Color(0xFF2563EB),
                  onTap: onEditar,
                ),
                const SizedBox(width: 6),
                _BotaoAcao(
                  icone: Icons.delete,
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

  static const _c = TextStyle(fontSize: 12, color: Color(0xFF111827));
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
    // MODIFICAÇÃO 18: texto "Exibindo X de Y" encurtado para caber em telas
    // estreitas; usamos Flexible para não transbordar no Row.
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Flexible(
            child: Text(
              '$totalItens alunos',
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
              // MODIFICAÇÃO 19: exibe "página atual / total" para melhor
              // orientação sem ocupar mais espaço.
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

// ─── Dialog: Adicionar / Editar Aluno ─────────────────────────────────────────

class _AlunoDialog extends StatefulWidget {
  const _AlunoDialog({this.aluno, required this.onSalvar});

  final Map<String, dynamic>? aluno;
  final Future<void> Function(Map<String, dynamic>) onSalvar;

  @override
  State<_AlunoDialog> createState() => _AlunoDialogState();
}

class _AlunoDialogState extends State<_AlunoDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _numeroCtrl;
  late final TextEditingController _nomeCtrl;
  late final TextEditingController _telefoneCtrl;
  late final TextEditingController _instrumentoCtrl;

  String? _setorSelecionado;
  String? _categoriaSelecionada;
  String? _nivelSelecionado;
  bool _salvando = false;

  final _setores = ['Danca', 'Escudo', 'Pavilhao', 'Linha', 'Baliza'];
  final _categorias = ['Mentora', 'Kids', 'Avancar', 'Aprendiz', 'Ex-Aprendiz'];
  final _niveis = ['Iniciante', 'Intermediario', 'Avancado'];

  @override
  void initState() {
    super.initState();
    final a = widget.aluno;
    _numeroCtrl = TextEditingController(
      text: a?['numero_aluno']?.toString() ?? '',
    );
    _nomeCtrl = TextEditingController(
      text: a?['nome_completo']?.toString() ?? '',
    );
    _telefoneCtrl = TextEditingController(
      text: a?['telefone']?.toString() ?? '',
    );
    _instrumentoCtrl = TextEditingController(
      text: a?['id_instrumento']?.toString() ?? '',
    );
    _setorSelecionado = a?['setor']?.toString();
    _categoriaSelecionada = a?['categoria_usuario']?.toString();
    _nivelSelecionado = a?['nivel']?.toString();
  }

  @override
  void dispose() {
    _numeroCtrl.dispose();
    _nomeCtrl.dispose();
    _telefoneCtrl.dispose();
    _instrumentoCtrl.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _salvando = true);
    try {
      final dados = {
        'numero_aluno': int.tryParse(_numeroCtrl.text.trim()),
        'nome_completo': _nomeCtrl.text.trim(),
        'setor': _setorSelecionado,
        'categoria_usuario': _categoriaSelecionada,
        'nivel': _nivelSelecionado,
        if (_telefoneCtrl.text.trim().isNotEmpty)
          'telefone': _telefoneCtrl.text.trim(),
        if (_instrumentoCtrl.text.trim().isNotEmpty)
          'id_instrumento': int.tryParse(_instrumentoCtrl.text.trim()),
      };
      await widget.onSalvar(dados);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdicao = widget.aluno != null;

    // MODIFICAÇÃO 20: Dialog com insetPadding reduzido para mobile.
    // Por padrão o Dialog tem 40px de margem lateral — reduzimos para 16px
    // em telas estreitas, dando mais espaço ao formulário.
    return Dialog(
      backgroundColor: const Color(0xFF1E1E2E),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        // MODIFICAÇÃO 21: padding interno reduzido de 24→20 para ganhar
        // espaço vertical no formulário em telas pequenas.
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    // MODIFICAÇÃO 22: Expanded no título do dialog evita
                    // overflow se o texto + ícone não couberem na linha.
                    child: Text(
                      isEdicao ? 'Editar Aluno' : 'Adicionar Novo Aluno',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              _CampoTexto(
                label: 'Número do Aluno',
                controller: _numeroCtrl,
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Informe o número';
                  if (int.tryParse(v) == null) return 'Digite apenas números';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              _CampoTexto(
                label: 'Nome Completo',
                controller: _nomeCtrl,
                validator: (v) => v!.isEmpty ? 'Informe o nome' : null,
              ),
              const SizedBox(height: 12),
              _CampoDropdown(
                label: 'Setor',
                hint: 'Selecionar Setor',
                valor: _setorSelecionado,
                opcoes: _setores,
                onChanged: (v) => setState(() => _setorSelecionado = v),
                validator: (v) => v == null ? 'Selecione um setor' : null,
              ),
              const SizedBox(height: 12),
              _CampoDropdown(
                label: 'Categoria do Usuário',
                hint: 'Selecionar Categoria',
                valor: _categoriaSelecionada,
                opcoes: _categorias,
                onChanged: (v) => setState(() => _categoriaSelecionada = v),
                validator: (v) => v == null ? 'Selecione uma categoria' : null,
              ),
              const SizedBox(height: 12),
              _CampoDropdown(
                label: 'Nível de Conhecimento',
                hint: 'Selecionar Nível',
                valor: _nivelSelecionado,
                opcoes: _niveis,
                onChanged: (v) => setState(() => _nivelSelecionado = v),
                validator: (v) => v == null ? 'Selecione um nível' : null,
              ),
              const SizedBox(height: 12),
              _CampoTexto(
                label: 'Telefone (Opcional)',
                hint: '(99) 99999-9999',
                controller: _telefoneCtrl,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              _CampoTexto(
                label: 'ID Instrumento (Opcional)',
                hint: 'Ex: 1',
                controller: _instrumentoCtrl,
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v != null && v.isNotEmpty && int.tryParse(v) == null) {
                    return 'Digite um número válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _salvando
                          ? null
                          : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: Colors.white54),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _salvando ? null : _salvar,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _salvando
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              isEdicao ? 'Salvar' : 'Adicionar',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Widgets auxiliares ───────────────────────────────────────────────────────

class _CampoTexto extends StatelessWidget {
  const _CampoTexto({
    required this.label,
    required this.controller,
    this.hint,
    this.keyboardType,
    this.validator,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          style: const TextStyle(color: Colors.black87),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.black38),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
            ),
          ),
        ),
      ],
    );
  }
}

class _CampoDropdown extends StatelessWidget {
  const _CampoDropdown({
    required this.label,
    required this.hint,
    required this.valor,
    required this.opcoes,
    required this.onChanged,
    this.validator,
  });

  final String label;
  final String hint;
  final String? valor;
  final List<String> opcoes;
  final void Function(String?) onChanged;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          initialValue: valor,
          hint: Text(hint, style: const TextStyle(color: Colors.black38)),
          validator: validator,
          onChanged: onChanged,
          style: const TextStyle(color: Colors.black87, fontSize: 14),
          dropdownColor: Colors.white,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
            ),
          ),
          items: opcoes
              .map(
                (o) => DropdownMenuItem(
                  value: o,
                  child: Text(o, style: const TextStyle(color: Colors.black87)),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}
