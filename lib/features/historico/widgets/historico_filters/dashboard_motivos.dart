import 'package:controle_instrumentos/features/historico/widgets/historico_filters/motivo_visual.dart';
import 'package:flutter/material.dart';

class DashboardMotivos extends StatelessWidget {
  const DashboardMotivos({
    super.key,
    required this.contagem,
    required this.motivoConfig,
    required this.anoFiltrado,
  });

  final Map<String, int> contagem;
  final Map<String, MotivoVisual> motivoConfig;
  final int? anoFiltrado;

  @override
  Widget build(BuildContext context) {
    final total = contagem.values.fold(0, (a, b) => a + b);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Motivos de Desligamento',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              const Spacer(),
              if (anoFiltrado != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$anoFiltrado',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF2563EB),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Todos os anos',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF6B7280),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: contagem.entries.toList().asMap().entries.map((entry) {
              final i = entry.key;
              final e = entry.value;
              final config = motivoConfig[e.key]!;
              final pct = total == 0 ? 0.0 : e.value / total;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(left: i == 0 ? 0 : 8),
                  child: _MotivoCard(
                    motivo: e.key,
                    quantidade: e.value,
                    percentual: pct,
                    visual: config,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
          if (total > 0)
            _BarraProporcao(contagem: contagem, motivoConfig: motivoConfig),
        ],
      ),
    );
  }
}

class _MotivoCard extends StatelessWidget {
  const _MotivoCard({
    required this.motivo,
    required this.quantidade,
    required this.percentual,
    required this.visual,
  });

  final String motivo;
  final int quantidade;
  final double percentual;
  final MotivoVisual visual;

  String get _abrev {
    switch (motivo) {
      case 'Falta de Tempo':
        return 'Tempo';
      case 'Falta de Disciplina':
        return 'Disciplina';
      case 'Falta de Interesse':
        return 'Interesse';
      default:
        return motivo;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: visual.corFundo,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(visual.icone, size: 18, color: visual.cor),
          ),
          const SizedBox(height: 8),
          Text(
            '$quantidade',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: visual.cor,
            ),
          ),
          Text(
            _abrev,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            '${(percentual * 100).toStringAsFixed(0)}%',
            style: TextStyle(
              fontSize: 11,
              color: visual.cor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _BarraProporcao extends StatelessWidget {
  const _BarraProporcao({required this.contagem, required this.motivoConfig});

  final Map<String, int> contagem;
  final Map<String, MotivoVisual> motivoConfig;

  @override
  Widget build(BuildContext context) {
    final total = contagem.values.fold(0, (a, b) => a + b);
    if (total == 0) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            height: 8,
            child: Row(
              children: contagem.entries.map((e) {
                final flex = (e.value * 1000 ~/ total).clamp(1, 1000);
                return Expanded(
                  flex: flex,
                  child: Container(
                    color: motivoConfig[e.key]?.cor ?? Colors.grey,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 14,
          runSpacing: 4,
          children: contagem.entries.map((e) {
            final cor = motivoConfig[e.key]?.cor ?? Colors.grey;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: cor, shape: BoxShape.circle),
                ),
                const SizedBox(width: 4),
                Text(
                  e.key,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}
