import '../models/user_model.dart';

/// Clase para manejar permisos del sistema de usuarios
class PermissionManager {
  /// Verificar acceso a gestión de usuarios
  static bool canAccessUsers(UserModel? user) {
    if (user == null) return false;
    if (user.appRole == AppRole.SuperUser) return true;
    if (user.appRole == AppRole.ADMIN) {
      return ![UserType.ESTUDIANTE, UserType.ACUDIENTE].contains(user.userType);
    }
    return false;
  }

  /// Verificar si puede crear usuarios
  static bool canCreateUsers(UserModel? user) {
    if (user == null) return false;
    // Solo SuperUser puede crear usuarios
    return user.appRole == AppRole.SuperUser;
  }

  /// Verificar si puede editar un usuario específico
  static bool canEditUser(UserModel? currentUser, UserModel? targetUser) {
    if (currentUser == null || targetUser == null) return false;
    // Solo SuperUser puede editar usuarios
    return currentUser.appRole == AppRole.SuperUser;
  }

  /// Verificar si puede eliminar un usuario
  static bool canDeleteUser(UserModel? currentUser, UserModel? targetUser) {
    if (currentUser == null || targetUser == null) return false;
    return currentUser.appRole == AppRole.SuperUser;
  }

  /// Verificar si puede cambiar el estado de un usuario
  static bool canChangeUserStatus(UserModel? currentUser, UserModel? targetUser) {
    if (currentUser == null || targetUser == null) return false;
    // Solo SuperUser puede cambiar el estado de usuarios
    return currentUser.appRole == AppRole.SuperUser;
  }

  /// Verificar si puede resetear contraseña
  static bool canResetPassword(UserModel? currentUser, UserModel? targetUser) {
    if (currentUser == null || targetUser == null) return false;
    // Solo SuperUser puede resetear contraseñas de otros usuarios
    return currentUser.appRole == AppRole.SuperUser;
  }

  /// Obtener mensaje de restricción
  static String getAccessRestrictionMessage(UserModel? user, String feature) {
    if (user == null) return 'Debe iniciar sesión para acceder a esta función';
    if (user.appRole == AppRole.USER) return 'No tiene permisos para acceder a esta función';
    return 'Acceso restringido';
  }

  /// Verificar si puede ver datos completos de un usuario
  static bool canViewFullUserData(UserModel? currentUser, UserModel? targetUser) {
    if (currentUser == null || targetUser == null) return false;
    if (currentUser.appRole == AppRole.SuperUser) return true;
    if (currentUser.appRole == AppRole.ADMIN) return true;
    // Usuarios solo pueden ver sus propios datos completos
    return currentUser.uid == targetUser.uid;
  }

  /// Verificar si puede asignar roles
  static bool canAssignRole(UserModel? currentUser, AppRole targetRole) {
    if (currentUser == null) return false;
    if (currentUser.appRole == AppRole.SuperUser) return true;
    if (currentUser.appRole == AppRole.ADMIN) {
      // Admin no puede asignar SuperUser
      return targetRole != AppRole.SuperUser;
    }
    return false;
  }

  /// Verificar si puede crear SuperUsers
  static bool canCreateSuperUser(UserModel? currentUser) {
    if (currentUser == null) return false;
    return currentUser.appRole == AppRole.SuperUser;
  }

  /// Obtener roles que puede asignar el usuario actual
  static List<AppRole> getAssignableRoles(UserModel? currentUser) {
    if (currentUser == null) return [];
    
    switch (currentUser.appRole) {
      case AppRole.SuperUser:
        return [AppRole.SuperUser, AppRole.ADMIN, AppRole.USER];
      case AppRole.ADMIN:
        return []; // Admin no puede asignar roles
      case AppRole.USER:
        return [];
    }
  }

  /// Obtener tipos de usuario que puede crear
  static List<UserType> getCreatableUserTypes(UserModel? currentUser) {
    if (currentUser == null) return [];
    
    switch (currentUser.appRole) {
      case AppRole.SuperUser:
        return [UserType.ADMIN_STAFF, UserType.DOCENTE, UserType.ESTUDIANTE, UserType.ACUDIENTE];
      case AppRole.ADMIN:
        return []; // Admin no puede crear usuarios
      case AppRole.USER:
        return [];
    }
  }
} 