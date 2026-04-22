import 'package:flutter/material.dart';

class FiltroChipGroup extends StatelessWidget {
  const FiltroChipGroup({
    super.key,
    required this.label,
    required this.children,
  });

  final String? label;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label ?? '',
          style: const TextStyle(
            fontSize: 12,
            color: Colors.black,
            fontWeight: FontWeight.w500,
          ),
        ),
        Wrap(spacing: 8, children: children),
      ],
    );
  }
}

class CheckboxChipWidget extends StatelessWidget {
  const CheckboxChipWidget({
    super.key,
    required this.texto,
    required this.selecionado,
    required this.onChanged,
  });

  final String texto;
  final bool selecionado;
  final void Function(bool) onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!selecionado),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selecionado
                ? const Color(0xFF2563EB)
                : const Color(0xFFE5E7EB),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Checkbox(
              value: selecionado,
              onChanged: (v) => onChanged(v ?? false),
              activeColor: const Color(0xFF2563EB),
              checkColor: Colors.white,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            Text(
              texto,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
