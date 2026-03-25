import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

<<<<<<< HEAD
=======
import '../data/instruments_repository.dart';
>>>>>>> 242608c (WIP: salvar progresso atual)
import 'widgets/app_drawer.dart';
import 'widgets/perfil_drawer.dart';
import 'widgets/instrumento_card.dart';
import 'widgets/instrumento_dialog.dart';
import 'widgets/instrumento_actionbuttom.dart';

class InstrumentosPage extends StatefulWidget {
  const InstrumentosPage({super.key});

  @override
  State<InstrumentosPage> createState() => _InstrumentosPageState();
}

class _InstrumentosPageState extends State<InstrumentosPage> {
  final _supabase = Supabase.instance.client;
<<<<<<< HEAD
=======
  final _repository = InstrumentsRepository();
>>>>>>> 242608c (WIP: salvar progresso atual)
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  bool _isLoading = true;
  List<Map<String, dynamic>> _instrumentos = [];
  String _search = '';
<<<<<<< HEAD
  String? _erroCarregamento;
=======
>>>>>>> 242608c (WIP: salvar progresso atual)

  String _texto(Map<String, dynamic> item, List<String> chaves) {
    for (final chave in chaves) {
      final valor = item[chave];
      if (valor != null) return valor.toString();
    }
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

  void _abrirModalInstrumento({
    required String nome,
    required String patrimonio,
    required String status,
    required String observacoes,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.58,
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.asset(
                        'assets/instrumento.png',
                        height: 140,
                        width: 140,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    nome,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Patrimônio: $patrimonio',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Status: $status',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Observações: ${observacoes.isEmpty ? 'Sem observações' : observacoes}',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _carregarInstrumentos() async {
    if (!mounted) return;

<<<<<<< HEAD
    setState(() {
      _isLoading = true;
      _erroCarregamento = null;
    });

    try {
      final response = await _supabase
          .from('instrumentos')
          .select(
            'id_instrumento, numero_patrimonio, nome_instrumento, disponivel, propriedade_instrumento, leva_instrumento, observacoes, imagem_url',
          )
          .order('id_instrumento', ascending: true);
=======
    setState(() => _isLoading = true);

    try {
      final response = await _repository.fetchInstrumentos();

      if (!mounted) return;
>>>>>>> 242608c (WIP: salvar progresso atual)

      if (!mounted) return;

      setState(() {
<<<<<<< HEAD
        _instrumentos = List<Map<String, dynamic>>.from(
          (response as List).map((item) => Map<String, dynamic>.from(item)),
        );
=======
        _instrumentos = response;
>>>>>>> 242608c (WIP: salvar progresso atual)
        _isLoading = false;
      });
    } catch (e, s) {
      debugPrint('Erro ao carregar instrumentos: $e');
      debugPrintStack(stackTrace: s);

      if (!mounted) return;

<<<<<<< HEAD
      setState(() {
        _isLoading = false;
        _erroCarregamento = e.toString();
      });
=======
      setState(() => _isLoading = false);
>>>>>>> 242608c (WIP: salvar progresso atual)

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao carregar instrumentos: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
      await _supabase.from('instrumentos').delete().eq('id_instrumento', id);
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
            await _supabase.from('instrumentos').insert(dados);
          } else {
            await _supabase
                .from('instrumentos')
                .update(dados)
                .eq('id_instrumento', instrumento['id_instrumento']);
          }

          await _carregarInstrumentos();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final instrumentosFiltrados = _instrumentos.where((item) {
<<<<<<< HEAD
      final nome = _texto(item, ['nome_instrumento']).toLowerCase();
      final patrimonio = _texto(item, ['numero_patrimonio']).toLowerCase();
=======
      final nome = _texto(item, ['nome_instrumento', 'nome']).toLowerCase();
      final patrimonio =
          _texto(item, ['numero_patrimonio', 'patrimonio']).toLowerCase();
>>>>>>> 242608c (WIP: salvar progresso atual)
      final termo = _search.toLowerCase();

      return nome.contains(termo) || patrimonio.contains(termo);
    }).toList();

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
              onChanged: (value) {
                setState(() => _search = value);
              },
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
          const SizedBox(height: 15),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
<<<<<<< HEAD
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
                : instrumentosFiltrados.isEmpty
                    ? const Center(
                        child: Text('Nenhum instrumento cadastrado.'),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: instrumentosFiltrados.length,
                        itemBuilder: (context, index) {
                          final item = instrumentosFiltrados[index];

                          final nome = _texto(item, ['nome_instrumento']);
                          final patrimonio = _texto(
                            item,
                            ['numero_patrimonio'],
                          );
                          final disponivel = _bool(item, ['disponivel']);
                          final observacoes = _texto(item, ['observacoes']);

                          final status =
                              disponivel ? 'Disponível' : 'Indisponível';

                          return Column(
                            children: [
                              InstrumentoCard(
                                nome: nome,
                                tipo: patrimonio,
                                aluno: status,
                                onTap: () {
                                  _abrirModalInstrumento(
                                    nome: nome,
                                    patrimonio: patrimonio,
                                    status: status,
                                    observacoes: observacoes,
                                  );
                                },
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  InstrumentoActionbuttom(
                                    icone: Icons.edit,
                                    cor: const Color(0xFF2563EB),
                                    onTap: () => _abrirDialogInstrumento(
                                      instrumento: item,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  InstrumentoActionbuttom(
                                    icone: Icons.delete,
                                    cor: const Color(0xFFB91C1C),
                                    onTap: () => _deletarInstrumento(
                                      item['id_instrumento'],
                                    ),
                                  ),
                                ],
                              ),
=======
                : instrumentosFiltrados.isEmpty
                    ? const Center(
                        child: Text('Nenhum instrumento cadastrado.'),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: instrumentosFiltrados.length,
                        itemBuilder: (context, index) {
                          final item = instrumentosFiltrados[index];

                          final nome =
                              _texto(item, ['nome_instrumento', 'nome']);
                          final patrimonio = _texto(
                            item,
                            ['numero_patrimonio', 'patrimonio'],
                          );
                          final disponivel = _bool(
                            item,
                            ['disponivel', 'disponibilidade'],
                          );
                          final observacoes = _texto(
                            item,
                            ['observacoes', 'observacao'],
                          );

                          final status =
                              disponivel ? 'Disponível' : 'Indisponível';

                          return Column(
                            children: [
                              InstrumentoCard(
                                nome: nome,
                                tipo: patrimonio,
                                aluno: status,
                                onTap: () {
                                  _abrirModalInstrumento(
                                    nome: nome,
                                    patrimonio: patrimonio,
                                    status: status,
                                    observacoes: observacoes,
                                  );
                                },
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  InstrumentoActionbuttom(
                                    icone: Icons.edit,
                                    cor: const Color(0xFF2563EB),
                                    onTap: () =>
                                        _abrirDialogInstrumento(instrumento: item),
                                  ),
                                  const SizedBox(width: 8),
                                  InstrumentoActionbuttom(
                                    icone: Icons.delete,
                                    cor: const Color(0xFFB91C1C),
                                    onTap: () => _deletarInstrumento(
                                      item['id_instrumento'],
                                    ),
                                  ),
                                ],
                              ),
>>>>>>> 242608c (WIP: salvar progresso atual)
                              const SizedBox(height: 12),
                            ],
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
