import 'package:controle_instrumentos/features/chamada/exportacao/chamada_exportacao.dart';
import 'package:controle_instrumentos/features/chamada/models.dart';
import 'package:excel/excel.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SelecaoExportacaoChamada', () {
    test('gera nomes de arquivo para mês, ano e período', () {
      expect(
        SelecaoExportacaoChamada.mes(mes: 8, ano: 2026).nomeArquivo,
        'chamada_agosto_2026.xlsx',
      );
      expect(
        SelecaoExportacaoChamada.anoCompleto(2026).nomeArquivo,
        'chamada_ano-completo_2026.xlsx',
      );
      expect(
        SelecaoExportacaoChamada.periodo(
          mesInicial: 1,
          anoInicial: 2026,
          mesFinal: 3,
          anoFinal: 2026,
        ).nomeArquivo,
        'chamada_jan-mar_2026.xlsx',
      );
    });

    test('identifica período final anterior ao inicial', () {
      final selecao = SelecaoExportacaoChamada.periodo(
        mesInicial: 4,
        anoInicial: 2026,
        mesFinal: 3,
        anoFinal: 2026,
      );

      expect(selecao.periodoValido, isFalse);
    });
  });

  test('planilha ordena datas e alunos e preserva P, F e A', () {
    final bytes = gerarPlanilhaChamada(
      alunos: [
        StudentRecord(idAluno: 1, name: 'Yuri', attendance: {}),
        StudentRecord(idAluno: 2, name: 'Álvaro', attendance: {}),
      ],
      aulas: [
        AulaRecord(id: 'aula-2', data: DateTime(2026, 8, 12)),
        AulaRecord(id: 'aula-1', data: DateTime(2026, 8, 5)),
      ],
      chamadas: const [
        ChamadaRecord(
          id: '1',
          aulaId: 'aula-1',
          idAluno: 2,
          status: AttendanceStatus.A,
        ),
        ChamadaRecord(
          id: '2',
          aulaId: 'aula-2',
          idAluno: 2,
          status: AttendanceStatus.P,
        ),
        ChamadaRecord(
          id: '3',
          aulaId: 'aula-1',
          idAluno: 1,
          status: AttendanceStatus.F,
        ),
      ],
    );

    final planilha = Excel.decodeBytes(bytes).tables['Chamada']!;
    expect(_valores(planilha.rows[0]), ['Nome', '05/08/2026', '12/08/2026']);
    expect(_valores(planilha.rows[1]), ['Álvaro', 'A', 'P']);
    expect(_valores(planilha.rows[2]), ['Yuri', 'F', '']);
  });

  test('não salva arquivo quando o período não possui aulas', () async {
    final dataSource = _FakeDataSource(aulas: const []);
    final saver = _FakeSaver();
    final service = ChamadaExcelService(
      dataSource: dataSource,
      arquivoSaver: saver,
    );

    final resultado = await service.exportar(
      SelecaoExportacaoChamada.mes(mes: 8, ano: 2026),
    );

    expect(resultado.exportado, isFalse);
    expect(saver.salvou, isFalse);
    expect(dataSource.buscouAlunos, isFalse);
  });

  test('propaga nome final e pasta confirmados pelo salvador', () async {
    final dataSource = _FakeDataSource(
      aulas: [AulaRecord(id: 'aula-1', data: DateTime(2026, 3, 1))],
    );
    final saver = _FakeSaver(
      arquivo: const ArquivoChamadaSalvo(
        nomeArquivo: 'chamada_marco_2026 (1).xlsx',
        localSalvamento: 'Downloads/CAMPS',
        uri: 'content://downloads/1',
      ),
    );
    final service = ChamadaExcelService(
      dataSource: dataSource,
      arquivoSaver: saver,
    );

    final resultado = await service.exportar(
      SelecaoExportacaoChamada.mes(mes: 3, ano: 2026),
    );

    expect(resultado.exportado, isTrue);
    expect(resultado.nomeArquivo, 'chamada_marco_2026 (1).xlsx');
    expect(resultado.localSalvamento, 'Downloads/CAMPS');
  });

  group('FileSaverChamadaArquivo no Android', () {
    test('aceita apenas retorno confirmado com URI ou caminho', () async {
      final gateway = _FakeAndroidGateway(
        result: {
          'fileName': 'chamada_marco_2026.xlsx',
          'location': 'Downloads/CAMPS',
          'uri': 'content://downloads/2',
          'path': null,
        },
      );
      final saver = FileSaverChamadaArquivo(
        androidGateway: gateway,
        forcarAndroid: true,
      );

      final arquivo = await saver.salvar(
        'chamada_marco_2026.xlsx',
        Uint8List.fromList([1, 2, 3]),
      );

      expect(arquivo.nomeArquivo, 'chamada_marco_2026.xlsx');
      expect(arquivo.localSalvamento, 'Downloads/CAMPS');
      expect(gateway.nomeArquivo, 'chamada_marco_2026.xlsx');
      expect(
        gateway.mimeType,
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      );
    });

    test('rejeita retorno vazio em vez de informar sucesso', () async {
      final saver = FileSaverChamadaArquivo(
        androidGateway: _FakeAndroidGateway(result: null),
        forcarAndroid: true,
      );

      expect(
        () => saver.salvar('chamada.xlsx', Uint8List.fromList([1])),
        throwsA(isA<ChamadaArquivoException>()),
      );
    });

    test('converte permissão negada em erro específico', () async {
      final saver = FileSaverChamadaArquivo(
        androidGateway: _FakeAndroidGateway(
          error: PlatformException(
            code: 'STORAGE_PERMISSION_DENIED',
            message: 'negada',
          ),
        ),
        forcarAndroid: true,
      );

      expect(
        () => saver.salvar('chamada.xlsx', Uint8List.fromList([1])),
        throwsA(isA<PermissaoArmazenamentoNegadaException>()),
      );
    });

    test('propaga falha de escrita sem informar sucesso', () async {
      final saver = FileSaverChamadaArquivo(
        androidGateway: _FakeAndroidGateway(
          error: PlatformException(
            code: 'SAVE_FAILED',
            message: 'Armazenamento indisponível.',
          ),
        ),
        forcarAndroid: true,
      );

      expect(
        () => saver.salvar('chamada.xlsx', Uint8List.fromList([1])),
        throwsA(
          isA<ChamadaArquivoException>().having(
            (error) => error.mensagem,
            'mensagem',
            'Armazenamento indisponível.',
          ),
        ),
      );
    });
  });
}

