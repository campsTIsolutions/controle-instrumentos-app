import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/utils/debouncer.dart';
import '../../../shared/widgets/profile_menu_button.dart';
import '../repository/instrumentos_repository.dart';
import 'instrumentos_page_utils.dart';
import 'widgets/app_drawer.dart';
import 'widgets/instrumentos_content.dart';
import 'widgets/instrumentos_filters_bar.dart';
import 'widgets/instrumento_detalhe_page.dart';
import 'widgets/instrumento_dialog.dart';

class InstrumentosPage extends StatefulWidget {
  const InstrumentosPage({super.key});

  @override
  State<InstrumentosPage> createState() => _InstrumentosPageState();
}

class _InstrumentosPageState extends State<InstrumentosPage> {
  final _repository = InstrumentosRepository();
  final _supabase = Supabase.instance.client;
  final _searchDebouncer = Debouncer(delay: const Duration(milliseconds: 250));
  final _searchController = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  bool _isLoading = true;
  List<Map<String, dynamic>> _instrumentos = [];
  List<Map<String, dynamic>> _instrumentosFiltrados = [];
  Map<int, String> _nomesAlunosPorId = {};
  String? _erroCarregamento;
  bool _ordenarAlfabetico = false;
  String? _filtroPropriedade;
  String? _filtroStatus;

  final _propriedades = const ['CAMPS', 'Terceiros'];
  final _statusDisponibilidade = const ['Disponivel', 'Indisponivel'];

  @override
  void initState() {
    super.initState();
    _carregarInstrumentos();
  }

  @override
  void dispose() {
    _searchDebouncer.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _abrirDetalhesInstrumento({
    required BuildContext context,
    required String nome,
    required String patrimonio,
    required String status,
    required String alunoNome,
    required String propriedade,
    required bool levaInstrumento,
    required String observacoes,
    required String imageUrl,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => InstrumentoDetalhePage(
          nome: nome,
          patrimonio: patrimonio,
          status: status,
          alunoNome: alunoNome,
          propriedade: propriedade,
          levaInstrumento: levaInstrumento,
          observacoes: observacoes,
          imageUrl: imageUrl,
        ),
      ),
    );
  }

