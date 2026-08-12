import 'package:excel/excel.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../models.dart';
import '../student_sort.dart';
import '../supabase_service.dart';

enum TipoExportacaoChamada { mes, anoCompleto, periodo }

class SelecaoExportacaoChamada {
  const SelecaoExportacaoChamada._({
    required this.tipo,
    required this.mesInicial,
    required this.anoInicial,
    required this.mesFinal,
    required this.anoFinal,
  });

  factory SelecaoExportacaoChamada.mes({required int mes, required int ano}) =>
      SelecaoExportacaoChamada._(
        tipo: TipoExportacaoChamada.mes,
        mesInicial: mes,
        anoInicial: ano,
        mesFinal: mes,
        anoFinal: ano,
      );

  factory SelecaoExportacaoChamada.anoCompleto(int ano) =>
      SelecaoExportacaoChamada._(
        tipo: TipoExportacaoChamada.anoCompleto,
        mesInicial: 1,
        anoInicial: ano,
        mesFinal: 12,
        anoFinal: ano,
      );

  factory SelecaoExportacaoChamada.periodo({
    required int mesInicial,
    required int anoInicial,
    required int mesFinal,
    required int anoFinal,
  }) => SelecaoExportacaoChamada._(
    tipo: TipoExportacaoChamada.periodo,
    mesInicial: mesInicial,
    anoInicial: anoInicial,
    mesFinal: mesFinal,
    anoFinal: anoFinal,
  );

  final TipoExportacaoChamada tipo;
  final int mesInicial;
  final int anoInicial;
  final int mesFinal;
  final int anoFinal;

  DateTime get inicio => DateTime(anoInicial, mesInicial);
  DateTime get fim => DateTime(anoFinal, mesFinal + 1, 0);
  bool get periodoValido => !fim.isBefore(inicio);

  String get nomeArquivo {
    switch (tipo) {
      case TipoExportacaoChamada.mes:
        return 'chamada_${_nomesMesesArquivo[mesInicial - 1]}_$anoInicial.xlsx';
      case TipoExportacaoChamada.anoCompleto:
        return 'chamada_ano-completo_$anoInicial.xlsx';
      case TipoExportacaoChamada.periodo:
        final meses =
            '${_abreviacoesMeses[mesInicial - 1]}-${_abreviacoesMeses[mesFinal - 1]}';
        final anos = anoInicial == anoFinal
            ? '$anoInicial'
            : '$anoInicial-$anoFinal';
        return 'chamada_${meses}_$anos.xlsx';
    }
  }

  static const _nomesMesesArquivo = [
    'janeiro',
    'fevereiro',
    'marco',
    'abril',
    'maio',
    'junho',
    'julho',
    'agosto',
    'setembro',
    'outubro',
    'novembro',
    'dezembro',
  ];

  static const _abreviacoesMeses = [
    'jan',
    'fev',
    'mar',
    'abr',
    'mai',
    'jun',
    'jul',
    'ago',
    'set',
    'out',
    'nov',
    'dez',
  ];
}

class ResultadoExportacaoChamada {
  const ResultadoExportacaoChamada._({
    required this.exportado,
    this.nomeArquivo,
    this.localSalvamento,
  });

  const ResultadoExportacaoChamada.semAulas() : this._(exportado: false);

  ResultadoExportacaoChamada.sucesso(ArquivoChamadaSalvo arquivo)
    : this._(
        exportado: true,
        nomeArquivo: arquivo.nomeArquivo,
        localSalvamento: arquivo.localSalvamento,
      );

  final bool exportado;
  final String? nomeArquivo;
  final String? localSalvamento;
}

abstract class ChamadaExportacaoDataSource {
  Future<List<StudentRecord>> buscarAlunos();
  Future<List<AulaRecord>> buscarAulas(DateTime inicio, DateTime fim);
  Future<List<ChamadaRecord>> buscarChamadas(List<String> idsAulas);
}

class SupabaseChamadaExportacaoDataSource
    implements ChamadaExportacaoDataSource {
  @override
  Future<List<StudentRecord>> buscarAlunos() => SupabaseService.fetchAlunos();

  @override
  Future<List<AulaRecord>> buscarAulas(DateTime inicio, DateTime fim) =>
      SupabaseService.fetchAulasPeriodo(inicio: inicio, fim: fim);

  @override
  Future<List<ChamadaRecord>> buscarChamadas(List<String> idsAulas) =>
      SupabaseService.fetchChamadasPorAulas(idsAulas);
}

