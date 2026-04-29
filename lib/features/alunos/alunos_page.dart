import 'package:controle_instrumentos/core/utils/debouncer.dart';
import 'package:controle_instrumentos/core/utils/pagination_utils.dart';
import 'package:controle_instrumentos/features/alunos/models/aluno_record.dart';
import 'package:controle_instrumentos/features/alunos/repository/alunos_repository.dart';
import 'package:controle_instrumentos/features/alunos/widgets/aluno_dialog.dart';
import 'package:controle_instrumentos/features/alunos/widgets/alunos_list.dart';
import 'package:controle_instrumentos/features/alunos/widgets/dialog_justificativa_exclusao.dart';
import 'package:controle_instrumentos/features/instrumentos/ui/widgets/app_drawer.dart';
import 'package:controle_instrumentos/shared/widgets/pagination_footer.dart';
import 'package:controle_instrumentos/shared/widgets/profile_menu_button.dart';
import 'package:controle_instrumentos/core/theme/theme.dart';
import 'package:flutter/material.dart';

class AlunosPage extends StatefulWidget {
  const AlunosPage({super.key, this.repository});

  final AlunosRepositoryContract? repository;

  @override
  State<AlunosPage> createState() => _AlunosPageState();
}

class _AlunosPageState extends State<AlunosPage> {
  final _searchDebouncer = Debouncer(delay: const Duration(milliseconds: 250));
  final _searchController = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  List<AlunoRecord> _alunos = [];
  bool _isLoading = true;
  bool _isSalvando = false;
  bool _isExcluindo = false;

  int _currentPage = 1;
  int _totalItens = 0;
  final int _itensPorPagina = 10;

  bool _ordenarAlfabetico = false;
  final List<String> _filtroCategoria = [];
  final List<String> _filtroSetor = [];

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

  int get _totalPaginas =>
      pageCount(totalItems: _totalItens, itemsPerPage: _itensPorPagina);

