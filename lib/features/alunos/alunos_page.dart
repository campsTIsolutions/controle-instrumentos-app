import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:controle_instrumentos/features/instrumentos/ui/widgets/app_drawer.dart';

class AlunosPage extends StatefulWidget {
  const AlunosPage({super.key});

  @override
  State<AlunosPage> createState() => _AlunosPageState();
}

class _AlunosPageState extends State<AlunosPage> {
  final _supabase = Supabase.instance.client;
  final _searchController = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  List<Map<String, dynamic>> _alunos = [];
  List<Map<String, dynamic>> _alunosFiltrados = [];
  bool _isLoading = true;

  int _currentPage = 1;
  final int _itensPorPagina = 10;

  bool _ordenarAlfabetico = false;
  List<String> _filtroCategoria = [];
  List<String> _filtroSetor = [];
  final _categorias = [
    'Mentor(a)',
    'Kids',
    'Avançar',
    'Aprendiz',
    'Ex-Aprendiz',
  ];
  final _setores = ['Dança', 'Escudo', 'Pavilhão', 'Linha', 'Baliza'];

  @override
  void initState() {
    super.initState();
    _carregarAlunos();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _carregarAlunos() async {
    setState(() => _isLoading = true);
    try {
      final response = await _supabase
          .from('alunos')
          .select(
            'id_aluno, numero_aluno, nome_completo, setor, categoria_usuario, nivel, telefone, imagem_url, idade',
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar alunos: $e'),
            backgroundColor: Colors.red,
          ),
        );
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

    if (_filtroCategoria.isNotEmpty) {
      resultado = resultado
          .where((a) => _filtroCategoria.contains(a['categoria_usuario']))
          .toList();
    }

    if (_filtroSetor.isNotEmpty) {
      resultado = resultado
          .where((a) => _filtroSetor.contains(a['setor']))
          .toList();
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
    final resultado = await showDialog<Map<String, String>>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const _DialogJustificativaExclusao(),
    );

    if (resultado == null) return;

    try {
      final aluno = _alunos.firstWhere((a) => a['id_aluno'] == id);
      await _supabase.from('logs').insert({
        'id_aluno': aluno['id_aluno'],
        'numero_aluno': aluno['numero_aluno'],
        'nome_completo': aluno['nome_completo'],
        'setor': aluno['setor'],
        'categoria_usuario': aluno['categoria_usuario'],
        'nivel': aluno['nivel'],
        'telefone': aluno['telefone'],
        'imagem_url': aluno['imagem_url'],
        'idade': aluno['idade'],
        'motivo_exclusao': resultado['motivo'],
        'data_exclusao': DateTime.now().toIso8601String(),
      });

      await _supabase.from('alunos').delete().eq('id_aluno', id);
      _carregarAlunos();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Aluno excluído com sucesso.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao excluir: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _abrirDialogAluno({Map<String, dynamic>? aluno}) {
    showDialog(
      context: context,
      builder: (ctx) => _AlunoDialog(
        aluno: aluno,
        onSalvar: (dados, imagemFile) async {
          String? imagemUrl = aluno?['imagem_url'] as String?;

          if (imagemFile != null) {
            final bytes = await imagemFile.readAsBytes();
            final nomeArquivo =
                '${DateTime.now().millisecondsSinceEpoch}_${imagemFile.path.split('/').last}';
            await _supabase.storage
                .from('alunos-fotos')
                .uploadBinary(nomeArquivo, bytes);
            imagemUrl = _supabase.storage
                .from('alunos-fotos')
                .getPublicUrl(nomeArquivo);
          }

          final dadosFinais = {
            ...dados,
            if (imagemUrl != null) 'imagem_url': imagemUrl,
          };

          if (aluno == null) {
            await _supabase.from('alunos').insert(dadosFinais);
          } else {
            await _supabase
                .from('alunos')
                .update(dadosFinais)
                .eq('id_aluno', aluno['id_aluno']);
          }
          if (mounted) Navigator.pop(ctx);
          _carregarAlunos();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF2F3F5),
      drawer: const AppDrawer(),
      appBar: AppBar(
        leading: IconButton(
          icon: SizedBox(
            width: 24,
            height: 24,
            child: Image.asset("assets/menu-icon.png"),
          ),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
          style: IconButton.styleFrom(
            backgroundColor: const Color.fromARGB(0, 255, 255, 255),
          ),
        ),
        title: const Text(
          "CAMPS",
          style: TextStyle(
            color: Colors.black,
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
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 20, 16, 10),
                child: Text(
                  'Alunos',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
              ),

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

              // ── Filtros horizontais ────────────────────────────────────────
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // A-Z: Column com label vazio para alinhar com os demais
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Label invisível com a mesma altura dos demais labels
                        const Text(
                          '',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _ordenarAlfabetico
                                  ? const Color(0xFF2563EB)
                                  : const Color(0xFFE5E7EB),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Checkbox(
                                value: _ordenarAlfabetico,
                                activeColor: const Color(0xFF2563EB),
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                onChanged: (v) {
                                  setState(
                                    () => _ordenarAlfabetico = v ?? false,
                                  );
                                  _aplicarFiltros();
                                },
                              ),
                              const Text(
                                'A-Z',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.black,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(width: 10),

                    // Categoria
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Categoria',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.black,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Wrap(
                          spacing: 8,
                          children: _categorias.map((cat) {
                            final selecionado = _filtroCategoria.contains(cat);
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  if (selecionado) {
                                    _filtroCategoria.remove(cat);
                                  } else {
                                    _filtroCategoria.add(cat);
                                  }
                                  _aplicarFiltros();
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
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
                                      onChanged: (value) {
                                        setState(() {
                                          if (value == true) {
                                            _filtroCategoria.add(cat);
                                          } else {
                                            _filtroCategoria.remove(cat);
                                          }
                                          _aplicarFiltros();
                                        });
                                      },
                                      activeColor: const Color(0xFF2563EB),
                                      checkColor: Colors.white,
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    Text(
                                      cat,
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),

                    const SizedBox(width: 10),

                    // Setor
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Setor',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.black,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Wrap(
                          spacing: 8,
                          children: _setores.map((setor) {
                            final selecionado = _filtroSetor.contains(setor);
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  if (selecionado) {
                                    _filtroSetor.remove(setor);
                                  } else {
                                    _filtroSetor.add(setor);
                                  }
                                  _aplicarFiltros();
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
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
                                      onChanged: (value) {
                                        setState(() {
                                          if (value == true) {
                                            _filtroSetor.add(setor);
                                          } else {
                                            _filtroSetor.remove(setor);
                                          }
                                          _aplicarFiltros();
                                        });
                                      },
                                      activeColor: const Color(0xFF2563EB),
                                      checkColor: Colors.white,
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    Text(
                                      setor,
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

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
                if (isTablet)
                  _TabelaDesktop(
                    alunos: _alunosPaginados,
                    currentPage: _currentPage,
                    itensPorPagina: _itensPorPagina,
                  )
                else
                  _ListaCards(
                    alunos: _alunosPaginados,
                    currentPage: _currentPage,
                    itensPorPagina: _itensPorPagina,
                    onEditar: (a) => _abrirDialogAluno(aluno: a),
                    onDeletar: (a) => _deletarAluno(a['id_aluno'] as int),
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

// ─── Modal de Justificativa de Exclusão ───────────────────────────────────────

class _DialogJustificativaExclusao extends StatefulWidget {
  const _DialogJustificativaExclusao();

  @override
  State<_DialogJustificativaExclusao> createState() =>
      _DialogJustificativaExclusaoState();
}

class _DialogJustificativaExclusaoState
    extends State<_DialogJustificativaExclusao> {
  String? _motivoSelecionado;
  final _outroCtrl = TextEditingController();
  bool _confirmando = false;

  static const _motivos = [
    'Falta de Tempo',
    'Falta de Disciplina',
    'Falta de Interesse',
    'Outro',
  ];

  static const _icones = {
    'Falta de Tempo': Icons.schedule_outlined,
    'Falta de Disciplina': Icons.rule_outlined,
    'Falta de Interesse': Icons.sentiment_dissatisfied_outlined,
    'Outro': Icons.edit_note_outlined,
  };

  @override
  void dispose() {
    _outroCtrl.dispose();
    super.dispose();
  }

  void _confirmar() {
    if (_motivoSelecionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione um motivo para a exclusão.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    if (_motivoSelecionado == 'Outro' && _outroCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Descreva o motivo da exclusão.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final motivo = _motivoSelecionado == 'Outro'
        ? 'Outro: ${_outroCtrl.text.trim()}'
        : _motivoSelecionado!;

    Navigator.pop(context, {'motivo': motivo});
  }

  @override
  Widget build(BuildContext context) {
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
                    color: const Color(0xFFB91C1C).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    color: Color(0xFFEF4444),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Excluir Aluno',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Esta ação não pode ser desfeita.',
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

            const Text(
              'Motivo da exclusão',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFFD1D5DB),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Selecione o principal motivo pelo qual este aluno está sendo desligado.',
              style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
            ),

            const SizedBox(height: 14),

            ...(_motivos.map((motivo) {
              final selecionado = _motivoSelecionado == motivo;
              return GestureDetector(
                onTap: () => setState(() => _motivoSelecionado = motivo),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: selecionado
                        ? const Color(0xFFB91C1C).withOpacity(0.15)
                        : const Color(0xFF2A2A3E),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: selecionado
                          ? const Color(0xFFEF4444)
                          : const Color(0xFF374151),
                      width: selecionado ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _icones[motivo]!,
                        size: 20,
                        color: selecionado
                            ? const Color(0xFFEF4444)
                            : const Color(0xFF9CA3AF),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          motivo,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: selecionado
                                ? FontWeight.w600
                                : FontWeight.normal,
                            color: selecionado
                                ? Colors.white
                                : const Color(0xFFD1D5DB),
                          ),
                        ),
                      ),
                      if (selecionado)
                        const Icon(
                          Icons.check_circle,
                          size: 18,
                          color: Color(0xFFEF4444),
                        ),
                    ],
                  ),
                ),
              );
            })),

            if (_motivoSelecionado == 'Outro') ...[
              const SizedBox(height: 4),
              TextFormField(
                controller: _outroCtrl,
                maxLines: 3,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Descreva o motivo da exclusão...',
                  hintStyle: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 13,
                  ),
                  filled: true,
                  fillColor: const Color(0xFF2A2A3E),
                  contentPadding: const EdgeInsets.all(12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF374151)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF374151)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFEF4444)),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _confirmando
                        ? null
                        : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      side: const BorderSide(color: Colors.white24),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _confirmando ? null : _confirmar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFB91C1C),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _confirmando
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Confirmar Exclusão',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                  ),
                ),
              ],
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
    required this.alunos,
    required this.currentPage,
    required this.itensPorPagina,
  });

  final List<Map<String, dynamic>> alunos;
  final int currentPage;
  final int itensPorPagina;

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
            itemCount: alunos.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (ctx, i) {
              final aluno = alunos[i];
              final numero = (currentPage - 1) * itensPorPagina + i + 1;
              return _TabelaLinha(
                numero: numero,
                aluno: aluno,
                onEditar: () {},
                onDeletar: () {},
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
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4),
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

// ─── Card de Aluno (mobile) ───────────────────────────────────────────────────

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
    final imagemUrl = aluno['imagem_url'] as String?;
    final idade = aluno['idade'];

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
              color: const Color(0xFFEFF6FF),
            ),
            clipBehavior: Clip.antiAlias,
            child: imagemUrl != null && imagemUrl.isNotEmpty
                ? Image.network(
                    imagemUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.person,
                      color: Color(0xFF2563EB),
                      size: 24,
                    ),
                  )
                : const Icon(Icons.person, color: Color(0xFF2563EB), size: 24),
          ),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                    if (idade != null)
                      _Chip(
                        label: '$idade anos',
                        cor: const Color(0xFFFFF7ED),
                        textoCor: const Color(0xFF9A3412),
                      ),
                  ],
                ),

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
          SizedBox(width: 44, child: Text('Foto', style: _s)),
          SizedBox(width: 130, child: Text('Nome', style: _s)),
          SizedBox(width: 40, child: Text('Idade', style: _s)),
          SizedBox(width: 70, child: Text('Setor', style: _s)),
          SizedBox(width: 90, child: Text('Categoria', style: _s)),
          SizedBox(width: 100, child: Text('Nível', style: _s)),
          Expanded(child: Text('Telefone', style: _s)),
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
    final imagemUrl = aluno['imagem_url'] as String?;

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
            width: 48,
            child: Text(aluno['numero_aluno']?.toString() ?? '', style: _c),
          ),
          SizedBox(
            width: 44,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                color: const Color(0xFFEFF6FF),
              ),
              clipBehavior: Clip.antiAlias,
              child: imagemUrl != null && imagemUrl.isNotEmpty
                  ? Image.network(
                      imagemUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.person,
                        color: Color(0xFF2563EB),
                        size: 16,
                      ),
                    )
                  : const Icon(
                      Icons.person,
                      color: Color(0xFF2563EB),
                      size: 16,
                    ),
            ),
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
            width: 40,
            child: Text(
              aluno['idade'] != null ? '${aluno['idade']}' : '-',
              style: _c,
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

// ─── Dialog de Adicionar / Editar Aluno ──────────────────────────────────────

class _AlunoDialog extends StatefulWidget {
  const _AlunoDialog({this.aluno, required this.onSalvar});

  final Map<String, dynamic>? aluno;
  final Future<void> Function(Map<String, dynamic> dados, XFile? imagemFile)
  onSalvar;

  @override
  State<_AlunoDialog> createState() => _AlunoDialogState();
}

class _AlunoDialogState extends State<_AlunoDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _numeroCtrl;
  late final TextEditingController _nomeCtrl;
  late final TextEditingController _telefoneCtrl;
  late final TextEditingController _instrumentoCtrl;
  late final TextEditingController _idadeCtrl;

  String? _setorSelecionado;
  String? _categoriaSelecionada;
  String? _nivelSelecionado;
  bool _salvando = false;

  XFile? _imagemSelecionada;
  final _picker = ImagePicker();

  final _setores = ['Dança', 'Escudo', 'Pavilhão', 'Linha', 'Baliza'];
  final _categorias = [
    'Mentor(a)',
    'Kids',
    'Avançar',
    'Aprendiz',
    'Ex-Aprendiz',
  ];
  final _niveis = ['Iniciante', 'Intermediário', 'Avançado'];

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
    _idadeCtrl = TextEditingController(text: a?['idade']?.toString() ?? '');
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
    _idadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _selecionarImagem() async {
    final origem = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: const Color(0xFF1E1E2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Selecionar foto',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.camera_alt_outlined,
                    color: Color(0xFF2563EB),
                  ),
                ),
                title: const Text(
                  'Câmera',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
                contentPadding: EdgeInsets.zero,
              ),
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.photo_library_outlined,
                    color: Color(0xFF2563EB),
                  ),
                ),
                title: const Text(
                  'Galeria',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
                contentPadding: EdgeInsets.zero,
              ),
              if (_imagemSelecionada != null ||
                  (widget.aluno?['imagem_url'] != null &&
                      (widget.aluno!['imagem_url'] as String).isNotEmpty))
                ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFB91C1C).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.delete_outline,
                      color: Color(0xFFEF4444),
                    ),
                  ),
                  title: const Text(
                    'Remover foto',
                    style: TextStyle(color: Color(0xFFEF4444)),
                  ),
                  onTap: () => Navigator.pop(ctx, null),
                  contentPadding: EdgeInsets.zero,
                ),
            ],
          ),
        ),
      ),
    );

    if (!mounted) return;

    if (origem == null && _imagemSelecionada != null) {
      setState(() => _imagemSelecionada = null);
      return;
    }
    if (origem == null) return;

    final imagem = await _picker.pickImage(
      source: origem,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );

    if (imagem != null && mounted) {
      setState(() => _imagemSelecionada = imagem);
    }
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
        if (_idadeCtrl.text.trim().isNotEmpty)
          'idade': int.tryParse(_idadeCtrl.text.trim()),
      };
      await widget.onSalvar(dados, _imagemSelecionada);
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
    final imagemUrlExistente = widget.aluno?['imagem_url'] as String?;

    return Dialog(
      backgroundColor: const Color(0xFF1E1E2E),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
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

              const SizedBox(height: 20),

              Center(
                child: GestureDetector(
                  onTap: _selecionarImagem,
                  child: Stack(
                    children: [
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: const Color(0xFF2A2A3E),
                          border: Border.all(
                            color: const Color(0xFF374151),
                            width: 2,
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: _imagemSelecionada != null
                            ? Image.file(
                                File(_imagemSelecionada!.path),
                                fit: BoxFit.cover,
                              )
                            : (imagemUrlExistente != null &&
                                  imagemUrlExistente.isNotEmpty)
                            ? Image.network(
                                imagemUrlExistente,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    const _FotoPlaceholder(),
                              )
                            : const _FotoPlaceholder(),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: const Color(0xFF2563EB),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: const Color(0xFF1E1E2E),
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const Center(
                child: Padding(
                  padding: EdgeInsets.only(top: 8, bottom: 16),
                  child: Text(
                    'Toque para adicionar foto',
                    style: TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
                  ),
                ),
              ),

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

              _CampoTexto(
                label: 'Idade',
                hint: 'Ex: 17',
                controller: _idadeCtrl,
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v != null && v.isNotEmpty) {
                    final parsed = int.tryParse(v);
                    if (parsed == null) return 'Digite apenas números';
                    if (parsed < 1 || parsed > 120) return 'Idade inválida';
                  }
                  return null;
                },
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

// ─── Placeholder do avatar quando sem foto ────────────────────────────────────

class _FotoPlaceholder extends StatelessWidget {
  const _FotoPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.person_outline, color: Color(0xFF4B5563), size: 32),
        SizedBox(height: 4),
        Text('Foto', style: TextStyle(fontSize: 10, color: Color(0xFF6B7280))),
      ],
    );
  }
}

// ─── Widgets auxiliares reutilizáveis ─────────────────────────────────────────

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
          value: valor,
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