abstract class ChamadaArquivoSaver {
  Future<ArquivoChamadaSalvo> salvar(String nomeArquivo, Uint8List bytes);

  Future<bool> abrirConfiguracoesDoApp() async => false;
}

class ArquivoChamadaSalvo {
  const ArquivoChamadaSalvo({
    required this.nomeArquivo,
    required this.localSalvamento,
    this.uri,
    this.path,
  });

  factory ArquivoChamadaSalvo.fromPlatformResult(
    Map<Object?, Object?>? result,
  ) {
    final nomeArquivo = result?['fileName'] as String?;
    final localSalvamento = result?['location'] as String?;
    final uri = result?['uri'] as String?;
    final path = result?['path'] as String?;
    if (nomeArquivo == null ||
        nomeArquivo.trim().isEmpty ||
        localSalvamento == null ||
        localSalvamento.trim().isEmpty ||
        ((uri == null || uri.isEmpty) && (path == null || path.isEmpty))) {
      throw const ChamadaArquivoException(
        'O Android não confirmou o salvamento do arquivo.',
      );
    }
    return ArquivoChamadaSalvo(
      nomeArquivo: nomeArquivo,
      localSalvamento: localSalvamento,
      uri: uri,
      path: path,
    );
  }

  final String nomeArquivo;
  final String localSalvamento;
  final String? uri;
  final String? path;
}

class ChamadaArquivoException implements Exception {
  const ChamadaArquivoException(this.mensagem);

  final String mensagem;

  @override
  String toString() => mensagem;
}

class PermissaoArmazenamentoNegadaException extends ChamadaArquivoException {
  const PermissaoArmazenamentoNegadaException()
    : super(
        'No Android 9 ou anterior, a permissão de armazenamento é necessária para salvar em Downloads/CAMPS.',
      );
}

abstract class AndroidChamadaArquivoGateway {
  Future<Map<Object?, Object?>?> salvar({
    required String nomeArquivo,
    required Uint8List bytes,
    required String mimeType,
  });

  Future<bool> abrirConfiguracoesDoApp();
}

class MethodChannelAndroidChamadaArquivoGateway
    implements AndroidChamadaArquivoGateway {
  static const _channel = MethodChannel('camps/file_export');

  @override
  Future<Map<Object?, Object?>?> salvar({
    required String nomeArquivo,
    required Uint8List bytes,
    required String mimeType,
  }) => _channel.invokeMapMethod<Object?, Object?>('saveToDownloads', {
    'fileName': nomeArquivo,
    'bytes': bytes,
    'mimeType': mimeType,
  });

  @override
  Future<bool> abrirConfiguracoesDoApp() async =>
      await _channel.invokeMethod<bool>('openAppSettings') ?? false;
}

class FileSaverChamadaArquivo implements ChamadaArquivoSaver {
  FileSaverChamadaArquivo({
    AndroidChamadaArquivoGateway? androidGateway,
    bool? forcarAndroid,
  }) : _androidGateway =
           androidGateway ?? MethodChannelAndroidChamadaArquivoGateway(),
       _forcarAndroid = forcarAndroid;

  static const _xlsxMimeType =
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';

  final AndroidChamadaArquivoGateway _androidGateway;
  final bool? _forcarAndroid;

  bool get _usarSalvadorAndroid =>
      _forcarAndroid ??
      (!kIsWeb && defaultTargetPlatform == TargetPlatform.android);

  @override
  Future<ArquivoChamadaSalvo> salvar(
    String nomeArquivo,
    Uint8List bytes,
  ) async {
    if (_usarSalvadorAndroid) {
      try {
        final result = await _androidGateway.salvar(
          nomeArquivo: nomeArquivo,
          bytes: bytes,
          mimeType: _xlsxMimeType,
        );
        return ArquivoChamadaSalvo.fromPlatformResult(result);
      } on PlatformException catch (error) {
        if (error.code == 'STORAGE_PERMISSION_DENIED') {
          throw const PermissaoArmazenamentoNegadaException();
        }
        throw ChamadaArquivoException(
          error.message ?? 'Não foi possível salvar o arquivo no Android.',
        );
      }
    }

    final nomeSemExtensao = nomeArquivo.replaceFirst(RegExp(r'\.xlsx$'), '');
    final path = await FileSaver.instance.saveFile(
      name: nomeSemExtensao,
      bytes: bytes,
      fileExtension: 'xlsx',
      mimeType: MimeType.microsoftExcel,
    );
    if (path.trim().isEmpty ||
        path.contains('Something went wrong') ||
        path.startsWith('Error While Saving File')) {
      throw const ChamadaArquivoException(
        'O sistema não confirmou o salvamento do arquivo.',
      );
    }
    return ArquivoChamadaSalvo(
      nomeArquivo: nomeArquivo,
      localSalvamento: kIsWeb ? 'Downloads' : path,
      path: path,
    );
  }

