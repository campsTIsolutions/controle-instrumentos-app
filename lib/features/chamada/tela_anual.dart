// lib/features/chamada/tela_anual.dart
// Tela inicial: grade anual com 12 cards de mês.
// Ao tocar em um mês, navega para TelaMes.

import 'package:flutter/material.dart';
import 'models.dart';
import 'tela_mes.dart';

class TelaAnual extends StatefulWidget {
  const TelaAnual({super.key});

  @override
  State<TelaAnual> createState() => _TelaAnualState();
}

class _TelaAnualState extends State<TelaAnual> {
  final int _ano = DateTime.now().year;

  static const List<String> _nomesMeses = [
    'Janeiro', 'Fevereiro', 'Março', 'Abril',
    'Maio', 'Junho', 'Julho', 'Agosto',
    'Setembro', 'Outubro', 'Novembro', 'Dezembro',
  ];

  static const List<String> _abrevMeses = [
    'Jan', 'Fev', 'Mar', 'Abr',
    'Mai', 'Jun', 'Jul', 'Ago',
    'Set', 'Out', 'Nov', 'Dez',
  ];

  // ── Navegar para o mês selecionado ────────────────────────────────────────
  void _abrirMes(int mes) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TelaMes(
          ano: _ano,
          mes: mes,
          nomesMes: _nomesMeses[mes - 1],
        ),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: _buildAppBar(),
      body: _buildGrid(),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(Icons.menu, color: Colors.black87),
        onPressed: () {},
      ),
      title: const Text(
        'CAMPS',
        style: TextStyle(
          color: Colors.black87,
          fontWeight: FontWeight.w600,
          fontSize: 20,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildGrid() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              '$_ano',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
                letterSpacing: 0.4,
              ),
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
              final mes = index + 1; // 1-indexado
              final datas = buildMockDatesForMonth(_ano, mes);
              final temDados = datas.isNotEmpty;

              return _MesCard(
                abrev: _abrevMeses[index],
                numAulas: datas.length,
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
                ? const Color(0xFF1976D2).withOpacity(0.35)
                : Colors.grey.shade200,
            width: 0.8,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
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
                color: temDados
                    ? const Color(0xFF1976D2)
                    : Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              numAulas == 0 ? '—' : '$numAulas aula${numAulas > 1 ? 's' : ''}',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 6),
            // Indicador de dados
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: temDados
                    ? const Color(0xFF1976D2)
                    : Colors.transparent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
