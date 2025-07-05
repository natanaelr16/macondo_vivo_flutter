import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../../../shared/models/user_model.dart';
import '../../../../shared/services/user_service.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../../../shared/providers/data_provider.dart';
import '../../../../core/widgets/provisional_password_display.dart';


class CreateUserForm extends StatefulWidget {
  const CreateUserForm({super.key});

  @override
  State<CreateUserForm> createState() => _CreateUserFormState();
}

class _CreateUserFormState extends State<CreateUserForm> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isCheckingEmail = false;
  bool _emailExists = false;
  Timer? _emailCheckTimer;
  int _superUserCount = 0;

  // Services
  final UserService _userService = UserService();

  // Controllers
  final _emailController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _documentNumberController = TextEditingController();
  final _phoneController = TextEditingController();

  // Selected values
  DocumentType _selectedDocumentType = DocumentType.CC;
  UserType _selectedUserType = UserType.ESTUDIANTE;
  AppRole _selectedAppRole = AppRole.USER;

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
  final int _representedChildrenCount = 1;
  String _profession = '';

  // Student search fields for Acudiente
  final _studentSearchController = TextEditingController();
  List<UserModel> _allStudents = [];
  List<UserModel> _filteredStudents = [];
  final List<UserModel> _selectedStudents = [];
  final bool _isSearchingStudents = false;
  Timer? _studentSearchTimer;

  @override
  void initState() {
    super.initState();
    _loadSuperUserCount();
    _loadStudents();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _documentNumberController.dispose();
    _phoneController.dispose();
    _studentSearchController.dispose();
    _emailCheckTimer?.cancel();
    _studentSearchTimer?.cancel();
    super.dispose();
  }

  // Cargar conteo de SuperUsers
  Future<void> _loadSuperUserCount() async {
    try {
      final users = await _userService.getAllUsers();
      final superUserCount = users.where((user) => user.isSuperUser).length;
      if (mounted) {
        setState(() {
          _superUserCount = superUserCount;
        });
      }
    } catch (e) {
      print('Error loading super user count: $e');
    }
  }

  // Cargar estudiantes para búsqueda
  Future<void> _loadStudents() async {
    try {
      final users = await _userService.getAllUsers();
      final students = users.where((user) => user.userType == UserType.ESTUDIANTE).toList();
      if (mounted) {
        setState(() {
          _allStudents = students;
          _filteredStudents = students;
        });
      }
    } catch (e) {
      print('Error loading students: $e');
    }
  }

  // Buscar estudiantes
  void _searchStudents(String query) {
    _studentSearchTimer?.cancel();
    _studentSearchTimer = Timer(const Duration(milliseconds: 300), () {
      if (query.isEmpty) {
        setState(() {
          _filteredStudents = _allStudents;
        });
        return;
      }

      final filtered = _allStudents.where((student) {
        final searchLower = query.toLowerCase();
        return student.firstName.toLowerCase().contains(searchLower) ||
               student.lastName.toLowerCase().contains(searchLower) ||
               student.email.toLowerCase().contains(searchLower) ||
               student.documentNumber.toLowerCase().contains(searchLower);
      }).toList();

      setState(() {
        _filteredStudents = filtered;
      });
    });
  }

  // Agregar estudiante seleccionado
  void _addSelectedStudent(UserModel student) {
    if (!_selectedStudents.any((s) => s.uid == student.uid)) {
      setState(() {
        _selectedStudents.add(student);
      });
      _studentSearchController.clear();
      _searchStudents('');
    }
  }

  // Remover estudiante seleccionado
  void _removeSelectedStudent(UserModel student) {
    setState(() {
      _selectedStudents.removeWhere((s) => s.uid == student.uid);
    });
  }

  // Check if email exists
  Future<void> _checkEmailExists(String email) async {
    if (email.isEmpty || !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      setState(() {
        _emailExists = false;
        _isCheckingEmail = false;
      });
      return;
    }

    setState(() {
      _isCheckingEmail = true;
    });

    try {
      final exists = await _userService.emailExists(email);
      if (mounted) {
        setState(() {
          _emailExists = exists;
          _isCheckingEmail = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCheckingEmail = false;
        });
      }
    }
  }

  // Debounced email check
  void _onEmailChanged(String email) {
    _emailCheckTimer?.cancel();
    _emailCheckTimer = Timer(const Duration(milliseconds: 500), () {
      _checkEmailExists(email);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // Verificar permisos
        if (!authProvider.canCreateUsers) {
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
                      'No tienes permisos para crear usuarios.',
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
        title: const Text('Crear Usuario'),
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
                        Icon(Icons.info_outline, color: primaryColor),
                        const SizedBox(width: 8),
                        Text(
                          'Información del Usuario',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: primaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Complete todos los campos requeridos para crear un nuevo usuario en el sistema.',
                      style: TextStyle(
                        fontSize: 14,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Personal Information Section
              _buildSectionTitle('Información Personal', Icons.person),
              const SizedBox(height: 16),

              // First Name
              TextFormField(
                controller: _firstNameController,
                decoration: const InputDecoration(
                  labelText: 'Nombres *',
                  hintText: 'Ingrese los nombres',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Los nombres son requeridos';
                  }
                  if (value.trim().length < 2) {
                    return 'Los nombres deben tener al menos 2 caracteres';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Last Name
              TextFormField(
                controller: _lastNameController,
                decoration: const InputDecoration(
                  labelText: 'Apellidos *',
                  hintText: 'Ingrese los apellidos',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Los apellidos son requeridos';
                  }
                  if (value.trim().length < 2) {
                    return 'Los apellidos deben tener al menos 2 caracteres';
                  }
                  return null;
                },
              ),

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
                  DropdownMenuItem(value: DocumentType.TI, child: Text('Tarjeta de Identidad')),
                  DropdownMenuItem(value: DocumentType.CE, child: Text('Cédula de Extranjería')),
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

              // Document Number
              TextFormField(
                controller: _documentNumberController,
                decoration: const InputDecoration(
                  labelText: 'Número de Documento *',
                  hintText: 'Ingrese el número de documento',
                  prefixIcon: Icon(Icons.numbers),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El número de documento es requerido';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Phone
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Teléfono *',
                  hintText: 'Ingrese el número de teléfono',
                  prefixIcon: Icon(Icons.phone),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El teléfono es requerido';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Email
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Correo Electrónico *',
                  hintText: 'Ingrese el correo electrónico',
                  prefixIcon: const Icon(Icons.email),
                  suffixIcon: _isCheckingEmail
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: Padding(
                            padding: EdgeInsets.all(8.0),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : _emailController.text.isNotEmpty
                          ? Icon(
                              _emailExists ? Icons.error : Icons.check_circle,
                              color: _emailExists ? Colors.red : Colors.green,
                            )
                          : null,
                  errorText: _emailExists ? 'Este correo ya está registrado' : null,
                ),
                onChanged: _onEmailChanged,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El correo electrónico es requerido';
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                    return 'Ingrese un correo electrónico válido';
                  }
                  if (_emailExists) {
                    return 'Este correo ya está registrado';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // User Type and Role Section
              _buildSectionTitle('Tipo de Usuario y Rol', Icons.admin_panel_settings),
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
                  DropdownMenuItem(value: UserType.ACUDIENTE, child: Text('Acudiente/Padre de Familia')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedUserType = value;
                      // Reset role based on user type
                      if (value == UserType.ESTUDIANTE || value == UserType.ACUDIENTE) {
                        _selectedAppRole = AppRole.USER;
                      }
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

              // Información sobre límite de SuperUsers
              if (_superUserCount >= 2) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.orange, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Ya existen 2 SuperUsers en el sistema. No se pueden crear más.',
                          style: TextStyle(
                            color: Colors.orange[700],
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // App Role
              DropdownButtonFormField<AppRole>(
                value: _selectedAppRole,
                decoration: const InputDecoration(
                  labelText: 'Rol de Aplicación *',
                  prefixIcon: Icon(Icons.security),
                ),
                items: [
                  // Solo mostrar SuperUser si hay menos de 2
                  if (_superUserCount < 2) ...[
                    const DropdownMenuItem(value: AppRole.SuperUser, child: Text('Super Usuario')),
                  ],
                  const DropdownMenuItem(value: AppRole.ADMIN, child: Text('Administrador')),
                  const DropdownMenuItem(value: AppRole.USER, child: Text('Usuario')),
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
                    return 'Seleccione un rol';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

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
                _buildParentFields(),
              ],

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
                          'Crear Usuario',
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
        // School Position (moved to top)
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
                // Reset area of study when position changes
                if (value != SchoolPosition.DOCENTE) {
                  _areaOfStudy = '';
                }
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
              DropdownMenuItem(value: 'Tecnología', child: Text('Tecnología')),
              DropdownMenuItem(value: 'Castellano', child: Text('Castellano')),
              DropdownMenuItem(value: 'Cátedra Gabo', child: Text('Cátedra Gabo')),
              DropdownMenuItem(value: 'Biología', child: Text('Biología')),
              DropdownMenuItem(value: 'Química', child: Text('Química')),
              DropdownMenuItem(value: 'Física', child: Text('Física')),
              DropdownMenuItem(value: 'Sociales', child: Text('Sociales')),
              DropdownMenuItem(value: 'Religión', child: Text('Religión')),
              DropdownMenuItem(value: 'Ética y valores', child: Text('Ética y valores')),
              DropdownMenuItem(value: 'Filosofía', child: Text('Filosofía')),
              DropdownMenuItem(value: 'Educación física', child: Text('Educación física')),
              DropdownMenuItem(value: 'Artes escénicas', child: Text('Artes escénicas')),
              DropdownMenuItem(value: 'Música', child: Text('Música')),
              DropdownMenuItem(value: 'Artes plásticas', child: Text('Artes plásticas')),
              DropdownMenuItem(value: 'Inglés', child: Text('Inglés')),
              DropdownMenuItem(value: 'Otro', child: Text('Otro')),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _areaOfStudy = value;
                });
              }
            },
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Seleccione un área de estudio';
              }
              return null;
            },
          ),

          if (_areaOfStudy == 'Otro') ...[
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Especifique Área de Estudio *',
                hintText: 'Describa el área de estudio',
                prefixIcon: Icon(Icons.edit),
              ),
              onChanged: (value) => _areaOfStudy = value,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Especifique el área de estudio';
                }
                return null;
              },
            ),
          ],

          const SizedBox(height: 16),
        ],

        const SizedBox(height: 16),

        // Education Level
        DropdownButtonFormField<EducationLevel>(
          value: _educationLevel,
          decoration: const InputDecoration(
            labelText: 'Nivel de Educación *',
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
          validator: (value) {
            if (value == null) {
              return 'Seleccione un nivel de educación';
            }
            return null;
          },
        ),

        if (_educationLevel == EducationLevel.OTRO) ...[
          const SizedBox(height: 16),
          TextFormField(
            initialValue: _educationLevelOther,
            decoration: const InputDecoration(
              labelText: 'Especifique Otro Nivel *',
              hintText: 'Describa su nivel de educación',
              prefixIcon: Icon(Icons.edit),
            ),
            onChanged: (value) => _educationLevelOther = value,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Especifique el nivel de educación';
              }
              return null;
            },
          ),
        ],

        const SizedBox(height: 16),

        // Assigned Grade Level (only show if position is DOCENTE)
        if (_schoolPosition == SchoolPosition.DOCENTE) ...[
          DropdownButtonFormField<GradeLevel>(
            value: _assignedToGradeLevel,
            decoration: const InputDecoration(
              labelText: 'Nivel Asignado *',
              prefixIcon: Icon(Icons.grade),
            ),
            items: const [
              DropdownMenuItem(value: GradeLevel.PREESCOLAR, child: Text('Preescolar')),
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
            validator: (value) {
              if (value == null) {
                return 'Seleccione un nivel';
              }
              return null;
            },
          ),

          const SizedBox(height: 16),
        ],

        const SizedBox(height: 16),

        // Special Assignment
        TextFormField(
          initialValue: _specialAssignment,
          decoration: const InputDecoration(
            labelText: 'Asignación Especial',
            hintText: 'Ej: Coordinador de área, etc.',
            prefixIcon: Icon(Icons.assignment),
          ),
          onChanged: (value) => _specialAssignment = value,
        ),

        const SizedBox(height: 16),

        // Is PTA - Toggle Button
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '¿Es miembro de la PTA?',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isPTA = !_isPTA;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: _isPTA 
                        ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _isPTA 
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isPTA ? Icons.check_circle : Icons.circle_outlined,
                        color: _isPTA 
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isPTA ? 'Sí, es miembro PTA' : 'No es miembro PTA',
                        style: TextStyle(
                          color: _isPTA 
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Teacher Roles - Toggle Buttons
        Text(
          'Roles del Docente',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        
        // Roles en grid responsive
        LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount = constraints.maxWidth > 600 ? 3 : 2;
            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: crossAxisCount == 3 ? 3.5 : 2.8,
              children: [
                _buildRoleToggleButton(
                  'Representante\nConsejo Académico',
                  TeacherRole.REPRESENTANTE_CONSEJO_ACADEMICO,
                ),
                _buildRoleToggleButton(
                  'Representante\nComité Convivencia',
                  TeacherRole.REPRESENTANTE_COMITE_CONVIVENCIA,
                ),
                _buildRoleToggleButton(
                  'Líder de\nProyecto',
                  TeacherRole.LIDER_PROYECTO,
                ),
                _buildRoleToggleButton(
                  'Líder de\nÁrea',
                  TeacherRole.LIDER_AREA,
                ),
                _buildRoleToggleButton(
                  'Director de\nGrupo',
                  TeacherRole.DIRECTOR_GRUPO,
                ),
                _buildRoleToggleButton(
                  'Representante\nConsejo Directivo',
                  TeacherRole.REPRESENTANTE_CONSEJO_DIRECTIVO,
                ),
              ],
            );
          },
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
            labelText: 'Profesión *',
            hintText: 'Ej: Administrador, Contador, etc.',
            prefixIcon: Icon(Icons.work),
          ),
          onChanged: (value) => _profession = value,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'La profesión es requerida';
            }
            return null;
          },
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
            DropdownMenuItem(value: SchoolGrade.PRIMARIA_GRADO_1, child: Text('Primaria Grado 1')),
            DropdownMenuItem(value: SchoolGrade.PRIMARIA_GRADO_2, child: Text('Primaria Grado 2')),
            DropdownMenuItem(value: SchoolGrade.PRIMARIA_GRADO_3, child: Text('Primaria Grado 3')),
            DropdownMenuItem(value: SchoolGrade.PRIMARIA_GRADO_4, child: Text('Primaria Grado 4')),
            DropdownMenuItem(value: SchoolGrade.PRIMARIA_GRADO_5, child: Text('Primaria Grado 5')),
            DropdownMenuItem(value: SchoolGrade.BACHILLERATO_GRADO_6, child: Text('Bachillerato Grado 6')),
            DropdownMenuItem(value: SchoolGrade.BACHILLERATO_GRADO_7, child: Text('Bachillerato Grado 7')),
            DropdownMenuItem(value: SchoolGrade.BACHILLERATO_GRADO_8, child: Text('Bachillerato Grado 8')),
            DropdownMenuItem(value: SchoolGrade.BACHILLERATO_GRADO_9, child: Text('Bachillerato Grado 9')),
            DropdownMenuItem(value: SchoolGrade.BACHILLERATO_GRADO_10, child: Text('Bachillerato Grado 10')),
            DropdownMenuItem(value: SchoolGrade.BACHILLERATO_GRADO_11, child: Text('Bachillerato Grado 11')),
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
              return 'Seleccione un grado';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildParentFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Campo de búsqueda de estudiantes
        TextFormField(
          controller: _studentSearchController,
          decoration: InputDecoration(
            labelText: 'Buscar Estudiantes',
            hintText: 'Buscar por nombre, email o documento',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _studentSearchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _studentSearchController.clear();
                      _searchStudents('');
                    },
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
            ),
          ),
          onChanged: _searchStudents,
        ),

        const SizedBox(height: 16),

        // Lista de estudiantes filtrados
        if (_studentSearchController.text.isNotEmpty && _filteredStudents.isNotEmpty) ...[
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _filteredStudents.length,
              itemBuilder: (context, index) {
                final student = _filteredStudents[index];
                final isSelected = _selectedStudents.any((s) => s.uid == student.uid);
                
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isSelected 
                        ? Theme.of(context).colorScheme.primary 
                        : Colors.grey.shade200,
                    child: Icon(
                      isSelected ? Icons.check : Icons.person,
                      color: isSelected ? Colors.white : Colors.grey.shade600,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    '${student.firstName} ${student.lastName}',
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  subtitle: Text(
                    '${student.email} • ${student.documentNumber}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle, color: Colors.green, size: 20)
                      : IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: () => _addSelectedStudent(student),
                        ),
                  onTap: () {
                    if (isSelected) {
                      _removeSelectedStudent(student);
                    } else {
                      _addSelectedStudent(student);
                    }
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Estudiantes seleccionados
        if (_selectedStudents.isNotEmpty) ...[
          Text(
            'Estudiantes Asignados (${_selectedStudents.length})',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Column(
              children: _selectedStudents.map((student) {
                return Container(
                  margin: const EdgeInsets.all(8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.green.shade100,
                        child: Icon(
                          Icons.person,
                          color: Colors.green.shade700,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${student.firstName} ${student.lastName}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              student.email,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.remove_circle_outline,
                          color: Colors.red.shade400,
                          size: 20,
                        ),
                        onPressed: () => _removeSelectedStudent(student),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Mensaje informativo
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Colors.blue.shade600,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Busca y selecciona los estudiantes que representa este acudiente. Puedes buscar por nombre, email o número de documento.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue.shade700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validación adicional para SuperUsers
    if (_selectedAppRole == AppRole.SuperUser && _superUserCount >= 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pueden crear más de 2 SuperUsers en el sistema'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Additional validation for teachers based on position
    if (_selectedUserType == UserType.DOCENTE) {
      if (_schoolPosition == SchoolPosition.DOCENTE) {
        // For DOCENTE position, area of study and assigned grade level are required
        if (_areaOfStudy.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('El área de estudio es requerida para docentes de aula'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }
    }

    // Validation for Acudiente - must have at least one student
    if (_selectedUserType == UserType.ACUDIENTE && _selectedStudents.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debe seleccionar al menos un estudiante para el acudiente'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
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
            representedChildrenCount: _selectedStudents.length,
            representedStudentUIDs: _selectedStudents.map((s) => s.uid).toList(),
          );
          break;
      }

      // Create user model
      final user = UserModel(
        uid: '', // Will be set by Firestore
        email: _emailController.text.trim(),
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        documentType: _selectedDocumentType,
        documentNumber: _documentNumberController.text.trim(),
        phone: _phoneController.text.trim(),
        userType: _selectedUserType,
        appRole: _selectedAppRole,
        status: UserStatus.VERIFIED,
        isActive: true,
        provisionalPasswordSet: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        typeSpecificData: typeSpecificData,
      );

      // Create user using UserService
      final userService = UserService();
      final result = await userService.createUser(user);

      if (mounted) {
        // Actualizar la lista de usuarios en el DataProvider
        final dataProvider = Provider.of<DataProvider>(context, listen: false);
        await dataProvider.loadUsers();
        
        // Show success dialog with provisional password
        _showSuccessDialog(
          user: result.user,
          provisionalPassword: result.provisionalPassword,
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Error inesperado: $e';
        
        // Handle specific Firestore permission errors
        if (e.toString().contains('permission-denied')) {
          errorMessage = 'Error de permisos: No tienes permisos para crear usuarios en Firestore. '
              'Verifica las reglas de seguridad de Firebase.';
        } else if (e.toString().contains('network')) {
          errorMessage = 'Error de conexión: Verifica tu conexión a internet.';
        } else if (e.toString().contains('email-already-in-use')) {
          errorMessage = 'El email ya está registrado en el sistema.';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Cerrar',
              textColor: Colors.white,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
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

  void _showSuccessDialog({
    required UserModel user,
    required String provisionalPassword,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 28),
              SizedBox(width: 8),
              Text('Usuario Creado'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '✅ El usuario ha sido creado exitosamente.',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.green[700],
                  ),
                ),
                const SizedBox(height: 16),
                
                // User details
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.person, color: Colors.grey[600], size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Datos del Usuario',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.grey[800],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                      Text(
                                  '${user.firstName} ${user.lastName}',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[800],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  user.email,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Tipo: ${_getUserTypeDisplayName(user.userType)}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                          _buildRoleBadge(user.appRole),
                      ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Provisional password display
                ProvisionalPasswordDisplay(
                  userId: user.uid,
                  provisionalPasswordSet: true,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Close form and go back
              },
              child: const Text(
                'Cerrar',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
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
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: _teacherRoles.contains(role) 
              ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
              : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _teacherRoles.contains(role) 
                ? Theme.of(context).colorScheme.primary
                : Colors.grey,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _teacherRoles.contains(role) ? Icons.check_circle : Icons.circle_outlined,
              color: _teacherRoles.contains(role) 
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey,
              size: 16,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _teacherRoles.contains(role) 
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey,
                fontWeight: FontWeight.w500,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getUserTypeDisplayName(UserType userType) {
    switch (userType) {
      case UserType.DOCENTE:
        return 'Docente';
      case UserType.ADMIN_STAFF:
        return 'Administrativo';
      case UserType.ESTUDIANTE:
        return 'Estudiante';
      case UserType.ACUDIENTE:
        return 'Acudiente';
    }
  }

  Widget _buildRoleBadge(AppRole appRole) {
    Color badgeColor;
    IconData badgeIcon;
    String badgeText;

    switch (appRole) {
      case AppRole.SuperUser:
        badgeColor = Colors.purple;
        badgeIcon = Icons.admin_panel_settings;
        badgeText = 'SuperUser';
        break;
      case AppRole.ADMIN:
        badgeColor = Colors.red;
        badgeIcon = Icons.admin_panel_settings;
        badgeText = 'Administrador';
        break;
      case AppRole.USER:
        badgeColor = Colors.blue;
        badgeIcon = Icons.person;
        badgeText = 'Usuario';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: badgeColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            badgeIcon,
            size: 16,
            color: badgeColor,
          ),
          const SizedBox(width: 4),
          Text(
            badgeText,
            style: TextStyle(
              color: badgeColor,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
} 