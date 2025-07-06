import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../shared/models/user_model.dart';
import '../../../../shared/providers/data_provider.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../../../shared/services/activity_service.dart';
import '../../../../shared/models/activity_model.dart';

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
  List<String> _selectedResponsibleUsers = [];
  List<String> _selectedParticipants = [];
  
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
    _initializeSessions();
  }

  void _initializeSessions() {
    final now = DateTime.now();
    _sessionDates = [
      {
        'sessionNumber': 1,
        'date': now.toIso8601String().split('T')[0],
        'startTime': '08:00',
        'endTime': '09:00',
      }
    ];
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
        actions: [
          TextButton(
            onPressed: _saveActivity,
            child: const Text(
              'Guardar',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
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

                    const SizedBox(height: 40), // Bottom padding
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
            // Responsible users selection
            _buildUserSelection(
              'Responsables',
              users,
              _selectedResponsibleUsers,
              Icons.person_pin,
              'Buscar responsables...',
              _responsibleSearchController,
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
            ),
          ],
        );
      },
    );
  }

  Widget _buildUserSelection(
    String title,
    List<UserModel> users,
    List<String> selectedUsers,
    IconData icon,
    String hintText,
    TextEditingController searchController,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        
        // Selected users chips
        if (selectedUsers.isNotEmpty) ...[
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: selectedUsers.map((userId) {
              final user = users.firstWhere((u) => u.uid == userId);
              return Chip(
                label: Text(
                  '${user.firstName} ${user.lastName}',
                  style: const TextStyle(fontSize: 12),
                ),
                onDeleted: () {
                  setState(() {
                    selectedUsers.remove(userId);
                  });
                },
                deleteIcon: const Icon(Icons.close, size: 16),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
        ],
        
        // User search and selection
        _buildUserSearchDropdown(
          users,
          selectedUsers,
          hintText,
          icon,
          searchController,
          (userId) {
            setState(() {
              selectedUsers.add(userId);
              // Clear the search field after selection
              searchController.clear();
            });
          },
        ),
      ],
    );
  }

  Widget _buildUserSearchDropdown(
    List<UserModel> users,
    List<String> selectedUsers,
    String hintText,
    IconData icon,
    TextEditingController searchController,
    Function(String) onUserSelected,
  ) {
    return Autocomplete<String>(
      fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
        return TextFormField(
          controller: searchController,
          focusNode: focusNode,
          decoration: InputDecoration(
            labelText: hintText,
            hintText: 'Buscar por nombre, documento o correo...',
            prefixIcon: Icon(icon),
            suffixIcon: IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                // Trigger search
              },
            ),
          ),
        );
      },
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text.isEmpty) {
          return const Iterable<String>.empty();
        }
        
        final query = textEditingValue.text.toLowerCase();
        final availableUsers = users.where((user) => 
          !selectedUsers.contains(user.uid) &&
          (user.firstName.toLowerCase().contains(query) ||
           user.lastName.toLowerCase().contains(query) ||
           user.documentNumber.toLowerCase().contains(query) ||
           user.email.toLowerCase().contains(query))
        );
        
        return availableUsers.map((user) => user.uid);
      },
      displayStringForOption: (String userId) {
        final user = users.firstWhere((u) => u.uid == userId);
        return '${user.firstName} ${user.lastName}';
      },
      onSelected: (String userId) {
        onUserSelected(userId);
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Material(
          elevation: 4.0,
          child: Container(
            constraints: const BoxConstraints(maxHeight: 200),
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: options.length,
              itemBuilder: (context, index) {
                final userId = options.elementAt(index);
                final user = users.firstWhere((u) => u.uid == userId);
                
                return ListTile(
                  title: Text('${user.firstName} ${user.lastName}'),
                  subtitle: Text('${user.documentNumber} • ${user.email}'),
                  onTap: () {
                    onSelected(userId);
                  },
                );
              },
            ),
          ),
        );
      },
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
        date: DateTime.parse(session['date']),
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
