import 'package:flutter/material.dart';

class PaginationFooter extends StatelessWidget {
  const PaginationFooter({
    super.key,
    required this.totalLabel,
    required this.currentPage,
    required this.totalPages,
    required this.onFirstPage,
    required this.onPreviousPage,
    required this.onNextPage,
    required this.onLastPage,
  });

  final String totalLabel;
  final int currentPage;
  final int totalPages;
  final VoidCallback onFirstPage;
  final VoidCallback onPreviousPage;
  final VoidCallback onNextPage;
  final VoidCallback onLastPage;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Flexible(
            child: Text(
              totalLabel,
              style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Spacer(),
          _PaginationIconButton(
            icon: Icons.first_page,
            onTap: currentPage > 1 ? onFirstPage : null,
          ),
          _PaginationIconButton(
            icon: Icons.chevron_left,
            onTap: currentPage > 1 ? onPreviousPage : null,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              '$currentPage / $totalPages',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
          _PaginationIconButton(
            icon: Icons.chevron_right,
            onTap: currentPage < totalPages ? onNextPage : null,
          ),
          _PaginationIconButton(
            icon: Icons.last_page,
            onTap: currentPage < totalPages ? onLastPage : null,
          ),
        ],
      ),
    );
  }
}

class _PaginationIconButton extends StatelessWidget {
  const _PaginationIconButton({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Icon(
        icon,
        size: 20,
        color: onTap != null
            ? const Color(0xFF374151)
            : const Color(0xFFD1D5DB),
      ),
    );
  }
}
