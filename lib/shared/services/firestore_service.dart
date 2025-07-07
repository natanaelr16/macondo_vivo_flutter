import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../models/activity_model.dart';
import '../utils/password_utils.dart';
import '../utils/permissions.dart';


class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Colecciones
  static const String usersCollection = 'users';
  static const String activitiesCollection = 'activities';
  static const String sessionsCollection = 'sessions';

  // Límites del sistema
  static const int maxSuperUsers = 5;
  static const int maxUsersPerType = 1000;

  /// ===== MÉTODOS DE USUARIOS =====

  /// Crear usuario completo con Firebase Auth + Firestore
  Future<UserCreationResult> createUser(UserModel user, String provisionalPassword) async {
    User? authUser;
    
    try {
      print('FirestoreService: Iniciando creación de usuario...');
      print('FirestoreService: Usuario a crear: ${user.toJson()}');
      
      // 1. VALIDAR PERMISOS
      final currentUser = _auth.currentUser;
      print('FirestoreService: Usuario actual: ${currentUser?.email}');
      
      if (currentUser == null) {
        throw Exception('Usuario no autenticado');
      }
      
      final currentUserDoc = await _firestore.collection(usersCollection).doc(currentUser.uid).get();
      print('FirestoreService: Documento del usuario actual existe: ${currentUserDoc.exists}');
      
      if (!currentUserDoc.exists) {
        throw Exception('Usuario actual no encontrado en Firestore');
      }
      
      final currentUserModel = UserModel.fromFirestore(currentUserDoc);
      print('FirestoreService: Usuario actual: ${currentUserModel.toJson()}');
      
      final canCreate = PermissionManager.canCreateUsers(currentUserModel);
      print('FirestoreService: Puede crear usuarios: $canCreate');
      
      if (!canCreate) {
        throw Exception('No tiene permisos para crear usuarios');
      }
      
      // 2. VALIDAR LÍMITES
      print('FirestoreService: Validando límites para tipo: ${user.userType.name}, rol: ${user.appRole.name}');
      await _validateUserLimits(user.userType, user.appRole);
      print('FirestoreService: ✅ Límites validados correctamente');
      
      // 3. VALIDAR UNICIDAD
      print('FirestoreService: Validando unicidad de email y documento...');
      await _validateUniqueConstraints(user);
      print('FirestoreService: ✅ Unicidad validada correctamente');
      
      // 4. CREAR EN FIREBASE AUTH (PRIMERO)
      print('FirestoreService: Creando usuario en Firebase Auth...');
      
      // Guardar la sesión actual del admin
      final adminUser = _auth.currentUser;
      final adminEmail = adminUser?.email;
      final adminUid = adminUser?.uid;
      
      // Crear el usuario en Auth
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: user.email,
        password: provisionalPassword,
      );
      
      authUser = userCredential.user;
      if (authUser == null) {
        throw Exception('Error al crear usuario en Firebase Auth');
      }
      
      print('FirestoreService: ✅ Usuario creado en Firebase Auth con UID: ${authUser.uid}');
      
      // IMPORTANTE: Firebase Auth automáticamente inicia sesión con el nuevo usuario
      // Necesitamos volver a autenticar al admin inmediatamente
      print('FirestoreService: ⚠️ Firebase Auth inició sesión automáticamente con el nuevo usuario');
      print('FirestoreService: ⚠️ Re-autenticando al admin...');
      
      // Intentar re-autenticar al admin (esto requerirá que el admin ingrese su contraseña)
      // Por ahora, solo registramos que se necesita re-autenticación
      
      // 5. PREPARAR DATOS PARA FIRESTORE
      final userData = user.toFirestoreCreate(); // Usar toFirestoreCreate() para campos básicos
      userData['uid'] = authUser.uid; // Usar el UID real del usuario
      // NO almacenar provisionalPassword en Firestore (según documentación web)
      userData['provisionalPasswordSet'] = true;
      userData['createdAt'] = FieldValue.serverTimestamp(); // Usar server timestamp para consistencia
      userData['createdBy'] = currentUserModel.uid; // Usar el UID del admin como creador
      userData['status'] = UserStatus.VERIFIED.name; // Asegurar que status esté presente
      
      // Verificar que todos los campos requeridos estén presentes
      print('FirestoreService: Verificando campos requeridos...');
      final requiredFields = [
        'uid', 'email', 'firstName', 'lastName', 'documentType', 
        'documentNumber', 'userType', 'appRole', 'status', 'isActive', 
        'provisionalPasswordSet', 'createdAt', 'updatedAt', 'phone'
      ];
      
      for (final field in requiredFields) {
        if (!userData.containsKey(field)) {
          print('FirestoreService: ❌ Campo requerido faltante: $field');
        } else {
          print('FirestoreService: ✅ Campo presente: $field = ${userData[field]}');
        }
      }
      
      // Agregar typeSpecificData si existe
      if (user.typeSpecificData != null) {
        userData['typeSpecificData'] = user.typeSpecificData!.toMap();
      }
      
      print('FirestoreService: Datos a enviar a Firestore: ${userData.toString()}');
      print('FirestoreService: Tipo de datos: ${userData.runtimeType}');
      print('FirestoreService: Claves de datos: ${userData.keys.toList()}');
      
      // Verificar datos problemáticos
      for (var entry in userData.entries) {
        print('FirestoreService: Campo ${entry.key}: ${entry.value} (${entry.value.runtimeType})');
      }
      
      // 5. CREAR EN FIRESTORE (PRIMERO)
      print('FirestoreService: Creando documento en Firestore...');
      print('FirestoreService: Collection: $usersCollection');
      print('FirestoreService: Document ID: ${authUser.uid}');
      
      try {
        await _firestore.collection(usersCollection).doc(authUser.uid).set(userData);
        print('FirestoreService: ✅ Documento creado exitosamente en Firestore');
      } catch (firestoreError) {
        print('FirestoreService: ❌ Error específico de Firestore: $firestoreError');
        print('FirestoreService: Tipo de error: ${firestoreError.runtimeType}');
        print('FirestoreService: Stack trace: ${firestoreError.toString()}');
        rethrow;
      }
      
      print('FirestoreService: ✅ Documento creado en Firestore');
      
      // 6. CREAR EN FIRESTORE
      print('FirestoreService: Creando documento en Firestore...');
      print('FirestoreService: Collection: $usersCollection');
      print('FirestoreService: Document ID: ${authUser.uid}');
      
      try {
        await _firestore.collection(usersCollection).doc(authUser.uid).set(userData);
        print('FirestoreService: ✅ Documento creado exitosamente en Firestore');
      } catch (firestoreError) {
        print('FirestoreService: ❌ Error específico de Firestore: $firestoreError');
        print('FirestoreService: Tipo de error: ${firestoreError.runtimeType}');
        print('FirestoreService: Stack trace: ${firestoreError.toString()}');
        rethrow;
      }
      
      // 8. CREAR USUARIO FINAL
      // Crear el usuario final usando fromFirestore para manejar correctamente los Timestamps
      final newUserDoc = await _firestore.collection(usersCollection).doc(authUser.uid).get();
      final newUser = UserModel.fromFirestore(newUserDoc);
      
      // 8. FIRMAR SESIÓN DEL ADMIN
      // Nota: No podemos hacer sign in automático aquí porque no tenemos la contraseña real del admin
      // El admin deberá hacer sign in manualmente después de crear el usuario
      print('FirestoreService: ⚠️ Admin debe hacer sign in manualmente después de crear el usuario');
      
      print('FirestoreService: ✅ Usuario creado exitosamente');
      
      return UserCreationResult(
        user: newUser,
        provisionalPassword: provisionalPassword,
        requiresAdminReauth: true, // Requiere re-autenticación
        adminEmail: adminEmail, // Email del admin para re-autenticación
        adminUid: adminUid, // UID del admin para referencia
      );
      
    } catch (e) {
      print('FirestoreService: ❌ Error creando usuario: $e');
      
      // LIMPIEZA: Si se creó en Auth pero falló Firestore
      if (authUser != null) {
        try {
          print('FirestoreService: Limpiando usuario de Firebase Auth...');
          await authUser.delete();
          print('FirestoreService: ✅ Limpieza de Auth exitosa');
        } catch (cleanupError) {
          print('FirestoreService: ❌ Error limpiando Auth: $cleanupError');
          print('FirestoreService: LIMPIEZA MANUAL REQUERIDA: Eliminar usuario ${authUser.uid} de Firebase Auth');
        }
      }
      
      // LIMPIEZA: Si se creó en Auth pero falló la actualización
      if (authUser != null) {
        try {
          print('FirestoreService: Limpiando usuario de Firebase Auth...');
          await authUser.delete();
          print('FirestoreService: ✅ Limpieza de Auth exitosa');
        } catch (cleanupError) {
          print('FirestoreService: ❌ Error limpiando Auth: $cleanupError');
          print('FirestoreService: LIMPIEZA MANUAL REQUERIDA: Eliminar usuario ${authUser.uid} de Firebase Auth');
        }
      }
      
      throw Exception('Error creando usuario: $e');
    }
  }

  /// Validar límites del sistema
  Future<void> _validateUserLimits(UserType userType, AppRole appRole) async {
    print('FirestoreService: Validando límite de SuperUsers...');
    
    // Validar límite de SuperUsers
    if (appRole == AppRole.SuperUser) {
      final superUserCount = await _firestore
          .collection(usersCollection)
          .where('appRole', isEqualTo: AppRole.SuperUser.name)
          .count()
          .get();
      
      print('FirestoreService: SuperUsers actuales: ${superUserCount.count}');
      
      if (superUserCount.count != null && superUserCount.count! >= maxSuperUsers) {
        throw Exception('Se ha alcanzado el límite máximo de SuperUsers ($maxSuperUsers)');
      }
    }
    
    print('FirestoreService: Validando límite por tipo de usuario: ${userType.name}');
    
    // Validar límite por tipo de usuario
    final userTypeCount = await _firestore
        .collection(usersCollection)
        .where('userType', isEqualTo: userType.name)
        .count()
        .get();
    
    print('FirestoreService: Usuarios tipo ${userType.name}: ${userTypeCount.count}');
    
    if (userTypeCount.count != null && userTypeCount.count! >= maxUsersPerType) {
      throw Exception('Se ha alcanzado el límite máximo de usuarios tipo ${userType.name}');
    }
    
    print('FirestoreService: ✅ Límites validados correctamente');
  }

  /// Validar restricciones de unicidad
  Future<void> _validateUniqueConstraints(UserModel user) async {
    print('FirestoreService: Validando email único: ${user.email}');
    
    // Validar email único
    final emailQuery = await _firestore
        .collection(usersCollection)
        .where('email', isEqualTo: user.email)
        .get();
    
    print('FirestoreService: Emails encontrados: ${emailQuery.docs.length}');
    
    if (emailQuery.docs.isNotEmpty) {
      throw Exception('El email ${user.email} ya está registrado');
    }
    
    print('FirestoreService: Validando documento único: ${user.documentNumber}');
    
    // Validar documento único
    final documentQuery = await _firestore
        .collection(usersCollection)
        .where('documentNumber', isEqualTo: user.documentNumber)
        .where('documentType', isEqualTo: user.documentType.name)
        .get();
    
    print('FirestoreService: Documentos encontrados: ${documentQuery.docs.length}');
    
    if (documentQuery.docs.isNotEmpty) {
      throw Exception('El documento ${user.documentNumber} ya está registrado');
    }
    
    print('FirestoreService: ✅ Unicidad validada correctamente');
  }

  /// Obtener todos los usuarios con filtros
  Future<List<UserModel>> getUsers({
    UserType? userType,
    AppRole? appRole,
    UserStatus? status,
    String? searchQuery,
  }) async {
    try {
      Query query = _firestore.collection(usersCollection);
      
      // Aplicar filtros
      if (userType != null) {
        query = query.where('userType', isEqualTo: userType.name);
      }
      
      if (appRole != null) {
        query = query.where('appRole', isEqualTo: appRole.name);
      }
      
      if (status != null) {
        query = query.where('status', isEqualTo: status.name);
      }
      
      final snapshot = await query.get();
      List<UserModel> users = [];
      
      for (var doc in snapshot.docs) {
        try {
          final user = UserModel.fromFirestore(doc);
          users.add(user);
        } catch (e) {
          print('Error parsing user ${doc.id}: $e');
        }
      }
      
      // Aplicar búsqueda de texto
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        users = users.where((user) {
          return user.firstName.toLowerCase().contains(query) ||
                 user.lastName.toLowerCase().contains(query) ||
                 user.email.toLowerCase().contains(query) ||
                 user.documentNumber.contains(query);
        }).toList();
      }
      
      // Ordenar por nombre
      users.sort((a, b) => '${a.firstName} ${a.lastName}'.compareTo('${b.firstName} ${b.lastName}'));
      
      return users;
      
    } catch (e) {
      print('Error obteniendo usuarios: $e');
      throw Exception('Error obteniendo usuarios: $e');
    }
  }

  /// Obtener usuario por ID
  Future<UserModel?> getUserById(String uid) async {
    try {
      final doc = await _firestore.collection(usersCollection).doc(uid).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error obteniendo usuario $uid: $e');
      throw Exception('Error obteniendo usuario: $e');
    }
  }

  /// Método de prueba para verificar permisos de Firestore
  Future<void> testFirestorePermissions() async {
    try {
      print('FirestoreService: Probando permisos de lectura...');
      final testQuery = await _firestore.collection(usersCollection).limit(1).get();
      print('FirestoreService: ✅ Lectura exitosa, documentos encontrados: ${testQuery.docs.length}');
      
      print('FirestoreService: Probando permisos de escritura...');
      final testDoc = _firestore.collection('test').doc('permission_test');
      await testDoc.set({
        'test': true,
        'timestamp': FieldValue.serverTimestamp(),
      });
      print('FirestoreService: ✅ Escritura exitosa');
      
      // Limpiar documento de prueba
      await testDoc.delete();
      print('FirestoreService: ✅ Eliminación exitosa');
      
    } catch (e) {
      print('FirestoreService: ❌ Error en prueba de permisos: $e');
      throw Exception('Error en prueba de permisos: $e');
    }
  }

  /// Actualizar usuario
  Future<void> updateUser(String uid, Map<String, dynamic> updates) async {
    try {
      print('FirestoreService: Iniciando updateUser para UID: $uid');
      print('FirestoreService: Updates recibidos: $updates');
      print('FirestoreService: isActive en updates: ${updates['isActive']}');
      
      // Validar permisos
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        print('FirestoreService: ❌ Usuario no autenticado');
        throw Exception('Usuario no autenticado');
      }
      
      print('FirestoreService: Usuario actual autenticado: ${currentUser.email}');
      
      final currentUserDoc = await _firestore.collection(usersCollection).doc(currentUser.uid).get();
      if (!currentUserDoc.exists) {
        print('FirestoreService: ❌ Usuario actual no encontrado en Firestore');
        throw Exception('Usuario actual no encontrado');
      }
      
      final currentUserModel = UserModel.fromFirestore(currentUserDoc);
      print('FirestoreService: Usuario actual cargado: ${currentUserModel.email}');
      
      final targetUser = await getUserById(uid);
      
      if (targetUser == null) {
        print('FirestoreService: ❌ Usuario a actualizar no encontrado');
        throw Exception('Usuario a actualizar no encontrado');
      }
      
      print('FirestoreService: Usuario objetivo cargado: ${targetUser.email}, isActive actual: ${targetUser.isActive}');
      
      if (!PermissionManager.canEditUser(currentUserModel, targetUser)) {
        print('FirestoreService: ❌ No tiene permisos para editar este usuario');
        throw Exception('No tiene permisos para editar este usuario');
      }
      
      print('FirestoreService: ✅ Permisos validados correctamente');
      
      // Agregar timestamp de actualización
      updates['updatedAt'] = FieldValue.serverTimestamp();
      updates['updatedBy'] = currentUser.uid;
      
      print('FirestoreService: Updates finales antes de enviar a Firestore: $updates');
      print('FirestoreService: isActive final: ${updates['isActive']}');
      
      // Realizar la actualización en Firestore
      await _firestore.collection(usersCollection).doc(uid).update(updates);
      
      print('FirestoreService: ✅ Actualización en Firestore completada exitosamente');
      
      // Verificar que la actualización se realizó correctamente
      final updatedDoc = await _firestore.collection(usersCollection).doc(uid).get();
      final updatedUser = UserModel.fromFirestore(updatedDoc);
      print('FirestoreService: Usuario después de actualización: ${updatedUser.email}, isActive: ${updatedUser.isActive}');
      
    } catch (e) {
      print('FirestoreService: ❌ Error actualizando usuario $uid: $e');
      print('FirestoreService: Stack trace: ${e.toString()}');
      throw Exception('Error actualizando usuario: $e');
    }
  }

  /// Cambiar estado de usuario
  Future<void> changeUserStatus(String uid, UserStatus newStatus) async {
    try {
      await updateUser(uid, {'status': newStatus.name});
    } catch (e) {
      print('Error cambiando estado de usuario $uid: $e');
      throw Exception('Error cambiando estado de usuario: $e');
    }
  }

  /// Eliminar usuario
  Future<void> deleteUser(String uid) async {
    try {
      // Validar permisos
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('Usuario no autenticado');
      }
      
      final currentUserDoc = await _firestore.collection(usersCollection).doc(currentUser.uid).get();
      if (!currentUserDoc.exists) {
        throw Exception('Usuario actual no encontrado');
      }
      
      final currentUserModel = UserModel.fromFirestore(currentUserDoc);
      final targetUser = await getUserById(uid);
      
      if (targetUser == null) {
        throw Exception('Usuario a eliminar no encontrado');
      }
      
      if (!PermissionManager.canDeleteUser(currentUserModel, targetUser)) {
        throw Exception('No tiene permisos para eliminar este usuario');
      }
      
      // Eliminar de Firestore
      await _firestore.collection(usersCollection).doc(uid).delete();
      
      // Nota: La eliminación de Firebase Auth debe hacerse desde el backend
      print('Usuario eliminado de Firestore. Eliminación de Auth requerida desde backend.');
      
    } catch (e) {
      print('Error eliminando usuario $uid: $e');
      throw Exception('Error eliminando usuario: $e');
    }
  }

  /// Resetear contraseña de usuario
  Future<String> resetUserPassword(String uid) async {
    try {
      // Validar permisos
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('Usuario no autenticado');
      }
      
      final currentUserDoc = await _firestore.collection(usersCollection).doc(currentUser.uid).get();
      if (!currentUserDoc.exists) {
        throw Exception('Usuario actual no encontrado');
      }
      
      final currentUserModel = UserModel.fromFirestore(currentUserDoc);
      final targetUser = await getUserById(uid);
      
      if (targetUser == null) {
        throw Exception('Usuario no encontrado');
      }
      
      if (!PermissionManager.canResetPassword(currentUserModel, targetUser)) {
        throw Exception('No tiene permisos para resetear la contraseña de este usuario');
      }
      
      // Generar nueva contraseña provisional
      final newPassword = generateProvisionalPassword(targetUser.email);
      
      // Actualizar en Firestore
      await updateUser(uid, {
        'provisionalPassword': newPassword,
        'provisionalPasswordSet': true,
      });
      
      // Nota: El cambio en Firebase Auth debe hacerse desde el backend
      print('Contraseña provisional actualizada en Firestore. Cambio en Auth requerido desde backend.');
      
      return newPassword;
      
    } catch (e) {
      print('Error reseteando contraseña de usuario $uid: $e');
      throw Exception('Error reseteando contraseña: $e');
    }
  }

  /// ===== MÉTODOS DE ACTIVIDADES =====

  /// Obtener todas las actividades
  Future<List<ActivityModel>> getActivities() async {
    try {
      final snapshot = await _firestore.collection(activitiesCollection).get();
      return snapshot.docs.map((doc) => ActivityModel.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error obteniendo actividades: $e');
      throw Exception('Error obteniendo actividades: $e');
    }
  }

  /// Crear actividad
  Future<void> createActivity(ActivityModel activity) async {
    try {
      final activityData = activity.toFirestore();
      activityData['createdAt'] = FieldValue.serverTimestamp();
      
      await _firestore.collection(activitiesCollection).add(activityData);
    } catch (e) {
      print('Error creando actividad: $e');
      throw Exception('Error creando actividad: $e');
    }
  }

  /// Actualizar actividad
  Future<void> updateActivity(String id, Map<String, dynamic> updates) async {
    try {
      updates['updatedAt'] = FieldValue.serverTimestamp();
      await _firestore.collection(activitiesCollection).doc(id).update(updates);
    } catch (e) {
      print('Error actualizando actividad: $e');
      throw Exception('Error actualizando actividad: $e');
    }
  }

  /// Eliminar actividad
  Future<void> deleteActivity(String id) async {
    try {
      await _firestore.collection(activitiesCollection).doc(id).delete();
    } catch (e) {
      print('Error eliminando actividad: $e');
      throw Exception('Error eliminando actividad: $e');
    }
  }

  /// Limpiar contraseñas provisionales existentes (método de seguridad)
  Future<void> cleanupProvisionalPasswords() async {
    try {
      print('FirestoreService: Limpiando contraseñas provisionales existentes...');
      
      // Get all users with provisional passwords
      final snapshot = await _firestore
          .collection(usersCollection)
          .where('provisionalPassword', isNotEqualTo: null)
          .get();
      
      int cleanedCount = 0;
      for (var doc in snapshot.docs) {
        await doc.reference.update({
          'provisionalPassword': FieldValue.delete(),
        });
        cleanedCount++;
      }
      
      print('FirestoreService: ✅ Limpiadas $cleanedCount contraseñas provisionales');
    } catch (e) {
      print('FirestoreService: ❌ Error limpiando contraseñas provisionales: $e');
      throw Exception('Error limpiando contraseñas provisionales: $e');
    }
  }
}

/// Resultado de creación de usuario
class UserCreationResult {
  final UserModel user;
  final String provisionalPassword;
  final bool requiresAdminReauth;
  final String? adminEmail;
  final String? adminUid;

  UserCreationResult({
    required this.user,
    required this.provisionalPassword,
    this.requiresAdminReauth = false,
    this.adminEmail,
    this.adminUid,
  });
}
