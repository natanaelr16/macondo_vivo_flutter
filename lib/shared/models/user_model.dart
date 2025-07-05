import 'package:cloud_firestore/cloud_firestore.dart';

// Types from the documentation
enum UserType {
  DOCENTE,
  ADMIN_STAFF,
  ESTUDIANTE,
  ACUDIENTE,
}

enum AppRole {
  SuperUser,
  ADMIN,
  USER,
}

enum DocumentType {
  CC,
  CE,
  TI,
  PASSPORT,
}

enum UserStatus {
  PENDING,
  VERIFIED,
  DISABLED,
}

enum GradeLevel {
  PREESCOLAR,
  PRIMARIA,
  BACHILLERATO,
}

enum EducationLevel {
  PROFESIONAL,
  MAESTRIA,
  OTRO,
}

enum SchoolPosition {
  RECTOR,
  COORD_ACADEMICO_PRIMARIA,
  COORD_ACADEMICO_SECUNDARIA,
  COORD_CONVIVENCIA,
  ADMINISTRATIVO,
  DOCENTE,
}

enum SchoolGrade {
  PREESCOLAR,
  PRIMARIA_GRADO_1,
  PRIMARIA_GRADO_2,
  PRIMARIA_GRADO_3,
  PRIMARIA_GRADO_4,
  PRIMARIA_GRADO_5,
  BACHILLERATO_GRADO_6,
  BACHILLERATO_GRADO_7,
  BACHILLERATO_GRADO_8,
  BACHILLERATO_GRADO_9,
  BACHILLERATO_GRADO_10,
  BACHILLERATO_GRADO_11,
}

enum TeacherLevel {
  TRANSICION,
  PRIMARIA,
  BACHILLERATO,
}

enum TeacherRole {
  REPRESENTANTE_CONSEJO_ACADEMICO,
  REPRESENTANTE_COMITE_CONVIVENCIA,
  REPRESENTANTE_CONSEJO_DIRECTIVO,
  LIDER_PROYECTO,
  LIDER_AREA,
  DIRECTOR_GRUPO,
  NINGUNO,
}

// Type specific data interface
class TypeSpecificData {
  // Admin Staff
  final String? profession;
  
  // Docente
  final String? areaOfStudy;
  final GradeLevel? assignedToGradeLevel;
  final EducationLevel? educationLevel;
  final String? educationLevelOther;
  final SchoolPosition? schoolPosition;
  final String? specialAssignment;
  final TeacherLevel? teacherLevel;
  final bool? isPTA;
  final List<TeacherRole>? teacherRoles;
  
  // Estudiante
  final SchoolGrade? schoolGrade;
  
  // Acudiente
  final int? representedChildrenCount;
  final List<String>? representedStudentUIDs;

  TypeSpecificData({
    this.profession,
    this.areaOfStudy,
    this.assignedToGradeLevel,
    this.educationLevel,
    this.educationLevelOther,
    this.schoolPosition,
    this.specialAssignment,
    this.teacherLevel,
    this.isPTA,
    this.teacherRoles,
    this.schoolGrade,
    this.representedChildrenCount,
    this.representedStudentUIDs,
  });

  Map<String, dynamic> toMap() {
    return {
      'profession': profession,
      'areaOfStudy': areaOfStudy,
      'assignedToGradeLevel': assignedToGradeLevel?.name,
      'educationLevel': educationLevel?.name,
      'educationLevelOther': educationLevelOther,
      'schoolPosition': schoolPosition?.name,
      'specialAssignment': specialAssignment,
      'teacherLevel': teacherLevel?.name,
      'isPTA': isPTA,
      'teacherRoles': teacherRoles?.map((role) => role.name).toList(),
      'schoolGrade': schoolGrade?.name,
      'representedChildrenCount': representedChildrenCount,
      'representedStudentUIDs': representedStudentUIDs,
    };
  }

  factory TypeSpecificData.fromMap(Map<String, dynamic> map) {
    return TypeSpecificData(
      profession: map['profession'],
      areaOfStudy: map['areaOfStudy'],
      assignedToGradeLevel: map['assignedToGradeLevel'] != null 
          ? GradeLevel.values.firstWhere((e) => e.name == map['assignedToGradeLevel'])
          : null,
      educationLevel: map['educationLevel'] != null 
          ? EducationLevel.values.firstWhere((e) => e.name == map['educationLevel'])
          : null,
      educationLevelOther: map['educationLevelOther'],
      schoolPosition: map['schoolPosition'] != null 
          ? SchoolPosition.values.firstWhere((e) => e.name == map['schoolPosition'])
          : null,
      specialAssignment: map['specialAssignment'],
      teacherLevel: map['teacherLevel'] != null 
          ? TeacherLevel.values.firstWhere((e) => e.name == map['teacherLevel'])
          : null,
      isPTA: map['isPTA'],
      teacherRoles: map['teacherRoles'] != null 
          ? (map['teacherRoles'] as List).map((role) => 
              TeacherRole.values.firstWhere((e) => e.name == role)).toList()
          : null,
      schoolGrade: map['schoolGrade'] != null 
          ? SchoolGrade.values.firstWhere((e) => e.name == map['schoolGrade'])
          : null,
      representedChildrenCount: map['representedChildrenCount'],
      representedStudentUIDs: map['representedStudentUIDs'] != null 
          ? List<String>.from(map['representedStudentUIDs'])
          : null,
    );
  }
}

