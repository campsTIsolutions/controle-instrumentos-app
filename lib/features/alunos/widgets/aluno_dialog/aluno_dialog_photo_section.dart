import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

// Enum para distinguir a ação do usuário no bottom sheet de foto
enum AlunoImagemAcao { camera, galeria, remover }

// Retorna a ação escolhida ou null se o usuário fechou sem selecionar
Future<AlunoImagemAcao?> showAlunoImagemOrigemSheet({
  required BuildContext context,
  required bool exibirRemover,
}) {
  return showModalBottomSheet<AlunoImagemAcao>(
    context: context,
    backgroundColor: const Color(0xFF1E1E2E),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Selecionar foto',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.camera_alt_outlined,
                  color: Color(0xFF2563EB),
                ),
              ),
              title: const Text(
                'Câmera',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () => Navigator.pop(ctx, AlunoImagemAcao.camera),
              contentPadding: EdgeInsets.zero,
            ),
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.photo_library_outlined,
                  color: Color(0xFF2563EB),
                ),
              ),
              title: const Text(
                'Galeria',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () => Navigator.pop(ctx, AlunoImagemAcao.galeria),
              contentPadding: EdgeInsets.zero,
            ),
            if (exibirRemover)
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFB91C1C).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.delete_outline,
                    color: Color(0xFFEF4444),
                  ),
                ),
                title: const Text(
                  'Remover foto',
                  style: TextStyle(color: Color(0xFFEF4444)),
                ),
                onTap: () => Navigator.pop(ctx, AlunoImagemAcao.remover),
                contentPadding: EdgeInsets.zero,
              ),
          ],
        ),
      ),
    ),
  );
}

class AlunoDialogFotoSection extends StatelessWidget {
  const AlunoDialogFotoSection({
    super.key,
    required this.imagemSelecionada,
    required this.imagemUrlExistente,
    required this.onTap,
  });

  final XFile? imagemSelecionada;
  final String? imagemUrlExistente;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Center(
          child: GestureDetector(
            onTap: onTap,
            child: Stack(
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: const Color(0xFF2A2A3E),
                    border: Border.all(
                      color: const Color(0xFF374151),
                      width: 2,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: imagemSelecionada != null
                      ? Image.file(
                          File(imagemSelecionada!.path),
                          fit: BoxFit.cover,
                        )
                      : (imagemUrlExistente != null &&
                            imagemUrlExistente!.isNotEmpty)
                      ? Image.network(
                          imagemUrlExistente!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const _FotoPlaceholder(),
                        )
                      : const _FotoPlaceholder(),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: const Color(0xFF1E1E2E),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Toque para adicionar foto',
          style: TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _FotoPlaceholder extends StatelessWidget {
  const _FotoPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.person_outline, color: Color(0xFF4B5563), size: 32),
        SizedBox(height: 4),
        Text('Foto', style: TextStyle(fontSize: 10, color: Color(0xFF6B7280))),
      ],
    );
  }
}
