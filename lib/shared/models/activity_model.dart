import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/date_utils.dart';

// Types from the documentation
enum ActivityStatus {
  ACTIVA,
  INACTIVA,
  COMPLETADA,
}

enum CompletionStatus {
  PENDING_APPROVAL,
  APPROVED,
  COMPLETED,
}

// Session date structure
class SessionDate {
  final int sessionNumber;
  final DateTime date;
  final String startTime; // "HH:MM"
  final String endTime; // "HH:MM"
  final String? location;
  final String? status; // 'pending' | 'active' | 'completed'

  SessionDate({
    required this.sessionNumber,
    required this.date,
    required this.startTime,
    required this.endTime,
    this.location,
    this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'sessionNumber': sessionNumber,
      'date': date.toIso8601String(),
      'startTime': startTime,
      'endTime': endTime,
      'location': location,
      'status': status,
    };
  }

  factory SessionDate.fromMap(Map<String, dynamic> map) {
    // Helper function to parse dates from different formats
    DateTime parseDate(dynamic dateValue) {
      if (dateValue == null) return DateUtils.getCurrentLocalDateTime();
      
      if (dateValue is Timestamp) {
        return dateValue.toDate().toLocal(); // Convertir a zona horaria local
      } else if (dateValue is String) {
        try {
          return DateUtils.parseFromISOString(dateValue); // Usar utilidad para parsear
        } catch (e) {
          print('Error parsing date string: $dateValue');
          return DateUtils.getCurrentLocalDateTime();
        }
      } else if (dateValue is DateTime) {
        return dateValue.toLocal(); // Asegurar que esté en zona horaria local
      } else {
        print('Unknown date format: ${dateValue.runtimeType}');
        return DateUtils.getCurrentLocalDateTime();
      }
    }
    
    return SessionDate(
      sessionNumber: map['sessionNumber'] ?? 1,
      date: parseDate(map['date']),
      startTime: map['startTime'] ?? '09:00',
      endTime: map['endTime'] ?? '10:00',
      location: map['location'],
      status: map['status'],
    );
  }
}

// Participant structure
class Participant {
  final String userId;
  final String status; // 'PENDIENTE' | 'COMPLETADA'
  final DateTime? completedAt;

  Participant({
    required this.userId,
    required this.status,
    this.completedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'status': status,
      'completedAt': completedAt != null ? DateUtils.toLocalISOString(completedAt!) : null,
    };
  }

  factory Participant.fromMap(Map<String, dynamic> map) {
    // Helper function to parse dates from different formats
    DateTime? parseDate(dynamic dateValue) {
      if (dateValue == null) return null;
      
      if (dateValue is Timestamp) {
        return dateValue.toDate().toLocal(); // Convertir a zona horaria local
      } else if (dateValue is String) {
        try {
          return DateUtils.parseFromISOString(dateValue); // Usar utilidad para parsear
        } catch (e) {
          print('Error parsing date string: $dateValue');
          return null;
        }
      } else if (dateValue is DateTime) {
        return dateValue.toLocal(); // Asegurar que esté en zona horaria local
      } else {
        print('Unknown date format: ${dateValue.runtimeType}');
        return null;
      }
    }
    
    return Participant(
      userId: map['userId'] ?? '',
      status: map['status'] ?? 'PENDIENTE',
      completedAt: parseDate(map['completedAt']),
    );
  }
}

// Session completion structure
class SessionCompletion {
  final int sessionNumber;
  final String userId;
  final DateTime completedAt;
  final bool isResponsible;
  final CompletionStatus status;
  final String? approvedBy;
  final DateTime? approvedAt;

  SessionCompletion({
    required this.sessionNumber,
    required this.userId,
    required this.completedAt,
    required this.isResponsible,
    required this.status,
    this.approvedBy,
    this.approvedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'sessionNumber': sessionNumber,
      'userId': userId,
      'completedAt': DateUtils.toLocalISOString(completedAt),
      'isResponsible': isResponsible,
      'status': status.name,
      'approvedBy': approvedBy,
      'approvedAt': approvedAt != null ? DateUtils.toLocalISOString(approvedAt!) : null,
    };
  }

