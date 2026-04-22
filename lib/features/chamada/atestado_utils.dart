String extrairNomeArquivoAtestado(String? referencia) {
  if (referencia == null || referencia.trim().isEmpty) {
    return 'Nenhum comprovante anexado';
  }

  final trimmed = referencia.trim();

  String lastSegment;
  try {
    final uri = Uri.parse(trimmed);
    if (uri.pathSegments.isNotEmpty) {
      lastSegment = uri.pathSegments.last;
    } else {
      lastSegment = trimmed.split(RegExp(r'[\\/]')).last;
    }
  } catch (_) {
    lastSegment = trimmed.split(RegExp(r'[\\/]')).last;
  }

  final decoded = Uri.decodeComponent(lastSegment);
  return decoded.replaceFirst(RegExp(r'^\d+_'), '');
}
