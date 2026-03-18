import 'package:flutter/material.dart';
import '../data/instruments_repository.dart';
import 'widgets/instrumento_card.dart';
import 'widgets/app_drawer.dart';
import 'widgets/perfil_drawer.dart';
import 'widgets/instrumento_dialog.dart';
import 'widgets/instrumento_text.dart';
import 'widgets/instrumento_actionbuttom.dart';
import 'widgets/instrumento_detalhe_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class InstrumentosPage extends StatefulWidget {
  const InstrumentosPage({super.key});

  @override
  State<InstrumentosPage> createState() => _InstrumentosPageState();
}

class _InstrumentosPageState extends State<InstrumentosPage> {
  final repo = InstrumentsRepository();
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  List<Map<String, dynamic>> _instrumentos = [];
  late final Future<List<Map<String, dynamic>>> futureInstrumentos;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    futureInstrumentos = repo.fetchInstrumentos();
    _carregarInstrumentos();
  }

  void _abrirModalInstrumento({
    required String nome,
    required String tipo,
    required String aluno,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.5,
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(24),
              ),
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
                    'Tipo: $tipo',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Aluno: $aluno',
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
    setState(() => _isLoading = true);

    try {
      final response = await _supabase
          .from('instrumentos')
          .select('id_instrumento, nome, tipo, aluno')
          .order('id_instrumento', ascending: true);

      setState(() {
        _instrumentos = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar instrumentos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deletarInstrumento(int id) async {
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

    if (confirmar == true) {
      try {
        await _supabase.from('instrumentos').delete().eq('id_instrumento', id);
        _carregarInstrumentos();
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

          if (mounted) Navigator.pop(ctx);
          _carregarInstrumentos();
        },
      ),
    );
  }
  Future<void> _abrirMenuPerfil(BuildContext context) async {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;

    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(
          Offset(-15, button.size.height - 8),
          ancestor: overlay,
        ),
        button.localToGlobal(
          button.size.bottomRight(Offset.zero) + const Offset(-15, -8),
          ancestor: overlay,
        ),
      ),
      Offset.zero & overlay.size,
    );

    final result = await showMenu<String>(
      context: context,
      position: position,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      elevation: 8,
      color: Colors.white,
      items: const [
        PopupMenuItem<String>(
          value: 'perfil',
          child: Row(
            children: [
              Icon(Icons.person_outline),
              SizedBox(width: 10),
              Text('Perfil'),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'config',
          child: Row(
            children: [
              Icon(Icons.settings_outlined),
              SizedBox(width: 10),
              Text('Configurações'),
            ],
          ),
        ),
        PopupMenuDivider(),
        PopupMenuItem<String>(
          value: 'sair',
          child: Row(
            children: [
              Icon(Icons.logout),
              SizedBox(width: 10),
              Text('Sair'),
            ],
          ),
        ),
      ],
    );

    if (result == 'perfil') {
      debugPrint('Ir para perfil');
    } else if (result == 'config') {
      debugPrint('Ir para configurações');
    } else if (result == 'sair') {
      debugPrint('Sair');
    }
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
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: SizedBox(
                width: 24,
                height: 24,
                child: Image.asset("assets/profile.png"),
              ),
              onPressed: () => _abrirMenuPerfil(context),
            ),
          ),
        ],
      ),
      body: Column(
          children: [
            const SizedBox(height: 15),
            const Text(
              "Controle de Instrumentos",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                decoration: InputDecoration(
                  hintText: "Pesquisar instrumento...",
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
          : _instrumentos.isEmpty
              ? const Center(
                  child: Text("Nenhum instrumento cadastrado."),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _instrumentos.length,
                  itemBuilder: (context, index) {
                    final item = _instrumentos[index];

                    final nome = (item['nome'] ?? '').toString();
                    final tipo = (item['tipo'] ?? '').toString();
                    final aluno = (item['aluno'] ?? '').toString();

                    return Column(
                      children: [
                        InstrumentoCard(
                          nome: nome,
                          tipo: tipo,
                          aluno: aluno,
                          onTap: () {
                            _abrirModalInstrumento(
                              nome: nome,
                              tipo: tipo,
                              aluno: aluno,
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
                                item['id_instrumento'] as int,
                              ),
                            ),
                          ],
                        ),
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