import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/providers/data_provider.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../../../shared/models/activity_model.dart';
import '../../../../shared/models/model_extensions.dart';
import '../../../../shared/services/firestore_service.dart';
import '../../../../core/widgets/loading_widget.dart';

class ActivityDetailScreen extends StatefulWidget {
  final String activityId;

  const ActivityDetailScreen({
    super.key,
    required this.activityId,
  });

  @override
  State<ActivityDetailScreen> createState() => _ActivityDetailScreenState();
}

class _ActivityDetailScreenState extends State<ActivityDetailScreen> {
  ActivityModel? _activity;
  bool _isLoading = true;
  String? _error;
  final Map<String, String> _userNames = {};
  final Map<String, bool> _loadingStates = {};

  @override
  void initState() {
    super.initState();
    _loadActivityDetails();
  }

  Future<void> _loadActivityDetails() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final dataProvider = Provider.of<DataProvider>(context, listen: false);
      final activities = dataProvider.activities;
      
      final activity = activities.firstWhere(
        (a) => a.activityId == widget.activityId,
        orElse: () => throw Exception('Actividad no encontrada'),
      );

      setState(() {
        _activity = activity;
        _isLoading = false;
      });

      // Cargar nombres de usuarios
      await _loadUserNames();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadUserNames() async {
    if (_activity == null) return;

    final dataProvider = Provider.of<DataProvider>(context, listen: false);
    final allUserIds = <String>{};

    // Recolectar todos los IDs de usuario
    allUserIds.add(_activity!.createdBy_uid);
    for (final participant in _activity!.responsibleUsers) {
      allUserIds.add(participant.userId);
    }
    for (final participant in _activity!.participants) {
      allUserIds.add(participant.userId);
    }

    // Cargar nombres
    for (final userId in allUserIds) {
      if (_userNames.containsKey(userId)) continue;

      setState(() {
        _loadingStates[userId] = true;
      });

      try {
        final userModel = dataProvider.getUserById(userId);
        if (userModel != null) {
          setState(() {
            _userNames[userId] = userModel.name;
            _loadingStates[userId] = false;
          });
        } else {
          final user = await dataProvider.loadUserById(userId);
          setState(() {
            _userNames[userId] = user?.name ?? 'Usuario no encontrado';
            _loadingStates[userId] = false;
          });
        }
      } catch (e) {
        setState(() {
          _userNames[userId] = 'Error al cargar';
          _loadingStates[userId] = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final backgroundColor = Theme.of(context).colorScheme.background;
    final cardColor = Theme.of(context).colorScheme.surface;
    final textColor = Theme.of(context).colorScheme.onBackground;
    final textSecondaryColor = Theme.of(context).colorScheme.onSurface.withOpacity(0.7);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          title: const Text('Detalles de Actividad'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
        ),
        body: const LoadingWidget(),
      );
    }

    if (_error != null || _activity == null) {
      return Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          title: const Text('Detalles de Actividad'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                'Error al cargar la actividad',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error ?? 'Actividad no encontrada',
                style: TextStyle(color: textSecondaryColor),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadActivityDetails,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Detalles de Actividad'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (_canEditActivity())
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _showEditActivityDialog(context),
            ),
          if (_canDeleteActivity())
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _showDeleteActivityDialog(context),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadActivityDetails,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con título y estado
              _buildActivityHeader(textColor, textSecondaryColor, primaryColor),
              const SizedBox(height: 24),

              // Información básica
              _buildBasicInfo(cardColor, textColor, textSecondaryColor),
              const SizedBox(height: 16),

              // Responsables
              if (_activity!.responsibleUsers.isNotEmpty)
                _buildResponsibleUsers(cardColor, textColor, textSecondaryColor, primaryColor),
              const SizedBox(height: 16),

              // Participantes
              if (_activity!.participants.isNotEmpty)
                _buildParticipants(cardColor, textColor, textSecondaryColor),
              const SizedBox(height: 16),

              // Sesiones
              _buildSessions(cardColor, textColor, textSecondaryColor),
              const SizedBox(height: 16),

              // Materiales y objetivos
              if (_activity!.materials.isNotEmpty)
                _buildMaterials(cardColor, textColor, textSecondaryColor),
              const SizedBox(height: 16),

              if (_activity!.objectives.isNotEmpty)
                _buildObjectives(cardColor, textColor, textSecondaryColor),
              const SizedBox(height: 16),

              // Progreso de completado
              _buildCompletionProgress(cardColor, textColor, textSecondaryColor, primaryColor),
              const SizedBox(height: 24),

              // Botones de acción
              _buildActionButtons(primaryColor, textColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityHeader(Color textColor, Color textSecondaryColor, Color primaryColor) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getActivityStatusColor(_activity!.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getActivityIcon(_activity!.category ?? "general"),
                    color: _getActivityStatusColor(_activity!.status),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _activity!.title,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getActivityStatusColor(_activity!.status).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _getActivityStatusDisplayName(_activity!.status),
                          style: TextStyle(
                            fontSize: 12,
                            color: _getActivityStatusColor(_activity!.status),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              _activity!.description,
              style: TextStyle(
                fontSize: 16,
                color: textColor,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfo(Color cardColor, Color textColor, Color textSecondaryColor) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Información General',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Creado por', _userNames[_activity!.createdBy_uid] ?? 'Cargando...'),
            _buildInfoRow('Categoría', _getTypeDisplayName(_activity!.category ?? "general")),
            if (_activity!.estimatedDuration != null)
              _buildInfoRow('Duración estimada', '${_activity!.estimatedDuration} minutos'),
            _buildInfoRow('Número de sesiones', '${_activity!.numberOfSessions}'),
            if (_activity!.submissionLink != null)
              _buildInfoRow('Enlace de entrega', _activity!.submissionLink!),
          ],
        ),
      ),
    );
  }

  Widget _buildResponsibleUsers(Color cardColor, Color textColor, Color textSecondaryColor, Color primaryColor) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person_outline, color: primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Responsables',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...(_activity!.responsibleUsers.map((participant) {
              final userName = _userNames[participant.userId] ?? 'Cargando...';
              final isLoading = _loadingStates[participant.userId] ?? false;
              
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: primaryColor.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.person, color: primaryColor, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        userName,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: textColor,
                        ),
                      ),
                    ),
                    if (isLoading)
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                        ),
                      ),
                  ],
                ),
              );
            })),
          ],
        ),
      ),
    );
  }

  Widget _buildParticipants(Color cardColor, Color textColor, Color textSecondaryColor) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.people_outline, color: textSecondaryColor),
                const SizedBox(width: 8),
                Text(
                  'Participantes (${_activity!.participants.length})',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...(_activity!.participants.map((participant) {
              final userName = _userNames[participant.userId] ?? 'Cargando...';
              final isLoading = _loadingStates[participant.userId] ?? false;
              
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: textSecondaryColor.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.person, color: textSecondaryColor, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        userName,
                        style: TextStyle(
                          fontSize: 14,
                          color: textColor,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getParticipantStatusColor(participant.status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getParticipantStatusDisplayName(participant.status),
                        style: TextStyle(
                          fontSize: 12,
                          color: _getParticipantStatusColor(participant.status),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (isLoading)
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(textSecondaryColor),
                        ),
                      ),
                  ],
                ),
              );
            })),
          ],
        ),
      ),
    );
  }

  Widget _buildSessions(Color cardColor, Color textColor, Color textSecondaryColor) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.schedule, color: textSecondaryColor),
                const SizedBox(width: 8),
                Text(
                  'Sesiones (${_activity!.sessionDates.length})',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...(_activity!.sessionDates.map((session) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: textSecondaryColor.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Sesión ${session.sessionNumber}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                        const Spacer(),
                        if (session.status != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getSessionStatusColor(session.status!).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _getSessionStatusDisplayName(session.status!),
                              style: TextStyle(
                                fontSize: 12,
                                color: _getSessionStatusColor(session.status!),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Fecha: ${_formatDate(session.date)}',
                      style: TextStyle(
                        fontSize: 14,
                        color: textSecondaryColor,
                      ),
                    ),
                    Text(
                      'Horario: ${session.startTime} - ${session.endTime}',
                      style: TextStyle(
                        fontSize: 14,
                        color: textSecondaryColor,
                      ),
                    ),
                    if (session.location != null)
                      Text(
                        'Ubicación: ${session.location}',
                        style: TextStyle(
                          fontSize: 14,
                          color: textSecondaryColor,
                        ),
                      ),
                  ],
                ),
              );
            })),
          ],
        ),
      ),
    );
  }

  Widget _buildMaterials(Color cardColor, Color textColor, Color textSecondaryColor) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.inventory_2_outlined, color: textSecondaryColor),
                const SizedBox(width: 8),
                Text(
                  'Materiales',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...(_activity!.materials.map((material) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.fiber_manual_record, size: 8, color: textSecondaryColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        material,
                        style: TextStyle(
                          fontSize: 14,
                          color: textColor,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            })),
          ],
        ),
      ),
    );
  }

  Widget _buildObjectives(Color cardColor, Color textColor, Color textSecondaryColor) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.flag_outlined, color: textSecondaryColor),
                const SizedBox(width: 8),
                Text(
                  'Objetivos',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...(_activity!.objectives.map((objective) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.fiber_manual_record, size: 8, color: textSecondaryColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        objective,
                        style: TextStyle(
                          fontSize: 14,
                          color: textColor,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            })),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletionProgress(Color cardColor, Color textColor, Color textSecondaryColor, Color primaryColor) {
    final completionPercentage = _activity!.completionPercentage ?? 0.0;
    
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics_outlined, color: primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Progreso de Completado',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: completionPercentage / 100,
              backgroundColor: Colors.grey.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
              minHeight: 8,
            ),
            const SizedBox(height: 8),
            Text(
              '${completionPercentage.toStringAsFixed(1)}% completado',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${_activity!.sessionCompletions.where((sc) => sc.status == CompletionStatus.COMPLETED).length} de ${_activity!.numberOfSessions * _activity!.participants.length} sesiones completadas',
              style: TextStyle(
                fontSize: 14,
                color: textSecondaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(Color primaryColor, Color textColor) {
    final currentUser = Provider.of<AuthProvider>(context, listen: false).user;
    if (currentUser == null) return const SizedBox.shrink();

    final isParticipant = _activity!.participants.any((p) => p.userId == currentUser.uid);
    final isResponsible = _activity!.responsibleUsers.any((r) => r.userId == currentUser.uid);
    final canComplete = isParticipant || isResponsible;

    return Column(
      children: [
        if (canComplete && _activity!.status != ActivityStatus.COMPLETADA)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _showCompleteSessionDialog,
              icon: const Icon(Icons.check_circle),
              label: const Text('Completar Sesión'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        if (isResponsible)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _showApproveCompletionsDialog,
              icon: const Icon(Icons.approval),
              label: const Text('Aprobar Completaciones'),
              style: OutlinedButton.styleFrom(
                foregroundColor: primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onBackground,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods
  Color _getActivityStatusColor(ActivityStatus status) {
    switch (status) {
      case ActivityStatus.COMPLETADA:
        return Colors.green;
      case ActivityStatus.ACTIVA:
        return Colors.blue;
      case ActivityStatus.INACTIVA:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getActivityStatusDisplayName(ActivityStatus status) {
    switch (status) {
      case ActivityStatus.COMPLETADA:
        return 'Completada';
      case ActivityStatus.ACTIVA:
        return 'Activa';
      case ActivityStatus.INACTIVA:
        return 'Inactiva';
      default:
        return 'Desconocido';
    }
  }

  Color _getParticipantStatusColor(String status) {
    switch (status) {
      case 'COMPLETADA':
        return Colors.green;
      case 'PENDIENTE':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getParticipantStatusDisplayName(String status) {
    switch (status) {
      case 'COMPLETADA':
        return 'Completada';
      case 'PENDIENTE':
        return 'Pendiente';
      default:
        return 'Desconocido';
    }
  }

  Color _getSessionStatusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'active':
        return Colors.blue;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getSessionStatusDisplayName(String status) {
    switch (status) {
      case 'completed':
        return 'Completada';
      case 'active':
        return 'Activa';
      case 'pending':
        return 'Pendiente';
      default:
        return 'Desconocido';
    }
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'assignment':
        return Colors.blue;
      case 'exam':
        return Colors.red;
      case 'project':
        return Colors.purple;
      case 'homework':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getTypeDisplayName(String type) {
    switch (type.toLowerCase()) {
      case 'assignment':
        return 'Tarea';
      case 'exam':
        return 'Examen';
      case 'project':
        return 'Proyecto';
      case 'homework':
        return 'Deberes';
      default:
        return 'Actividad';
    }
  }

  IconData _getActivityIcon(String type) {
    switch (type.toLowerCase()) {
      case 'assignment':
        return Icons.assignment;
      case 'exam':
        return Icons.quiz;
      case 'project':
        return Icons.work;
      case 'homework':
        return Icons.book;
      default:
        return Icons.assignment;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  bool _canEditActivity() {
    final currentUser = Provider.of<AuthProvider>(context, listen: false).user;
    if (currentUser == null) return false;
    
    // TODO: Implementar verificación de roles cuando tengamos el modelo de usuario completo
    // Por ahora, permitir edición si es el creador
    return _activity!.createdBy_uid == currentUser.uid;
  }

  bool _canDeleteActivity() {
    final currentUser = Provider.of<AuthProvider>(context, listen: false).user;
    if (currentUser == null) return false;
    
    // TODO: Implementar verificación de roles cuando tengamos el modelo de usuario completo
    // Por ahora, permitir eliminación si es el creador
    return _activity!.createdBy_uid == currentUser.uid;
  }

  void _showEditActivityDialog(BuildContext context) {
    // TODO: Implementar edición de actividad
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Función de edición en desarrollo')),
    );
  }

  void _showDeleteActivityDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Actividad'),
        content: Text('¿Estás seguro de que quieres eliminar "${_activity!.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              final dataProvider = Provider.of<DataProvider>(context, listen: false);
              dataProvider.deleteActivity(_activity!.activityId);
              Navigator.of(context).pop();
              context.pop(); // Volver a la lista
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _showCompleteSessionDialog() {
    // TODO: Implementar diálogo de completar sesión
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Función de completar sesión en desarrollo')),
    );
  }

  void _showApproveCompletionsDialog() {
    // TODO: Implementar diálogo de aprobar completaciones
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Función de aprobar completaciones en desarrollo')),
    );
  }
} 