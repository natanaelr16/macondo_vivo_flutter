import 'dart:math';

/// Genera una contraseña provisional determinística basada en el email (exactamente igual que app web)
String generateProvisionalPassword([String? email]) {
  if (email == null || email.isEmpty) {
    // Fallback a generación aleatoria si no hay email
    return _generateRandomPassword();
  }
  
  // NO normalizar email (exactamente igual que en la web)
  // La web app NO normaliza el email, usar tal como viene
  
  // Crear hash simple del email (exactamente igual que en la web - algoritmo djb2)
  int hash = 0;
  for (int i = 0; i < email.length; i++) {
    final char = email.codeUnitAt(i);
    hash = ((hash << 5) - hash) + char;
    hash = hash & hash; // Convertir a entero de 32 bits
  }
  
  // Usar el hash para generar una contraseña de 12 caracteres (exactamente igual que en la web)
  const String charset = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#\$%^&*';
  String password = '';
  final int seed = hash.abs();
  
  for (int i = 0; i < 12; i++) {
    final int index = (seed + i * 7) % charset.length;
    password += charset[index];
  }
  
  return password;
}

/// Genera una contraseña aleatoria (fallback)
String _generateRandomPassword() {
  const String lowercase = 'abcdefghijklmnopqrstuvwxyz';
  const String uppercase = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  const String numbers = '0123456789';
  const String specialChars = '!@#\$%^&*';
  
  final Random random = Random();
  
  // Asegurar que tenga al menos un carácter de cada tipo requerido
  String password = '';
  password += lowercase[random.nextInt(lowercase.length)];
  password += uppercase[random.nextInt(uppercase.length)];
  password += numbers[random.nextInt(numbers.length)];
  password += specialChars[random.nextInt(specialChars.length)];
  
  // Completar hasta 12 caracteres con caracteres aleatorios de todos los sets
  const String allChars = lowercase + uppercase + numbers + specialChars;
  for (int i = password.length; i < 12; i++) {
    password += allChars[random.nextInt(allChars.length)];
  }
  
  // Mezclar los caracteres para que no sea predecible el orden
  List<String> passwordChars = password.split('');
  passwordChars.shuffle(random);
  return passwordChars.join();
}

/// Genera una contraseña provisional simple de 8 caracteres (alternativa)
String generateSimpleProvisionalPassword() {
  const String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  final Random random = Random();
  
  return List.generate(8, (index) => chars[random.nextInt(chars.length)]).join();
}

/// Valida que una contraseña cumpla con los requisitos mínimos
bool isValidPassword(String password) {
  // Mínimo 6 caracteres
  if (password.length < 6) return false;
  
  // Al menos una letra
  if (!password.contains(RegExp(r'[A-Za-z]'))) return false;
  
  // Al menos un número
  if (!password.contains(RegExp(r'[0-9]'))) return false;
  
  return true;
}

/// Valida que una contraseña cumpla con los requisitos de seguridad completos
bool isValidSecurePassword(String password) {
  // Mínimo 8 caracteres, máximo 50
  if (password.length < 8 || password.length > 50) return false;
  
  // Al menos una mayúscula
  if (!password.contains(RegExp(r'[A-Z]'))) return false;
  
  // Al menos una minúscula
  if (!password.contains(RegExp(r'[a-z]'))) return false;
  
  // Al menos un número
  if (!password.contains(RegExp(r'[0-9]'))) return false;
  
  return true;
}

/// Función de debug para verificar consistencia de contraseñas
void debugPasswordGeneration(String email) {
  print('=== DEBUG PASSWORD GENERATION ===');
  print('Email: $email');
  
  // NO normalizar email (igual que web app)
  print('Email (sin normalizar): $email');
  
  // Crear hash simple (algoritmo djb2)
  int hash = 0;
  for (int i = 0; i < email.length; i++) {
    final char = email.codeUnitAt(i);
    hash = ((hash << 5) - hash) + char;
    hash = hash & hash; // Convertir a entero de 32 bits
  }
  print('djb2 hash: $hash');
  print('Seed: ${hash.abs()}');
  
  // Generar contraseña
  final password = generateProvisionalPassword(email);
  print('Generated password: $password');
  print('Password length: ${password.length}');
  
  // Verificar requisitos
  print('Has uppercase: ${password.contains(RegExp(r'[A-Z]'))}');
  print('Has lowercase: ${password.contains(RegExp(r'[a-z]'))}');
  print('Has number: ${password.contains(RegExp(r'[0-9]'))}');
  print('Has special: ${password.contains(RegExp(r'[!@#\$%^&*]'))}');
  print('=== END DEBUG ===');
}

/// Genera una contraseña provisional determinística basada en el email
/// Esta función replica exactamente la lógica de la app web
String generateDeterministicPassword(String email) {
  // Crear un hash simple del email para generar una contraseña consistente (SIN normalizar)
  int hash = 0;
  for (int i = 0; i < email.length; i++) {
    int char = email.codeUnitAt(i);
    hash = ((hash << 5) - hash) + char;
    hash = hash & hash; // Convertir a entero de 32 bits
  }
  
  // Usar el hash para generar una contraseña de 12 caracteres
  const String charset = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#\$%^&*';
  String password = '';
  int seed = hash.abs();
  
  for (int i = 0; i < 12; i++) {
    int index = (seed + i * 7) % charset.length;
    password += charset[index];
  }
  
  return password;
} 