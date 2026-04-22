import 'package:flutter/material.dart';

class InstrumentoActionbuttom extends StatelessWidget {
  const InstrumentoActionbuttom({
    super.key,
    required this.icone,
    required this.cor,
    required this.onTap,
  });
  final IconData icone;
  final Color cor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: cor,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icone, color: Colors.white, size: 16),
      ),
    );
  }
}