  Future<void> _carregarAlunos({int? page, bool showLoading = true}) async {
    final nextPage = page ?? _currentPage;

    if (showLoading && mounted) {
      setState(() => _isLoading = true);
    }

    try {
      final result = await _alunosRepository.listarAlunosPaginados(
        page: nextPage,
        itemsPerPage: _itensPorPagina,
        query: _searchController.text,
        categorias: _filtroCategoria,
        setores: _filtroSetor,
        ordenarAlfabetico: _ordenarAlfabetico,
      );

      if (!mounted) return;

      setState(() {
        _alunos = result.items;
        _totalItens = result.total;
        _currentPage = result.page;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao carregar alunos: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _aplicarFiltrosServidor() async {
    await _carregarAlunos(page: 1);
  }

  Future<void> _deletarAluno(AlunoRecord aluno) async {
    final resultado = await showDialog<Map<String, String>>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const DialogJustificativaExclusao(),
    );

    if (resultado == null) return;

    setState(() => _isExcluindo = true);

    try {
      await _alunosRepository.registrarExclusaoEDeletar(
        aluno: aluno,
        motivoExclusao: resultado['motivo'] ?? 'Outro',
      );

      if (!mounted) return;

      final targetPage = (_alunos.length == 1 && _currentPage > 1)
          ? _currentPage - 1
          : _currentPage;

      await _carregarAlunos(page: targetPage);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aluno excluído com sucesso.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao excluir: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isExcluindo = false);
      }
    }
  }

  void _abrirDialogAluno({AlunoRecord? aluno}) {
    showDialog(
      context: context,
      builder: (_) => AlunoDialog(
        aluno: aluno?.toMap(),
        onSalvar: (dados, imagemFile) async {
          if (_isSalvando) return;

          setState(() => _isSalvando = true);

          try {
            String? imagemUrl;
            if (imagemFile != null) {
              final bytes = await imagemFile.readAsBytes();
              imagemUrl = await _alunosRepository.uploadFotoAluno(
                bytes: bytes,
                originalFileName: imagemFile.name,
              );
            }

            final Map<String, dynamic> dadosFinais = {
              ...dados,

              ...((dados.containsKey('imagem_url') &&
                      dados['imagem_url'] == null)
                  ? <String, dynamic>{'imagem_url': null}
                  : <String, dynamic>{}),

              if (imagemUrl != null) 'imagem_url': imagemUrl,
            };

            await _alunosRepository.salvarAluno(
              dados: dadosFinais,
              idAluno: aluno?.idAluno,
            );

            if (!mounted) return;
            Navigator.of(context).pop();
            await _carregarAlunos(page: _currentPage, showLoading: false);
          } finally {
            if (mounted) {
              setState(() => _isSalvando = false);
            }
          }
        },
      ),
    );
  }

  AlunosRepositoryContract get _alunosRepository {
    return widget.repository ?? _defaultRepository;
  }

  static final AlunosRepository _defaultRepository = AlunosRepository();

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
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
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
        actions: const [ProfileMenuButton()],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.sm,
                ),
                child: Text('Alunos', style: AppTextStyles.pageTitle),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xxs,
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) {
                    _searchDebouncer.run(() async {
                      if (!mounted) return;
                      await _carregarAlunos(page: 1, showLoading: false);
                    });
                  },
                  style: const TextStyle(color: Colors.black87),
                  decoration: InputDecoration(
                    hintText: 'Buscar aluno...',
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
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(AppRadii.sm),
                            border: Border.all(
                              color: _ordenarAlfabetico
                                  ? AppColors.primary
                                  : AppColors.border,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Checkbox(
                                value: _ordenarAlfabetico,
                                activeColor: AppColors.primary,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                onChanged: (v) async {
                                  setState(
                                    () => _ordenarAlfabetico = v ?? false,
                                  );
                                  await _aplicarFiltrosServidor();
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
                              onTap: () async {
                                setState(() {
                                  if (selecionado) {
                                    _filtroCategoria.remove(cat);
                                  } else {
                                    _filtroCategoria.add(cat);
                                  }
                                });
                                await _aplicarFiltrosServidor();
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(
                                    AppRadii.sm,
                                  ),
                                  border: Border.all(
                                    color: selecionado
                                        ? AppColors.primary
                                        : AppColors.border,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Checkbox(
                                      value: selecionado,
                                      onChanged: (value) async {
                                        setState(() {
                                          if (value == true &&
                                              !_filtroCategoria.contains(cat)) {
                                            _filtroCategoria.add(cat);
                                          } else {
                                            _filtroCategoria.remove(cat);
                                          }
                                        });
                                        await _aplicarFiltrosServidor();
                                      },
                                      activeColor: AppColors.primary,
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
                              onTap: () async {
                                setState(() {
                                  if (selecionado) {
                                    _filtroSetor.remove(setor);
                                  } else {
                                    _filtroSetor.add(setor);
                                  }
                                });
                                await _aplicarFiltrosServidor();
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(
                                    AppRadii.sm,
                                  ),
                                  border: Border.all(
                                    color: selecionado
                                        ? AppColors.primary
                                        : AppColors.border,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Checkbox(
                                      value: selecionado,
                                      onChanged: (value) async {
                                        setState(() {
                                          if (value == true &&
                                              !_filtroSetor.contains(setor)) {
                                            _filtroSetor.add(setor);
                                          } else {
                                            _filtroSetor.remove(setor);
                                          }
                                        });
                                        await _aplicarFiltrosServidor();
                                      },
                                      activeColor: AppColors.primary,
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
              else if (_alunos.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: Text('Nenhum aluno encontrado.')),
                )
              else ...[
                AlunosList(
                  alunos: _alunos,
                  currentPage: _currentPage,
                  itensPorPagina: _itensPorPagina,
                  isTablet: isTablet,
                  onEditar: _isSalvando || _isExcluindo
                      ? (_) {}
                      : (a) => _abrirDialogAluno(aluno: a),
                  onDeletar: _isSalvando || _isExcluindo
                      ? (_) {}
                      : _deletarAluno,
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
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: PaginationFooter(
                    totalLabel: '$_totalItens alunos',
                    currentPage: _currentPage,
                    totalPages: _totalPaginas,
                    onFirstPage: () =>
                        _carregarAlunos(page: 1, showLoading: false),
                    onPreviousPage: () => _carregarAlunos(
                      page: (_currentPage - 1).clamp(1, _totalPaginas),
                      showLoading: false,
                    ),
                    onNextPage: () => _carregarAlunos(
                      page: (_currentPage + 1).clamp(1, _totalPaginas),
                      showLoading: false,
                    ),
                    onLastPage: () => _carregarAlunos(
                      page: _totalPaginas,
                      showLoading: false,
                    ),
                  ),
                ),
                const SizedBox(height: 80),
              ],
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isSalvando || _isExcluindo
            ? null
            : () => _abrirDialogAluno(),
        backgroundColor: AppColors.primary,
        child: _isSalvando
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
