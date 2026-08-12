import 'package:flutter/material.dart';

import '../exportacao/chamada_exportacao.dart';

class ChamadaExportacaoDialog extends StatefulWidget {
  const ChamadaExportacaoDialog({
    super.key,
    required this.anoSelecionado,
    required this.anoMinimo,
    required this.anoMaximo,
  });

  final int anoSelecionado;
  final int anoMinimo;
  final int anoMaximo;

  @override
  State<ChamadaExportacaoDialog> createState() =>
      _ChamadaExportacaoDialogState();
}

class _ChamadaExportacaoDialogState extends State<ChamadaExportacaoDialog> {
  static const _verde = Color(0xFF2E7D32);
  static const _meses = [
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

  TipoExportacaoChamada _tipo = TipoExportacaoChamada.mes;
  int _mes = DateTime.now().month;
  late int _mesInicial;
  late int _anoInicial;
  late int _mesFinal;
  late int _anoFinal;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _mesInicial = 1;
    _anoInicial = widget.anoSelecionado;
    _mesFinal = 12;
    _anoFinal = widget.anoSelecionado;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 12, 4),
      contentPadding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      actionsPadding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      title: Row(
        children: [
          const Icon(Icons.table_view_outlined, color: _verde),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Exportar chamada',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
            ),
          ),
          IconButton(
            tooltip: 'Fechar',
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: RadioGroup<TipoExportacaoChamada>(
            groupValue: _tipo,
            onChanged: (valor) {
              if (valor == null) return;
              setState(() {
                _tipo = valor;
                _erro = null;
              });
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _opcao(
                  tipo: TipoExportacaoChamada.mes,
                  titulo: 'Um mês específico',
                  subtitulo: 'Exporta somente o mês escolhido',
                ),
                if (_tipo == TipoExportacaoChamada.mes)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                    child: _dropdownMes(
                      key: const Key('exportacao_mes'),
                      valor: _mes,
                      onChanged: (valor) => setState(() => _mes = valor),
                    ),
                  ),
                _opcao(
                  tipo: TipoExportacaoChamada.anoCompleto,
                  titulo: 'Ano completo',
                  subtitulo: 'Janeiro a dezembro de ${widget.anoSelecionado}',
                ),
                _opcao(
                  tipo: TipoExportacaoChamada.periodo,
                  titulo: 'Período específico',
                  subtitulo: 'Escolha o mês/ano inicial e final',
                ),
                if (_tipo == TipoExportacaoChamada.periodo)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Início',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        _linhaMesAno(
                          prefixoKey: 'inicio',
                          mes: _mesInicial,
                          ano: _anoInicial,
                          onMesChanged: (valor) =>
                              setState(() => _mesInicial = valor),
                          onAnoChanged: (valor) =>
                              setState(() => _anoInicial = valor),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Fim',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        _linhaMesAno(
                          prefixoKey: 'fim',
                          mes: _mesFinal,
                          ano: _anoFinal,
                          onMesChanged: (valor) =>
                              setState(() => _mesFinal = valor),
                          onAnoChanged: (valor) =>
                              setState(() => _anoFinal = valor),
                        ),
                      ],
                    ),
                  ),
                if (_erro != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Text(
                      _erro!,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          key: const Key('confirmar_exportacao'),
          style: FilledButton.styleFrom(backgroundColor: _verde),
          onPressed: _confirmar,
          icon: const Icon(Icons.download, size: 18),
          label: const Text('Exportar'),
        ),
      ],
    );
  }

  Widget _opcao({
    required TipoExportacaoChamada tipo,
    required String titulo,
    required String subtitulo,
  }) {
    return RadioListTile<TipoExportacaoChamada>(
      value: tipo,
      activeColor: _verde,
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      title: Text(
        titulo,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(subtitulo, style: const TextStyle(fontSize: 11)),
    );
  }

  Widget _linhaMesAno({
    required String prefixoKey,
    required int mes,
    required int ano,
    required ValueChanged<int> onMesChanged,
    required ValueChanged<int> onAnoChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: _dropdownMes(
            key: Key('exportacao_${prefixoKey}_mes'),
            valor: mes,
            onChanged: onMesChanged,
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 105,
          child: _dropdownAno(
            key: Key('exportacao_${prefixoKey}_ano'),
            valor: ano,
            onChanged: onAnoChanged,
          ),
        ),
      ],
    );
  }

  Widget _dropdownMes({
    required Key key,
    required int valor,
    required ValueChanged<int> onChanged,
  }) {
    return DropdownButtonFormField<int>(
      key: key,
      initialValue: valor,
      isExpanded: true,
      decoration: _decoracaoCampo(),
      items: List.generate(
        12,
        (index) => DropdownMenuItem(
          value: index + 1,
          child: Text(_meses[index], overflow: TextOverflow.ellipsis),
        ),
      ),
      onChanged: (novoValor) {
        if (novoValor != null) onChanged(novoValor);
      },
    );
  }

  Widget _dropdownAno({
    required Key key,
    required int valor,
    required ValueChanged<int> onChanged,
  }) {
    return DropdownButtonFormField<int>(
      key: key,
      initialValue: valor,
      isExpanded: true,
      decoration: _decoracaoCampo(),
      items: List.generate(widget.anoMaximo - widget.anoMinimo + 1, (index) {
        final ano = widget.anoMinimo + index;
        return DropdownMenuItem(value: ano, child: Text('$ano'));
      }),
      onChanged: (novoValor) {
        if (novoValor != null) onChanged(novoValor);
      },
    );
  }

  InputDecoration _decoracaoCampo() => InputDecoration(
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
  );

  void _confirmar() {
    final selecao = switch (_tipo) {
      TipoExportacaoChamada.mes => SelecaoExportacaoChamada.mes(
        mes: _mes,
        ano: widget.anoSelecionado,
      ),
      TipoExportacaoChamada.anoCompleto => SelecaoExportacaoChamada.anoCompleto(
        widget.anoSelecionado,
      ),
      TipoExportacaoChamada.periodo => SelecaoExportacaoChamada.periodo(
        mesInicial: _mesInicial,
        anoInicial: _anoInicial,
        mesFinal: _mesFinal,
        anoFinal: _anoFinal,
      ),
    };

    if (!selecao.periodoValido) {
      setState(
        () => _erro =
            'O período final deve ser igual ou posterior ao período inicial.',
      );
      return;
    }
    Navigator.pop(context, selecao);
  }
}
