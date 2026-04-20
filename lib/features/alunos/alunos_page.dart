import 'package:controle_instrumentos/core/utils/pagination_utils.dart';
import 'package:controle_instrumentos/core/utils/debouncer.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:controle_instrumentos/features/instrumentos/ui/widgets/app_drawer.dart';
import 'package:controle_instrumentos/features/alunos/models/aluno_record.dart';
import 'package:controle_instrumentos/features/alunos/repository/alunos_repository.dart';
import 'package:controle_instrumentos/features/alunos/widgets/aluno_dialog.dart';
import 'package:controle_instrumentos/features/alunos/widgets/alunos_list.dart';
import 'package:controle_instrumentos/features/alunos/widgets/dialog_justificativa_exclusao.dart';
import 'package:controle_instrumentos/shared/widgets/pagination_footer.dart';

class AlunosPage extends StatefulWidget {
  const AlunosPage({super.key});

  @override
  State<AlunosPage> createState() => _AlunosPageState();
}

class _AlunosPageState extends State<AlunosPage> {
  final _supabase = Supabase.instance.client;
  final _alunosRepository = AlunosRepository();
  final _searchDebouncer = Debouncer(delay: const Duration(milliseconds: 250));
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
    _searchDebouncer.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _carregarAlunos() async {
    setState(() => _isLoading = true);
    try {
      final response = await _alunosRepository.listarAlunos();

      setState(() {
        _alunos = response.map((a) => a.toMap()).toList();
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
    return pagedSlice(
      items: _alunosFiltrados,
      currentPage: _currentPage,
      itemsPerPage: _itensPorPagina,
    );
  }

  int get _totalPaginas => pageCount(
    totalItems: _alunosFiltrados.length,
    itemsPerPage: _itensPorPagina,
  );

  Future<void> _deletarAluno(int id) async {
    final resultado = await showDialog<Map<String, String>>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const DialogJustificativaExclusao(),
    );

    if (resultado == null) return;

    try {
      final aluno = _alunos.firstWhere((a) => a['id_aluno'] == id);
      final alunoRecord = AlunoRecord.fromMap(aluno);
      await _alunosRepository.registrarExclusaoEDeletar(
        aluno: alunoRecord,
        motivoExclusao: resultado['motivo'] ?? 'Outro',
      );
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
      builder: (ctx) => AlunoDialog(
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
                  onChanged: (_) {
                    _searchDebouncer.run(() {
                      if (!mounted) return;
                      _aplicarFiltros();
                    });
                  },
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
                AlunosList(
                  alunos: _alunosPaginados,
                  currentPage: _currentPage,
                  itensPorPagina: _itensPorPagina,
                  isTablet: isTablet,
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
                  child: PaginationFooter(
                    totalLabel: '${_alunosFiltrados.length} alunos',
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
