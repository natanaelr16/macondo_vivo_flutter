import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../shared/models/activity_model.dart';
import '../../../../shared/models/user_model.dart';
import '../../../../shared/providers/data_provider.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../../../shared/services/activity_service.dart';
import '../../../../core/widgets/loading_widget.dart';
import 'session_action_buttons.dart';

class ActivityDetailsDialog extends StatefulWidget {
  final ActivityModel activity;
  final VoidCallback? onActivityUpdate;

  const ActivityDetailsDialog({
    super.key,
    required this.activity,
    this.onActivityUpdate,
  });

  @override
  State<ActivityDetailsDialog> createState() => _ActivityDetailsDialogState();
}

class _ActivityDetailsDialogState extends State<ActivityDetailsDialog> {
  final bool _isLoading = false;
  bool _isCompletingSession = false;
  final bool _isApprovingSession = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final dataProvider = Provider.of<DataProvider>(context);
    final currentUser = authProvider.userData;
    final currentUserId = authProvider.firebaseUser?.uid;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.activity.title,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Status and Category
            Row(
              children: [
                _buildStatusChip(widget.activity.status),
                const SizedBox(width: 8),
                if (widget.activity.category != null)
                  Chip(
                    label: Text(widget.activity.category!),
                    backgroundColor: theme.colorScheme.secondary.withOpacity(0.1),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Description
            Text(
              'Descripción',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.activity.description,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),

            // Progress Section
            _buildProgressSection(dataProvider),
            const SizedBox(height: 20),

            // Sessions Section
            Expanded(
              child: _buildSessionsSection(dataProvider, currentUserId),
            ),

            // Actions Section
            if (currentUserId != null)
              _buildActionsSection(currentUserId, currentUser, dataProvider),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(ActivityStatus status) {
    Color color;
    IconData icon;
    String label;

    switch (status) {
      case ActivityStatus.ACTIVA:
        color = Colors.orange;
        icon = Icons.assignment;
        label = 'Activa';
        break;
      case ActivityStatus.COMPLETADA:
        color = Colors.green;
        icon = Icons.check_circle;
        label = 'Completada';
        break;
      case ActivityStatus.INACTIVA:
        color = Colors.grey;
        icon = Icons.schedule;
        label = 'Inactiva';
        break;
    }

    return Chip(
      avatar: Icon(icon, color: color, size: 16),
      label: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w500),
      ),
      backgroundColor: color.withOpacity(0.1),
    );
  }

  Widget _buildProgressSection(DataProvider dataProvider) {
    final progress = _calculateProgress();
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Progreso General',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: progress['percentage'] / 100,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      progress['percentage'] == 100 ? Colors.green : Colors.orange,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${progress['percentage'].round()}%',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${progress['completed']} de ${progress['total']} sesiones completadas',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionsSection(DataProvider dataProvider, String? currentUserId) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sesiones',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.builder(
            itemCount: widget.activity.sessionDates.length,
            itemBuilder: (context, index) {
              final session = widget.activity.sessionDates[index];
              final sessionNumber = index + 1;
              final completion = _getSessionCompletion(sessionNumber, currentUserId);
              final isResponsible = _isUserResponsible(currentUserId);
              final canComplete = _canCompleteSession(sessionNumber, currentUserId, isResponsible);

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getSessionStatusColor(completion?.status),
                    child: Text(
                      '$sessionNumber',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(
                    'Sesión $sessionNumber',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_formatDate(session.date)} - ${session.startTime} a ${session.endTime}',
                        style: theme.textTheme.bodySmall,
                      ),
                      if (completion != null)
                        Text(
                          _getCompletionStatusText(completion.status),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: _getSessionStatusColor(completion.status),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                  trailing: SessionActionButtons(
                    activity: widget.activity,
                    sessionNumber: sessionNumber,
                    canComplete: true,
                    canApprove: true,
                    onActivityUpdate: () {
                      dataProvider.loadActivities();
                      Navigator.of(context).pop();
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActionsSection(
    String currentUserId,
    UserModel? currentUser,
    DataProvider dataProvider,
  ) {
    final theme = Theme.of(context);
    final canEdit = _canEditActivity(currentUser);
    final canDelete = _canDeleteActivity(currentUser);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Acciones',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (canEdit)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _editActivity(),
                      icon: const Icon(Icons.edit),
                      label: const Text('Editar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                if (canEdit) const SizedBox(width: 8),
                if (canDelete)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _deleteActivity(dataProvider),
                      icon: const Icon(Icons.delete),
                      label: const Text('Eliminar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods
  Map<String, dynamic> _calculateProgress() {
    final participants = widget.activity.participants;
    final totalSessions = widget.activity.numberOfSessions;
    final totalRequired = participants.length * totalSessions;
    
    int completed = 0;
    if (widget.activity.sessionCompletions.isNotEmpty) {
      completed = widget.activity.sessionCompletions
          .where((c) => c.status == CompletionStatus.APPROVED || c.status == CompletionStatus.COMPLETED)
          .length;
    }
    
    final percentage = totalRequired > 0 ? (completed / totalRequired) * 100 : 0;
    
    return {
      'completed': completed,
      'total': totalRequired,
      'percentage': percentage,
    };
  }

  SessionCompletion? _getSessionCompletion(int sessionNumber, String? userId) {
    if (userId == null) return null;
    
    try {
      return widget.activity.sessionCompletions.firstWhere(
        (c) => c.sessionNumber == sessionNumber && c.userId == userId,
      );
    } catch (e) {
      return null;
    }
  }

  bool _isUserResponsible(String? userId) {
    if (userId == null) return false;
    return widget.activity.responsibleUsers.any((r) => r.userId == userId);
  }

  bool _canCompleteSession(int sessionNumber, String? userId, bool isResponsible) {
    if (userId == null) return false;
    
    // Verificar si ya completó esta sesión
    final existingCompletion = _getSessionCompletion(sessionNumber, userId);
    if (existingCompletion != null) return false;
    
    // Verificar si es la próxima sesión a completar
    final userCompletions = widget.activity.sessionCompletions
        .where((c) => c.userId == userId && 
            (c.status == CompletionStatus.APPROVED || c.status == CompletionStatus.COMPLETED))
        .map((c) => c.sessionNumber)
        .toList();
    
    final nextSession = userCompletions.isEmpty ? 1 : userCompletions.reduce((a, b) => a > b ? a : b) + 1;
    
    // Si no es la próxima sesión, no puede completar
    if (sessionNumber != nextSession) return false;
    
    // Si es responsable, verificar que todos los participantes hayan completado y sido aprobados
    if (isResponsible) {
      final participants = widget.activity.participants;
      final participantUserIds = participants.map((p) => p.userId).toList();
      
      // Verificar que todos los participantes hayan completado esta sesión
      for (final participantId in participantUserIds) {
        final participantCompletion = _getSessionCompletion(sessionNumber, participantId);
        if (participantCompletion == null || participantCompletion.status != CompletionStatus.APPROVED) {
          return false; // Al menos un participante no ha completado o no ha sido aprobado
        }
      }
    }
    
    return true;
  }

  Color _getSessionStatusColor(CompletionStatus? status) {
    switch (status) {
      case CompletionStatus.COMPLETED:
        return Colors.green;
      case CompletionStatus.APPROVED:
        return Colors.blue;
      case CompletionStatus.PENDING_APPROVAL:
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getCompletionStatusText(CompletionStatus status) {
    switch (status) {
      case CompletionStatus.COMPLETED:
        return 'Completada';
      case CompletionStatus.APPROVED:
        return 'Aprobada';
      case CompletionStatus.PENDING_APPROVAL:
        return 'Pendiente de aprobación';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  bool _canEditActivity(UserModel? user) {
    if (user == null) return false;
    if (user.isSuperUser) return true;
    if (user.isAdmin && widget.activity.createdBy_uid == user.uid) return true;
    return false;
  }

  bool _canDeleteActivity(UserModel? user) {
    if (user == null) return false;
    if (user.isSuperUser) return true;
    if (user.isAdmin && widget.activity.createdBy_uid == user.uid) return true;
    return false;
  }

  // Action methods
  Future<void> _completeSession(int sessionNumber, DataProvider dataProvider) async {
    final currentUser = context.read<AuthProvider>().userData;
    final isResponsible = _isUserResponsible(currentUser?.uid);
    
    // Validar si puede completar la sesión
    if (!_canCompleteSession(sessionNumber, currentUser?.uid, isResponsible)) {
      if (isResponsible) {
        _showResponsibleCannotCompleteMessage(sessionNumber);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No puede completar esta sesión en este momento'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }
    
    setState(() {
      _isCompletingSession = true;
    });

    try {
      final activityService = ActivityService();
      await activityService.completeSession(widget.activity.activityId, sessionNumber);
      
      if (mounted) {
        String message;
        if (isResponsible) {
          message = 'Sesión completada exitosamente como responsable';
        } else {
          message = 'Sesión marcada como completada. Pendiente de aprobación del responsable.';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
        
        // Recargar actividades
        await dataProvider.loadActivities();
        
        // Notificar actualización
        widget.onActivityUpdate?.call();
        
        // Cerrar diálogo
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        String errorMessage;
        if (isResponsible) {
          errorMessage = 'Error al completar sesión como responsable: $e';
        } else {
          errorMessage = 'Error al marcar sesión como completada: $e';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCompletingSession = false;
        });
      }
    }
  }

  void _showResponsibleCannotCompleteMessage(int sessionNumber) {
    final participants = widget.activity.participants;
    final participantUserIds = participants.map((p) => p.userId).toList();
    final pendingParticipants = <String>[];
    
    // Verificar qué participantes no han completado o no han sido aprobados
    for (final participantId in participantUserIds) {
      final participantCompletion = _getSessionCompletion(sessionNumber, participantId);
      if (participantCompletion == null) {
        pendingParticipants.add('Usuario $participantId: No ha completado la sesión');
      } else if (participantCompletion.status != CompletionStatus.APPROVED) {
        pendingParticipants.add('Usuario $participantId: ${_getCompletionStatusText(participantCompletion.status)}');
      }
    }
    
    // Usar el mensaje exacto de la documentación
    const message = 'No puedes completar esta sesión hasta que todos los participantes hayan enviado su parte';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('No puedes completar esta sesión'),
        content: SingleChildScrollView(
          child: const Text(message),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  void _editActivity() {
    // TODO: Implementar edición de actividad
    Navigator.of(context).pop();
  }

  Future<void> _deleteActivity(DataProvider dataProvider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: const Text('¿Estás seguro de que quieres eliminar esta actividad?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final activityService = ActivityService();
        await activityService.deleteActivity(widget.activity.activityId);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Actividad eliminada exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
          
          // Recargar actividades
          await dataProvider.loadActivities();
          
          // Notificar actualización
          widget.onActivityUpdate?.call();
          
          // Cerrar diálogo
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al eliminar actividad: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
} 