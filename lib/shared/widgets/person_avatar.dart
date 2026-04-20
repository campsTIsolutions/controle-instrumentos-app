import 'package:flutter/material.dart';

class PersonAvatar extends StatelessWidget {
  const PersonAvatar({
    super.key,
    required this.imageUrl,
    required this.size,
    required this.radius,
    required this.backgroundColor,
    required this.iconColor,
    required this.iconSize,
    this.margin = EdgeInsets.zero,
  });

  final String? imageUrl;
  final double size;
  final double radius;
  final Color backgroundColor;
  final Color iconColor;
  final double iconSize;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;
    return Container(
      width: size,
      height: size,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        color: backgroundColor,
      ),
      clipBehavior: Clip.antiAlias,
      child: hasImage
          ? Image.network(
              imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  Icon(Icons.person, color: iconColor, size: iconSize),
            )
          : Icon(Icons.person, color: iconColor, size: iconSize),
    );
  }
}
