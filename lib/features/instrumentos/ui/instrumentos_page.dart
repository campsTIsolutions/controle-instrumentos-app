import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../repository/instrumentos_repository.dart';
import 'widgets/app_drawer.dart';
import 'widgets/perfil_drawer.dart';
import 'widgets/instrumento_card.dart';
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

  String _texto(Map<String, dynamic> item, List<String> chaves) {
    for (final chave in chaves) {
      final valor = item[chave];
      if (valor != null) return valor.toString();
    }
    return '';
  }

  String _nomeAluno(Map<String, dynamic> item) {
    final alunoId = item['id_aluno'];
    final id = alunoId is int ? alunoId : int.tryParse(alunoId?.toString() ?? '');
    if (id == null) return '';
    final nome = _nomesAlunosPorId[id];
    if (nome != null) return nome;
    return '';
  }

  bool _bool(Map<String, dynamic> item, List<String> chaves) {
    for (final chave in chaves) {
      final valor = item[chave];
      if (valor is bool) return valor;
      if (valor is num) return valor != 0;
      if (valor is String) {
        final normalizado = valor.trim().toLowerCase();
        if (normalizado == 'true' ||
            normalizado == '1' ||
            normalizado == 'sim' ||
            normalizado == 'disponivel' ||
            normalizado == 'disponível') {
          return true;
        }
        if (normalizado == 'false' ||
            normalizado == '0' ||
            normalizado == 'nao' ||
            normalizado == 'não' ||
            normalizado == 'indisponivel' ||
            normalizado == 'indisponível') {
          return false;
        }
      }
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    _carregarInstrumentos();
  }

  @override
  void dispose() {
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
      final alunosResponse = await _supabase
          .from('alunos')
          .select('id_aluno, nome_completo');

      if (!mounted) return;

      final nomesAlunosPorId = <int, String>{};
      for (final item in alunosResponse as List) {
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
        final nome = _texto(item, ['nome_instrumento']).toLowerCase();
        final patrimonio = _texto(item, ['numero_patrimonio']).toLowerCase();
        return nome.contains(query) || patrimonio.contains(query);
      }).toList();
    }

    if (_filtroPropriedade != null) {
      resultado = resultado.where((item) {
        return _texto(item, ['propriedade_instrumento']) == _filtroPropriedade;
      }).toList();
    }

    if (_filtroStatus != null) {
      final disponivel = _filtroStatus == 'Disponivel';
      resultado = resultado
          .where((item) => _bool(item, ['disponivel']) == disponivel)
          .toList();
    }

    if (_ordenarAlfabetico) {
      resultado.sort(
        (a, b) => _texto(a, ['nome_instrumento']).compareTo(
          _texto(b, ['nome_instrumento']),
        ),
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
            child: const Text(
              'Excluir',
              style: TextStyle(color: Colors.red),
            ),
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
      endDrawer: const PerfilDrawer(),
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
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: SizedBox(
                width: 24,
                height: 24,
                child: Image.asset('assets/profile.png'),
              ),
              onPressed: () async {
                final RenderBox button =
                    context.findRenderObject() as RenderBox;
                final RenderBox overlay =
                    Overlay.of(context).context.findRenderObject() as RenderBox;

                final RelativeRect position = RelativeRect.fromRect(
                  Rect.fromPoints(
                    button.localToGlobal(
                      Offset(-15, button.size.height - 8),
                      ancestor: overlay,
                    ),
                    button.localToGlobal(
                      button.size.bottomRight(Offset.zero) +
                          const Offset(-15, -8),
                      ancestor: overlay,
                    ),
                  ),
                  Offset.zero & overlay.size,
                );

                final user = Supabase.instance.client.auth.currentUser;
                final nomeUsuario = user?.userMetadata?['name'] ?? 'Usuário';

                final result = await showMenu<String>(
                  context: context,
                  position: position,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  items: [
                    PopupMenuItem<String>(
                      enabled: false,
                      child: Row(
                        children: [
                          const Icon(Icons.person_outline),
                          const SizedBox(width: 10),
                          Text(
                            nomeUsuario.toString(),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem<String>(
                      value: 'logout',
                      child: Row(
                        children: [
                          Icon(Icons.logout, color: Colors.red),
                          SizedBox(width: 10),
                          Text(
                            'Sair',
                            style: TextStyle(color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                  ],
                );

                if (result == 'logout') {
                  // implementar logout depois
                }
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _abrirDialogInstrumento(),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          const SizedBox(height: 15),
          const Text(
            'Controle de Instrumentos',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(_aplicarFiltros),
              decoration: InputDecoration(
                hintText: 'Pesquisar instrumento...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: const Color.fromARGB(255, 255, 255, 255),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
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
                        width: 32,
                        height: 32,
                        child: Checkbox(
                          value: _ordenarAlfabetico,
                          activeColor: const Color(0xFF2563EB),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          onChanged: (v) {
                            setState(() {
                              _ordenarAlfabetico = v ?? false;
                              _aplicarFiltros();
                            });
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
                  hint: 'Propriedade',
                  valor: _filtroPropriedade,
                  opcoes: _propriedades,
                  onChanged: (v) {
                    setState(() {
                      _filtroPropriedade = v;
                      _aplicarFiltros();
                    });
                  },
                  onLimpar: () {
                    setState(() {
                      _filtroPropriedade = null;
                      _aplicarFiltros();
                    });
                  },
                ),
                const SizedBox(width: 10),
                _FiltroDropdown(
                  hint: 'Status',
                  valor: _filtroStatus,
                  opcoes: _statusDisponibilidade,
                  onChanged: (v) {
                    setState(() {
                      _filtroStatus = v;
                      _aplicarFiltros();
                    });
                  },
                  onLimpar: () {
                    setState(() {
                      _filtroStatus = null;
                      _aplicarFiltros();
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 15),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _erroCarregamento != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'Nao foi possivel carregar os instrumentos.',
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _erroCarregamento!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.red),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _carregarInstrumentos,
                                child: const Text('Tentar novamente'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _instrumentosFiltrados.isEmpty
                        ? const Center(
                            child: Text('Nenhum instrumento encontrado.'),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(12),
                            itemCount: _instrumentosFiltrados.length,
                            itemBuilder: (context, index) {
                              final item = _instrumentosFiltrados[index];
                              final nome = _texto(item, ['nome_instrumento']);
                              final patrimonio = _texto(
                                item,
                                ['numero_patrimonio'],
                              );
                              final disponivel = _bool(item, ['disponivel']);
                              final observacoes = _texto(item, ['observacoes']);
                              final propriedade = _texto(
                                item,
                                ['propriedade_instrumento'],
                              );
                              final alunoNome = _nomeAluno(item);
                              final levaInstrumento = _bool(
                                item,
                                ['leva_instrumento'],
                              );
                              final imageUrl = _texto(item, ['imagem_url']);

                              final status =
                                  disponivel ? 'Disponível' : 'Indisponível';

                              return InstrumentoCard(
                                nome: nome,
                                patrimonio: patrimonio,
                                status: status,
                                alunoNome: alunoNome,
                                propriedade: propriedade,
                                levaInstrumento: levaInstrumento,
                                observacoes: observacoes,
                                imageUrl: imageUrl,
                                onTap: () {
                                  _abrirDetalhesInstrumento(
                                    context: context,
                                    nome: nome,
                                    patrimonio: patrimonio,
                                    status: status,
                                    alunoNome: alunoNome,
                                    propriedade: propriedade,
                                    levaInstrumento: levaInstrumento,
                                    observacoes: observacoes,
                                    imageUrl: imageUrl,
                                  );
                                },
                                onEdit: () => _abrirDialogInstrumento(
                                  instrumento: item,
                                ),
                                onDelete: () => _deletarInstrumento(
                                  item['id_instrumento'],
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}

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
  final ValueChanged<String?> onChanged;
  final VoidCallback onLimpar;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: valor,
          hint: Text(
            hint,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF6B7280),
            ),
          ),
          borderRadius: BorderRadius.circular(10),
          items: [
            ...opcoes.map(
              (opcao) => DropdownMenuItem<String>(
                value: opcao,
                child: Text(opcao),
              ),
            ),
            if (valor != null)
              const DropdownMenuItem<String>(
                value: '__limpar__',
                child: Text('Limpar filtro'),
              ),
          ],
          onChanged: (value) {
            if (value == '__limpar__') {
              onLimpar();
              return;
            }
            onChanged(value);
          },
        ),
      ),
    );
  }
}
