import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../shared/models/user_model.dart';
import '../../../../shared/services/user_service.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../../../shared/providers/data_provider.dart';

class EditUserForm extends StatefulWidget {
  final UserModel user;
  
  const EditUserForm({super.key, required this.user});

  @override
  State<EditUserForm> createState() => _EditUserFormState();
}

class _EditUserFormState extends State<EditUserForm> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Services
  final UserService _userService = UserService();

  // Controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _documentNumberController = TextEditingController();

  // Selected values
  DocumentType _selectedDocumentType = DocumentType.CC;
  UserType _selectedUserType = UserType.ESTUDIANTE;
  AppRole _selectedAppRole = AppRole.USER;
  bool _isActive = true;

  // Type-specific fields
  String _areaOfStudy = '';
  GradeLevel _assignedToGradeLevel = GradeLevel.PRIMARIA;
  EducationLevel _educationLevel = EducationLevel.PROFESIONAL;
  String _educationLevelOther = '';
  SchoolPosition _schoolPosition = SchoolPosition.DOCENTE;
  String _specialAssignment = '';
  bool _isPTA = false;
  final List<TeacherRole> _teacherRoles = [];
  SchoolGrade _schoolGrade = SchoolGrade.PRIMARIA_GRADO_1;
  String _profession = '';
  int _representedChildrenCount = 1;

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    final user = widget.user;
    
    // Basic info
    _firstNameController.text = user.firstName;
    _lastNameController.text = user.lastName;
    _phoneController.text = user.phone ?? '';
    _documentNumberController.text = user.documentNumber;
    _selectedDocumentType = user.documentType;
    _selectedUserType = user.userType;
    _selectedAppRole = user.appRole;
    _isActive = user.isActive;

    // Type-specific data
    final data = user.typeSpecificData;
    if (data != null) {
      _areaOfStudy = data.areaOfStudy ?? '';
      _assignedToGradeLevel = data.assignedToGradeLevel ?? GradeLevel.PRIMARIA;
      _educationLevel = data.educationLevel ?? EducationLevel.PROFESIONAL;
      _educationLevelOther = data.educationLevelOther ?? '';
      _schoolPosition = data.schoolPosition ?? SchoolPosition.DOCENTE;
      _specialAssignment = data.specialAssignment ?? '';
      _isPTA = data.isPTA ?? false;
      _teacherRoles.clear();
      if (data.teacherRoles != null) {
        _teacherRoles.addAll(data.teacherRoles!);
      }
      _schoolGrade = data.schoolGrade ?? SchoolGrade.PRIMARIA_GRADO_1;
      _profession = data.profession ?? '';
      _representedChildrenCount = data.representedChildrenCount ?? 1;
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _documentNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // Verificar permisos
        if (!authProvider.canManageUsers) {
          return Scaffold(
            backgroundColor: theme.colorScheme.surface,
            appBar: AppBar(
              title: const Text('Acceso Denegado'),
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.lock_outline,
                      size: 64,
                      color: theme.colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Acceso Denegado',
                      style: theme.textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No tienes permisos para editar usuarios.',
                      style: theme.textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Volver'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: theme.colorScheme.surface,
          appBar: AppBar(
            title: Text('Editar Usuario: ${widget.user.name}'),
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header info
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: primaryColor.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.edit,
                              color: primaryColor,
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Editar Información del Usuario',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Modifica la información del usuario. Los campos marcados con * son obligatorios.',
                          style: TextStyle(
                            fontSize: 14,
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Información Personal
                  _buildSectionTitle('Información Personal', Icons.person),
                  const SizedBox(height: 16),

                  // Email (read-only)
                  TextFormField(
                    initialValue: widget.user.email,
                    enabled: false,
                    decoration: const InputDecoration(
                      labelText: 'Correo Electrónico',
                      hintText: 'No se puede editar',
                      prefixIcon: Icon(Icons.email),
                      filled: true,
                      fillColor: Colors.grey,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // First Name
                  TextFormField(
                    controller: _firstNameController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre *',
                      hintText: 'Ingrese el nombre',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'El nombre es requerido';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // Last Name
                  TextFormField(
                    controller: _lastNameController,
                    decoration: const InputDecoration(
                      labelText: 'Apellido *',
                      hintText: 'Ingrese el apellido',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'El apellido es requerido';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 24),

                  // Documento de Identidad
                  _buildSectionTitle('Documento de Identidad', Icons.badge),
                  const SizedBox(height: 16),

                  // Document Type
                  DropdownButtonFormField<DocumentType>(
                    value: _selectedDocumentType,
                    decoration: const InputDecoration(
                      labelText: 'Tipo de Documento *',
                      prefixIcon: Icon(Icons.badge),
                    ),
                    items: const [
                      DropdownMenuItem(value: DocumentType.CC, child: Text('Cédula de Ciudadanía')),
                      DropdownMenuItem(value: DocumentType.CE, child: Text('Cédula de Extranjería')),
                      DropdownMenuItem(value: DocumentType.TI, child: Text('Tarjeta de Identidad')),
                      DropdownMenuItem(value: DocumentType.PASSPORT, child: Text('Pasaporte')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedDocumentType = value;
                        });
                      }
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Seleccione un tipo de documento';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // Document Number (editable)
                  TextFormField(
                    controller: _documentNumberController,
                    decoration: const InputDecoration(
                      labelText: 'Número de Documento *',
                      hintText: 'Ingrese el número de documento',
                      prefixIcon: Icon(Icons.badge),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'El número de documento es requerido';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 24),

                  // Información de Contacto
                  _buildSectionTitle('Información de Contacto', Icons.contact_phone),
                  const SizedBox(height: 16),

                  // Phone
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Teléfono',
                      hintText: 'Ingrese el número de teléfono',
                      prefixIcon: Icon(Icons.phone),
                    ),
                    keyboardType: TextInputType.phone,
                  ),

                  const SizedBox(height: 24),

                  // Roles y Permisos
                  _buildSectionTitle('Roles y Permisos', Icons.security),
                  const SizedBox(height: 16),

                  // User Type
                  DropdownButtonFormField<UserType>(
                    value: _selectedUserType,
                    decoration: const InputDecoration(
                      labelText: 'Tipo de Usuario *',
                      prefixIcon: Icon(Icons.category),
                    ),
                    items: const [
                      DropdownMenuItem(value: UserType.DOCENTE, child: Text('Docente')),
                      DropdownMenuItem(value: UserType.ADMIN_STAFF, child: Text('Personal Administrativo')),
                      DropdownMenuItem(value: UserType.ESTUDIANTE, child: Text('Estudiante')),
                      DropdownMenuItem(value: UserType.ACUDIENTE, child: Text('Acudiente')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedUserType = value;
                        });
                      }
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Seleccione un tipo de usuario';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // App Role
                  DropdownButtonFormField<AppRole>(
                    value: _selectedAppRole,
                    decoration: const InputDecoration(
                      labelText: 'Rol de Aplicación *',
                      prefixIcon: Icon(Icons.security),
                    ),
                    items: const [
                      DropdownMenuItem(value: AppRole.USER, child: Text('Usuario')),
                      DropdownMenuItem(value: AppRole.ADMIN, child: Text('Administrador')),
                      DropdownMenuItem(value: AppRole.SuperUser, child: Text('Super Usuario')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedAppRole = value;
                        });
                      }
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Seleccione un rol de aplicación';
                      }
                      return null;
                    },
                  ),

                  // Type-specific fields
                  if (_selectedUserType == UserType.DOCENTE) ...[
                    _buildSectionTitle('Información del Docente', Icons.school),
                    const SizedBox(height: 16),
                    _buildTeacherFields(),
                  ] else if (_selectedUserType == UserType.ADMIN_STAFF) ...[
                    _buildSectionTitle('Información Administrativa', Icons.business),
                    const SizedBox(height: 16),
                    _buildAdminStaffFields(),
                  ] else if (_selectedUserType == UserType.ESTUDIANTE) ...[
                    _buildSectionTitle('Información del Estudiante', Icons.school),
                    const SizedBox(height: 16),
                    _buildStudentFields(),
                  ] else if (_selectedUserType == UserType.ACUDIENTE) ...[
                    _buildSectionTitle('Información del Acudiente', Icons.family_restroom),
                    const SizedBox(height: 16),
                    _buildAcudienteFields(),
                  ],

                  const SizedBox(height: 24),

                  // Estado del Usuario (al final)
                  _buildSectionTitle('Estado del Usuario', Icons.info),
                  const SizedBox(height: 16),

                  // Active Status (read-only display)
                  ListTile(
                    title: const Text('Estado del Usuario'),
                    subtitle: Text(_isActive ? 'Usuario activo - puede acceder al sistema' : 'Usuario inactivo - no puede acceder al sistema'),
                    leading: Icon(
                      _isActive ? Icons.check_circle : Icons.cancel,
                      color: _isActive ? Colors.green : Colors.red,
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _isActive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _isActive ? Colors.green : Colors.red,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        _isActive ? 'ACTIVO' : 'INACTIVO',
                        style: TextStyle(
                          color: _isActive ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Guardar Cambios',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildTeacherFields() {
    return Column(
      children: [
        // School Position
        DropdownButtonFormField<SchoolPosition>(
          value: _schoolPosition,
          decoration: const InputDecoration(
            labelText: 'Cargo en la Institución *',
            prefixIcon: Icon(Icons.work),
          ),
          items: const [
            DropdownMenuItem(value: SchoolPosition.RECTOR, child: Text('Rector')),
            DropdownMenuItem(value: SchoolPosition.COORD_ACADEMICO_PRIMARIA, child: Text('Coordinador Académico Primaria')),
            DropdownMenuItem(value: SchoolPosition.COORD_ACADEMICO_SECUNDARIA, child: Text('Coordinador Académico Secundaria')),
            DropdownMenuItem(value: SchoolPosition.COORD_CONVIVENCIA, child: Text('Coordinador de Convivencia')),
            DropdownMenuItem(value: SchoolPosition.ADMINISTRATIVO, child: Text('Administrativo')),
            DropdownMenuItem(value: SchoolPosition.DOCENTE, child: Text('Docente')),
          ],
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _schoolPosition = value;
              });
            }
          },
          validator: (value) {
            if (value == null) {
              return 'Seleccione un cargo';
            }
            return null;
          },
        ),

        const SizedBox(height: 16),

        // Area of Study (only required for DOCENTE position)
        if (_schoolPosition == SchoolPosition.DOCENTE) ...[
          DropdownButtonFormField<String>(
            value: _areaOfStudy.isNotEmpty ? _areaOfStudy : null,
            decoration: const InputDecoration(
              labelText: 'Área de Estudio *',
              prefixIcon: Icon(Icons.subject),
            ),
            items: const [
              DropdownMenuItem(value: 'Matemáticas', child: Text('Matemáticas')),
              DropdownMenuItem(value: 'Estadística', child: Text('Estadística')),
              DropdownMenuItem(value: 'Ciencias', child: Text('Ciencias')),
              DropdownMenuItem(value: 'Lenguaje', child: Text('Lenguaje')),
              DropdownMenuItem(value: 'Sociales', child: Text('Sociales')),
              DropdownMenuItem(value: 'Inglés', child: Text('Inglés')),
              DropdownMenuItem(value: 'Arte', child: Text('Arte')),
              DropdownMenuItem(value: 'Educación Física', child: Text('Educación Física')),
              DropdownMenuItem(value: 'Tecnología', child: Text('Tecnología')),
              DropdownMenuItem(value: 'Religión', child: Text('Religión')),
              DropdownMenuItem(value: 'Ética', child: Text('Ética')),
              DropdownMenuItem(value: 'Filosofía', child: Text('Filosofía')),
            ],
            onChanged: (value) {
              setState(() {
                _areaOfStudy = value ?? '';
              });
            },
            validator: (value) {
              if (_schoolPosition == SchoolPosition.DOCENTE && (value == null || value.isEmpty)) {
                return 'Seleccione un área de estudio';
              }
              return null;
            },
          ),

          const SizedBox(height: 16),
        ],

        // Grade Level Assignment
        DropdownButtonFormField<GradeLevel>(
          value: _assignedToGradeLevel,
          decoration: const InputDecoration(
            labelText: 'Nivel Asignado',
            prefixIcon: Icon(Icons.grade),
          ),
          items: const [
            DropdownMenuItem(value: GradeLevel.PRIMARIA, child: Text('Primaria')),
            DropdownMenuItem(value: GradeLevel.BACHILLERATO, child: Text('Bachillerato')),
          ],
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _assignedToGradeLevel = value;
              });
            }
          },
        ),

        const SizedBox(height: 16),

        // Education Level
        DropdownButtonFormField<EducationLevel>(
          value: _educationLevel,
          decoration: const InputDecoration(
            labelText: 'Nivel de Educación',
            prefixIcon: Icon(Icons.school),
          ),
                      items: const [
              DropdownMenuItem(value: EducationLevel.PROFESIONAL, child: Text('Profesional')),
              DropdownMenuItem(value: EducationLevel.MAESTRIA, child: Text('Maestría')),
              DropdownMenuItem(value: EducationLevel.OTRO, child: Text('Otro')),
            ],
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _educationLevel = value;
              });
            }
          },
        ),

        if (_educationLevel == EducationLevel.OTRO) ...[
          const SizedBox(height: 16),
          TextFormField(
            initialValue: _educationLevelOther,
            decoration: const InputDecoration(
              labelText: 'Especifique Nivel de Educación',
              hintText: 'Ingrese el nivel de educación',
              prefixIcon: Icon(Icons.edit),
            ),
            onChanged: (value) => _educationLevelOther = value,
          ),
        ],

        const SizedBox(height: 16),

        // Special Assignment
        TextFormField(
          initialValue: _specialAssignment,
          decoration: const InputDecoration(
            labelText: 'Asignación Especial',
            hintText: 'Asignación especial (opcional)',
            prefixIcon: Icon(Icons.assignment),
          ),
          onChanged: (value) => _specialAssignment = value,
        ),

        const SizedBox(height: 16),

        // PTA Member
        CheckboxListTile(
          title: const Text('Miembro PTA'),
          subtitle: const Text('Padres y Maestros Asociados'),
          value: _isPTA,
          onChanged: (value) {
            setState(() {
              _isPTA = value ?? false;
            });
          },
          controlAffinity: ListTileControlAffinity.leading,
        ),

        const SizedBox(height: 16),

        // Teacher Roles
        _buildSectionTitle('Roles Adicionales', Icons.assignment_ind),
        const SizedBox(height: 8),
        Text(
          'Selecciona los roles adicionales que desempeña el docente:',
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 16),
        
        // Teacher Roles Grid
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 8,
          childAspectRatio: 2.5,
          children: [
            _buildRoleToggleButton('Representante Consejo Académico', TeacherRole.REPRESENTANTE_CONSEJO_ACADEMICO),
            _buildRoleToggleButton('Representante Comité Convivencia', TeacherRole.REPRESENTANTE_COMITE_CONVIVENCIA),
            _buildRoleToggleButton('Representante Consejo Directivo', TeacherRole.REPRESENTANTE_CONSEJO_DIRECTIVO),
            _buildRoleToggleButton('Líder de Proyecto', TeacherRole.LIDER_PROYECTO),
            _buildRoleToggleButton('Líder de Área', TeacherRole.LIDER_AREA),
            _buildRoleToggleButton('Director de Grupo', TeacherRole.DIRECTOR_GRUPO),
          ],
        ),
      ],
    );
  }

  Widget _buildAdminStaffFields() {
    return Column(
      children: [
        TextFormField(
          initialValue: _profession,
          decoration: const InputDecoration(
            labelText: 'Profesión',
            hintText: 'Ingrese la profesión',
            prefixIcon: Icon(Icons.work),
          ),
          onChanged: (value) => _profession = value,
        ),
      ],
    );
  }

  Widget _buildStudentFields() {
    return Column(
      children: [
        DropdownButtonFormField<SchoolGrade>(
          value: _schoolGrade,
          decoration: const InputDecoration(
            labelText: 'Grado Escolar *',
            prefixIcon: Icon(Icons.grade),
          ),
          items: const [
            DropdownMenuItem(value: SchoolGrade.PREESCOLAR, child: Text('Preescolar')),
            DropdownMenuItem(value: SchoolGrade.PRIMARIA_GRADO_1, child: Text('Primaria 1')),
            DropdownMenuItem(value: SchoolGrade.PRIMARIA_GRADO_2, child: Text('Primaria 2')),
            DropdownMenuItem(value: SchoolGrade.PRIMARIA_GRADO_3, child: Text('Primaria 3')),
            DropdownMenuItem(value: SchoolGrade.PRIMARIA_GRADO_4, child: Text('Primaria 4')),
            DropdownMenuItem(value: SchoolGrade.PRIMARIA_GRADO_5, child: Text('Primaria 5')),
            DropdownMenuItem(value: SchoolGrade.BACHILLERATO_GRADO_6, child: Text('Bachillerato 6')),
            DropdownMenuItem(value: SchoolGrade.BACHILLERATO_GRADO_7, child: Text('Bachillerato 7')),
            DropdownMenuItem(value: SchoolGrade.BACHILLERATO_GRADO_8, child: Text('Bachillerato 8')),
            DropdownMenuItem(value: SchoolGrade.BACHILLERATO_GRADO_9, child: Text('Bachillerato 9')),
            DropdownMenuItem(value: SchoolGrade.BACHILLERATO_GRADO_10, child: Text('Bachillerato 10')),
            DropdownMenuItem(value: SchoolGrade.BACHILLERATO_GRADO_11, child: Text('Bachillerato 11')),
          ],
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _schoolGrade = value;
              });
            }
          },
          validator: (value) {
            if (value == null) {
              return 'Seleccione un grado escolar';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildAcudienteFields() {
    return Column(
      children: [
        // Number of children represented
        DropdownButtonFormField<int>(
          value: _representedChildrenCount,
          decoration: const InputDecoration(
            labelText: 'Número de Estudiantes a Cargo',
            prefixIcon: Icon(Icons.family_restroom),
          ),
          items: List.generate(10, (index) => index + 1).map((count) {
            return DropdownMenuItem(
              value: count,
              child: Text('$count ${count == 1 ? 'estudiante' : 'estudiantes'}'),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _representedChildrenCount = value;
              });
            }
          },
        ),
      ],
    );
  }

  void _submitForm() async {
    print('EditUserForm: Iniciando _submitForm');
    print('EditUserForm: Estado actual del usuario - isActive: ${widget.user.isActive}');
    print('EditUserForm: Nuevo estado deseado - isActive: $_isActive');
    
    if (!_formKey.currentState!.validate()) {
      print('EditUserForm: Validación del formulario falló');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      print('EditUserForm: Creando TypeSpecificData...');
      // Create TypeSpecificData based on user type
      TypeSpecificData? typeSpecificData;
      
      switch (_selectedUserType) {
        case UserType.DOCENTE:
          typeSpecificData = TypeSpecificData(
            areaOfStudy: _areaOfStudy,
            assignedToGradeLevel: _assignedToGradeLevel,
            educationLevel: _educationLevel,
            educationLevelOther: _educationLevel == EducationLevel.OTRO ? _educationLevelOther : null,
            schoolPosition: _schoolPosition,
            specialAssignment: _specialAssignment.isNotEmpty ? _specialAssignment : null,
            isPTA: _isPTA,
            teacherRoles: _teacherRoles,
          );
          break;
        case UserType.ADMIN_STAFF:
          typeSpecificData = TypeSpecificData(
            profession: _profession,
          );
          break;
        case UserType.ESTUDIANTE:
          typeSpecificData = TypeSpecificData(
            schoolGrade: _schoolGrade,
          );
          break;
        case UserType.ACUDIENTE:
          typeSpecificData = TypeSpecificData(
            representedChildrenCount: _representedChildrenCount,
          );
          break;
      }

      print('EditUserForm: Creando UserModel actualizado...');
      // Create updated user model
      final updatedUser = UserModel(
        uid: widget.user.uid,
        email: widget.user.email,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        documentType: _selectedDocumentType,
        documentNumber: _documentNumberController.text.trim(),
        phone: _phoneController.text.trim(),
        userType: _selectedUserType,
        appRole: _selectedAppRole,
        status: widget.user.status,
        isActive: _isActive,
        provisionalPasswordSet: widget.user.provisionalPasswordSet,
        createdAt: widget.user.createdAt,
        updatedAt: DateTime.now(),
        typeSpecificData: typeSpecificData,
      );

      print('EditUserForm: UserModel creado - isActive: ${updatedUser.isActive}');

      // Update user using UserService
      final updates = {
        'firstName': updatedUser.firstName,
        'lastName': updatedUser.lastName,
        'documentNumber': updatedUser.documentNumber,
        'phone': updatedUser.phone,
        'documentType': updatedUser.documentType.name,
        'userType': updatedUser.userType.name,
        'appRole': updatedUser.appRole.name,
        'isActive': updatedUser.isActive,
        'updatedAt': updatedUser.updatedAt.toIso8601String(),
        'typeSpecificData': updatedUser.typeSpecificData?.toMap(),
      };
      
      print('EditUserForm: Enviando updates al UserService:');
      print('EditUserForm: Updates: $updates');
      print('EditUserForm: isActive en updates: ${updates['isActive']}');
      
      await _userService.updateUser(updatedUser.uid, updates);
      print('EditUserForm: UserService.updateUser completado');

      if (mounted) {
        // Refresh the data provider
        final dataProvider = context.read<DataProvider>();
        await dataProvider.loadUsers();

        // Close the form first
        Navigator.of(context).pop('success');
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Error inesperado: $e';
        
        if (e.toString().contains('permission-denied')) {
          errorMessage = 'Error de permisos: No tienes permisos para actualizar usuarios.';
        } else if (e.toString().contains('network')) {
          errorMessage = 'Error de conexión: Verifica tu conexión a internet.';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildRoleToggleButton(String label, TeacherRole role) {
    return GestureDetector(
      onTap: () {
        setState(() {
          if (_teacherRoles.contains(role)) {
            _teacherRoles.remove(role);
          } else {
            _teacherRoles.add(role);
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: _teacherRoles.contains(role) 
              ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
              : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: _teacherRoles.contains(role) 
                ? Theme.of(context).colorScheme.primary
                : Colors.grey,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Icon(
              _teacherRoles.contains(role) ? Icons.check_circle : Icons.circle_outlined,
              color: _teacherRoles.contains(role) 
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey,
              size: 16,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: _teacherRoles.contains(role) 
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey,
                  fontWeight: FontWeight.w500,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 