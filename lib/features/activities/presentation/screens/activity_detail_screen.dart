import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/providers/data_provider.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../../../shared/models/activity_model.dart';
import '../../../../shared/models/user_model.dart';
import '../../../../shared/services/activity_service.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../widgets/session_action_buttons.dart';

class ActivityDetailScreen extends StatefulWidget {
  final ActivityModel activity;

  const ActivityDetailScreen({
    super.key,
    required this.activity,
  });

  @override
  State<ActivityDetailScreen> createState() => _ActivityDetailScreenState();
}

class _ActivityDetailScreenState extends State<ActivityDetailScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final backgroundColor = theme.colorScheme.surface;
    final textColor = theme.colorScheme.onSurface;
    final textSecondaryColor = theme.colorScheme.onSurface.withOpacity(0.7);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Detalles de Actividad'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _editActivity(),
          ),
        ],
      ),
      body: Consumer2<DataProvider, AuthProvider>(
        builder: (context, dataProvider, authProvider, child) {
          final currentUser = authProvider.userData;
          final users = dataProvider.users;
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with status and category
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
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getStatusColor(widget.activity.status).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(_getStatusIcon(widget.activity.status), 
                                     size: 16, 
                                     color: _getStatusColor(widget.activity.status)),
                                const SizedBox(width: 4),
                                Text(
                                  _getStatusLabel(widget.activity.status),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: _getStatusColor(widget.activity.status),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              widget.activity.category ?? 'General',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: primaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.activity.title,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.activity.description,
                        style: TextStyle(
                          fontSize: 16,
                          color: textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Progress section
                _buildProgressSection(textColor, primaryColor),

                const SizedBox(height: 24),

                // Sessions section
                _buildSessionsSection(textColor, primaryColor, currentUser, users),

                const SizedBox(height: 24),

                // Participants section
                _buildParticipantsSection(textColor, primaryColor, users),

                const SizedBox(height: 24),

                // Responsible users section
                _buildResponsibleUsersSection(textColor, primaryColor, users),

                const SizedBox(height: 24),

                // Additional details
                _buildAdditionalDetailsSection(textColor, textSecondaryColor),

                const SizedBox(height: 24),

                // Action buttons
                _buildActionButtons(currentUser, primaryColor),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProgressSection(Color textColor, Color primaryColor) {
    final progress = _calculateProgress();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.trending_up, color: Colors.green, size: 20),
              const SizedBox(width: 8),
              Text(
                'Progreso de la Actividad',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${progress['percentage']}%',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    Text(
                      'Completado',
                      style: TextStyle(
                        fontSize: 14,
                        color: textColor.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${progress['current']}/${progress['total']}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    Text(
                      'Sesiones completadas',
                      style: TextStyle(
                        fontSize: 12,
                        color: textColor.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: progress['percentage'] / 100,
            backgroundColor: textColor.withOpacity(0.1),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
            minHeight: 8,
          ),
        ],
      ),
    );
  }

  Widget _buildSessionsSection(Color textColor, Color primaryColor, UserModel? currentUser, List<UserModel> users) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sesiones (${widget.activity.sessionDates.length})',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        const SizedBox(height: 16),
        ...widget.activity.sessionDates.asMap().entries.map((entry) {
          final index = entry.key;
          final session = entry.value;
          final sessionNumber = session.sessionNumber;
          final sessionDate = session.date;
          final startTime = session.startTime;
          final endTime = session.endTime;
          
          final userProgress = _getUserSessionProgress(sessionNumber, currentUser?.uid);
          final canComplete = _canCompleteSession(sessionNumber, currentUser);
          final canApprove = _canApproveSession(sessionNumber, currentUser);
          
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.withOpacity(0.2)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.event,
                        color: primaryColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sesión $sessionNumber',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          Text(
                            '${_formatDate(sessionDate)} • $startTime - $endTime',
                            style: TextStyle(
                              fontSize: 14,
                              color: textColor.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (userProgress != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getCompletionStatusColor(userProgress.status).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _getCompletionStatusLabel(userProgress.status),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: _getCompletionStatusColor(userProgress.status),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Session actions
                SessionActionButtons(
                  activity: widget.activity,
                  sessionNumber: sessionNumber,
                  canComplete: canComplete,
                  canApprove: canApprove,
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildParticipantsSection(Color textColor, Color primaryColor, List<UserModel> users) {
    final participants = widget.activity.participants;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Participantes (${participants.length})',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        const SizedBox(height: 16),
        if (participants.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.people_outline, color: Colors.grey, size: 20),
                const SizedBox(width: 8),
                Text(
                  'No hay participantes asignados',
                  style: TextStyle(
                    fontSize: 14,
                    color: textColor.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          )
        else
          ...participants.map((participant) {
            final user = users.firstWhere(
              (u) => u.uid == participant.userId,
              orElse: () => UserModel(
                uid: participant.userId,
                firstName: 'Usuario',
                lastName: 'Desconocido',
                email: '',
                documentType: DocumentType.CC,
                documentNumber: 'N/A',
                userType: UserType.ESTUDIANTE,
                appRole: AppRole.USER,
                isActive: true,
                provisionalPasswordSet: false,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              ),
            );
            
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: primaryColor.withOpacity(0.1),
                    child: Text(
                      '${user.firstName[0]}${user.lastName[0]}',
                      style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${user.firstName} ${user.lastName}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                        Text(
                          user.email,
                          style: TextStyle(
                            fontSize: 12,
                            color: textColor.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getParticipantStatusColor(participant.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      participant.status,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: _getParticipantStatusColor(participant.status),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
      ],
    );
  }

  Widget _buildResponsibleUsersSection(Color textColor, Color primaryColor, List<UserModel> users) {
    final responsibleUsers = widget.activity.responsibleUsers;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Responsables (${responsibleUsers.length})',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        const SizedBox(height: 16),
        if (responsibleUsers.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.person, color: Colors.grey, size: 20),
                const SizedBox(width: 8),
                Text(
                  'No hay responsables asignados',
                  style: TextStyle(
                    fontSize: 14,
                    color: textColor.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          )
        else
          ...responsibleUsers.map((responsible) {
            final user = users.firstWhere(
              (u) => u.uid == responsible.userId,
              orElse: () => UserModel(
                uid: responsible.userId,
                firstName: 'Usuario',
                lastName: 'Desconocido',
                email: '',
                documentType: DocumentType.CC,
                documentNumber: 'N/A',
                userType: UserType.ESTUDIANTE,
                appRole: AppRole.USER,
                isActive: true,
                provisionalPasswordSet: false,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              ),
            );
            
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: primaryColor.withOpacity(0.1),
                    child: Icon(
                      Icons.person,
                      color: primaryColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${user.firstName} ${user.lastName}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                        Text(
                          'Responsable • ${user.appRole.name}',
                          style: TextStyle(
                            fontSize: 12,
                            color: textColor.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getParticipantStatusColor(responsible.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      responsible.status,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: _getParticipantStatusColor(responsible.status),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
      ],
    );
  }

  Widget _buildAdditionalDetailsSection(Color textColor, Color textSecondaryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Detalles Adicionales',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        const SizedBox(height: 16),
        
        // Estimated duration
        if (widget.activity.estimatedDuration != null) ...[
          _buildDetailItem(
            Icons.timer,
            'Duración Estimada',
            '${widget.activity.estimatedDuration} minutos',
            textColor,
            textSecondaryColor,
          ),
          const SizedBox(height: 12),
        ],
        
        // Submission link
        if (widget.activity.submissionLink != null && widget.activity.submissionLink!.isNotEmpty) ...[
          _buildDetailItem(
            Icons.link,
            'Enlace de Entrega',
            widget.activity.submissionLink!,
            textColor,
            textSecondaryColor,
            isLink: true,
          ),
          const SizedBox(height: 12),
        ],
        
        // Materials
        if (widget.activity.materials.isNotEmpty) ...[
          _buildDetailItem(
            Icons.inventory,
            'Materiales',
            widget.activity.materials.join(', '),
            textColor,
            textSecondaryColor,
          ),
          const SizedBox(height: 12),
        ],
        
        // Objectives
        if (widget.activity.objectives.isNotEmpty) ...[
          _buildDetailItem(
            Icons.flag,
            'Objetivos',
            widget.activity.objectives.join(', '),
            textColor,
            textSecondaryColor,
          ),
        ],
      ],
    );
  }

  Widget _buildDetailItem(
    IconData icon,
    String title,
    String value,
    Color textColor,
    Color textSecondaryColor, {
    bool isLink = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: textSecondaryColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: textSecondaryColor,
                  ),
                ),
                const SizedBox(height: 2),
                if (isLink)
                  GestureDetector(
                    onTap: () => _openLink(value),
                    child: Text(
                      value,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  )
                else
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 14,
                      color: textColor,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(UserModel? currentUser, Color primaryColor) {
    final canEdit = _canEditActivity(currentUser);
    final canDelete = _canDeleteActivity(currentUser);
    
    return Column(
      children: [
        if (canEdit)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _editActivity,
              icon: const Icon(Icons.edit),
              label: const Text('Editar Actividad'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        if (canEdit && canDelete) const SizedBox(height: 12),
        if (canDelete)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _deleteActivity,
              icon: const Icon(Icons.delete, color: Colors.red),
              label: const Text('Eliminar Actividad', style: TextStyle(color: Colors.red)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
      ],
    );
  }

  // Helper methods
  Map<String, dynamic> _calculateProgress() {
    final participants = widget.activity.participants;
    final totalParticipants = participants.length;
    final totalSessions = widget.activity.numberOfSessions;
    
    // Solo contar sesiones completadas por participantes (no responsables)
    final participantUserIds = participants.map((p) => p.userId).toList();
    final completions = widget.activity.sessionCompletions;
    
    // Contar solo completaciones de participantes que estén aprobadas o completadas
    final validCompletions = completions.where((c) => 
      participantUserIds.contains(c.userId) && 
      (c.status == CompletionStatus.APPROVED || c.status == CompletionStatus.COMPLETED)
    ).length;
    
    final totalRequiredCompletions = totalParticipants * totalSessions;
    final percentage = totalRequiredCompletions > 0 
        ? ((validCompletions / totalRequiredCompletions * 100).round()).clamp(0, 100)
        : 0;
    
    return {
      'percentage': percentage,
      'current': validCompletions,
      'total': totalRequiredCompletions,
      'isComplete': validCompletions >= totalRequiredCompletions,
    };
  }

  SessionCompletion? _getUserSessionProgress(int sessionNumber, String? userId) {
    if (userId == null) return null;
    
    final completions = widget.activity.sessionCompletions;
    try {
      return completions.firstWhere(
        (c) => c.sessionNumber == sessionNumber && c.userId == userId,
      );
    } catch (e) {
      return null;
    }
  }

  bool _canCompleteSession(int sessionNumber, UserModel? currentUser) {
    if (currentUser == null) return false;
    
    // Verificar si ya completó esta sesión
    final existingCompletion = _getUserSessionProgress(sessionNumber, currentUser.uid);
    if (existingCompletion != null) return false;
    
    // Verificar si es la próxima sesión a completar
    final userCompletions = widget.activity.sessionCompletions
        .where((c) => c.userId == currentUser.uid && 
            (c.status == CompletionStatus.APPROVED || c.status == CompletionStatus.COMPLETED))
        .map((c) => c.sessionNumber)
        .toList();
    
    final nextSession = userCompletions.isEmpty ? 1 : userCompletions.reduce((a, b) => a > b ? a : b) + 1;
    
    // Si no es la próxima sesión, no puede completar
    if (sessionNumber != nextSession) return false;
    
    // Verificar si es responsable
    final isResponsible = widget.activity.responsibleUsers.any((r) => r.userId == currentUser.uid);
    
    // Si es responsable, verificar que todos los participantes hayan completado y sido aprobados
    if (isResponsible) {
      final participants = widget.activity.participants;
      final participantUserIds = participants.map((p) => p.userId).toList();
      
      // Verificar que todos los participantes hayan completado esta sesión
      for (final participantId in participantUserIds) {
        final participantCompletion = _getUserSessionProgress(sessionNumber, participantId);
        if (participantCompletion == null || participantCompletion.status != CompletionStatus.APPROVED) {
          return false; // Al menos un participante no ha completado o no ha sido aprobado
        }
      }
    }
    
    return true;
  }

  bool _canApproveSession(int sessionNumber, UserModel? currentUser) {
    if (currentUser == null) return false;
    
    // Only responsible users can approve
    final isResponsible = widget.activity.responsibleUsers.any((r) => r.userId == currentUser.uid);
    if (!isResponsible) return false;
    
    // Check if there are pending completions to approve
    final completions = widget.activity.sessionCompletions;
    final pendingCompletions = completions.where((c) => 
      c.sessionNumber == sessionNumber && c.status == CompletionStatus.PENDING_APPROVAL
    );
    
    return pendingCompletions.isNotEmpty;
  }

  bool _canEditActivity(UserModel? currentUser) {
    if (currentUser == null) return false;
    
    if (currentUser.appRole == AppRole.SuperUser) return true;
    if (currentUser.appRole == AppRole.ADMIN) {
      return widget.activity.createdBy_uid == currentUser.uid;
    }
    
    return false;
  }

  bool _canDeleteActivity(UserModel? currentUser) {
    if (currentUser == null) return false;
    
    if (currentUser.appRole == AppRole.SuperUser) return true;
    if (currentUser.appRole == AppRole.ADMIN) {
      return widget.activity.createdBy_uid == currentUser.uid;
    }
    
    return false;
  }

  Color _getStatusColor(ActivityStatus status) {
    switch (status) {
      case ActivityStatus.ACTIVA:
        return const Color(0xFFFF5722);
      case ActivityStatus.COMPLETADA:
        return const Color(0xFF4CAF50);
      case ActivityStatus.INACTIVA:
        return const Color(0xFF9E9E9E);
    }
  }

  IconData _getStatusIcon(ActivityStatus status) {
    switch (status) {
      case ActivityStatus.ACTIVA:
        return Icons.assignment;
      case ActivityStatus.COMPLETADA:
        return Icons.check_circle;
      case ActivityStatus.INACTIVA:
        return Icons.schedule;
    }
  }

  String _getStatusLabel(ActivityStatus status) {
    switch (status) {
      case ActivityStatus.ACTIVA:
        return 'Activa';
      case ActivityStatus.COMPLETADA:
        return 'Completada';
      case ActivityStatus.INACTIVA:
        return 'Inactiva';
    }
  }

  Color _getCompletionStatusColor(CompletionStatus status) {
    switch (status) {
      case CompletionStatus.PENDING_APPROVAL:
        return const Color(0xFFFF9800);
      case CompletionStatus.APPROVED:
        return const Color(0xFF2196F3);
      case CompletionStatus.COMPLETED:
        return const Color(0xFF4CAF50);
    }
  }

  String _getCompletionStatusLabel(CompletionStatus status) {
    switch (status) {
      case CompletionStatus.PENDING_APPROVAL:
        return 'Pendiente';
      case CompletionStatus.APPROVED:
        return 'Aprobado';
      case CompletionStatus.COMPLETED:
        return 'Completado';
    }
  }

  Color _getParticipantStatusColor(String status) {
    switch (status) {
      case 'ACTIVO':
        return const Color(0xFF4CAF50);
      case 'PENDIENTE':
        return const Color(0xFFFF9800);
      case 'INACTIVO':
        return const Color(0xFF9E9E9E);
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  // Action methods
  void _editActivity() {
    // TODO: Implement edit activity
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Función de edición en desarrollo'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _deleteActivity() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Actividad'),
        content: const Text('¿Estás seguro de que quieres eliminar esta actividad? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _confirmDeleteActivity();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteActivity() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await context.read<DataProvider>().deleteActivity(widget.activity.activityId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Actividad eliminada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar actividad: ${e.toString()}'),
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

  void _completeSession(int sessionNumber) async {
    final currentUser = context.read<AuthProvider>().userData;
    
    // Validar si puede completar la sesión
    if (!_canCompleteSession(sessionNumber, currentUser)) {
      final isResponsible = widget.activity.responsibleUsers.any((r) => r.userId == currentUser?.uid);
      
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
      _isLoading = true;
    });

    try {
      final activityService = ActivityService();
      await activityService.completeSession(widget.activity.activityId, sessionNumber);
      
      if (mounted) {
        final isResponsible = widget.activity.responsibleUsers.any((r) => r.userId == currentUser?.uid);
        
        String message;
        if (isResponsible) {
          message = 'Sesión $sessionNumber completada exitosamente como responsable';
        } else {
          message = 'Sesión $sessionNumber marcada como completada. Pendiente de aprobación del responsable.';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
        // Refresh the activity data
        context.read<DataProvider>().loadActivities();
      }
    } catch (e) {
      if (mounted) {
        final isResponsible = widget.activity.responsibleUsers.any((r) => r.userId == currentUser?.uid);
        
        String errorMessage;
        if (isResponsible) {
          errorMessage = 'Error al completar sesión $sessionNumber como responsable: ${e.toString()}';
        } else {
          errorMessage = 'Error al marcar sesión $sessionNumber como completada: ${e.toString()}';
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
          _isLoading = false;
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
      final participantCompletion = _getUserSessionProgress(sessionNumber, participantId);
      if (participantCompletion == null) {
        pendingParticipants.add('Usuario $participantId: No ha completado la sesión');
      } else if (participantCompletion.status != CompletionStatus.APPROVED) {
        pendingParticipants.add('Usuario $participantId: ${_getCompletionStatusLabel(participantCompletion.status)}');
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

  void _showApprovalDialog(int sessionNumber) {
    final completions = widget.activity.sessionCompletions;
    final pendingCompletions = completions.where((c) => 
      c.sessionNumber == sessionNumber && c.status == CompletionStatus.PENDING_APPROVAL
    ).toList();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Aprobar Sesión $sessionNumber'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Completaciones pendientes de aprobación:'),
            const SizedBox(height: 12),
            ...pendingCompletions.map((completion) {
              return ListTile(
                title: Text('Usuario: ${completion.userId}'),
                subtitle: Text('Completado: ${_formatDate(completion.completedAt)}')
              );
            }).toList(),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _openLink(String url) {
    // TODO: Implement link opening
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Abriendo enlace: $url'),
        backgroundColor: Colors.blue,
      ),
    );
  }
}