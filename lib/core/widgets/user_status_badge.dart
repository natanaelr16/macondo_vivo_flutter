import 'package:flutter/material.dart';
import '../../shared/models/user_model.dart';

class UserStatusBadge extends StatelessWidget {
  final bool provisionalPasswordSet;
  final UserStatus? status;
  final bool isActive;

  const UserStatusBadge({
    super.key,
    required this.provisionalPasswordSet,
    this.status,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    // Si el usuario tiene contraseña provisional, mostrar icono de no verificado
    if (provisionalPasswordSet) {
      return Icon(
        Icons.warning_amber_rounded,
        size: 16,
        color: Colors.orange[700],
      );
    }

    // Si el usuario no está activo, mostrar icono de inactivo
    if (!isActive) {
      return Icon(
        Icons.block,
        size: 16,
        color: Colors.red[700],
      );
    }

    // Si el usuario está verificado y activo, mostrar icono de verificado
    return Icon(
      Icons.verified,
      size: 16,
      color: Colors.green[700],
    );
  }
} 