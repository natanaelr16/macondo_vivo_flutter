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
  
  // ScrollControllers para listas de búsqueda
  final ScrollController _responsibleListScrollController = ScrollController();
  final ScrollController _participantsListScrollController = ScrollController();

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
    _responsibleListScrollController.dispose();
    _participantsListScrollController.dispose();
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

    return SafeArea(
      child: Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Header con título y botones
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  const Text(
                    'Crear Actividad',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  // Botón para limpiar formulario
                  IconButton(
                    icon: const Icon(Icons.clear_all, color: Colors.white),
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
                  // Botón para cerrar
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            // Contenido del formulario
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
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

                      // Padding dinámico para manejar el teclado
                      SizedBox(
                        height: MediaQuery.of(context).viewInsets.bottom + 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
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
        ],
      ),
    );
  }

  Widget _buildParticipantsSection() {
    return Consumer<DataProvider>(
      builder: (context, dataProvider, child) {
        final users = dataProvider.users;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Show error if any
            if (dataProvider.error != null)
              Container(
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  border: Border.all(color: Colors.red.shade200),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Error: ${dataProvider.error}',
                  style: TextStyle(color: Colors.red.shade700),
                ),
              ),
            
            // Show loading state
            if (dataProvider.isLoading)
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  border: Border.all(color: Colors.blue.shade200),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Cargando usuarios...',
                      style: TextStyle(color: Colors.blue.shade700),
                    ),
                  ],
                ),
              ),
            
            // Show no users message
            if (!dataProvider.isLoading && users.isEmpty && dataProvider.error == null)
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  border: Border.all(color: Colors.orange.shade200),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange.shade700, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'No hay usuarios disponibles. Verifica que existan usuarios en el sistema.',
                        style: TextStyle(color: Colors.orange.shade700),
                      ),
                    ),
                  ],
                ),
              ),
            
            // Responsible users selection
            _buildUserSelection(
              'Responsables',
              users,
              _selectedResponsibleUsers,
              Icons.person_pin,
              'Buscar responsables...',
              _responsibleSearchController,
              _responsibleListScrollController,
            ),
            
            const SizedBox(height: 16),
            
            // Participants selection
            _buildUserSelection(
              'Participantes',
              users,
              _selectedParticipants,
              Icons.people,
              'Buscar participantes...',
              _participantsSearchController,
              _participantsListScrollController,
            ),
          ],
        );
      },
    );
  }

  Widget _buildUserSelection(
    String label,
    List<UserModel> users,
    List<String> selectedUsers,
    IconData icon,
    String hintText,
    TextEditingController searchController,
    ScrollController listScrollController,
  ) {
    final searchQuery = searchController.text.toLowerCase();
    final filteredUsers = users
        .where((user) =>
            !selectedUsers.contains(user.uid) &&
            ('${user.firstName} ${user.lastName}'.toLowerCase().contains(searchQuery) ||
                user.email.toLowerCase().contains(searchQuery) ||
                user.documentNumber.toLowerCase().contains(searchQuery)))
        .toList();

    // Scroll automático cuando aparecen resultados
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (filteredUsers.isNotEmpty && searchQuery.isNotEmpty) {
        listScrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: searchController,
          decoration: InputDecoration(
            labelText: hintText,
            hintText: 'Escribe para buscar usuarios...',
            prefixIcon: Icon(icon),
            suffixIcon: searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      searchController.clear();
                      setState(() {});
                    },
                  )
                : null,
          ),
          onChanged: (value) {
            setState(() {});
          },
        ),
        const SizedBox(height: 8),
        
        // Mostrar usuarios seleccionados
        if (selectedUsers.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: selectedUsers.map((uid) {
              final user = users.firstWhere((u) => u.uid == uid);
              return Chip(
                label: Text(
                  '${user.firstName} ${user.lastName}',
                  style: const TextStyle(fontSize: 12),
                ),
                deleteIcon: const Icon(Icons.close, size: 16),
                onDeleted: () {
                  setState(() {
                    selectedUsers.remove(uid);
                  });
                },
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                deleteIconColor: Theme.of(context).colorScheme.error,
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
        ],
        
        // Lista de resultados de búsqueda
        if (searchQuery.isNotEmpty)
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: filteredUsers.isEmpty
                ? Container(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'No se encontraron usuarios con "$searchQuery"',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: listScrollController,
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemCount: filteredUsers.length,
                    itemBuilder: (context, index) {
                      final user = filteredUsers[index];
                      return ListTile(
                        dense: true,
                        leading: CircleAvatar(
                          radius: 16,
                          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                          child: Text(
                            '${user.firstName[0]}${user.lastName[0]}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                        title: Text(
                          '${user.firstName} ${user.lastName}',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                        subtitle: Text(
                          '${user.documentNumber} • ${user.email}',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                        onTap: () {
                          setState(() => selectedUsers.add(user.uid));
                          searchController.clear();
                          setState(() {});
                        },
                      );
                    },
                  ),
          ),
      ],
    );
  }

  Future<void> _selectSessionDate(int index) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: AppDateUtils.DateUtils.parseFromISOString(_sessionDates[index]['date']),
      firstDate: AppDateUtils.DateUtils.getCurrentLocalDateTime(),
      lastDate: AppDateUtils.DateUtils.getCurrentLocalDateTime().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        _sessionDates[index]['date'] = AppDateUtils.DateUtils.getCurrentDateString();
      });
    }
  }

  Future<void> _selectSessionTime(int index, String timeType) async {
    final currentTime = TimeOfDay.fromDateTime(
      DateTime.parse('2023-01-01 ${_sessionDates[index][timeType]}:00')
    );
    
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: currentTime,
    );

    if (picked != null) {
      setState(() {
        _sessionDates[index][timeType] = 
            '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _saveActivity() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedResponsibleUsers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debe seleccionar al menos un responsable')),
      );
      return;
    }

    try {
      // Get current user
      final authProvider = context.read<AuthProvider>();
      final currentUser = authProvider.userData;
      
      if (currentUser == null) {
        throw Exception('Usuario no autenticado');
      }

      // Convert session dates to SessionDate objects
      final sessionDates = _sessionDates.map((session) => SessionDate(
        sessionNumber: session['sessionNumber'],
        date: AppDateUtils.DateUtils.parseFromISOString(session['date']),
        startTime: session['startTime'],
        endTime: session['endTime'],
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

      // Create activity data for API
      final activityData = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'numberOfSessions': _numberOfSessions,
        'sessionDates': sessionDates.map((sd) => sd.toMap()).toList(),
        'submissionLink': _submissionLinkController.text.trim().isEmpty 
            ? null 
            : _submissionLinkController.text.trim(),
        'category': _selectedCategory ?? 'Otros',
        'estimatedDuration': int.tryParse(_estimatedDurationController.text) ?? 60,
        'materials': <String>[],
        'objectives': <String>[],
        'responsibleUsers': responsibleUsers.map((p) => p.toMap()).toList(),
        'participants': participants.map((p) => p.toMap()).toList(),
        'status': ActivityStatus.ACTIVA.name,
        'adminCanEdit': true,
        'createdBy_uid': currentUser.uid,
      };

      final activityService = ActivityService();
      await activityService.createActivity(activityData);

      if (mounted) {
        // Actualizar la lista de actividades inmediatamente
        final dataProvider = context.read<DataProvider>();
        await dataProvider.loadActivities();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Actividad creada exitosamente')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al crear la actividad: $e')),
        );
      }
    }
  }
} 
