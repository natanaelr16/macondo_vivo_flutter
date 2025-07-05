
import '../models/user_model.dart';

/// Utilidades para validación de datos de usuarios
class ValidationUtils {
  /// Validar formato de email
  static String? validateEmail(String email) {
    if (email.isEmpty) {
      return 'El email es requerido';
    }
    
    // Validar formato básico
    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!emailRegex.hasMatch(email)) {
      return 'Formato de email inválido';
    }
    
    return null;
  }

  /// Validar número de documento según tipo
  static String? validateDocumentNumber(String documentNumber, DocumentType documentType) {
    if (documentNumber.isEmpty) {
      return 'El número de documento es requerido';
    }
    
    // Limpiar solo números
    final cleanNumber = documentNumber.replaceAll(RegExp(r'[^\d]'), '');
    
    // Validar longitud según tipo
    switch (documentType) {
      case DocumentType.CC:
        if (cleanNumber.length != 10) {
          return 'La cédula debe tener 10 dígitos';
        }
        break;
      case DocumentType.TI:
        if (cleanNumber.length != 11) {
          return 'La tarjeta de identidad debe tener 11 dígitos';
        }
        break;
      case DocumentType.CE:
        if (cleanNumber.length < 7 || cleanNumber.length > 12) {
          return 'La cédula de extranjería debe tener entre 7 y 12 dígitos';
        }
        break;
      case DocumentType.PASSPORT:
        if (cleanNumber.length < 6 || cleanNumber.length > 9) {
          return 'El pasaporte debe tener entre 6 y 9 dígitos';
        }
        break;
    }
    
    return null;
  }

  /// Validar nombres y apellidos
  static String? validateName(String name, String fieldName) {
    if (name.isEmpty) {
      return '$fieldName es requerido';
    }
    
    if (name.trim().length < 2) {
      return '$fieldName debe tener al menos 2 caracteres';
    }
    
    if (name.trim().length > 50) {
      return '$fieldName no puede exceder 50 caracteres';
    }
    
    // Validar que solo contenga letras y espacios
    final nameRegex = RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]+$');
    if (!nameRegex.hasMatch(name.trim())) {
      return '$fieldName solo puede contener letras y espacios';
    }
    
    return null;
  }

  /// Validar teléfono
  static String? validatePhone(String phone) {
    if (phone.isEmpty) return null; // Opcional
    
    // Limpiar solo números
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');
    
    if (cleanPhone.length < 7 || cleanPhone.length > 15) {
      return 'El teléfono debe tener entre 7 y 15 dígitos';
    }
    
    return null;
  }

  /// Validar datos específicos por tipo de usuario
  static String? validateTypeSpecificData(UserType userType, TypeSpecificData? data) {
    if (data == null) {
      return 'Los datos específicos son requeridos para este tipo de usuario';
    }
    
    switch (userType) {
      case UserType.DOCENTE:
        return _validateTeacherData(data);
      case UserType.ESTUDIANTE:
        return _validateStudentData(data);
      case UserType.ACUDIENTE:
        return _validateParentData(data);
      case UserType.ADMIN_STAFF:
        return _validateAdminStaffData(data);
    }
  }

  /// Validar datos de docente
  static String? _validateTeacherData(TypeSpecificData data) {
    if (data.areaOfStudy == null || data.areaOfStudy!.isEmpty) {
      return 'El área de estudio es requerida para docentes';
    }
    
    if (data.assignedToGradeLevel == null) {
      return 'El nivel asignado es requerido para docentes';
    }
    
    if (data.educationLevel == null) {
      return 'El nivel de educación es requerido para docentes';
    }
    
    if (data.schoolPosition == null) {
      return 'El cargo es requerido para docentes';
    }
    
    return null;
  }

  /// Validar datos de estudiante
  static String? _validateStudentData(TypeSpecificData data) {
    if (data.schoolGrade == null) {
      return 'El grado escolar es requerido para estudiantes';
    }
    
    return null;
  }

  /// Validar datos de acudiente
  static String? _validateParentData(TypeSpecificData data) {
    if (data.representedChildrenCount == null || data.representedChildrenCount! < 1) {
      return 'El número de hijos representados es requerido y debe ser mayor a 0';
    }
    
    return null;
  }

  /// Validar datos de personal administrativo
  static String? _validateAdminStaffData(TypeSpecificData data) {
    if (data.profession == null || data.profession!.isEmpty) {
      return 'La profesión es requerida para personal administrativo';
    }
    
    return null;
  }

  /// Validar que el documento sea único
  static Future<String?> validateUniqueDocument(String documentNumber) async {
    try {
      // Esta validación se hará en el servicio
      return null;
    } catch (e) {
      return 'Error al validar documento: $e';
    }
  }

  /// Validar que el email sea único
  static Future<String?> validateUniqueEmail(String email, UserType userType) async {
    try {
      // Esta validación se hará en el servicio
      return null;
    } catch (e) {
      return 'Error al validar email: $e';
    }
  }

  /// Validar límite de SuperUsers
  static Future<String?> validateSuperUserLimit() async {
    try {
      // Esta validación se hará en el servicio
      return null;
    } catch (e) {
      return 'Error al validar límite de SuperUsers: $e';
    }
  }

  /// Validar formulario completo de usuario
  static Map<String, String> validateUserForm({
    required String firstName,
    required String lastName,
    required String email,
    required DocumentType documentType,
    required String documentNumber,
    String? phone,
    required UserType userType,
    required AppRole appRole,
    TypeSpecificData? typeSpecificData,
  }) {
    final errors = <String, String>{};
    
    // Validar nombres
    final firstNameError = validateName(firstName, 'Nombre');
    if (firstNameError != null) errors['firstName'] = firstNameError;
    
    final lastNameError = validateName(lastName, 'Apellido');
    if (lastNameError != null) errors['lastName'] = lastNameError;
    
    // Validar email
    final emailError = validateEmail(email);
    if (emailError != null) errors['email'] = emailError;
    
    // Validar documento
    final documentError = validateDocumentNumber(documentNumber, documentType);
    if (documentError != null) errors['documentNumber'] = documentError;
    
    // Validar teléfono
    if (phone != null && phone.isNotEmpty) {
      final phoneError = validatePhone(phone);
      if (phoneError != null) errors['phone'] = phoneError;
    }
    
    // Validar datos específicos
    final typeDataError = validateTypeSpecificData(userType, typeSpecificData);
    if (typeDataError != null) errors['typeSpecificData'] = typeDataError;
    
    // Validar que solo ADMIN_STAFF puede ser SuperUser
    if (appRole == AppRole.SuperUser && userType != UserType.ADMIN_STAFF) {
      errors['appRole'] = 'Solo los usuarios tipo Administrador pueden ser SuperUser';
    }
    
    return errors;
  }
} 