class UserModel {
  final String uid;
  final String email;
  final String firstName;
  final String lastName;
  final DocumentType documentType;
  final String documentNumber;
  final String? phone;
  final UserType userType;
  final AppRole appRole;
  final UserStatus? status;
  final bool isActive;
  final bool provisionalPasswordSet;
  final String? provisionalPassword; // Stored temporarily until user changes password
  final DateTime createdAt;
  final DateTime updatedAt;
  final TypeSpecificData? typeSpecificData;

  UserModel({
    required this.uid,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.documentType,
    required this.documentNumber,
    this.phone,
    required this.userType,
    required this.appRole,
    this.status,
    required this.isActive,
    required this.provisionalPasswordSet,
    this.provisionalPassword,
    required this.createdAt,
    required this.updatedAt,
    this.typeSpecificData,
  });

  // Computed properties
  String get name => '$firstName $lastName';
  String get fullName => '$firstName $lastName';
  String get displayName => name.isNotEmpty ? name : email;

  // Helper methods
  bool get isSuperUser => appRole == AppRole.SuperUser;
  bool get isAdmin => appRole == AppRole.ADMIN || appRole == AppRole.SuperUser;
  bool get isTeacher => userType == UserType.DOCENTE;
  bool get isStudent => userType == UserType.ESTUDIANTE;
  bool get isParent => userType == UserType.ACUDIENTE;
  bool get isAdminStaff => userType == UserType.ADMIN_STAFF;

