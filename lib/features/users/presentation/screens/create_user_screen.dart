import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../../../shared/services/user_service.dart';

class CreateUserScreen extends StatefulWidget {
  const CreateUserScreen({super.key});

  @override
  State<CreateUserScreen> createState() => _CreateUserScreenState();
}

class _CreateUserScreenState extends State<CreateUserScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Controllers
  final _emailController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _documentNumberController = TextEditingController();
  final _phoneController = TextEditingController();
  final _schoolGradeController = TextEditingController();
  final _representedChildrenCountController = TextEditingController();
  final _areaOfStudyController = TextEditingController();
  final _schoolPositionController = TextEditingController();

  // Form data
  String _selectedUserType = 'DOCENTE';
  String _selectedAppRole = 'USER';
  String _selectedDocumentType = 'CC';
  String _selectedGradeLevel = 'TRANSICION';
  String _selectedEducationLevel = 'PRIMARIA';
  String _selectedTeacherRole = 'NINGUNO';

  // Options
  final List<String> _userTypes = ['DOCENTE', 'ESTUDIANTE', 'ACUDIENTE'];
  final List<String> _appRoles = ['USER', 'ADMIN', 'SuperUser'];
  final List<String> _documentTypes = ['CC', 'CE', 'TI', 'PP', 'NIT'];
  final List<String> _gradeLevels = ['TRANSICION', 'PRIMARIA', 'BACHILLERATO'];
  final List<String> _educationLevels = ['PRIMARIA', 'BACHILLERATO'];
  final List<String> _teacherRoles = [
    'NINGUNO',
    'REPRESENTANTE_CONSEJO_ACADEMICO',
    'REPRESENTANTE_COMITE_CONVIVENCIA',
    'REPRESENTANTE_CONSEJO_DIRECTIVO',
    'LIDER_PROYECTO',
    'LIDER_AREA',
    'DIRECTOR_GRUPO'
  ];

  @override
  void dispose() {
    _emailController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _documentNumberController.dispose();
    _phoneController.dispose();
    _schoolGradeController.dispose();
    _representedChildrenCountController.dispose();
    _areaOfStudyController.dispose();
    _schoolPositionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final backgroundColor = theme.colorScheme.surface;
    final textColor = theme.colorScheme.onSurface;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Crear Usuario'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
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
                        Icon(Icons.person_add, color: primaryColor),
                        const SizedBox(width: 8),
                        Text(
                          'Nuevo Usuario',
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
                      'Complete la información para crear un nuevo usuario en el sistema.',
                      style: TextStyle(
                        fontSize: 14,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Basic Information Section
              _buildSectionTitle('Información Básica', textColor),
              const SizedBox(height: 16),

              // User Type
              DropdownButtonFormField<String>(
                value: _selectedUserType,
                decoration: const InputDecoration(
                  labelText: 'Tipo de Usuario *',
                  prefixIcon: Icon(Icons.category),
                ),
                items: _userTypes.map((type) {
                  return DropdownMenuItem<String>(
                    value: type,
                    child: Text(_getUserTypeDisplayName(type)),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedUserType = value;
                      // Reset role-specific fields
                      _resetRoleSpecificFields();
                    });
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Seleccione un tipo de usuario';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // App Role
              DropdownButtonFormField<String>(
                value: _selectedAppRole,
                decoration: const InputDecoration(
                  labelText: 'Rol de Aplicación *',
                  prefixIcon: Icon(Icons.security),
                ),
                items: _appRoles.map((role) {
                  return DropdownMenuItem<String>(
                    value: role,
                    child: Text(_getAppRoleDisplayName(role)),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedAppRole = value;
                    });
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Seleccione un rol de aplicación';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Email
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Correo Electrónico *',
                  hintText: 'usuario@ejemplo.com',
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El correo electrónico es requerido';
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
                    return 'Ingrese un correo electrónico válido';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // First Name
              TextFormField(
                controller: _firstNameController,
                decoration: const InputDecoration(
                  labelText: 'Primer Nombre *',
                  hintText: 'Juan',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El primer nombre es requerido';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Last Name
              TextFormField(
                controller: _lastNameController,
                decoration: const InputDecoration(
                  labelText: 'Primer Apellido *',
                  hintText: 'Pérez',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El primer apellido es requerido';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Document Type
              DropdownButtonFormField<String>(
                value: _selectedDocumentType,
                decoration: const InputDecoration(
                  labelText: 'Tipo de Documento *',
                  prefixIcon: Icon(Icons.badge),
                ),
                items: _documentTypes.map((type) {
                  return DropdownMenuItem<String>(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedDocumentType = value;
                    });
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
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
                  hintText: '12345678',
                  prefixIcon: Icon(Icons.numbers),
                ),
                keyboardType: TextInputType.number,
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
                  hintText: '3001234567',
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El teléfono es requerido';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // Role-specific fields
              if (_selectedUserType == 'DOCENTE') ...[
                _buildSectionTitle('Información de Docente', textColor),
                const SizedBox(height: 16),
                
                // Area of Study
                TextFormField(
                  controller: _areaOfStudyController,
                  decoration: const InputDecoration(
                    labelText: 'Área de Estudio *',
                    hintText: 'Matemáticas, Ciencias, etc.',
                    prefixIcon: Icon(Icons.school),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'El área de estudio es requerida';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Assigned Grade Level
                DropdownButtonFormField<String>(
                  value: _selectedGradeLevel,
                  decoration: const InputDecoration(
                    labelText: 'Nivel Asignado *',
                    prefixIcon: Icon(Icons.grade),
                  ),
                  items: _gradeLevels.map((level) {
                    return DropdownMenuItem<String>(
                      value: level,
                      child: Text(_getGradeLevelDisplayName(level)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedGradeLevel = value;
                      });
                    }
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Seleccione un nivel asignado';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Education Level
                DropdownButtonFormField<String>(
                  value: _selectedEducationLevel,
                  decoration: const InputDecoration(
                    labelText: 'Nivel Educativo *',
                    prefixIcon: Icon(Icons.school),
                  ),
                  items: _educationLevels.map((level) {
                    return DropdownMenuItem<String>(
                      value: level,
                      child: Text(_getEducationLevelDisplayName(level)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedEducationLevel = value;
                      });
                    }
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Seleccione un nivel educativo';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // School Position
                TextFormField(
                  controller: _schoolPositionController,
                  decoration: const InputDecoration(
                    labelText: 'Cargo Escolar *',
                    hintText: 'Docente, Coordinador, etc.',
                    prefixIcon: Icon(Icons.work),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'El cargo escolar es requerido';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Teacher Role
                DropdownButtonFormField<String>(
                  value: _selectedTeacherRole,
                  decoration: const InputDecoration(
                    labelText: 'Rol de Docente',
                    prefixIcon: Icon(Icons.admin_panel_settings),
                  ),
                  items: _teacherRoles.map((role) {
                    return DropdownMenuItem<String>(
                      value: role,
                      child: Text(_getTeacherRoleDisplayName(role)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedTeacherRole = value;
                      });
                    }
                  },
                ),
              ],

              if (_selectedUserType == 'ESTUDIANTE') ...[
                _buildSectionTitle('Información de Estudiante', textColor),
                const SizedBox(height: 16),
                
                // School Grade
                TextFormField(
                  controller: _schoolGradeController,
                  decoration: const InputDecoration(
                    labelText: 'Grado Escolar *',
                    hintText: '1°, 2°, 3°, etc.',
                    prefixIcon: Icon(Icons.grade),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'El grado escolar es requerido';
                    }
                    return null;
                  },
                ),
              ],

              if (_selectedUserType == 'ACUDIENTE') ...[
                _buildSectionTitle('Información de Acudiente', textColor),
                const SizedBox(height: 16),
                
                // Represented Children Count
                TextFormField(
                  controller: _representedChildrenCountController,
                  decoration: const InputDecoration(
                    labelText: 'Número de Hijos Representados *',
                    hintText: '1, 2, 3, etc.',
                    prefixIcon: Icon(Icons.family_restroom),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'El número de hijos es requerido';
                    }
                    final count = int.tryParse(value.trim());
                    if (count == null || count <= 0) {
                      return 'Ingrese un número válido';
                    }
                    return null;
                  },
                ),
              ],

              const SizedBox(height: 32),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : () {
                        Navigator.of(context).pop();
                      },
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _createUser,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text('Crear Usuario'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color textColor) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: textColor,
      ),
    );
  }

  void _resetRoleSpecificFields() {
    _schoolGradeController.clear();
    _representedChildrenCountController.clear();
    _areaOfStudyController.clear();
    _schoolPositionController.clear();
    _selectedGradeLevel = 'TRANSICION';
    _selectedEducationLevel = 'PRIMARIA';
    _selectedTeacherRole = 'NINGUNO';
  }

  String _getUserTypeDisplayName(String type) {
    switch (type) {
      case 'DOCENTE':
        return 'Docente';
      case 'ESTUDIANTE':
        return 'Estudiante';
      case 'ACUDIENTE':
        return 'Acudiente';
      default:
        return type;
    }
  }

  String _getAppRoleDisplayName(String role) {
    switch (role) {
      case 'USER':
        return 'Usuario';
      case 'ADMIN':
        return 'Administrador';
      case 'SuperUser':
        return 'Super Usuario';
      default:
        return role;
    }
  }

  String _getGradeLevelDisplayName(String level) {
    switch (level) {
      case 'TRANSICION':
        return 'Transición';
      case 'PRIMARIA':
        return 'Primaria';
      case 'BACHILLERATO':
        return 'Bachillerato';
      default:
        return level;
    }
  }

  String _getEducationLevelDisplayName(String level) {
    switch (level) {
      case 'PRIMARIA':
        return 'Primaria';
      case 'BACHILLERATO':
        return 'Bachillerato';
      default:
        return level;
    }
  }

  String _getTeacherRoleDisplayName(String role) {
    switch (role) {
      case 'NINGUNO':
        return 'Ninguno';
      case 'REPRESENTANTE_CONSEJO_ACADEMICO':
        return 'Representante Consejo Académico';
      case 'REPRESENTANTE_COMITE_CONVIVENCIA':
        return 'Representante Comité Convivencia';
      case 'REPRESENTANTE_CONSEJO_DIRECTIVO':
        return 'Representante Consejo Directivo';
      case 'LIDER_PROYECTO':
        return 'Líder de Proyecto';
      case 'LIDER_AREA':
        return 'Líder de Área';
      case 'DIRECTOR_GRUPO':
        return 'Director de Grupo';
      default:
        return role;
    }
  }

  Future<void> _createUser() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      final currentUser = authProvider.userData;

      if (currentUser == null) {
        throw Exception('Usuario no autenticado');
      }

      // Validate permissions
      if (currentUser.appRole != 'SuperUser') {
        throw Exception('No tienes permisos para crear usuarios');
      }

      final userData = {
        'email': _emailController.text.trim(),
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'documentType': _selectedDocumentType,
        'documentNumber': _documentNumberController.text.trim(),
        'phone': _phoneController.text.trim(),
        'userType': _selectedUserType,
        'appRole': _selectedAppRole,
        'isActive': true,
        'provisionalPasswordSet': true,
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      };

      // Add role-specific fields
      if (_selectedUserType == 'DOCENTE') {
        userData['areaOfStudy'] = _areaOfStudyController.text.trim();
        userData['assignedToGradeLevel'] = _selectedGradeLevel;
        userData['educationLevel'] = _selectedEducationLevel;
        userData['schoolPosition'] = _schoolPositionController.text.trim();
        userData['teacherRole'] = _selectedTeacherRole;
      } else if (_selectedUserType == 'ESTUDIANTE') {
        userData['schoolGrade'] = _schoolGradeController.text.trim();
      } else if (_selectedUserType == 'ACUDIENTE') {
        userData['representedChildrenCount'] = int.parse(_representedChildrenCountController.text.trim());
      }

      final userService = UserService();
      await userService.createUser(userData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Usuario creado exitosamente. Se ha enviado un email para configurar la contraseña.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al crear usuario: ${e.toString()}'),
            backgroundColor: Colors.red,
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
} 