import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart' show UserModel;

class ApiService {
  static const String baseUrl = 'https://macondo-vivo-macondovivo.vercel.app/api';
  
  static Future<String> _getAuthToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('Usuario no autenticado');
    }
    final token = await user.getIdToken();
    if (token == null) {
      throw Exception('No se pudo obtener el token');
    }
    return token;
  }

  static Future<Map<String, String>> _getHeaders() async {
    final token = await _getAuthToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Crear usuario usando la API del proyecto web
  static Future<Map<String, dynamic>> createUser(Map<String, dynamic> userData) async {
    try {
      final headers = await _getHeaders();
      
      final response = await http.post(
        Uri.parse('$baseUrl/users/create'),
        headers: headers,
        body: jsonEncode(userData),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Error al crear usuario');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Obtener usuarios usando la API del proyecto web
  static Future<List<UserModel>> getUsers() async {
    try {
      final headers = await _getHeaders();
      
      final response = await http.get(
        Uri.parse('$baseUrl/users'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => UserModel.fromJson(json)).toList();
      } else {
        throw Exception('Error al obtener usuarios');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Actualizar usuario usando la API del proyecto web
  static Future<void> updateUser(String userId, Map<String, dynamic> userData) async {
    try {
      final headers = await _getHeaders();
      
      final response = await http.put(
        Uri.parse('$baseUrl/users/update/$userId'),
        headers: headers,
        body: jsonEncode(userData),
      );

      if (response.statusCode != 200) {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Error al actualizar usuario');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Eliminar usuario usando la API del proyecto web
  static Future<void> deleteUser(String userId) async {
    try {
      print('ApiService: 🗑️ Iniciando eliminación de usuario: $userId');
      final headers = await _getHeaders();
      
      final url = '$baseUrl/users/delete/$userId';
      print('ApiService: 📡 URL de eliminación: $url');
      print('ApiService: 📋 Headers: $headers');
      
      final response = await http.delete(
        Uri.parse(url),
        headers: headers,
      );

      print('ApiService: 📊 Código de respuesta: ${response.statusCode}');
      print('ApiService: 📄 Cuerpo de respuesta: "${response.body}"');

      if (response.statusCode == 200) {
        print('ApiService: ✅ Usuario eliminado exitosamente de Firebase Auth y Firestore');
      } else {
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData['message'] ?? 'Error al eliminar usuario';
        print('ApiService: ❌ Error del servidor: $errorMessage');
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('ApiService: ❌ Error de conexión: $e');
      throw Exception('Error de conexión: $e');
    }
  }

  // Resetear contraseña usando la API del proyecto web
  static Future<String> resetPassword(String userId) async {
    try {
      final headers = await _getHeaders();
      
      final response = await http.post(
        Uri.parse('$baseUrl/users/reset-password/$userId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['provisionalPassword'];
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Error al resetear contraseña');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Toggle user status using the web API
  static Future<Map<String, dynamic>> toggleUserStatus(String userId, bool newStatus) async {
    try {
      final headers = await _getHeaders();
      
      print('ApiService: Toggling user status for $userId to $newStatus');
      print('ApiService: Request URL: $baseUrl/users/$userId');
      print('ApiService: Request body: ${jsonEncode({'isActive': newStatus})}');
      print('ApiService: Headers: $headers');
      
      final response = await http.patch(
        Uri.parse('$baseUrl/users/$userId'),
        headers: headers,
        body: jsonEncode({'isActive': newStatus}),
      );

      print('ApiService: Response status code: ${response.statusCode}');
      print('ApiService: Response headers: ${response.headers}');
      print('ApiService: Response body length: ${response.body.length}');
      print('ApiService: Response body: "${response.body}"');

      if (response.statusCode == 200) {
        // Verificar que la respuesta no esté vacía
        if (response.body.isEmpty) {
          print('ApiService: ❌ Empty response body');
          throw Exception('Respuesta vacía del servidor');
        }
        
        try {
          final responseData = jsonDecode(response.body);
          print('ApiService: ✅ Parsed response: $responseData');
          print('ApiService: ✅ Success field: ${responseData['success']}');
          print('ApiService: ✅ Message field: ${responseData['message']}');
          return responseData;
        } catch (jsonError) {
          print('ApiService: ❌ JSON decode error: $jsonError');
          print('ApiService: ❌ Raw response body: "${response.body}"');
          throw Exception('Error al procesar respuesta del servidor: $jsonError');
        }
      } else {
        // Manejar respuesta de error
        if (response.body.isEmpty) {
          print('ApiService: ❌ Empty error response body');
          throw Exception('Error del servidor: ${response.statusCode}');
        }
        
        try {
          final errorData = jsonDecode(response.body);
          print('ApiService: ❌ Error response: $errorData');
          print('ApiService: ❌ Error message: ${errorData['message']}');
          throw Exception(errorData['message'] ?? 'Error al cambiar estado del usuario');
        } catch (jsonError) {
          print('ApiService: ❌ Error JSON decode error: $jsonError');
          print('ApiService: ❌ Raw error response body: "${response.body}"');
          throw Exception('Error del servidor: ${response.statusCode}');
        }
      }
    } catch (e) {
      print('ApiService: ❌ Exception: $e');
      print('ApiService: ❌ Exception type: ${e.runtimeType}');
      if (e.toString().contains('FormatException')) {
        throw Exception('Error de formato en la respuesta del servidor');
      }
      throw Exception('Error de conexión: $e');
    }
  }

  // Reset user password using the web API
  static Future<Map<String, dynamic>> resetUserPassword(String userId) async {
    try {
      final headers = await _getHeaders();
      
      final response = await http.post(
        Uri.parse('$baseUrl/users/$userId/reset-password'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Error al resetear contraseña');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Obtener actividades usando la API del proyecto web
  static Future<List<Map<String, dynamic>>> getActivities() async {
    try {
      final headers = await _getHeaders();
      
      final response = await http.get(
        Uri.parse('$baseUrl/activities'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Error al obtener actividades');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Crear actividad usando la API del proyecto web
  static Future<Map<String, dynamic>> createActivity(Map<String, dynamic> activityData) async {
    try {
      final headers = await _getHeaders();
      
      final response = await http.post(
        Uri.parse('$baseUrl/activities'),
        headers: headers,
        body: jsonEncode(activityData),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Error al crear actividad');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Completar sesión de actividad
  static Future<Map<String, dynamic>> completeActivitySession(
    String activityId, 
    Map<String, dynamic> completionData
  ) async {
    try {
      final headers = await _getHeaders();
      
      final response = await http.post(
        Uri.parse('$baseUrl/activities/$activityId/complete'),
        headers: headers,
        body: jsonEncode(completionData),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Error al completar sesión');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Aprobar completación de sesión
  static Future<Map<String, dynamic>> approveActivitySession(
    String activityId, 
    Map<String, dynamic> approvalData
  ) async {
    try {
      final headers = await _getHeaders();
      
      final response = await http.post(
        Uri.parse('$baseUrl/activities/$activityId/approve'),
        headers: headers,
        body: jsonEncode(approvalData),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Error al aprobar sesión');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Obtener reportes
  static Future<List<Map<String, dynamic>>> getReports({int? limit, String? userId}) async {
    try {
      final headers = await _getHeaders();
      
      final queryParams = <String, String>{};
      if (limit != null) queryParams['limit'] = limit.toString();
      if (userId != null) queryParams['userId'] = userId;
      
      final uri = Uri.parse('$baseUrl/reports').replace(queryParameters: queryParams);
      
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Error al obtener reportes');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Crear reporte
  static Future<Map<String, dynamic>> createReport(Map<String, dynamic> reportData) async {
    try {
      final headers = await _getHeaders();
      
      final response = await http.post(
        Uri.parse('$baseUrl/reports'),
        headers: headers,
        body: jsonEncode(reportData),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Error al crear reporte');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Verificar estado de sesión
  static Future<Map<String, dynamic>> checkSessionStatus(
    String sessionId, 
    String firebaseToken
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/session/check-status'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'sessionId': sessionId,
          'firebaseToken': firebaseToken,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Error al verificar estado de sesión');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Obtener sesiones de usuario
  static Future<List<Map<String, dynamic>>> getUserSessions(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/session/user-sessions?token=$token'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['sessions'] ?? []);
      } else {
        throw Exception('Error al obtener sesiones de usuario');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Terminar sesión
  static Future<void> terminateSession(
    String sessionId, 
    String firebaseToken, 
    {String reason = 'remote_termination'}
  ) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/session/user-sessions'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'sessionId': sessionId,
          'firebaseToken': firebaseToken,
          'reason': reason,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Error al terminar sesión');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Obtener contraseña provisional usando la API del proyecto web
  static Future<String?> getProvisionalPassword(String userId) async {
    try {
      final headers = await _getHeaders();
      print('[API] 🔄 Iniciando consulta de contraseña provisional...');
      print('[API] 🔄 URL: $baseUrl/users/$userId/provisional-password');
      print('[API] 🔄 UserID: $userId');
      print('[API] 🔄 Headers obtenidos correctamente');
      final response = await http.get(
        Uri.parse('$baseUrl/users/$userId/provisional-password'),
        headers: headers,
      );
      print('[API] Status: [1m${response.statusCode}[0m');
      print('[API] Body: ${response.body}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('[API] Provisional password: ${data['provisionalPassword']}');
        return data['provisionalPassword'];
      } else {
        print('[API] No se pudo obtener la clave provisional.');
        return null;
      }
    } catch (e) {
      print('[API] Error al consultar clave provisional: $e');
      return null;
    }
  }
} 