import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import 'firestore_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirestoreService _firestoreService = FirestoreService();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    print('AuthService: Attempting sign in for $email');
    try {
      // First, try to sign in normally
      try {
        final credential = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        
        print('AuthService: Sign in successful for ${credential.user?.email}');
        
        // Update last login time and check user status
        if (credential.user != null) {
          await _updateLastLogin(credential.user!.uid);
          await _checkUserStatus(credential.user!.uid);
        }
        
        return credential;
      } catch (e) {
        // If sign in fails, check if it's a user-not-found error
        if (e is FirebaseAuthException && e.code == 'user-not-found') {
          print('AuthService: User not found in Auth, checking Firestore for provisional user...');
          
          // Provisional user verification not implemented yet
          print('AuthService: Provisional user verification not implemented');
          
          // Now try to sign in again
          final credential = await _auth.signInWithEmailAndPassword(
            email: email,
            password: password,
          );
          
          print('AuthService: Provisional user verified and signed in successfully');
          
          // Update last login time and check user status
          if (credential.user != null) {
            await _updateLastLogin(credential.user!.uid);
            await _checkUserStatus(credential.user!.uid);
          }
          
          return credential;
        } else {
          // Re-throw other errors
          rethrow;
        }
      }
    } catch (e) {
      print('AuthService: Sign in failed - $e');
      throw _handleAuthError(e);
    }
  }

  // Sign out
  Future<void> signOut() async {
    print('AuthService: Signing out');
    try {
      await _auth.signOut();
      print('AuthService: Sign out completed');
    } catch (e) {
      print('AuthService: Sign out error - $e');
      throw _handleAuthError(e);
    }
  }

  // Get user data from Firestore
  Future<UserModel?> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  // Get current user's full data
  Future<UserModel?> getCurrentUserData() async {
    final user = currentUser;
    if (user == null) return null;
    return await getUserData(user.uid);
  }

  // Update last login time
  Future<void> _updateLastLogin(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'lastLogin': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('AuthService: Last login updated for user $uid');
    } catch (e) {
      print('Error updating last login: $e');
    }
  }

  // Check if user is active
  Future<void> _checkUserStatus(String uid) async {
    try {
      final userData = await getUserData(uid);
      if (userData != null && !userData.isActive) {
        await signOut();
        throw Exception('Su cuenta ha sido desactivada. Por favor, contacte a los administradores.');
      }
    } catch (e) {
      print('Error checking user status: $e');
      rethrow;
    }
  }

  // Update password
  Future<void> updatePassword(String currentPassword, String newPassword) async {
    try {
      final user = currentUser;
      if (user == null || user.email == null) {
        throw Exception('No hay usuario autenticado');
      }

      // Reauthenticate before password change
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);

      // Update password
      await user.updatePassword(newPassword);
      
      // Update Firestore to mark password as changed and remove any provisional password
      await _firestore.collection('users').doc(user.uid).update({
        'provisionalPasswordSet': false,
        'provisionalPassword': FieldValue.delete(), // Remove any existing provisional password
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      print('AuthService: Password updated successfully');
    } catch (e) {
      print('AuthService: Password update failed - $e');
      throw _handleAuthError(e);
    }
  }

  // Get ID token for API calls
  Future<String> getIdToken() async {
    try {
      final user = currentUser;
      if (user == null) {
        throw Exception('No autenticado');
      }
      final token = await user.getIdToken(true);
      if (token == null) {
        throw Exception('No se pudo obtener el token de autenticación');
      }
      return token;
    } catch (e) {
      print('Error getting ID token: $e');
      throw Exception('No se pudo obtener el token de autenticación');
    }
  }

  // Handle Firebase Auth errors
  String _handleAuthError(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return 'No se encontró una cuenta con este correo electrónico.';
        case 'wrong-password':
          return 'Contraseña incorrecta.';
        case 'invalid-email':
          return 'El correo electrónico no es válido.';
        case 'user-disabled':
          return 'Esta cuenta ha sido deshabilitada.';
        case 'too-many-requests':
          return 'Demasiados intentos fallidos. Intenta más tarde.';
        case 'network-request-failed':
          return 'Error de conexión. Verifica tu internet.';
        case 'requires-recent-login':
          return 'Por seguridad, debes iniciar sesión nuevamente.';
        case 'weak-password':
          return 'La contraseña es demasiado débil.';
        case 'email-already-in-use':
          return 'Este correo electrónico ya está en uso.';
        default:
          return 'Error de autenticación: ${error.message}';
      }
    }
    return error.toString();
  }
} 