  @override
  Future<bool> abrirConfiguracoesDoApp() => _usarSalvadorAndroid
      ? _androidGateway.abrirConfiguracoesDoApp()
      : Future.value(false);
}

class ChamadaExcelService {
  ChamadaExcelService({
    ChamadaExportacaoDataSource? dataSource,
    ChamadaArquivoSaver? arquivoSaver,
  }) : _dataSource = dataSource ?? SupabaseChamadaExportacaoDataSource(),
       _arquivoSaver = arquivoSaver ?? FileSaverChamadaArquivo();

  final ChamadaExportacaoDataSource _dataSource;
  final ChamadaArquivoSaver _arquivoSaver;

  Future<ResultadoExportacaoChamada> exportar(
    SelecaoExportacaoChamada selecao,
  ) async {
    if (!selecao.periodoValido) {
      throw ArgumentError(
        'O período final deve ser igual ou posterior ao inicial.',
      );
    }

    final aulas = await _dataSource.buscarAulas(selecao.inicio, selecao.fim);
    if (aulas.isEmpty) return const ResultadoExportacaoChamada.semAulas();

    final resultados = await Future.wait([
      _dataSource.buscarAlunos(),
      _dataSource.buscarChamadas(aulas.map((aula) => aula.id).toList()),
    ]);
    final alunos = resultados[0] as List<StudentRecord>;
    final chamadas = resultados[1] as List<ChamadaRecord>;
    final bytes = gerarPlanilhaChamada(
      alunos: alunos,
      aulas: aulas,
      chamadas: chamadas,
    );

    final arquivo = await _arquivoSaver.salvar(selecao.nomeArquivo, bytes);
    return ResultadoExportacaoChamada.sucesso(arquivo);
  }

  Future<bool> abrirConfiguracoesDoApp() =>
      _arquivoSaver.abrirConfiguracoesDoApp();
}

Uint8List gerarPlanilhaChamada({
  required List<StudentRecord> alunos,
  required List<AulaRecord> aulas,
  required List<ChamadaRecord> chamadas,
}) {
  final aulasOrdenadas = aulas.toList()
    ..sort((a, b) => a.data.compareTo(b.data));
  final alunosOrdenados = ordenarAlunosPorNome(alunos);
  final chamadasPorAulaEAluno = <String, AttendanceStatus>{
    for (final chamada in chamadas)
      '${chamada.aulaId}:${chamada.idAluno}': chamada.status,
  };

  final excel = Excel.createExcel();
  excel.rename('Sheet1', 'Chamada');
  final planilha = excel['Chamada'];
  final formatadorData = DateFormat('dd/MM/yyyy');

  planilha.appendRow([
    TextCellValue('Nome'),
    ...aulasOrdenadas.map(
      (aula) => TextCellValue(formatadorData.format(aula.data)),
    ),
  ]);

  for (final aluno in alunosOrdenados) {
    planilha.appendRow([
      TextCellValue(aluno.name),
      ...aulasOrdenadas.map((aula) {
        final status = chamadasPorAulaEAluno['${aula.id}:${aluno.idAluno}'];
        return TextCellValue(_valorExportado(status));
      }),
    ]);
  }

  final estiloCabecalho = CellStyle(
    bold: true,
    fontColorHex: ExcelColor.white,
    backgroundColorHex: ExcelColor.fromHexString('FF2E7D32'),
    horizontalAlign: HorizontalAlign.Center,
    verticalAlign: VerticalAlign.Center,
  );
  for (var coluna = 0; coluna <= aulasOrdenadas.length; coluna++) {
    planilha
            .cell(CellIndex.indexByColumnRow(columnIndex: coluna, rowIndex: 0))
            .cellStyle =
        estiloCabecalho;
    planilha.setColumnWidth(coluna, coluna == 0 ? 34 : 14);
  }

  final bytes = excel.encode();
  if (bytes == null) throw StateError('Não foi possível gerar a planilha.');
  return Uint8List.fromList(bytes);
}

String _valorExportado(AttendanceStatus? status) {
  switch (status) {
    case AttendanceStatus.P:
      return 'P';
    case AttendanceStatus.F:
      return 'F';
    case AttendanceStatus.A:
      return 'A';
    case AttendanceStatus.none:
    case null:
      return '';
  }
}