  factory SessionCompletion.fromMap(Map<String, dynamic> map) {
    // Helper function to parse dates from different formats
    DateTime parseDate(dynamic dateValue) {
      if (dateValue == null) return DateUtils.getCurrentLocalDateTime();
      
      if (dateValue is Timestamp) {
        return dateValue.toDate().toLocal(); // Convertir a zona horaria local
      } else if (dateValue is String) {
        try {
          return DateUtils.parseFromISOString(dateValue); // Usar utilidad para parsear
        } catch (e) {
          print('Error parsing date string: $dateValue');
          return DateUtils.getCurrentLocalDateTime();
        }
      } else if (dateValue is DateTime) {
        return dateValue.toLocal(); // Asegurar que esté en zona horaria local
      } else {
        print('Unknown date format: ${dateValue.runtimeType}');
        return DateUtils.getCurrentLocalDateTime();
      }
    }
    
    // Helper function to parse optional dates
    DateTime? parseOptionalDate(dynamic dateValue) {
      if (dateValue == null) return null;
      
      if (dateValue is Timestamp) {
        return dateValue.toDate().toLocal(); // Convertir a zona horaria local
      } else if (dateValue is String) {
        try {
          return DateUtils.parseFromISOString(dateValue); // Usar utilidad para parsear
        } catch (e) {
          print('Error parsing date string: $dateValue');
          return null;
        }
      } else if (dateValue is DateTime) {
        return dateValue.toLocal(); // Asegurar que esté en zona horaria local
      } else {
        print('Unknown date format: ${dateValue.runtimeType}');
        return null;
      }
    }
    
    return SessionCompletion(
      sessionNumber: map['sessionNumber'] ?? 1,
      userId: map['userId'] ?? '',
      completedAt: parseDate(map['completedAt']),
      isResponsible: map['isResponsible'] ?? false,
      status: CompletionStatus.values.firstWhere(
        (e) => e.name == (map['status'] ?? 'PENDING_APPROVAL'),
        orElse: () => CompletionStatus.PENDING_APPROVAL,
      ),
      approvedBy: map['approvedBy'],
      approvedAt: parseOptionalDate(map['approvedAt']),
    );
  }

  SessionCompletion copyWith({
    int? sessionNumber,
    String? userId,
    DateTime? completedAt,
    bool? isResponsible,
    CompletionStatus? status,
    String? approvedBy,
    DateTime? approvedAt,
  }) {
    return SessionCompletion(
      sessionNumber: sessionNumber ?? this.sessionNumber,
      userId: userId ?? this.userId,
      completedAt: completedAt ?? this.completedAt,
      isResponsible: isResponsible ?? this.isResponsible,
      status: status ?? this.status,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedAt: approvedAt ?? this.approvedAt,
    );
  }
}

class ActivityModel {
  final String activityId;
  final String title;
  final String description; // HTML rich text
  final int numberOfSessions;
  final List<SessionDate> sessionDates;
  final String? submissionLink;
  final String? category;
  final int? estimatedDuration; // minutes
  final List<String> materials;
  final List<String> objectives;
  final List<Participant> responsibleUsers;
  final List<Participant> participants;
  final ActivityStatus status;
  final bool adminCanEdit;
  final String createdBy_uid;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<SessionCompletion> sessionCompletions;
  final double? completionPercentage;

  ActivityModel({
    required this.activityId,
    required this.title,
    required this.description,
    required this.numberOfSessions,
    required this.sessionDates,
    this.submissionLink,
    this.category,
    this.estimatedDuration,
    required this.materials,
    required this.objectives,
    required this.responsibleUsers,
    required this.participants,
    required this.status,
    required this.adminCanEdit,
    required this.createdBy_uid,
    required this.createdAt,
    required this.updatedAt,
    required this.sessionCompletions,
    this.completionPercentage,
  });

  // Computed properties
  bool get isActive => status == ActivityStatus.ACTIVA;
  bool get isCompleted => status == ActivityStatus.COMPLETADA;
  bool get isInactive => status == ActivityStatus.INACTIVA;

  // Compatibility getters for legacy code
  String get id => activityId;
  String get createdBy => createdBy_uid;
  String get type => category ?? 'general';

  // Helper methods
  bool isUserResponsible(String userId) {
    return responsibleUsers.any((user) => user.userId == userId);
  }

  bool isUserParticipant(String userId) {
    return participants.any((user) => user.userId == userId);
  }

