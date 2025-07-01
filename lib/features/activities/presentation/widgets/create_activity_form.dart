import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../shared/providers/data_provider.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../../../shared/models/activity_model.dart';
import '../../../../shared/models/user_model.dart';

class CreateActivityForm extends StatefulWidget {
  const CreateActivityForm({super.key});

  @override
  State<CreateActivityForm> createState() => _CreateActivityFormState();
}

class _CreateActivityFormState extends State<CreateActivityForm> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Controllers for basic info
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _submissionLinkController = TextEditingController();
  final _estimatedDurationController = TextEditingController();

  // Activity properties
  int _numberOfSessions = 1;
  String _selectedCategory = 'Académica';
  String _status = 'ACTIVA';
  bool _adminCanEdit = true;

  // Lists for materials and objectives
  final List<String> _materials = [];
  final List<String> _objectives = [];
  final _materialController = TextEditingController();
  final _objectiveController = TextEditingController();

  // Session dates
  final List<DateTime> _sessionDates = [];

  // Participants and responsible users
  final List<String> _selectedParticipants = [];
  final List<String> _selectedResponsibleUsers = [];

  // Options
  final List<String> _categoryOptions = [
    'Académica',
    'Deportiva',
    'Cultural',
    'Social',
    'Administrativa',
    'Formativa',
    'Extracurricular',
  ];

  final List<String> _statusOptions = ['ACTIVA', 'INACTIVA', 'COMPLETADA'];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _submissionLinkController.dispose();
    _estimatedDurationController.dispose();
    _materialController.dispose();
    _objectiveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final backgroundColor = theme.colorScheme.background;
    final textColor = theme.colorScheme.onBackground;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Crear Actividad'),
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
                        Icon(Icons.assignment, color: primaryColor),
                        const SizedBox(width: 8),
                        Text(
                          'Nueva Actividad Escolar',
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
                      'Complete la información para crear una nueva actividad en el sistema.',
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

              // Title
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Título de la Actividad *',
                  hintText: 'Ingrese el título de la actividad',
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El título es requerido';
                  }
                  if (value.trim().length < 5) {
                    return 'El título debe tener al menos 5 caracteres';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Descripción *',
                  hintText: 'Describa detalladamente la actividad',
                  prefixIcon: Icon(Icons.description),
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'La descripción es requerida';
                  }
                  if (value.trim().length < 10) {
                    return 'La descripción debe tener al menos 10 caracteres';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Category
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Categoría *',
                  prefixIcon: Icon(Icons.category),
                ),
                items: _categoryOptions.map((category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedCategory = value;
                    });
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Seleccione una categoría';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // Sessions Section
              _buildSectionTitle('Configuración de Sesiones', textColor),
              const SizedBox(height: 16),

              // Number of Sessions
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: theme.colorScheme.outline),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Número de Sesiones *',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        IconButton(
                          onPressed: () {
                            if (_numberOfSessions > 1) {
                              setState(() {
                                _numberOfSessions--;
                                if (_sessionDates.length > _numberOfSessions) {
                                  _sessionDates.removeRange(_numberOfSessions, _sessionDates.length);
                                }
                              });
                            }
                          },
                          icon: const Icon(Icons.remove_circle_outline),
                        ),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              '$_numberOfSessions sesión${_numberOfSessions == 1 ? '' : 'es'}',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.titleLarge,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _numberOfSessions++;
                            });
                          },
                          icon: const Icon(Icons.add_circle_outline),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Session Dates
              if (_numberOfSessions > 0) ...[
                Text(
                  'Fechas de las Sesiones',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 8),
                ...List.generate(_numberOfSessions, (index) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: theme.colorScheme.outline),
                      ),
                      leading: Icon(Icons.calendar_today, color: primaryColor),
                      title: Text('Sesión ${index + 1}'),
                      subtitle: Text(
                        _sessionDates.length > index
                            ? _formatDate(_sessionDates[index])
                            : 'Seleccionar fecha',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _selectSessionDate(index),
                    ),
                  );
                }),
              ],

              const SizedBox(height: 24),

              // Additional Details Section
              _buildSectionTitle('Detalles Adicionales', textColor),
              const SizedBox(height: 16),

              // Estimated Duration
              TextFormField(
                controller: _estimatedDurationController,
                decoration: const InputDecoration(
                  labelText: 'Duración Estimada (minutos)',
                  hintText: '60',
                  prefixIcon: Icon(Icons.timer),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value != null && value.trim().isNotEmpty) {
                    final duration = int.tryParse(value.trim());
                    if (duration == null || duration <= 0) {
                      return 'Ingrese una duración válida en minutos';
                    }
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Submission Link
              TextFormField(
                controller: _submissionLinkController,
                decoration: const InputDecoration(
                  labelText: 'Enlace de Entrega',
                  hintText: 'https://classroom.google.com/...',
                  prefixIcon: Icon(Icons.link),
                ),
                keyboardType: TextInputType.url,
                validator: (value) {
                  if (value != null && value.trim().isNotEmpty) {
                    final uri = Uri.tryParse(value.trim());
                    if (uri == null || !uri.hasAbsolutePath) {
                      return 'Ingrese un enlace válido';
                    }
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // Materials Section
              _buildSectionTitle('Materiales Necesarios', textColor),
              const SizedBox(height: 16),
              _buildListManager(
                'Material',
                _materials,
                _materialController,
                'Agregar material necesario para la actividad',
                Icons.inventory,
              ),

              const SizedBox(height: 24),

              // Objectives Section
              _buildSectionTitle('Objetivos de Aprendizaje', textColor),
              const SizedBox(height: 16),
              _buildListManager(
                'Objetivo',
                _objectives,
                _objectiveController,
                'Agregar objetivo de aprendizaje',
                Icons.flag,
              ),

              const SizedBox(height: 24),

              // Participants Section
              _buildSectionTitle('Participantes y Responsables', textColor),
              const SizedBox(height: 16),
              _buildParticipantsSection(),

              const SizedBox(height: 24),

              // Status and Admin Settings
              _buildSectionTitle('Configuración', textColor),
              const SizedBox(height: 16),

              // Status
              DropdownButtonFormField<String>(
                value: _status,
                decoration: const InputDecoration(
                  labelText: 'Estado *',
                  prefixIcon: Icon(Icons.flag),
                ),
                items: _statusOptions.map((status) {
                  return DropdownMenuItem<String>(
                    value: status,
                    child: Text(_getStatusDisplayName(status)),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _status = value;
                    });
                  }
                },
              ),

              const SizedBox(height: 16),

              // Admin Can Edit
              SwitchListTile(
                title: const Text('Los administradores pueden editar'),
                subtitle: const Text('Permitir que otros administradores editen esta actividad'),
                value: _adminCanEdit,
                onChanged: (value) {
                  setState(() {
                    _adminCanEdit = value;
                  });
                },
                contentPadding: EdgeInsets.zero,
              ),

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
                      onPressed: _isLoading ? null : _createActivity,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text('Crear Actividad'),
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

  Widget _buildListManager(
    String itemName,
    List<String> items,
    TextEditingController controller,
    String hintText,
    IconData icon,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: hintText,
                  prefixIcon: Icon(icon),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  setState(() {
                    items.add(controller.text.trim());
                    controller.clear();
                  });
                }
              },
              icon: const Icon(Icons.add_circle),
            ),
          ],
        ),
        if (items.isNotEmpty) ...[
          const SizedBox(height: 8),
          ...items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
                ),
              ),
              child: Row(
                children: [
                  Expanded(child: Text(item)),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        items.removeAt(index);
                      });
                    },
                    icon: Icon(Icons.delete, color: Colors.red, size: 20),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ],
    );
  }

  Widget _buildParticipantsSection() {
    return Consumer<DataProvider>(
      builder: (context, dataProvider, child) {
        final users = dataProvider.users;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Usuarios disponibles: ${users.length}',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Los participantes y responsables se asignarán automáticamente según los permisos de usuario.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _selectSessionDate(int index) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        if (_sessionDates.length <= index) {
          _sessionDates.addAll(List.filled(index + 1 - _sessionDates.length, DateTime.now()));
        }
        _sessionDates[index] = picked;
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _getStatusDisplayName(String status) {
    switch (status) {
      case 'ACTIVA':
        return 'Activa';
      case 'INACTIVA':
        return 'Inactiva';
      case 'COMPLETADA':
        return 'Completada';
      default:
        return status;
    }
  }

  Future<void> _createActivity() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_sessionDates.length < _numberOfSessions) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor seleccione las fechas para todas las sesiones'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      final currentUser = authProvider.user;

      if (currentUser == null) {
        throw Exception('Usuario no autenticado');
      }

      await context.read<DataProvider>().createActivity(
        ActivityModel(
          activityId: '', // Will be set by Firestore
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          numberOfSessions: _numberOfSessions,
          sessionDates: _sessionDates.take(_numberOfSessions).toList().asMap().entries.map((entry) => SessionDate(
            sessionNumber: entry.key + 1,
            date: entry.value,
            startTime: '09:00',
            endTime: '10:00',
          )).toList(),
          submissionLink: _submissionLinkController.text.trim().isEmpty 
              ? null 
              : _submissionLinkController.text.trim(),
          category: _selectedCategory,
          estimatedDuration: _estimatedDurationController.text.trim().isEmpty 
              ? null 
              : int.tryParse(_estimatedDurationController.text.trim()),
          materials: _materials,
          objectives: _objectives,
          responsibleUsers: [], // Will be populated by the backend
          participants: [], // Will be populated by the backend
          status: ActivityStatus.values.firstWhere((e) => e.name == _status),
          adminCanEdit: _adminCanEdit,
          createdBy_uid: currentUser.uid,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          sessionCompletions: [],
        ),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Actividad creada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al crear actividad: ${e.toString()}'),
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
