import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../shared/models/activity_model.dart';
import '../../../../shared/services/activity_service.dart';
import '../../../../shared/providers/data_provider.dart';
import '../../../../shared/providers/auth_provider.dart';

class SessionActionButtons extends StatefulWidget {
  final ActivityModel activity;
  final int sessionNumber;
  final bool canComplete;
  final bool canApprove;
  final VoidCallback? onActivityUpdate;

  const SessionActionButtons({
    super.key,
    required this.activity,
    required this.sessionNumber,
    required this.canComplete,
    required this.canApprove,
    this.onActivityUpdate,
  });

  @override
  State<SessionActionButtons> createState() => _SessionActionButtonsState();
}

class _SessionActionButtonsState extends State<SessionActionButtons> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final currentUser = context.read<AuthProvider>().userData;
    if (currentUser == null) return const SizedBox.shrink();

    final isResponsible = widget.activity.responsibleUsers.any((r) => r.userId == currentUser.uid);
    final isParticipant = widget.activity.participants.any((p) => p.userId == currentUser.uid);
    
    // Obtener el estado de completación del usuario actual
    final userCompletion = _getUserSessionProgress(currentUser.uid);
    final pendingCompletions = _getPendingCompletions();
    
    return Column(
      children: [
        // Botón principal según el rol y estado
        if (isParticipant && userCompletion == null) ...[
          // Participante puede completar
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : () => _completeSession(),
              icon: const Icon(Icons.check_circle, size: 18),
              label: Text('Enviar Sesión ${widget.sessionNumber}'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ] else if (isParticipant && userCompletion != null) ...[
          // Participante ya completó - mostrar estado
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                Icon(
                  userCompletion.status == CompletionStatus.APPROVED 
                      ? Icons.check_circle 
                      : Icons.schedule,
                  color: userCompletion.status == CompletionStatus.APPROVED 
                      ? Colors.green 
                      : Colors.orange,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  userCompletion.status == CompletionStatus.APPROVED 
                      ? 'Sesión aprobada' 
                      : 'Pendiente de aprobación',
                  style: TextStyle(
                    color: userCompletion.status == CompletionStatus.APPROVED 
                        ? Colors.green 
                        : Colors.orange,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ] else if (isResponsible && _canResponsibleComplete()) ...[
          // Responsable puede completar (después de aprobar a todos)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : () => _completeSession(),
              icon: const Icon(Icons.check_circle, size: 18),
              label: Text('Completar Sesión ${widget.sessionNumber}'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ] else if (isResponsible && !_canResponsibleComplete()) ...[
          // Responsable no puede completar aún
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade300),
            ),
            child: Row(
              children: [
                const Icon(Icons.lock, color: Colors.orange, size: 18),
                const SizedBox(width: 8),
                const Text(
                  'Esperando completaciones de participantes',
                  style: TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
        
        // Botón de aprobación para responsables
        if (isResponsible && pendingCompletions.isNotEmpty) ...[
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _isLoading ? null : () => _showApprovalDialog(),
              icon: const Icon(Icons.approval, size: 18),
              label: Text('Aprobar Participantes (${pendingCompletions.length})'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.orange,
                side: const BorderSide(color: Colors.orange),
              ),
            ),
          ),
        ],
        
        // Mostrar completaciones pendientes
        if (pendingCompletions.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Completaciones pendientes de aprobación:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                ...pendingCompletions.map((completion) => 
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.person, size: 16, color: Colors.orange),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Usuario ${completion.userId} - ${_formatDate(completion.completedAt)}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        if (isResponsible)
                          ElevatedButton(
                            onPressed: _isLoading ? null : () => _approveSession(completion.userId),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            ),
                            child: const Text('Aprobar', style: TextStyle(fontSize: 12)),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  bool _canResponsibleComplete() {
    final participants = widget.activity.participants;
    final participantUserIds = participants.map((p) => p.userId).toList();
    
    // Verificar que todos los participantes hayan completado y sido aprobados
    for (final participantId in participantUserIds) {
      final participantCompletion = _getUserSessionProgress(participantId);
      if (participantCompletion == null || participantCompletion.status != CompletionStatus.APPROVED) {
        return false;
      }
    }
    return true;
  }

  List<SessionCompletion> _getPendingCompletions() {
    return widget.activity.sessionCompletions
        .where((c) => c.sessionNumber == widget.sessionNumber && 
            c.status == CompletionStatus.PENDING_APPROVAL)
        .toList();
  }

  SessionCompletion? _getUserSessionProgress(String userId) {
    try {
      return widget.activity.sessionCompletions.firstWhere(
        (c) => c.sessionNumber == widget.sessionNumber && c.userId == userId,
      );
    } catch (e) {
      return null;
    }
  }

  void _completeSession() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final activityService = ActivityService();
      await activityService.completeSession(widget.activity.activityId, widget.sessionNumber);
      
      if (mounted) {
        final currentUser = context.read<AuthProvider>().userData;
        final isResponsible = widget.activity.responsibleUsers.any((r) => r.userId == currentUser?.uid);
        
        String message;
        if (isResponsible) {
          message = 'Sesión ${widget.sessionNumber} completada exitosamente como responsable';
        } else {
          message = 'Sesión ${widget.sessionNumber} enviada para revisión';
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
        widget.onActivityUpdate?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al completar sesión: ${e.toString()}'),
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

  void _showApprovalDialog() {
    final pendingCompletions = _getPendingCompletions();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Aprobar Sesión ${widget.sessionNumber}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Completaciones pendientes de aprobación:'),
            const SizedBox(height: 12),
            ...pendingCompletions.map((completion) => 
              Card(
                child: ListTile(
                  title: Text('Usuario: ${completion.userId}'),
                  subtitle: Text('Completado: ${_formatDate(completion.completedAt)}'),
                  trailing: ElevatedButton(
                    onPressed: () => _approveSession(completion.userId),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Aprobar'),
                  ),
                ),
              ),
            ),
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

  void _approveSession(String participantUserId) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final activityService = ActivityService();
      await activityService.approveSessionCompletion(
        widget.activity.activityId, 
        participantUserId, 
        widget.sessionNumber,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sesión ${widget.sessionNumber} aprobada para el participante'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
        
        // Refresh the activity data
        context.read<DataProvider>().loadActivities();
        widget.onActivityUpdate?.call();
        Navigator.of(context).pop(); // Close dialog if open
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al aprobar sesión: ${e.toString()}'),
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
} 