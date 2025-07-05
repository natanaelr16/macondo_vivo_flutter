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
  String _profession = '';

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
    _selectedDocumentType = user.documentType;
    _selectedUserType = user.userType;
    _selectedAppRole = user.appRole;

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
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
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

                  // Basic Information
                  _buildSectionTitle('Información Básica', Icons.person),
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
            decoration: const InputDecoration(
              labelText: 'Especifique Nivel de Educación *',
              hintText: 'Describa el nivel de educación',
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

        // Special Assignment
        TextFormField(
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
      ],
    );
  }

  Widget _buildAdminStaffFields() {
    return Column(
      children: [
        TextFormField(
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

  void _submitForm() async {
    if (!_formKey.currentState!.validate()) {
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
          // Keep existing data for acudiente
          typeSpecificData = widget.user.typeSpecificData;
          break;
      }

      // Create updated user model
      final updatedUser = UserModel(
        uid: widget.user.uid,
        email: widget.user.email,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        documentType: _selectedDocumentType,
        documentNumber: widget.user.documentNumber,
        phone: _phoneController.text.trim(),
        userType: _selectedUserType,
        appRole: _selectedAppRole,
        status: widget.user.status,
        isActive: widget.user.isActive,
        provisionalPasswordSet: widget.user.provisionalPasswordSet,
        createdAt: widget.user.createdAt,
        updatedAt: DateTime.now(),
        typeSpecificData: typeSpecificData,
      );

      // Update user using UserService
      final updates = {
        'firstName': updatedUser.firstName,
        'lastName': updatedUser.lastName,
        'phone': updatedUser.phone,
        'documentType': updatedUser.documentType.name,
        'userType': updatedUser.userType.name,
        'appRole': updatedUser.appRole.name,
        'updatedAt': updatedUser.updatedAt.toIso8601String(),
        'typeSpecificData': updatedUser.typeSpecificData?.toMap(),
      };
      
      await _userService.updateUser(updatedUser.uid, updates);

      if (mounted) {
        // Refresh the data provider
        final dataProvider = context.read<DataProvider>();
        await dataProvider.loadUsers();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Usuario actualizado exitosamente'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // Close the form
        Navigator.of(context).pop();
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
} 