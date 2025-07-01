import 'package:flutter/material.dart';

class TextLogo extends StatelessWidget {
  final double fontSize;
  final Color? color;
  final bool showSubtitle;

  const TextLogo({
    super.key,
    this.fontSize = 32,
    this.color,
    this.showSubtitle = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final logoColor = color ?? theme.colorScheme.primary;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Main Logo Text
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [
              logoColor,
              logoColor.withOpacity(0.8),
              logoColor.withOpacity(0.6),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds),
          child: Text(
            'MacondoVIVO',
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              color: Colors.white,
            ),
          ),
        ),
        
        // Subtitle
        if (showSubtitle) ...[
          const SizedBox(height: 4),
          Text(
            'Sistema de Gestión Escolar',
            style: TextStyle(
              fontSize: fontSize * 0.3,
              fontWeight: FontWeight.w400,
              color: theme.colorScheme.onSurface.withOpacity(0.7),
              letterSpacing: 0.5,
            ),
          ),
        ],
      ],
    );
  }
} 