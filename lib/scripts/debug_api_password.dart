import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../shared/services/api_service.dart';
import '../shared/utils/password_utils.dart';

void main() async {
  print('=== DEBUG: PROVISIONAL PASSWORD API ===');
  
  // Inicializar Firebase
  await Firebase.initializeApp();
  
  try {
    // Verificar autenticación
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      print('❌ No hay usuario autenticado');
      return;
    }
    
    print('✅ Usuario autenticado: ${currentUser.email}');
    print('✅ UID: ${currentUser.uid}');
    
    // Buscar un usuario con provisionalPasswordSet = true
    final usersQuery = await FirebaseFirestore.instance
        .collection('users')
        .where('provisionalPasswordSet', isEqualTo: true)
        .limit(1)
        .get();
    
    if (usersQuery.docs.isEmpty) {
      print('❌ No se encontraron usuarios con contraseñas provisionales');
      return;
    }
    
    final userDoc = usersQuery.docs.first;
    final userData = userDoc.data();
    final email = userData['email'] as String;
    
    print('\n--- TESTING CON USUARIO REAL ---');
    print('Usuario: ${userData['firstName']} ${userData['lastName']}');
    print('Email: $email');
    print('UID: ${userDoc.id}');
    
    // 1. Generar contraseña localmente
    final localPassword = generateProvisionalPassword(email);
    print('\n🔧 Contraseña LOCAL: $localPassword');
    
    // 2. Consultar API
    print('\n📡 Consultando API...');
    try {
      final apiPassword = await ApiService.getProvisionalPassword(userDoc.id);
      print('🌐 Contraseña API: $apiPassword');
      
      // 3. Comparar
      if (localPassword == apiPassword) {
        print('✅ LAS CONTRASEÑAS SON IGUALES');
      } else {
        print('❌ LAS CONTRASEÑAS SON DIFERENTES');
        print('   Local: $localPassword');
        print('   API:   $apiPassword');
      }
    } catch (e) {
      print('❌ Error consultando API: $e');
    }
    
    // 4. Verificar URL y token
    print('\n--- VERIFICACIÓN DE CONFIGURACIÓN ---');
    print('URL Base: ${ApiService.baseUrl}');
    
    try {
      final token = await currentUser.getIdToken();
      print('✅ Token obtenido: ${token?.substring(0, 50)}...');
    } catch (e) {
      print('❌ Error obteniendo token: $e');
    }
    
  } catch (e) {
    print('❌ Error general: $e');
  }
  
  print('\n=== FIN DEBUG ===');
}

// Función auxiliar para acceder a la URL base
extension ApiServiceDebug on ApiService {
  static String get baseUrl => ApiService.baseUrl;
} 