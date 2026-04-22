import 'package:controle_instrumentos/core/services/user_profile_service.dart';
import 'package:controle_instrumentos/features/login/login_page.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileMenuButton extends StatefulWidget {
  const ProfileMenuButton({super.key});

  @override
  State<ProfileMenuButton> createState() => _ProfileMenuButtonState();
}

class _ProfileMenuButtonState extends State<ProfileMenuButton> {
  final _supabase = Supabase.instance.client;
  final _userProfileService = UserProfileService();
  bool _isOpening = false;

  Future<void> _openMenu(BuildContext context) async {
    if (_isOpening) return;
    setState(() => _isOpening = true);
    try {
      final RenderBox button = context.findRenderObject() as RenderBox;
      final RenderBox overlay =
          Overlay.of(context).context.findRenderObject() as RenderBox;

      final position = RelativeRect.fromRect(
        Rect.fromPoints(
          button.localToGlobal(
            Offset(-15, button.size.height - 8),
            ancestor: overlay,
          ),
          button.localToGlobal(
            button.size.bottomRight(Offset.zero) + const Offset(-15, -8),
            ancestor: overlay,
          ),
        ),
        Offset.zero & overlay.size,
      );

      final nomeUsuario = await _userProfileService.resolveDisplayName();
      if (!context.mounted) return;

      final result = await showMenu<String>(
        context: context,
        position: position,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        items: [
          PopupMenuItem<String>(
            enabled: false,
            child: Row(
              children: [
                const Icon(Icons.person_outline),
                const SizedBox(width: 10),
                Text(
                  nomeUsuario,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const PopupMenuDivider(),
          const PopupMenuItem<String>(
            value: 'logout',
            child: Row(
              children: [
                Icon(Icons.logout, color: Colors.red),
                SizedBox(width: 10),
                Text('Sair', style: TextStyle(color: Colors.red)),
              ],
            ),
          ),
        ],
      );

      if (result != 'logout') return;

      await _supabase.auth.signOut();
      if (!context.mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    } finally {
      if (mounted) setState(() => _isOpening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: SizedBox(
        width: 24,
        height: 24,
        child: Image.asset('assets/profile.png'),
      ),
      onPressed: _isOpening ? null : () => _openMenu(context),
    );
  }
}
