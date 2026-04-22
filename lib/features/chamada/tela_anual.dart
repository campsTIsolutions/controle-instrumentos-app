// lib/features/chamada/tela_anual.dart
// Tela inicial: grade anual com 12 cards de mês.
// • Dropdown de seleção de ano (2026–2040)
// • Contagem dinâmica de aulas por mês buscada no Supabase
// • Ao tocar em um mês, navega para TelaMes

import 'package:flutter/material.dart';
import 'package:controle_instrumentos/features/instrumentos/ui/widgets/app_drawer.dart';
import 'package:controle_instrumentos/shared/widgets/profile_menu_button.dart';
import 'supabase_service.dart';
import 'tela_mes.dart';

class TelaAnual extends StatefulWidget {
  const TelaAnual({super.key});

  @override
  State<TelaAnual> createState() => _TelaAnualState();
}

class _TelaAnualState extends State<TelaAnual> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // ── Intervalo de anos disponíveis no dropdown ─────────────────────────────
  static const int _anoMin = 2026;
  static const int _anoMax = 2040;

  late int _anoSelecionado;

  /// aulasPorMes[mes] = quantidade de aulas naquele mês (1-indexed)
  final Map<int, int> _aulasPorMes = {};
  bool _carregando = false;

  static const List<String> _nomesMeses = [
    'Janeiro',
    'Fevereiro',
    'Março',
    'Abril',
    'Maio',
    'Junho',
    'Julho',
    'Agosto',
    'Setembro',
    'Outubro',
    'Novembro',
    'Dezembro',
  ];

  static const List<String> _abrevMeses = [
    'Jan',
    'Fev',
    'Mar',
    'Abr',
    'Mai',
    'Jun',
    'Jul',
    'Ago',
    'Set',
    'Out',
    'Nov',
    'Dez',
  ];

  @override
  void initState() {
    super.initState();
    // Inicia no ano atual, limitado ao intervalo do dropdown
    final agora = DateTime.now().year;
    _anoSelecionado = agora.clamp(_anoMin, _anoMax);
    _carregarAulasPorAno(_anoSelecionado);
  }

  // ── Carrega a contagem de aulas de todos os meses do ano ──────────────────
  Future<void> _carregarAulasPorAno(int ano) async {
    setState(() => _carregando = true);
    try {
      final Map<int, int> contagem = {};
      // Busca todos os 12 meses em paralelo
      final futures = List.generate(
        12,
        (i) => SupabaseService.fetchAulas(ano: ano, mes: i + 1),
      );
      final resultados = await Future.wait(futures);
      for (int i = 0; i < 12; i++) {
        contagem[i + 1] = resultados[i].length;
      }
      if (mounted) {
        setState(() {
          _aulasPorMes
            ..clear()
            ..addAll(contagem);
          _carregando = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _carregando = false);
    }
  }

  // ── Navegar para o mês selecionado ────────────────────────────────────────
  Future<void> _abrirMes(int mes) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TelaMes(
          ano: _anoSelecionado,
          mes: mes,
          nomesMes: _nomesMeses[mes - 1],
        ),
      ),
    );
    // Recarrega contagem ao voltar (podem ter aulas adicionadas/removidas)
    _carregarAulasPorAno(_anoSelecionado);
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: const AppDrawer(),
      backgroundColor: Colors.grey.shade100,
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: SizedBox(
          width: 24,
          height: 24,
          child: Image.asset('assets/menu-icon.png'),
        ),
        onPressed: () => _scaffoldKey.currentState?.openDrawer(),
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
      actions: const [ProfileMenuButton()],
    );
  }

  /// Dropdown compacto para selecionar o ano
  Widget _buildDropdownAno() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1976D2).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF1976D2).withValues(alpha: 0.35),
          width: 0.8,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _anoSelecionado,
          isDense: true,
          icon: const Icon(
            Icons.keyboard_arrow_down,
            size: 16,
            color: Color(0xFF1976D2),
          ),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1976D2),
          ),
          items: List.generate(_anoMax - _anoMin + 1, (i) {
            final ano = _anoMin + i;
            return DropdownMenuItem(value: ano, child: Text('$ano'));
          }),
          onChanged: (novoAno) {
            if (novoAno == null || novoAno == _anoSelecionado) return;
            setState(() {
              _anoSelecionado = novoAno;
              _aulasPorMes.clear();
            });
            _carregarAulasPorAno(novoAno);
          },
        ),
      ),
    );
  }

  Widget _buildBody() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          24 + MediaQuery.of(context).padding.bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4, right: 4, bottom: 8),
              child: Text(
                'Chamada',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade900,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 4, right: 4, bottom: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Text(
                          '$_anoSelecionado',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade600,
                            letterSpacing: 0.4,
                          ),
                        ),
                        if (_carregando) ...[
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  _buildDropdownAno(),
                ],
              ),
            ),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.1,
              ),
              itemCount: 12,
              itemBuilder: (context, index) {
                final mes = index + 1;
                final numAulas = _aulasPorMes[mes] ?? 0;
                final temDados = numAulas > 0;

                return _MesCard(
                  abrev: _abrevMeses[index],
                  numAulas: numAulas,
                  temDados: temDados,
                  onTap: () => _abrirMes(mes),
                );
              },
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                'Toque em um mês para abrir a chamada',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// ─── Card individual de mês ───────────────────────────────────────────────────

class _MesCard extends StatelessWidget {
  final String abrev;
  final int numAulas;
  final bool temDados;
  final VoidCallback onTap;

  const _MesCard({
    required this.abrev,
    required this.numAulas,
    required this.temDados,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: temDados
                ? const Color(0xFF1976D2).withValues(alpha: 0.35)
                : Colors.grey.shade200,
            width: 0.8,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              abrev,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: temDados ? const Color(0xFF1976D2) : Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              numAulas == 0 ? '—' : '$numAulas aula${numAulas > 1 ? 's' : ''}',
              style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 6),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: temDados ? const Color(0xFF1976D2) : Colors.transparent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