  // Compatibility getters for legacy code
  String get id => uid;
  String get role => appRole.name;

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'documentType': documentType.name,
      'documentNumber': documentNumber,
      'phone': phone,
      'userType': userType.name,
      'appRole': appRole.name,
      'status': status?.name,
      'isActive': isActive,
      'provisionalPasswordSet': provisionalPasswordSet,
      'provisionalPassword': provisionalPassword, // Stored temporarily until password change
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'typeSpecificData': typeSpecificData?.toMap(),
    };
  }

  // Convert to Firestore document with only required fields per security rules
  Map<String, dynamic> toFirestoreCreate() {
    return {
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'documentType': documentType.name,
      'documentNumber': documentNumber,
      'phone': phone ?? '', // Required by Firestore rules - ensure it's never null
      'userType': userType.name,
      'appRole': appRole.name,
      'status': status?.name ?? 'VERIFIED', // Required by Firestore rules
      'isActive': isActive,
      'provisionalPasswordSet': provisionalPasswordSet,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Create from Firestore document
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    print('UserModel.fromFirestore: Raw data: $data');
    print('UserModel.fromFirestore: appRole from Firestore: ${data['appRole']}');
    print('UserModel.fromFirestore: userType from Firestore: ${data['userType']}');
    
    // Helper function to parse dates from different formats
    DateTime parseDate(dynamic dateValue) {
      if (dateValue == null) return DateTime.now();
      
      if (dateValue is Timestamp) {
        return dateValue.toDate();
      } else if (dateValue is String) {
        try {
          return DateTime.parse(dateValue);
        } catch (e) {
          print('Error parsing date string: $dateValue');
          return DateTime.now();
        }
      } else if (dateValue is DateTime) {
        return dateValue;
      } else {
        print('Unknown date format: ${dateValue.runtimeType}');
        return DateTime.now();
      }
    }
    
    // Parse appRole with detailed logging
    AppRole parsedAppRole;
    try {
      final appRoleString = data['appRole'] ?? 'USER';
      print('UserModel.fromFirestore: Parsing appRole: $appRoleString');
      print('UserModel.fromFirestore: Available AppRole values: ${AppRole.values.map((e) => e.name).toList()}');
      
      parsedAppRole = AppRole.values.firstWhere(
        (e) => e.name == appRoleString,
        orElse: () {
          print('UserModel.fromFirestore: AppRole not found, defaulting to USER');
          return AppRole.USER;
        },
      );
      print('UserModel.fromFirestore: Parsed appRole: ${parsedAppRole.name}');
    } catch (e) {
      print('UserModel.fromFirestore: Error parsing appRole: $e');
      parsedAppRole = AppRole.USER;
    }
    
    // Parse userType with detailed logging
    UserType parsedUserType;
    try {
      final userTypeString = data['userType'] ?? 'ESTUDIANTE';
      print('UserModel.fromFirestore: Parsing userType: $userTypeString');
      print('UserModel.fromFirestore: Available UserType values: ${UserType.values.map((e) => e.name).toList()}');
      
      parsedUserType = UserType.values.firstWhere(
        (e) => e.name == userTypeString,
        orElse: () {
          print('UserModel.fromFirestore: UserType not found, defaulting to ESTUDIANTE');
          return UserType.ESTUDIANTE;
        },
      );
      print('UserModel.fromFirestore: Parsed userType: ${parsedUserType.name}');
    } catch (e) {
      print('UserModel.fromFirestore: Error parsing userType: $e');
      parsedUserType = UserType.ESTUDIANTE;
    }
    
    final userModel = UserModel(
      uid: data['uid'] ?? doc.id,
      email: data['email'] ?? '',
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      documentType: DocumentType.values.firstWhere(
        (e) => e.name == (data['documentType'] ?? 'CC'),
        orElse: () => DocumentType.CC,
      ),
      documentNumber: data['documentNumber'] ?? '',
      phone: data['phone'],
      userType: parsedUserType,
      appRole: parsedAppRole,
      status: data['status'] != null 
          ? UserStatus.values.firstWhere((e) => e.name == data['status'])
          : null,
      isActive: data['isActive'] ?? true,
      provisionalPasswordSet: data['provisionalPasswordSet'] ?? false,
      provisionalPassword: data['provisionalPassword'], // Read from Firestore if exists
      createdAt: parseDate(data['createdAt']),
      updatedAt: parseDate(data['updatedAt']),
      typeSpecificData: data['typeSpecificData'] != null 
          ? TypeSpecificData.fromMap(data['typeSpecificData'])
          : null,
    );
    
    print('UserModel.fromFirestore: Final user model - appRole: ${userModel.appRole.name}, isSuperUser: ${userModel.isSuperUser}, isAdmin: ${userModel.isAdmin}');
    
    return userModel;
  }

  // Create a copy with updated fields
  UserModel copyWith({
    String? uid,
    String? email,
    String? firstName,
    String? lastName,
    DocumentType? documentType,
    String? documentNumber,
    String? phone,
    UserType? userType,
    AppRole? appRole,
    UserStatus? status,
    bool? isActive,
    bool? provisionalPasswordSet,
    String? provisionalPassword,
    DateTime? createdAt,
    DateTime? updatedAt,
    TypeSpecificData? typeSpecificData,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      documentType: documentType ?? this.documentType,
      documentNumber: documentNumber ?? this.documentNumber,
      phone: phone ?? this.phone,
      userType: userType ?? this.userType,
      appRole: appRole ?? this.appRole,
      status: status ?? this.status,
      isActive: isActive ?? this.isActive,
      provisionalPasswordSet: provisionalPasswordSet ?? this.provisionalPasswordSet,
      provisionalPassword: provisionalPassword ?? this.provisionalPassword,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      typeSpecificData: typeSpecificData ?? this.typeSpecificData,
    );
  }

  // Convert to JSON for API calls
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'documentType': documentType.name,
      'documentNumber': documentNumber,
      'phone': phone,
      'userType': userType.name,
      'appRole': appRole.name,
      'status': status?.name,
      'isActive': isActive,
      'provisionalPasswordSet': provisionalPasswordSet,
      'provisionalPassword': provisionalPassword, // Include in JSON for API compatibility
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'typeSpecificData': typeSpecificData?.toMap(),
    };
  }

  // Create from JSON
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] ?? '',
      email: json['email'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      documentType: DocumentType.values.firstWhere(
        (e) => e.name == (json['documentType'] ?? 'CC'),
        orElse: () => DocumentType.CC,
      ),
      documentNumber: json['documentNumber'] ?? '',
      phone: json['phone'],
      userType: UserType.values.firstWhere(
        (e) => e.name == (json['userType'] ?? 'ESTUDIANTE'),
        orElse: () => UserType.ESTUDIANTE,
      ),
      appRole: AppRole.values.firstWhere(
        (e) => e.name == (json['appRole'] ?? 'USER'),
        orElse: () => AppRole.USER,
      ),
      status: json['status'] != null 
          ? UserStatus.values.firstWhere((e) => e.name == json['status'])
          : null,
      isActive: json['isActive'] ?? true,
      provisionalPasswordSet: json['provisionalPasswordSet'] ?? false,
      provisionalPassword: json['provisionalPassword'], // Read from JSON if exists
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
      typeSpecificData: json['typeSpecificData'] != null 
          ? TypeSpecificData.fromMap(json['typeSpecificData'])
          : null,
    );
  }

  @override
  String toString() {
    return 'UserModel(uid: $uid, email: $email, name: $name, userType: $userType, appRole: $appRole)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel && other.uid == uid;
  }

  @override
  int get hashCode => uid.hashCode;
} 