List<String> _valores(List<Data?> cells) =>
    cells.map((cell) => cell?.value?.toString() ?? '').toList(growable: false);

class _FakeDataSource implements ChamadaExportacaoDataSource {
  _FakeDataSource({required this.aulas});

  final List<AulaRecord> aulas;
  bool buscouAlunos = false;

  @override
  Future<List<StudentRecord>> buscarAlunos() async {
    buscouAlunos = true;
    return [];
  }

  @override
  Future<List<AulaRecord>> buscarAulas(DateTime inicio, DateTime fim) async =>
      aulas;

  @override
  Future<List<ChamadaRecord>> buscarChamadas(List<String> idsAulas) async => [];
}

class _FakeSaver implements ChamadaArquivoSaver {
  _FakeSaver({
    this.arquivo = const ArquivoChamadaSalvo(
      nomeArquivo: 'chamada.xlsx',
      localSalvamento: 'Downloads/CAMPS',
      uri: 'content://downloads/test',
    ),
  });

  final ArquivoChamadaSalvo arquivo;
  bool salvou = false;

  @override
  Future<ArquivoChamadaSalvo> salvar(
    String nomeArquivo,
    Uint8List bytes,
  ) async {
    salvou = true;
    return arquivo;
  }

  @override
  Future<bool> abrirConfiguracoesDoApp() async => false;
}

class _FakeAndroidGateway implements AndroidChamadaArquivoGateway {
  _FakeAndroidGateway({this.result, this.error});

  final Map<Object?, Object?>? result;
  final PlatformException? error;
  String? nomeArquivo;
  String? mimeType;

  @override
  Future<Map<Object?, Object?>?> salvar({
    required String nomeArquivo,
    required Uint8List bytes,
    required String mimeType,
  }) async {
    this.nomeArquivo = nomeArquivo;
    this.mimeType = mimeType;
    if (error != null) throw error!;
    return result;
  }

  @override
  Future<bool> abrirConfiguracoesDoApp() async => true;
}