  Future<void> _carregarInstrumentos() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _erroCarregamento = null;
    });

    try {
      final response = await _repository.listarInstrumentos();
      final dynamic alunosResponse = await _supabase
          .from('alunos')
          .select('id_aluno, nome_completo');

      if (!mounted) return;

      final alunosRawData = alunosResponse is PostgrestResponse
          ? alunosResponse.data
          : alunosResponse;
      if (alunosRawData is! List) {
        throw StateError(
          'Resposta inesperada ao listar alunos vinculados: ${alunosRawData.runtimeType}',
        );
      }

      final nomesAlunosPorId = <int, String>{};
      for (final item in alunosRawData) {
        final aluno = Map<String, dynamic>.from(item as Map);
        final id = aluno['id_aluno'];
        final nome = aluno['nome_completo'];
        final idInt = id is int ? id : int.tryParse(id?.toString() ?? '');
        if (idInt != null && nome != null) {
          nomesAlunosPorId[idInt] = nome.toString();
        }
      }

      setState(() {
        _instrumentos = response;
        _nomesAlunosPorId = nomesAlunosPorId;
        _aplicarFiltros();
        _isLoading = false;
      });
    } catch (e, s) {
      debugPrint('Erro ao carregar instrumentos: $e');
      debugPrintStack(stackTrace: s);

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _erroCarregamento = e.toString();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao carregar instrumentos: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _aplicarFiltros() {
    List<Map<String, dynamic>> resultado = List.from(_instrumentos);

    final query = _searchController.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      resultado = resultado.where((item) {
        final nome = InstrumentosPageUtils.texto(item, [
          'nome_instrumento',
        ]).toLowerCase();
        final patrimonio = InstrumentosPageUtils.texto(item, [
          'numero_patrimonio',
        ]).toLowerCase();
        return nome.contains(query) || patrimonio.contains(query);
      }).toList();
    }

    if (_filtroPropriedade != null) {
      resultado = resultado.where((item) {
        return InstrumentosPageUtils.texto(item, ['propriedade_instrumento']) ==
            _filtroPropriedade;
      }).toList();
    }

    if (_filtroStatus != null) {
      final disponivel = _filtroStatus == 'Disponivel';
      resultado = resultado
          .where(
            (item) =>
                InstrumentosPageUtils.boolValue(item, ['disponivel']) ==
                disponivel,
          )
          .toList();
    }

    if (_ordenarAlfabetico) {
      resultado.sort(
        (a, b) => InstrumentosPageUtils.texto(a, [
          'nome_instrumento',
        ]).compareTo(InstrumentosPageUtils.texto(b, ['nome_instrumento'])),
      );
    }

    _instrumentosFiltrados = resultado;
  }

  Future<void> _deletarInstrumento(dynamic idRaw) async {
    final int? id = idRaw is int ? idRaw : int.tryParse(idRaw.toString());
    if (id == null) return;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar exclusão'),
        content: const Text('Tem certeza que deseja excluir este instrumento?'),
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

    if (confirmar != true) return;

    try {
      await _repository.eliminarInstrumento(id);
      await _carregarInstrumentos();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao excluir: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _abrirDialogInstrumento({Map<String, dynamic>? instrumento}) {
    showDialog(
      context: context,
      builder: (ctx) => InstrumentoDialog(
        instrumento: instrumento,
        onSalvar: (dados) async {
          if (instrumento == null) {
            await _repository.criarInstrumento(dados);
          } else {
            await _repository.atualizarInstrumento(
              idInstrumento: instrumento['id_instrumento'],
              dados: dados,
            );
          }

          await _carregarInstrumentos();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
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
        actions: [const ProfileMenuButton()],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _abrirDialogInstrumento(),
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 15),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Controle de Instrumentos',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 12),
            InstrumentosFiltersBar(
              searchController: _searchController,
              onSearchChanged: (_) {
                _searchDebouncer.run(() {
                  if (!mounted) return;
                  setState(_aplicarFiltros);
                });
              },
              ordenarAlfabetico: _ordenarAlfabetico,
              onOrdenarAlfabeticoChanged: (value) {
                setState(() {
                  _ordenarAlfabetico = value;
                  _aplicarFiltros();
                });
              },
              filtroPropriedade: _filtroPropriedade,
              propriedades: _propriedades,
              onFiltroPropriedadeChanged: (value) {
                setState(() {
                  _filtroPropriedade = value;
                  _aplicarFiltros();
                });
              },
              filtroStatus: _filtroStatus,
              statusDisponibilidade: _statusDisponibilidade,
              onFiltroStatusChanged: (value) {
                setState(() {
                  _filtroStatus = value;
                  _aplicarFiltros();
                });
              },
            ),
            const SizedBox(height: 15),
            Expanded(
              child: InstrumentosContent(
                isLoading: _isLoading,
                erroCarregamento: _erroCarregamento,
                instrumentosFiltrados: _instrumentosFiltrados,
                nomesAlunosPorId: _nomesAlunosPorId,
                onRetry: _carregarInstrumentos,
                onTapItem: (item) => _abrirDetalhesInstrumento(
                  context: context,
                  nome: item.nome,
                  patrimonio: item.patrimonio,
                  status: item.status,
                  alunoNome: item.alunoNome,
                  propriedade: item.propriedade,
                  levaInstrumento: item.levaInstrumento,
                  observacoes: item.observacoes,
                  imageUrl: item.imageUrl,
                ),
                onEditItem: (item) =>
                    _abrirDialogInstrumento(instrumento: item),
                onDeleteItem: _deletarInstrumento,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
