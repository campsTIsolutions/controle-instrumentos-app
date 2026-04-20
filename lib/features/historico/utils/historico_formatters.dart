String formatarDataHistorico(String? isoString) {
  if (isoString == null) return '-';
  try {
    final dt = DateTime.parse(isoString).toLocal();
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final y = dt.year;
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$d/$m/$y às $h:$min';
  } catch (_) {
    return isoString;
  }
}
