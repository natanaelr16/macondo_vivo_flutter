import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'lib/shared/services/api_service.dart';

void main() async {
  // Inicializar Firebase
  await Firebase.initializeApp();
  
  // Autenticar con un usuario de prueba
  try {
    await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: 'estefaniacmjb@gmail.com', // Usuario SuperUser
      password: 'tu_contraseña_aqui', // Reemplaza con la contraseña real
    );
    
    print('✅ Usuario autenticado: ${FirebaseAuth.instance.currentUser?.email}');
    
    // Test de eliminación de usuario
    final testUserId = 'test_user_id'; // Reemplaza con un UID real de prueba
    
    print('🧪 Probando eliminación de usuario: $testUserId');
    
    try {
      await ApiService.deleteUser(testUserId);
      print('✅ Usuario eliminado exitosamente');
    } catch (e) {
      print('❌ Error eliminando usuario: $e');
    }
    
  } catch (e) {
    print('❌ Error de autenticación: $e');
  }
} 