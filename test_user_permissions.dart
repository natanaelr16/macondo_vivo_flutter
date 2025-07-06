import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'lib/shared/models/user_model.dart';
import 'lib/shared/utils/permissions.dart';

void main() async {
  // Inicializar Flutter
  TestWidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar Firebase
  await Firebase.initializeApp();
  
  try {
    // Obtener usuario actual
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      print('❌ No hay usuario autenticado');
      return;
    }
    
    print('✅ Usuario autenticado: ${currentUser.email} (${currentUser.uid})');
    
    // Obtener datos del usuario desde Firestore
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .get();
    
    if (!userDoc.exists) {
      print('❌ Usuario no encontrado en Firestore');
      return;
    }
    
    final userModel = UserModel.fromFirestore(userDoc);
    print('📋 Datos del usuario:');
    print('   - Email: ${userModel.email}');
    print('   - AppRole: ${userModel.appRole}');
    print('   - UserType: ${userModel.userType}');
    print('   - IsSuperUser: ${userModel.isSuperUser}');
    print('   - IsAdmin: ${userModel.isAdmin}');
    
    // Verificar permisos
    print('\n🔐 Verificando permisos:');
    print('   - Can create users: ${PermissionManager.canCreateUsers(userModel)}');
    print('   - Can delete users: ${PermissionManager.canDeleteUser(userModel, null)}');
    print('   - Can reset passwords: ${PermissionManager.canResetPassword(userModel, null)}');
    
    // Test de token
    print('\n🎫 Verificando token de autenticación:');
    try {
      final token = await currentUser.getIdToken();
      print('   - Token obtenido: ${token != null ? '✅' : '❌'}');
      if (token != null) {
        print('   - Token length: ${token.length}');
        print('   - Token preview: ${token.substring(0, 20)}...');
      }
    } catch (e) {
      print('   - Error obteniendo token: $e');
    }
    
  } catch (e) {
    print('❌ Error: $e');
  }
} 