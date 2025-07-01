import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/providers/data_provider.dart';
import '../../../../shared/models/user_model.dart';

class CreateUserForm extends StatefulWidget {
  const CreateUserForm({super.key});

  @override
  State<CreateUserForm> createState() => _CreateUserFormState();
}

class _CreateUserFormState extends State<CreateUserForm> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

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
  TeacherLevel _teacherLevel = TeacherLevel.PRIMARIA;
  bool _isPTA = false;
  List<TeacherRole> _teacherRoles = [];
  SchoolGrade _schoolGrade = SchoolGrade.PRIMARIA_GRADO_1;
  int _representedChildrenCount = 1;
  String _profession = '';

  @override
  void dispose() {
    _emailController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _documentNumberController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
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
                        color: theme.colorScheme.onBackground,
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
                items: [
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
                decoration: const InputDecoration(
                  labelText: 'Correo Electrónico *',
                  hintText: 'Ingrese el correo electrónico',
                  prefixIcon: Icon(Icons.email),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El correo electrónico es requerido';
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                    return 'Ingrese un correo electrónico válido';
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
                items: [
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

              // App Role
              DropdownButtonFormField<AppRole>(
                value: _selectedAppRole,
                decoration: const InputDecoration(
                  labelText: 'Rol de Aplicación *',
                  prefixIcon: Icon(Icons.security),
                ),
                items: [
                  DropdownMenuItem(value: AppRole.SuperUser, child: Text('Super Usuario')),
                  DropdownMenuItem(value: AppRole.ADMIN, child: Text('Administrador')),
                  DropdownMenuItem(value: AppRole.USER, child: Text('Usuario')),
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
            color: Theme.of(context).colorScheme.onBackground,
          ),
        ),
      ],
    );
  }

  Widget _buildTeacherFields() {
    return Column(
      children: [
        // Area of Study
        TextFormField(
          initialValue: _areaOfStudy,
          decoration: const InputDecoration(
            labelText: 'Área de Estudio *',
            hintText: 'Ej: Matemáticas, Ciencias, etc.',
            prefixIcon: Icon(Icons.subject),
          ),
          onChanged: (value) => _areaOfStudy = value,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'El área de estudio es requerida';
            }
            return null;
          },
        ),

        const SizedBox(height: 16),

        // Assigned Grade Level
        DropdownButtonFormField<GradeLevel>(
          value: _assignedToGradeLevel,
          decoration: const InputDecoration(
            labelText: 'Nivel Asignado *',
            prefixIcon: Icon(Icons.grade),
          ),
          items: [
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

        // Education Level
        DropdownButtonFormField<EducationLevel>(
          value: _educationLevel,
          decoration: const InputDecoration(
            labelText: 'Nivel de Educación *',
            prefixIcon: Icon(Icons.school),
          ),
          items: [
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

        // School Position
        DropdownButtonFormField<SchoolPosition>(
          value: _schoolPosition,
          decoration: const InputDecoration(
            labelText: 'Cargo en la Institución *',
            prefixIcon: Icon(Icons.work),
          ),
          items: [
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

        // Teacher Level
        DropdownButtonFormField<TeacherLevel>(
          value: _teacherLevel,
          decoration: const InputDecoration(
            labelText: 'Nivel del Docente *',
            prefixIcon: Icon(Icons.person_pin),
          ),
          items: [
            DropdownMenuItem(value: TeacherLevel.TRANSICION, child: Text('Transición')),
            DropdownMenuItem(value: TeacherLevel.PRIMARIA, child: Text('Primaria')),
            DropdownMenuItem(value: TeacherLevel.BACHILLERATO, child: Text('Bachillerato')),
          ],
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _teacherLevel = value;
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

        // Is PTA
        CheckboxListTile(
          title: const Text('¿Es miembro de la PTA?'),
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
        Text(
          'Roles del Docente',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onBackground,
          ),
        ),
        const SizedBox(height: 8),
        CheckboxListTile(
          title: const Text('Representante Consejo Académico'),
          value: _teacherRoles.contains(TeacherRole.REPRESENTANTE_CONSEJO_ACADEMICO),
          onChanged: (value) {
            setState(() {
              if (value == true) {
                _teacherRoles.add(TeacherRole.REPRESENTANTE_CONSEJO_ACADEMICO);
              } else {
                _teacherRoles.remove(TeacherRole.REPRESENTANTE_CONSEJO_ACADEMICO);
              }
            });
          },
          controlAffinity: ListTileControlAffinity.leading,
        ),
        CheckboxListTile(
          title: const Text('Representante Comité Convivencia'),
          value: _teacherRoles.contains(TeacherRole.REPRESENTANTE_COMITE_CONVIVENCIA),
          onChanged: (value) {
            setState(() {
              if (value == true) {
                _teacherRoles.add(TeacherRole.REPRESENTANTE_COMITE_CONVIVENCIA);
              } else {
                _teacherRoles.remove(TeacherRole.REPRESENTANTE_COMITE_CONVIVENCIA);
              }
            });
          },
          controlAffinity: ListTileControlAffinity.leading,
        ),
        CheckboxListTile(
          title: const Text('Líder de Proyecto'),
          value: _teacherRoles.contains(TeacherRole.LIDER_PROYECTO),
          onChanged: (value) {
            setState(() {
              if (value == true) {
                _teacherRoles.add(TeacherRole.LIDER_PROYECTO);
              } else {
                _teacherRoles.remove(TeacherRole.LIDER_PROYECTO);
              }
            });
          },
          controlAffinity: ListTileControlAffinity.leading,
        ),
        CheckboxListTile(
          title: const Text('Líder de Área'),
          value: _teacherRoles.contains(TeacherRole.LIDER_AREA),
          onChanged: (value) {
            setState(() {
              if (value == true) {
                _teacherRoles.add(TeacherRole.LIDER_AREA);
              } else {
                _teacherRoles.remove(TeacherRole.LIDER_AREA);
              }
            });
          },
          controlAffinity: ListTileControlAffinity.leading,
        ),
        CheckboxListTile(
          title: const Text('Director de Grupo'),
          value: _teacherRoles.contains(TeacherRole.DIRECTOR_GRUPO),
          onChanged: (value) {
            setState(() {
              if (value == true) {
                _teacherRoles.add(TeacherRole.DIRECTOR_GRUPO);
              } else {
                _teacherRoles.remove(TeacherRole.DIRECTOR_GRUPO);
              }
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
          items: [
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
      children: [
        TextFormField(
          initialValue: _representedChildrenCount.toString(),
          decoration: const InputDecoration(
            labelText: 'Número de Hijos Representados *',
            hintText: 'Ingrese el número de hijos',
            prefixIcon: Icon(Icons.family_restroom),
          ),
          keyboardType: TextInputType.number,
          onChanged: (value) {
            _representedChildrenCount = int.tryParse(value) ?? 1;
          },
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'El número de hijos es requerido';
            }
            final count = int.tryParse(value);
            if (count == null || count < 1) {
              return 'Ingrese un número válido mayor a 0';
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
            teacherLevel: _teacherLevel,
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
            representedStudentUIDs: [],
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

      // Generate provisional password
      final provisionalPassword = _generateProvisionalPassword();

      // Create user
      final dataProvider = Provider.of<DataProvider>(context, listen: false);
      await dataProvider.createUser(user, provisionalPassword);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Usuario creado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al crear usuario: $e'),
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

  String _generateProvisionalPassword() {
    const length = 12;
    const charset = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#\$%^&*';
    String password = '';
    for (int i = 0; i < length; i++) {
      final randomIndex = (DateTime.now().millisecondsSinceEpoch % charset.length);
      password += charset[randomIndex];
    }
    return password;
  }
} 