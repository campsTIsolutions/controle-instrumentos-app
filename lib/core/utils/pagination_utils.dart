List<T> pagedSlice<T>({
  required List<T> items,
  required int currentPage,
  required int itemsPerPage,
}) {
  final start = (currentPage - 1) * itemsPerPage;
  final end = start + itemsPerPage;
  return items.sublist(
    start.clamp(0, items.length),
    end.clamp(0, items.length),
  );
}

int pageCount({
  required int totalItems,
  required int itemsPerPage,
}) {
  return (totalItems / itemsPerPage).ceil().clamp(1, 9999);
}
