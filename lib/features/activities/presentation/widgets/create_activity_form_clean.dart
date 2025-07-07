import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../shared/models/user_model.dart';
import '../../../../shared/providers/data_provider.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../../../shared/services/activity_service.dart';
import '../../../../shared/models/activity_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../shared/utils/date_utils.dart' as AppDateUtils;

class CreateActivityForm extends StatefulWidget {
  const CreateActivityForm({super.key});

  @override
  State<CreateActivityForm> createState() => _CreateActivityFormState();
}

class _CreateActivityFormState extends State<CreateActivityForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _estimatedDurationController = TextEditingController();
  final _submissionLinkController = TextEditingController();
  
  String? _selectedCategory;
  int _numberOfSessions = 1;
  List<Map<String, dynamic>> _sessionDates = [];
  final List<String> _selectedResponsibleUsers = [];
  final List<String> _selectedParticipants = [];
  
  // Controllers for user search
  final _responsibleSearchController = TextEditingController();
  final _participantsSearchController = TextEditingController();

  final List<String> _categoryOptions = [
    'Matemáticas',
    'Ciencias',
    'Lenguaje',
    'Historia',
    'Geografía',
    'Arte',
    'Música',
    'Deportes',
    'Tecnología',
    'Otros',
  ];

  @override
  void initState() {
    super.initState();
    
    // Initialize session dates with current date
    final now = AppDateUtils.DateUtils.getCurrentLocalDateTime();
    _sessionDates = [
      {
        'sessionNumber': 1,
        'date': AppDateUtils.DateUtils.getCurrentDateString(),
        'startTime': '09:00',
        'endTime': '10:00',
        'location': '',
      },
    ];
    
    // Add more sessions if needed
    for (int i = 2; i <= _numberOfSessions; i++) {
      final nextDate = now.add(Duration(days: (i - 1) * 7));
      _sessionDates.add({
        'sessionNumber': i,
        'date': AppDateUtils.DateUtils.formatDateOnly(nextDate).split('/').reversed.join('-'),
        'startTime': '09:00',
        'endTime': '10:00',
        'location': '',
      });
    }
    
    _loadUsers();
  }

  void _loadUsers() async {
    try {
      final dataProvider = context.read<DataProvider>();
      
      // Verificar si ya hay usuarios cargados
      if (dataProvider.users.isNotEmpty) {
        return;
      }
      
      await dataProvider.loadUsers();
      
      // Forzar rebuild del widget
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      // Mostrar error al usuario
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar usuarios: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _estimatedDurationController.dispose();
    _submissionLinkController.dispose();
    _responsibleSearchController.dispose();
    _participantsSearchController.dispose();
    super.dispose();
  }

  // Limpiar formulario
  void _clearForm() {
    setState(() {
      _titleController.clear();
      _descriptionController.clear();
      _selectedCategory = null;
      _numberOfSessions = 1;
      _sessionDates = [
        {
          'sessionNumber': 1,
          'date': AppDateUtils.DateUtils.getCurrentDateString(),
          'startTime': '09:00',
          'endTime': '10:00',
          'location': '',
        },
      ];
      _selectedResponsibleUsers.clear();
      _selectedParticipants.clear();
      _estimatedDurationController.clear();
      _submissionLinkController.clear();
      _responsibleSearchController.clear();
      _participantsSearchController.clear();
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Formulario limpiado'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _addSession() {
    setState(() {
      final lastSession = _sessionDates.last;
      final lastDate = DateTime.parse(lastSession['date']);
      final nextDate = lastDate.add(const Duration(days: 7));
      
      _sessionDates.add({
        'sessionNumber': _sessionDates.length + 1,
        'date': nextDate.toIso8601String().split('T')[0],
        'startTime': '08:00',
        'endTime': '09:00',
      });
      _numberOfSessions = _sessionDates.length;
    });
  }

  void _removeSession(int index) {
    setState(() {
      _sessionDates.removeAt(index);
      // Reorder session numbers
      for (int i = 0; i < _sessionDates.length; i++) {
        _sessionDates[i]['sessionNumber'] = i + 1;
      }
      _numberOfSessions = _sessionDates.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final backgroundColor = theme.colorScheme.surface;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Crear Actividad'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 56,
        actions: [
          // Botón para limpiar formulario
          IconButton(
            icon: const Icon(Icons.clear_all),
            tooltip: 'Limpiar formulario',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Limpiar formulario'),
                  content: const Text('¿Estás seguro de que quieres limpiar todo el formulario? Esta acción no se puede deshacer.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancelar'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _clearForm();
                      },
                      child: const Text('Limpiar'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: DraggableScrollableSheet(
          initialChildSize: 0.98,
          minChildSize: 0.7,
          maxChildSize: 0.98,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Drag handle
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),

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
                                'Información de la Actividad',
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
                            'Complete todos los campos requeridos para crear una nueva actividad educativa.',
                            style: TextStyle(
                              fontSize: 14,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Basic Information Section
                    _buildSectionTitle('Información Básica'),
                    const SizedBox(height: 12),

                    // Title
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Título *',
                        hintText: 'Título de la actividad',
                        prefixIcon: Icon(Icons.title),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'El título es requerido';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 12),

                    // Description
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Descripción *',
                        hintText: 'Descripción de la actividad',
                        prefixIcon: Icon(Icons.description),
                      ),
                      maxLines: 2,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'La descripción es requerida';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 12),

                    // Category and Duration Row
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              labelText: 'Categoría',
                              prefixIcon: Icon(Icons.category),
                            ),
                            value: _selectedCategory,
                            items: _categoryOptions.map((category) {
                              return DropdownMenuItem<String>(
                                value: category,
                                child: Text(category),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedCategory = value;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _estimatedDurationController,
                            decoration: const InputDecoration(
                              labelText: 'Duración (min)',
                              prefixIcon: Icon(Icons.timer),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Submission Link
                    TextFormField(
                      controller: _submissionLinkController,
                      decoration: const InputDecoration(
                        labelText: 'Enlace para Entregas',
                        hintText: 'https://ejemplo.com/entregas',
                        prefixIcon: Icon(Icons.link),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Sessions Section
                    _buildSectionTitle('Sesiones'),
                    const SizedBox(height: 12),

                    // Sessions list
                    ..._sessionDates.asMap().entries.map((entry) {
                      final index = entry.key;
                      final session = entry.value;
                      return _buildSessionCard(index, session);
                    }),

                    // Add session button
                    Center(
                      child: TextButton.icon(
                        onPressed: _addSession,
                        icon: const Icon(Icons.add),
                        label: const Text('Agregar Sesión'),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Participants Section
                    _buildSectionTitle('Participantes'),
                    const SizedBox(height: 12),

                    _buildParticipantsSection(),

                    const SizedBox(height: 32),

                    // Create Activity Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveActivity,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 2,
                        ),
                        child: const Text(
                          'Crear Actividad',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20), // Bottom padding
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildSessionCard(int index, Map<String, dynamic> session) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final textColor = theme.colorScheme.onSurface;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Sesión ${session['sessionNumber']}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              const Spacer(),
              if (_sessionDates.length > 1)
                IconButton(
                  onPressed: () => _removeSession(index),
                  icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Date picker
          InkWell(
            onTap: () => _selectSessionDate(index),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: theme.colorScheme.outline),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: primaryColor),
                  const SizedBox(width: 8),
                  Text(
                    _formatDate(DateTime.parse(session['date'])),
                    style: TextStyle(color: textColor),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Time pickers
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => _selectSessionTime(index, 'startTime'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: theme.colorScheme.outline),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.access_time, size: 16, color: primaryColor),
                        const SizedBox(width: 8),
                        Text(
                          session['startTime'],
                          style: TextStyle(color: textColor),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: InkWell(
                  onTap: () => _selectSessionTime(index, 'endTime'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: theme.colorScheme.outline),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.access_time, size: 16, color: primaryColor),
                        const SizedBox(width: 8),
                        Text(
                          session['endTime'],
                          style: TextStyle(color: textColor),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Location
          TextFormField(
            initialValue: session['location'] ?? '',
            decoration: const InputDecoration(
              labelText: 'Ubicación',
              hintText: 'Aula, sala, etc.',
              prefixIcon: Icon(Icons.location_on, size: 16),
            ),
            onChanged: (value) {
              setState(() {
                _sessionDates[index]['location'] = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantsSection() {
    final dataProvider = context.read<DataProvider>();
    final users = dataProvider.users;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Responsibles Section
        Text(
          'Responsables',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        
        // Responsibles search
        TextFormField(
          controller: _responsibleSearchController,
          decoration: const InputDecoration(
            labelText: 'Buscar responsables',
            hintText: 'Escribe para buscar usuarios...',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (value) {
            setState(() {});
          },
        ),
        
        const SizedBox(height: 8),
        
        // Responsibles list
        if (_responsibleSearchController.text.isNotEmpty)
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: users.where((user) => 
                user.firstName.toLowerCase().contains(_responsibleSearchController.text.toLowerCase()) ||
                user.lastName.toLowerCase().contains(_responsibleSearchController.text.toLowerCase()) ||
                user.email.toLowerCase().contains(_responsibleSearchController.text.toLowerCase())
              ).length,
              itemBuilder: (context, index) {
                final filteredUsers = users.where((user) => 
                  user.firstName.toLowerCase().contains(_responsibleSearchController.text.toLowerCase()) ||
                  user.lastName.toLowerCase().contains(_responsibleSearchController.text.toLowerCase()) ||
                  user.email.toLowerCase().contains(_responsibleSearchController.text.toLowerCase())
                ).toList();
                final user = filteredUsers[index];
                final isSelected = _selectedResponsibleUsers.contains(user.uid);
                
                return ListTile(
                  title: Text('${user.firstName} ${user.lastName}'),
                  subtitle: Text(user.email),
                  leading: CircleAvatar(
                    child: Text(user.firstName[0]),
                  ),
                  trailing: Icon(
                    isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: isSelected ? Colors.green : Colors.grey,
                  ),
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedResponsibleUsers.remove(user.uid);
                      } else {
                        _selectedResponsibleUsers.add(user.uid);
                      }
                    });
                  },
                );
              },
            ),
          ),
        
        // Selected responsibles
        if (_selectedResponsibleUsers.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _selectedResponsibleUsers.map((userId) {
              final user = users.firstWhere((u) => u.uid == userId);
              return Chip(
                label: Text('${user.firstName} ${user.lastName}'),
                onDeleted: () {
                  setState(() {
                    _selectedResponsibleUsers.remove(userId);
                  });
                },
              );
            }).toList(),
          ),
        ],
        
        const SizedBox(height: 20),
        
        // Participants Section
        Text(
          'Participantes',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        
        // Participants search
        TextFormField(
          controller: _participantsSearchController,
          decoration: const InputDecoration(
            labelText: 'Buscar participantes',
            hintText: 'Escribe para buscar usuarios...',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (value) {
            setState(() {});
          },
        ),
        
        const SizedBox(height: 8),
        
        // Participants list
        if (_participantsSearchController.text.isNotEmpty)
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: users.where((user) => 
                user.firstName.toLowerCase().contains(_participantsSearchController.text.toLowerCase()) ||
                user.lastName.toLowerCase().contains(_participantsSearchController.text.toLowerCase()) ||
                user.email.toLowerCase().contains(_participantsSearchController.text.toLowerCase())
              ).length,
              itemBuilder: (context, index) {
                final filteredUsers = users.where((user) => 
                  user.firstName.toLowerCase().contains(_participantsSearchController.text.toLowerCase()) ||
                  user.lastName.toLowerCase().contains(_participantsSearchController.text.toLowerCase()) ||
                  user.email.toLowerCase().contains(_participantsSearchController.text.toLowerCase())
                ).toList();
                final user = filteredUsers[index];
                final isSelected = _selectedParticipants.contains(user.uid);
                
                return ListTile(
                  title: Text('${user.firstName} ${user.lastName}'),
                  subtitle: Text(user.email),
                  leading: CircleAvatar(
                    child: Text(user.firstName[0]),
                  ),
                  trailing: Icon(
                    isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: isSelected ? Colors.green : Colors.grey,
                  ),
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedParticipants.remove(user.uid);
                      } else {
                        _selectedParticipants.add(user.uid);
                      }
                    });
                  },
                );
              },
            ),
          ),
        
        // Selected participants
        if (_selectedParticipants.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _selectedParticipants.map((userId) {
              final user = users.firstWhere((u) => u.uid == userId);
              return Chip(
                label: Text('${user.firstName} ${user.lastName}'),
                onDeleted: () {
                  setState(() {
                    _selectedParticipants.remove(userId);
                  });
                },
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Future<void> _selectSessionDate(int index) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.parse(_sessionDates[index]['date']),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (picked != null) {
      setState(() {
        _sessionDates[index]['date'] = picked.toIso8601String().split('T')[0];
      });
    }
  }

  Future<void> _selectSessionTime(int index, String timeType) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
        DateTime.parse('2023-01-01 ${_sessionDates[index][timeType]}:00'),
      ),
    );
    
    if (picked != null) {
      setState(() {
        _sessionDates[index][timeType] = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Future<void> _saveActivity() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedResponsibleUsers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debe seleccionar al menos un responsable'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final authProvider = context.read<AuthProvider>();
      final currentUser = authProvider.user;
      
      if (currentUser == null) {
        throw Exception('Usuario no autenticado');
      }

      // Convert session dates to SessionDate objects
      final sessionDates = _sessionDates.map((session) => SessionDate(
        sessionNumber: session['sessionNumber'],
        date: DateTime.parse(session['date']),
        startTime: session['startTime'],
        endTime: session['endTime'],
        location: session['location'] ?? '',
      )).toList();

      // Convert user IDs to Participant objects
      final responsibleUsers = _selectedResponsibleUsers.map((userId) => Participant(
        userId: userId,
        status: 'PENDIENTE',
      )).toList();

      final participants = _selectedParticipants.map((userId) => Participant(
        userId: userId,
        status: 'PENDIENTE',
      )).toList();

      final activity = ActivityModel(
        activityId: '', // Will be generated by Firestore
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        numberOfSessions: _numberOfSessions,
        sessionDates: sessionDates,
        materials: [],
        objectives: [],
        responsibleUsers: responsibleUsers,
        participants: participants,
        status: ActivityStatus.ACTIVA,
        adminCanEdit: true,
        createdBy_uid: currentUser.uid,
        createdAt: AppDateUtils.DateUtils.getCurrentLocalDateTime(),
        updatedAt: AppDateUtils.DateUtils.getCurrentLocalDateTime(),
        sessionCompletions: [],
      );

      await ActivityService.createActivity(activity);

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
            content: Text('Error al crear la actividad: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
} 