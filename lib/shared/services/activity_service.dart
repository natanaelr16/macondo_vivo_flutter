import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/activity_model.dart';

class ActivityService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Base URL for API calls
  static const String baseUrl = 'https://macondo-vivo-logasi3oq-macondovivo.vercel.app/api';

  // Get current user's ID token for API calls
  Future<String> _getIdToken() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('No hay usuario autenticado');
    }
    
    try {
      // Forzar renovación del token
      final token = await user.getIdToken(true);
      if (token == null || token.isEmpty) {
        throw Exception('No se pudo obtener el token de autenticación');
      }
      return token;
    } catch (e) {
      print('Error obteniendo token: $e');
      // Intentar obtener token sin forzar renovación
      try {
        final token = await user.getIdToken(false);
        if (token == null || token.isEmpty) {
          throw Exception('Token de autenticación inválido');
        }
        return token;
      } catch (e2) {
        print('Error obteniendo token sin renovación: $e2');
        throw Exception('Error de autenticación. Por favor, inicie sesión nuevamente.');
      }
    }
  }

  // Make authenticated HTTP request
  Future<Map<String, dynamic>> _makeAuthenticatedRequest(
    String url, {
    required String method,
    required String token,
    Map<String, dynamic>? data,
  }) async {
    try {
      final headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      http.Response response;
      
      switch (method.toUpperCase()) {
        case 'GET':
          response = await http.get(Uri.parse(url), headers: headers);
          break;
        case 'POST':
          response = await http.post(
            Uri.parse(url),
            headers: headers,
            body: data != null ? jsonEncode(data) : null,
          );
          break;
        case 'PUT':
          response = await http.put(
            Uri.parse(url),
            headers: headers,
            body: data != null ? jsonEncode(data) : null,
          );
          break;
        case 'DELETE':
          response = await http.delete(Uri.parse(url), headers: headers);
          break;
        default:
          throw Exception('Método HTTP no soportado: $method');
      }

      // Manejar errores de autenticación
      if (response.statusCode == 401) {
        print('Error 401 - Token inválido, intentando renovar...');
        // Intentar renovar el token y reintentar la petición
        try {
          final newToken = await _getIdToken();
          if (newToken != token) {
            // Reintentar con el nuevo token
            headers['Authorization'] = 'Bearer $newToken';
            
            switch (method.toUpperCase()) {
              case 'GET':
                response = await http.get(Uri.parse(url), headers: headers);
                break;
              case 'POST':
                response = await http.post(
                  Uri.parse(url),
                  headers: headers,
                  body: data != null ? jsonEncode(data) : null,
                );
                break;
              case 'PUT':
                response = await http.put(
                  Uri.parse(url),
                  headers: headers,
                  body: data != null ? jsonEncode(data) : null,
                );
                break;
              case 'DELETE':
                response = await http.delete(Uri.parse(url), headers: headers);
                break;
            }
          }
        } catch (e) {
          print('Error renovando token: $e');
          throw Exception('Error de autenticación. Por favor, inicie sesión nuevamente.');
        }
      }

      final responseData = response.body.isNotEmpty 
          ? jsonDecode(response.body) 
          : null;

      return {
        'statusCode': response.statusCode,
        'data': responseData,
      };
    } catch (e) {
      print('Error making authenticated request: $e');
      rethrow;
    }
  }

  // ==================== ACTIVITY MANAGEMENT ====================

  // Get all activities with filtering
  Future<List<ActivityModel>> getAllActivities({
    String? searchTerm,
    String? status,
    String? category,
    String? creatorId,
  }) async {
    try {
      final token = await _getIdToken();
      
      // Build query parameters
      final Map<String, String> queryParams = {};
      if (searchTerm != null && searchTerm.isNotEmpty) {
        queryParams['search'] = searchTerm;
      }
      if (status != null) {
        queryParams['status'] = status;
      }
      if (category != null) {
        queryParams['category'] = category;
      }
      if (creatorId != null) {
        queryParams['creatorId'] = creatorId;
      }

      // Build URL with query parameters
      String url = '$baseUrl/activities';
      if (queryParams.isNotEmpty) {
        final queryString = queryParams.entries
            .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
            .join('&');
        url += '?$queryString';
      }

      final response = await _makeAuthenticatedRequest(
        url,
        method: 'GET',
        token: token,
      );

      if (response['statusCode'] == 200) {
        final List<dynamic> activitiesData = response['data'];
        return activitiesData.map((data) => ActivityModel.fromJson(data)).toList();
      } else {
        throw Exception('Error al obtener actividades: ${response['statusCode']}');
      }
    } catch (e) {
      print('Error getting activities: $e');
      rethrow;
    }
  }

  // Get activity by ID
  Future<ActivityModel?> getActivityById(String activityId) async {
    try {
      final token = await _getIdToken();
      
      final response = await _makeAuthenticatedRequest(
        '$baseUrl/activities/$activityId',
        method: 'GET',
        token: token,
      );

      if (response['statusCode'] == 200) {
        return ActivityModel.fromJson(response['data']);
      } else if (response['statusCode'] == 404) {
        return null;
      } else {
        throw Exception('Error al obtener actividad: ${response['statusCode']}');
      }
    } catch (e) {
      print('Error getting activity by ID: $e');
      rethrow;
    }
  }

  // Create new activity
  Future<ActivityModel> createActivity(Map<String, dynamic> activityData) async {
    try {
      final token = await _getIdToken();
      
      final response = await _makeAuthenticatedRequest(
        '$baseUrl/activities',
        method: 'POST',
        token: token,
        data: activityData,
      );

      if (response['statusCode'] == 200 || response['statusCode'] == 201) {
        final responseData = response['data'];
        if (responseData != null) {
          if (responseData['activity'] != null) {
            return ActivityModel.fromJson(responseData['activity']);
          }
          return ActivityModel.fromJson(responseData);
        } else {
          throw Exception('Respuesta inválida del servidor: datos faltantes');
        }
      } else {
        throw Exception('Error al crear actividad: ${response['statusCode']}');
      }
    } catch (e) {
      print('Error creating activity: $e');
      rethrow;
    }
  }

  // Update activity
  Future<void> updateActivity(String activityId, Map<String, dynamic> updates) async {
    try {
      final token = await _getIdToken();
      
      final response = await _makeAuthenticatedRequest(
        '$baseUrl/activities/$activityId',
        method: 'PUT',
        token: token,
        data: updates,
      );

      if (response['statusCode'] != 200) {
        throw Exception('Error al actualizar actividad: ${response['statusCode']}');
      }
    } catch (e) {
      print('Error updating activity: $e');
      rethrow;
    }
  }

  // Delete activity
  Future<void> deleteActivity(String activityId) async {
    try {
      final token = await _getIdToken();
      
      final response = await _makeAuthenticatedRequest(
        '$baseUrl/activities/$activityId',
        method: 'DELETE',
        token: token,
      );

      if (response['statusCode'] != 200) {
        throw Exception('Error al eliminar actividad: ${response['statusCode']}');
      }
    } catch (e) {
      print('Error deleting activity: $e');
      rethrow;
    }
  }

  // Add participant to activity
  Future<void> addParticipantToActivity(String activityId, String userId) async {
    try {
      final activity = await getActivityById(activityId);
      if (activity == null) {
        throw Exception('Actividad no encontrada');
      }

      // Check if user is already a participant
      final isAlreadyParticipant = activity.participants.any((p) => p.userId == userId);
      if (isAlreadyParticipant) {
        throw Exception('El usuario ya es participante de esta actividad');
      }

      final newParticipant = {
        'userId': userId,
        'status': 'PENDIENTE',
      };

      final updatedParticipants = [...activity.participants, newParticipant];
      
      await updateActivity(activityId, {'participants': updatedParticipants});
    } catch (e) {
      print('Error adding participant: $e');
      rethrow;
    }
  }

  // Remove participant from activity
  Future<void> removeParticipantFromActivity(String activityId, String userId) async {
    try {
      final activity = await getActivityById(activityId);
      if (activity == null) {
        throw Exception('Actividad no encontrada');
      }

      final updatedParticipants = activity.participants
          .where((p) => p.userId != userId)
          .toList();
      
      await updateActivity(activityId, {'participants': updatedParticipants});
    } catch (e) {
      print('Error removing participant: $e');
      rethrow;
    }
  }

  // Mark user as completed for an activity
  Future<void> markUserAsCompleted(String activityId, String userId, bool isResponsible) async {
    try {
      final activity = await getActivityById(activityId);
      if (activity == null) {
        throw Exception('Actividad no encontrada');
      }

      final participants = activity.participants;
      final participantIndex = participants.indexWhere((p) => p.userId == userId);
      
      if (participantIndex == -1) {
        throw Exception('Usuario no es participante de esta actividad');
      }

      // Update participant status
      final originalParticipant = participants[participantIndex];
      participants[participantIndex] = Participant(
        userId: originalParticipant.userId,
        status: 'COMPLETADO',
        completedAt: DateTime.now(),
      );

      await updateActivity(activityId, {'participants': participants});
    } catch (e) {
      print('Error marking user as completed: $e');
      rethrow;
    }
  }

  // Approve session completion
  Future<void> approveSessionCompletion(
    String activityId, 
    String participantUserId, 
    int sessionNumber,
  ) async {
    try {
      final token = await _getIdToken();
      
      final response = await _makeAuthenticatedRequest(
        '$baseUrl/activities/$activityId/approve',
        method: 'POST',
        token: token,
        data: {
          'participantUserId': participantUserId,
          'sessionNumber': sessionNumber,
        },
      );

      if (response['statusCode'] != 200) {
        throw Exception('Error al aprobar sesión: ${response['statusCode']}');
      }
    } catch (e) {
      print('Error approving session completion: $e');
      rethrow;
    }
  }

  // Complete session
  Future<void> completeSession(String activityId, int sessionNumber) async {
    try {
      final token = await _getIdToken();
      
      final response = await _makeAuthenticatedRequest(
        '$baseUrl/activities/$activityId/complete',
        method: 'POST',
        token: token,
        data: {
          'sessionNumber': sessionNumber,
        },
      );

      if (response['statusCode'] != 200) {
        throw Exception('Error al completar sesión: ${response['statusCode']}');
      }
    } catch (e) {
      print('Error completing session: $e');
      rethrow;
    }
  }

  // ==================== UTILITY METHODS ====================

  // Get activity statistics
  Future<Map<String, int>> getActivityStatistics({String? creatorId}) async {
    try {
      final allActivities = await getAllActivities(creatorId: creatorId);
      
      final stats = <String, int>{};
      stats['total'] = allActivities.length;
      stats['active'] = allActivities.where((a) => a.status.name == 'ACTIVA').length;
      stats['completed'] = allActivities.where((a) => a.status.name == 'COMPLETADA').length;
      stats['inactive'] = allActivities.where((a) => a.status.name == 'INACTIVA').length;
      stats['pending'] = allActivities.where((a) => a.status.name == 'PENDIENTE').length;
      return stats;
    } catch (e) {
      print('Error getting activity statistics: $e');
      rethrow;
    }
  }

  // Search activities
  Future<List<ActivityModel>> searchActivities(String searchTerm) async {
    return await getAllActivities(searchTerm: searchTerm);
  }

  // Get activities by status
  Future<List<ActivityModel>> getActivitiesByStatus(String status) async {
    return await getAllActivities(status: status);
  }

  // Get activities by category
  Future<List<ActivityModel>> getActivitiesByCategory(String category) async {
    return await getAllActivities(category: category);
  }

  // Get activities created by specific user
  Future<List<ActivityModel>> getActivitiesByCreator(String creatorId) async {
    return await getAllActivities(creatorId: creatorId);
  }

  // Get user's activities (where they are participants)
  Future<List<ActivityModel>> getUserActivities(String userId) async {
    try {
      final allActivities = await getAllActivities();
      return allActivities.where((activity) {
        return activity.participants.any((p) => p.userId == userId);
      }).toList();
    } catch (e) {
      print('Error getting user activities: $e');
      rethrow;
    }
  }

  // Validate activity data
  String? validateActivityData(Map<String, dynamic> activityData) {
    final requiredFields = [
      'title', 'description', 'status', 'participants', 'createdBy'
    ];

    for (final field in requiredFields) {
      if (activityData[field] == null || activityData[field].toString().isEmpty) {
        return 'El campo $field es requerido';
      }
    }

    // Validate title length
    final title = activityData['title'].toString();
    if (title.length < 3) {
      return 'El título debe tener al menos 3 caracteres';
    }

    // Validate description length
    final description = activityData['description'].toString();
    if (description.length < 10) {
      return 'La descripción debe tener al menos 10 caracteres';
    }

    // Validate participants
    final participants = activityData['participants'];
    if (participants == null || participants is! List || participants.isEmpty) {
      return 'Debe seleccionar al menos un participante';
    }

    return null;
  }

  // Get activity categories
  List<String> getActivityCategories() {
    return [
      'ACADÉMICA',
      'DEPORTIVA',
      'CULTURAL',
      'SOCIAL',
      'ADMINISTRATIVA',
      'OTRA',
    ];
  }

  // Get activity statuses
  List<String> getActivityStatuses() {
    return [
      'PENDIENTE',
      'ACTIVA',
      'COMPLETADA',
      'INACTIVA',
      'CANCELADA',
    ];
  }
} 