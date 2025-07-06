import 'package:flutter/material.dart';
import '../../../../shared/models/activity_model.dart';

class ActivityProgress extends StatelessWidget {
  final ActivityModel activity;

  const ActivityProgress({
    super.key,
    required this.activity,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = _calculateProgress();
    final userProgress = _calculateUserProgress();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.analytics, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Progreso de la Actividad',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Overall Progress
            _buildOverallProgress(progress, theme),
            const SizedBox(height: 20),

            // User Progress
            _buildUserProgress(userProgress, theme),
            const SizedBox(height: 16),

            // Session Details
            _buildSessionDetails(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildOverallProgress(Map<String, dynamic> progress, ThemeData theme) {
    final percentage = progress['percentage'];
    final isCompleted = progress['isCompleted'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Progreso General',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: LinearProgressIndicator(
                value: percentage / 100,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                  isCompleted ? Colors.green : Colors.orange,
                ),
                minHeight: 8,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '${percentage.round()}%',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: isCompleted ? Colors.green : Colors.orange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Sesiones completadas: ${progress['completed']}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            Text(
              'Total requerido: ${progress['total']}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        if (isCompleted) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 16),
                const SizedBox(width: 4),
                Text(
                  'Actividad Completada',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildUserProgress(Map<String, dynamic> userProgress, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tu Progreso',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: LinearProgressIndicator(
                value: userProgress['percentage'] / 100,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                  userProgress['isCompleted'] ? Colors.green : Colors.blue,
                ),
                minHeight: 6,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '${userProgress['percentage'].round()}%',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: userProgress['isCompleted'] ? Colors.green : Colors.blue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Sesiones completadas: ${userProgress['completed']} de ${userProgress['total']}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
          ),
        ),
        if (userProgress['nextSession'] != null) ...[
          const SizedBox(height: 4),
          Text(
            'Próxima sesión: ${_formatDate(userProgress['nextSession'])}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.orange,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSessionDetails(ThemeData theme) {
    final sessions = activity.sessionDates;
    final completions = activity.sessionCompletions;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Detalle de Sesiones',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: sessions.length,
          itemBuilder: (context, index) {
            final session = sessions[index];
            final sessionNumber = index + 1;
            final sessionCompletions = completions
                .where((c) => c.sessionNumber == sessionNumber)
                .toList();

            return Card(
              margin: const EdgeInsets.only(bottom: 4),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: _getSessionStatusColor(sessionCompletions),
                      child: Text(
                        '$sessionNumber',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sesión $sessionNumber',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '${_formatDate(session.date)} - ${session.startTime} a ${session.endTime}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildSessionStatus(sessionCompletions, theme),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSessionStatus(List<SessionCompletion> completions, ThemeData theme) {
    if (completions.isEmpty) {
      return Icon(
        Icons.schedule,
        color: Colors.grey,
        size: 16,
      );
    }

    final approvedCompletions = completions
        .where((c) => c.status == CompletionStatus.APPROVED || c.status == CompletionStatus.COMPLETED)
        .length;

    final totalCompletions = completions.length;

    return Column(
      children: [
        Icon(
          _getSessionStatusIcon(completions),
          color: _getSessionStatusColor(completions),
          size: 16,
        ),
        Text(
          '$approvedCompletions/$totalCompletions',
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: 10,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  // Helper methods
  Map<String, dynamic> _calculateProgress() {
    final participants = activity.participants;
    final totalSessions = activity.numberOfSessions;
    final totalRequired = participants.length * totalSessions;
    
    int completed = 0;
    if (activity.sessionCompletions.isNotEmpty) {
      completed = activity.sessionCompletions
          .where((c) => c.status == CompletionStatus.APPROVED || c.status == CompletionStatus.COMPLETED)
          .length;
    }
    
    final percentage = totalRequired > 0 ? (completed / totalRequired) * 100 : 0;
    final isCompleted = completed >= totalRequired;
    
    return {
      'completed': completed,
      'total': totalRequired,
      'percentage': percentage,
      'isCompleted': isCompleted,
    };
  }

  Map<String, dynamic> _calculateUserProgress() {
    // TODO: Implementar cálculo de progreso del usuario actual
    // Por ahora retornamos valores de ejemplo
    return {
      'completed': 2,
      'total': 5,
      'percentage': 40.0,
      'isCompleted': false,
      'nextSession': activity.sessionDates.isNotEmpty ? activity.sessionDates[2].date : null,
    };
  }

  Color _getSessionStatusColor(List<SessionCompletion> completions) {
    if (completions.isEmpty) return Colors.grey;
    
    final hasApproved = completions.any((c) => 
        c.status == CompletionStatus.APPROVED || c.status == CompletionStatus.COMPLETED);
    
    if (hasApproved) return Colors.green;
    
    final hasPending = completions.any((c) => c.status == CompletionStatus.PENDING_APPROVAL);
    if (hasPending) return Colors.orange;
    
    return Colors.grey;
  }

  IconData _getSessionStatusIcon(List<SessionCompletion> completions) {
    if (completions.isEmpty) return Icons.schedule;
    
    final hasApproved = completions.any((c) => 
        c.status == CompletionStatus.APPROVED || c.status == CompletionStatus.COMPLETED);
    
    if (hasApproved) return Icons.check_circle;
    
    final hasPending = completions.any((c) => c.status == CompletionStatus.PENDING_APPROVAL);
    if (hasPending) return Icons.pending;
    
    return Icons.schedule;
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
} 