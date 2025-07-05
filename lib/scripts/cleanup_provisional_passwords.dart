import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart';

/// Script para limpiar contraseñas provisionales existentes en Firestore
/// Ejecutar este script UNA SOLA VEZ para limpiar datos sensibles existentes
Future<void> main() async {
  try {
    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    print('🔒 Iniciando limpieza de contraseñas provisionales...');
    
    final firestore = FirebaseFirestore.instance;
    
    // Get all users with provisional passwords
    final snapshot = await firestore
        .collection('users')
        .where('provisionalPassword', isNotEqualTo: null)
        .get();
    
    if (snapshot.docs.isEmpty) {
      print('✅ No se encontraron contraseñas provisionales para limpiar');
      return;
    }
    
    print('📋 Encontrados ${snapshot.docs.length} usuarios con contraseñas provisionales');
    
    int cleanedCount = 0;
    for (var doc in snapshot.docs) {
      try {
        await doc.reference.update({
          'provisionalPassword': FieldValue.delete(),
        });
        cleanedCount++;
        print('✅ Limpiada contraseña para usuario: ${doc.data()['email'] ?? doc.id}');
      } catch (e) {
        print('❌ Error limpiando contraseña para ${doc.id}: $e');
      }
    }
    
    print('🎉 Limpieza completada: $cleanedCount contraseñas provisionales eliminadas');
    print('🔒 Las contraseñas provisionales ya no se guardarán en Firestore');
    
  } catch (e) {
    print('❌ Error durante la limpieza: $e');
  } finally {
    // Exit the script
    exit(0);
  }
} 