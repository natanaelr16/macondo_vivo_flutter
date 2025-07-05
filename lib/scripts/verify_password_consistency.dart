import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../shared/utils/password_utils.dart';

void main() async {
  print('=== VERIFICACIÓN DE CONSISTENCIA DE CONTRASEÑAS ===');
  print('Verificando con usuarios reales existentes...\n');
  
  // Inicializar Firebase
  await Firebase.initializeApp();
  
  try {
    // Obtener usuarios que tienen provisionalPasswordSet = true (no verificados)
    final QuerySnapshot usersSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('provisionalPasswordSet', isEqualTo: true)
        .limit(3) // Solo primeros 3 usuarios para verificar
        .get();
    
    if (usersSnapshot.docs.isEmpty) {
      print('No se encontraron usuarios con contraseñas provisionales.');
      return;
    }
    
    print('Usuarios encontrados: ${usersSnapshot.docs.length}');
    
    for (var doc in usersSnapshot.docs) {
      final userData = doc.data() as Map<String, dynamic>;
      final email = userData['email'] as String?;
      
      if (email != null) {
        print('\n--- Usuario: ${userData['name'] ?? 'Sin nombre'} ---');
        print('Email: $email');
        
        // Generar contraseña con el algoritmo corregido
        final generatedPassword = generateProvisionalPassword(email);
        print('Contraseña generada (Flutter): $generatedPassword');
        
        // Simular el algoritmo de la web app para comparar
        final webPassword = _simulateWebAppAlgorithm(email);
        print('Contraseña simulada (Web): $webPassword');
        
        print('¿Son iguales?: ${generatedPassword == webPassword}');
        
        if (generatedPassword != webPassword) {
          print('⚠️  INCONSISTENCIA DETECTADA');
        } else {
          print('✅ CONSISTENCIA VERIFICADA');
        }
      }
    }
    
  } catch (e) {
    print('Error al verificar: $e');
  }
  
  print('\n=== FIN DE VERIFICACIÓN ===');
}

// Simular exactamente el algoritmo de la web app
String _simulateWebAppAlgorithm(String email) {
  // Algoritmo exacto de la web app (SIN normalización)
  int hash = 0;
  for (int i = 0; i < email.length; i++) {
    final char = email.codeUnitAt(i);
    hash = ((hash << 5) - hash) + char;
    hash = hash & hash;
  }
  
  const String charset = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#\$%^&*';
  String password = '';
  final int seed = hash.abs();
  
  for (int i = 0; i < 12; i++) {
    final int index = (seed + i * 7) % charset.length;
    password += charset[index];
  }
  
  return password;
} 