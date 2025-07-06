import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../shared/models/activity_model.dart';
import '../../../../shared/providers/data_provider.dart';
import '../../../../shared/providers/auth_provider.dart';
import 'activity_details_dialog.dart';

class ActivityCard extends StatelessWidget {
  final ActivityModel activity;
  final VoidCallback? onActivityUpdate;

  const ActivityCard({
    super.key,
    required this.activity,
    this.onActivityUpdate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final dataProvider = Provider.of<DataProvider>(context);
    final currentUserId = authProvider.firebaseUser?.uid;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: _getStatusColor(activity.status).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () => _showActivityDetails(context, dataProvider),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with status and actions
              Row(
                children: [
                  _buildStatusChip(activity.status),
                  const SizedBox(width: 8),
                  if (activity.category != null)
                    Chip(
                      label: Text(
                        activity.category!,
                        style: const TextStyle(fontSize: 12),
                      ),
                      backgroundColor: theme.colorScheme.secondary.withOpacity(0.1),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  const Spacer(),
                  _buildActionMenu(context, dataProvider),
                ],
              ),
              const SizedBox(height: 12),

              // Title
              Text(
                activity.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),

              // Description
              Text(
                activity.description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),

              // Session info
              _buildSessionInfo(),
              const SizedBox(height: 12),

              // Progress
              _buildProgressSection(),
              const SizedBox(height: 12),

              // Participants and responsible
              _buildParticipantsSection(dataProvider),
              const SizedBox(height: 12),

              // Actions
              if (currentUserId != null)
                _buildActionButtons(context, currentUserId, dataProvider),
            ],
          ),
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
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
      ),
      backgroundColor: color.withOpacity(0.1),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildActionMenu(BuildContext context, DataProvider dataProvider) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, size: 20),
      onSelected: (value) => _handleMenuAction(value, context, dataProvider),
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'view',
          child: Row(
            children: [
              Icon(Icons.visibility, size: 20),
              SizedBox(width: 8),
              Text('Ver detalles'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit, size: 20),
              SizedBox(width: 8),
              Text('Editar'),
            ],
          ),
        ),
        if (activity.status != ActivityStatus.COMPLETADA)
          const PopupMenuItem(
            value: 'complete',
            child: Row(
              children: [
                Icon(Icons.check_circle, size: 20, color: Colors.green),
                SizedBox(width: 8),
                Text('Marcar como completada', style: TextStyle(color: Colors.green)),
              ],
            ),
          ),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete, size: 20, color: Colors.red),
              SizedBox(width: 8),
              Text('Eliminar', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSessionInfo() {
    final nextSession = _getNextSession();
    
    return Row(
      children: [
        Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          'Sesiones: ${activity.numberOfSessions}',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        if (nextSession != null) ...[
          const SizedBox(width: 16),
          Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Text(
            'Próxima: ${_formatDate(nextSession.date)}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildProgressSection() {
    final progressDetails = activity.getProgressDetails();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progreso',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
            Text(
              '${progressDetails['completionPercentage'].round()}%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: progressDetails['completionPercentage'] == 100 ? Colors.green : Colors.orange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: progressDetails['completionPercentage'] / 100,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(
            progressDetails['completionPercentage'] == 100 ? Colors.green : Colors.orange,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          progressDetails['progressText'],
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildParticipantsSection(DataProvider dataProvider) {
    final responsibleUsers = activity.responsibleUsers;
    final participants = activity.participants;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (responsibleUsers.isNotEmpty) ...[
          Row(
            children: [
              Icon(Icons.person, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                'Responsables:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 4,
            children: responsibleUsers.take(3).map((responsible) {
              final user = dataProvider.getUserById(responsible.userId);
              return Chip(
                label: Text(
                  user?.name ?? 'Usuario',
                  style: const TextStyle(fontSize: 10),
                ),
                backgroundColor: Colors.blue.withOpacity(0.1),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              );
            }).toList(),
          ),
          if (responsibleUsers.length > 3)
            Text(
              '+${responsibleUsers.length - 3} más',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
              ),
            ),
        ],
        if (participants.isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.group, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                'Participantes:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${participants.length} participantes',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, String currentUserId, DataProvider dataProvider) {
    final canComplete = _canUserCompleteNextSession(currentUserId);
    final isResponsible = _isUserResponsible(currentUserId);
    
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => _showActivityDetails(context, dataProvider),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 8),
            ),
            child: const Text('Ver Detalles'),
          ),
        ),
        if (canComplete) ...[
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton(
              onPressed: () => _completeNextSession(context, dataProvider),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
              child: Text(isResponsible ? 'Completar' : 'Enviar'),
            ),
          ),
        ],
      ],
    );
  }

  // Helper methods
  Color _getStatusColor(ActivityStatus status) {
    switch (status) {
      case ActivityStatus.ACTIVA:
        return Colors.orange;
      case ActivityStatus.COMPLETADA:
        return Colors.green;
      case ActivityStatus.INACTIVA:
        return Colors.grey;
    }
  }

  SessionDate? _getNextSession() {
    if (activity.sessionDates.isEmpty) return null;
    
    final now = DateTime.now();
    final futureSessions = activity.sessionDates
        .where((session) => session.date.isAfter(now))
        .toList();
    
    if (futureSessions.isEmpty) return null;
    
    futureSessions.sort((a, b) => a.date.compareTo(b.date));
    return futureSessions.first;
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  bool _isUserResponsible(String userId) {
    return activity.responsibleUsers.any((r) => r.userId == userId);
  }

  bool _canUserCompleteNextSession(String userId) {
    // Usar el método del modelo que respeta la documentación
    final userProgress = activity.getUserProgress(userId);
    
    // Solo participantes pueden completar sesiones
    if (!userProgress['isParticipant']) return false;
    
    // Verificar si puede completar la próxima sesión
    return userProgress['canCompleteNextSession'] == true;
  }

  // Action methods
  void _showActivityDetails(BuildContext context, DataProvider dataProvider) {
    showDialog(
      context: context,
      builder: (context) => ActivityDetailsDialog(
        activity: activity,
        onActivityUpdate: onActivityUpdate,
      ),
    );
  }

  void _handleMenuAction(String value, BuildContext context, DataProvider dataProvider) {
    switch (value) {
      case 'view':
        _showActivityDetails(context, dataProvider);
        break;
      case 'edit':
        // TODO: Implementar edición
        break;
      case 'complete':
        // TODO: Implementar completar actividad
        break;
      case 'delete':
        _showDeleteConfirmation(context, dataProvider);
        break;
    }
  }

  Future<void> _completeNextSession(BuildContext context, DataProvider dataProvider) async {
    // TODO: Implementar completar próxima sesión
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Funcionalidad en desarrollo'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  Future<void> _showDeleteConfirmation(BuildContext context, DataProvider dataProvider) async {
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
      // TODO: Implementar eliminación
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Funcionalidad en desarrollo'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }
} 