  bool canUserEdit(String userId, String userRole) {
    if (userRole == 'SuperUser') return true;
    if (userRole == 'ADMIN' && createdBy_uid == userId) return true;
    return false;
  }

  bool canUserDelete(String userId, String userRole) {
    if (userRole == 'SuperUser') return true;
    if (userRole == 'ADMIN' && createdBy_uid == userId) return true;
    return false;
  }

  // Calculate completion percentage
  double calculateCompletionPercentage() {
    if (participants.isEmpty || numberOfSessions == 0) return 0.0;
    
    // Solo considerar PARTICIPANTES únicos (no responsables)
    final uniqueParticipantIds = participants.map((p) => p.userId).toSet();
    
    // Total requerido: número de sesiones × número de participantes
    final totalRequired = numberOfSessions * uniqueParticipantIds.length;
    
    if (totalRequired == 0) return 0.0;
    
    // Contar solo completaciones de PARTICIPANTES con estado APPROVED o COMPLETED
    final completed = sessionCompletions
        .where((sc) => 
          uniqueParticipantIds.contains(sc.userId) && // Solo participantes
          (sc.status == CompletionStatus.APPROVED || sc.status == CompletionStatus.COMPLETED) // Solo aprobadas o completadas
        )
        .length;
    
    // Calcular progreso pero asegurar que no exceda 100%
    final progress = (completed / totalRequired) * 100;
    return progress > 100 ? 100.0 : progress;
  }

  // Get detailed progress information
  Map<String, dynamic> getProgressDetails() {
    if (participants.isEmpty || numberOfSessions == 0) {
      return {
        'completionPercentage': 0.0,
        'currentCompletions': 0,
        'totalRequired': 0,
        'uniqueParticipants': 0,
        'isFullyCompleted': false,
        'progressText': '0 usuarios • 0 sesiones • 0/0 completadas'
      };
    }
    
    // Solo considerar PARTICIPANTES únicos (no responsables)
    final uniqueParticipantIds = participants.map((p) => p.userId).toSet();
    
    // Total requerido: número de sesiones × número de participantes
    final totalRequired = numberOfSessions * uniqueParticipantIds.length;
    
    // Contar solo completaciones de PARTICIPANTES con estado APPROVED o COMPLETED
    final completed = sessionCompletions
        .where((sc) => 
          uniqueParticipantIds.contains(sc.userId) && // Solo participantes
          (sc.status == CompletionStatus.APPROVED || sc.status == CompletionStatus.COMPLETED) // Solo aprobadas o completadas
        )
        .length;
    
    // Calcular progreso pero asegurar que no exceda 100%
    final completionPercentage = totalRequired > 0 ? (completed / totalRequired) * 100 : 0.0;
    final finalPercentage = completionPercentage > 100 ? 100.0 : completionPercentage;
    final isFullyCompleted = completed >= totalRequired;
    
    return {
      'completionPercentage': finalPercentage,
      'currentCompletions': completed,
      'totalRequired': totalRequired,
      'uniqueParticipants': uniqueParticipantIds.length,
      'isFullyCompleted': isFullyCompleted,
      'progressText': '${uniqueParticipantIds.length} usuarios • $numberOfSessions sesiones • $completed/$totalRequired completadas'
    };
  }

  // Get user progress for a specific participant
  Map<String, dynamic> getUserProgress(String userId) {
    // Verificar si el usuario es participante
    final isParticipant = participants.any((p) => p.userId == userId);
    if (!isParticipant) {
      return {
        'isParticipant': false,
        'completedSessions': <int>[],
        'nextSessionNumber': 1,
        'totalSessions': numberOfSessions,
        'progress': 0.0
      };
    }
    
    // Obtener completaciones del usuario (solo APPROVED o COMPLETED)
    final userCompletions = sessionCompletions
        .where((sc) => 
          sc.userId == userId && 
          (sc.status == CompletionStatus.APPROVED || sc.status == CompletionStatus.COMPLETED)
        )
        .toList();
    
    final completedSessions = userCompletions.map((sc) => sc.sessionNumber).toList();
    final nextSessionNumber = completedSessions.isEmpty ? 1 : completedSessions.length + 1;
    final progress = numberOfSessions > 0 ? (completedSessions.length / numberOfSessions) * 100 : 0.0;
    
    return {
      'isParticipant': true,
      'completedSessions': completedSessions,
      'nextSessionNumber': nextSessionNumber,
      'totalSessions': numberOfSessions,
      'progress': progress,
      'canCompleteNextSession': nextSessionNumber <= numberOfSessions
    };
  }

  // Check if activity should be marked as completed
  bool shouldBeMarkedAsCompleted() {
    final progressDetails = getProgressDetails();
    return progressDetails['isFullyCompleted'] == true;
  }

  // Get session completion status for a specific user and session
  SessionCompletion? getSessionCompletion(int sessionNumber, String userId) {
    try {
      return sessionCompletions.firstWhere(
        (sc) => sc.sessionNumber == sessionNumber && sc.userId == userId,
      );
    } catch (e) {
      return null;
    }
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'activityId': activityId,
      'title': title,
      'description': description,
      'numberOfSessions': numberOfSessions,
      'sessionDates': sessionDates.map((sd) => sd.toMap()).toList(),
      'submissionLink': submissionLink,
      'category': category,
      'estimatedDuration': estimatedDuration,
      'materials': materials,
      'objectives': objectives,
      'responsibleUsers': responsibleUsers.map((p) => p.toMap()).toList(),
      'participants': participants.map((p) => p.toMap()).toList(),
      'status': status.name,
      'adminCanEdit': adminCanEdit,
      'createdBy_uid': createdBy_uid,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'sessionCompletions': sessionCompletions.map((sc) => sc.toMap()).toList(),
      'completionPercentage': completionPercentage ?? calculateCompletionPercentage(),
    };
  }

  // Create from Firestore document
  factory ActivityModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Helper function to parse dates from different formats
    DateTime parseDate(dynamic dateValue) {
      if (dateValue == null) return DateUtils.getCurrentLocalDateTime();
      
      if (dateValue is Timestamp) {
        return dateValue.toDate().toLocal(); // Convertir a zona horaria local
      } else if (dateValue is String) {
        try {
          return DateUtils.parseFromISOString(dateValue); // Usar utilidad para parsear
        } catch (e) {
          print('Error parsing date string: $dateValue');
          return DateUtils.getCurrentLocalDateTime();
        }
      } else if (dateValue is DateTime) {
        return dateValue.toLocal(); // Asegurar que esté en zona horaria local
      } else {
        print('Unknown date format: ${dateValue.runtimeType}');
        return DateUtils.getCurrentLocalDateTime();
      }
    }
    
    return ActivityModel(
      activityId: data['activityId'] ?? doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      numberOfSessions: data['numberOfSessions'] ?? 1,
      sessionDates: (data['sessionDates'] as List<dynamic>?)
          ?.map((sd) => SessionDate.fromMap(sd))
          .toList() ?? [],
      submissionLink: data['submissionLink'],
      category: data['category'],
      estimatedDuration: data['estimatedDuration'],
      materials: List<String>.from(data['materials'] ?? []),
      objectives: List<String>.from(data['objectives'] ?? []),
      responsibleUsers: (data['responsibleUsers'] as List<dynamic>?)
          ?.map((p) => Participant.fromMap(p))
          .toList() ?? [],
      participants: (data['participants'] as List<dynamic>?)
          ?.map((p) => Participant.fromMap(p))
          .toList() ?? [],
      status: ActivityStatus.values.firstWhere(
        (e) => e.name == (data['status'] ?? 'ACTIVA'),
        orElse: () => ActivityStatus.ACTIVA,
      ),
      adminCanEdit: data['adminCanEdit'] ?? true,
      createdBy_uid: data['createdBy_uid'] ?? '',
      createdAt: parseDate(data['createdAt']),
      updatedAt: parseDate(data['updatedAt']),
      sessionCompletions: (data['sessionCompletions'] as List<dynamic>?)
          ?.map((sc) => SessionCompletion.fromMap(sc))
          .toList() ?? [],
      completionPercentage: data['completionPercentage']?.toDouble(),
    );
  }

  // Create a copy with updated fields
  ActivityModel copyWith({
    String? activityId,
    String? title,
    String? description,
    int? numberOfSessions,
    List<SessionDate>? sessionDates,
    String? submissionLink,
    String? category,
    int? estimatedDuration,
    List<String>? materials,
    List<String>? objectives,
    List<Participant>? responsibleUsers,
    List<Participant>? participants,
    ActivityStatus? status,
    bool? adminCanEdit,
    String? createdBy_uid,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<SessionCompletion>? sessionCompletions,
    double? completionPercentage,
  }) {
    return ActivityModel(
      activityId: activityId ?? this.activityId,
      title: title ?? this.title,
      description: description ?? this.description,
      numberOfSessions: numberOfSessions ?? this.numberOfSessions,
      sessionDates: sessionDates ?? this.sessionDates,
      submissionLink: submissionLink ?? this.submissionLink,
      category: category ?? this.category,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      materials: materials ?? this.materials,
      objectives: objectives ?? this.objectives,
      responsibleUsers: responsibleUsers ?? this.responsibleUsers,
      participants: participants ?? this.participants,
      status: status ?? this.status,
      adminCanEdit: adminCanEdit ?? this.adminCanEdit,
      createdBy_uid: createdBy_uid ?? this.createdBy_uid,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      sessionCompletions: sessionCompletions ?? this.sessionCompletions,
      completionPercentage: completionPercentage ?? this.completionPercentage,
    );
  }

  // Convert to JSON for API calls
  Map<String, dynamic> toJson() {
    return {
      'activityId': activityId,
      'title': title,
      'description': description,
      'numberOfSessions': numberOfSessions,
      'sessionDates': sessionDates.map((sd) => sd.toMap()).toList(),
      'submissionLink': submissionLink,
      'category': category,
      'estimatedDuration': estimatedDuration,
      'materials': materials,
      'objectives': objectives,
      'responsibleUsers': responsibleUsers.map((p) => p.toMap()).toList(),
      'participants': participants.map((p) => p.toMap()).toList(),
      'status': status.name,
      'adminCanEdit': adminCanEdit,
      'createdBy_uid': createdBy_uid,
      'createdAt': DateUtils.toLocalISOString(createdAt),
      'updatedAt': DateUtils.toLocalISOString(updatedAt),
      'sessionCompletions': sessionCompletions.map((sc) => sc.toMap()).toList(),
      'completionPercentage': completionPercentage ?? calculateCompletionPercentage(),
    };
  }

  // Create from JSON
  factory ActivityModel.fromJson(Map<String, dynamic> json) {
    return ActivityModel(
      activityId: json['activityId'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      numberOfSessions: json['numberOfSessions'] ?? 1,
      sessionDates: (json['sessionDates'] as List<dynamic>?)
          ?.map((sd) => SessionDate.fromMap(sd))
          .toList() ?? [],
      submissionLink: json['submissionLink'],
      category: json['category'],
      estimatedDuration: json['estimatedDuration'],
      materials: List<String>.from(json['materials'] ?? []),
      objectives: List<String>.from(json['objectives'] ?? []),
      responsibleUsers: (json['responsibleUsers'] as List<dynamic>?)
          ?.map((p) => Participant.fromMap(p))
          .toList() ?? [],
      participants: (json['participants'] as List<dynamic>?)
          ?.map((p) => Participant.fromMap(p))
          .toList() ?? [],
      status: ActivityStatus.values.firstWhere(
        (e) => e.name == (json['status'] ?? 'ACTIVA'),
        orElse: () => ActivityStatus.ACTIVA,
      ),
      adminCanEdit: json['adminCanEdit'] ?? true,
      createdBy_uid: json['createdBy_uid'] ?? '',
      createdAt: json['createdAt'] != null 
          ? DateUtils.parseFromISOString(json['createdAt'])
          : DateUtils.getCurrentLocalDateTime(),
      updatedAt: json['updatedAt'] != null 
          ? DateUtils.parseFromISOString(json['updatedAt'])
          : DateUtils.getCurrentLocalDateTime(),
      sessionCompletions: (json['sessionCompletions'] as List<dynamic>?)
          ?.map((sc) => SessionCompletion.fromMap(sc))
          .toList() ?? [],
      completionPercentage: json['completionPercentage']?.toDouble(),
    );
  }

  @override
  String toString() {
    return 'ActivityModel(activityId: $activityId, title: $title, status: $status, completionPercentage: $completionPercentage)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ActivityModel && other.activityId == activityId;
  }

  @override
  int get hashCode => activityId.hashCode;
} 