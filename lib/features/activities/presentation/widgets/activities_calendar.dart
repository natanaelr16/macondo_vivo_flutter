import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../../shared/models/activity_model.dart';
import '../../../../shared/models/user_model.dart';
import '../../../../shared/providers/data_provider.dart';
import '../../../../shared/providers/auth_provider.dart';
import 'activity_details_dialog.dart';

class ActivitiesCalendar extends StatefulWidget {
  final VoidCallback? onActivityUpdate;

  const ActivitiesCalendar({
    super.key,
    this.onActivityUpdate,
  });

  @override
  State<ActivitiesCalendar> createState() => _ActivitiesCalendarState();
}

class _ActivitiesCalendarState extends State<ActivitiesCalendar> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<ActivityModel>> _events = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dataProvider = Provider.of<DataProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUserId = authProvider.firebaseUser?.uid;

    // Filtrar actividades según permisos del usuario
    final filteredActivities = _getFilteredActivities(dataProvider.activities, authProvider.userData, currentUserId);
    
    // Generar eventos para el calendario
    _generateEvents(filteredActivities);

    return Column(
      children: [
        // Calendario
        Card(
          margin: const EdgeInsets.all(16),
          child: TableCalendar<ActivityModel>(
            firstDay: DateTime.utc(2024, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) {
              return isSameDay(_selectedDay, day);
            },
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            onFormatChanged: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
            eventLoader: (day) {
              return _getEventsForDay(day);
            },
            calendarStyle: CalendarStyle(
              outsideDaysVisible: false,
              weekendTextStyle: const TextStyle(color: Colors.red),
              holidayTextStyle: const TextStyle(color: Colors.red),
              selectedDecoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              markerDecoration: BoxDecoration(
                color: Colors.orange,
                shape: BoxShape.circle,
              ),
              markersMaxCount: 3,
            ),
            headerStyle: HeaderStyle(
              formatButtonVisible: true,
              titleCentered: true,
              formatButtonShowsNext: false,
              formatButtonDecoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              formatButtonTextStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),

        // Eventos del día seleccionado
        if (_selectedDay != null)
          _buildSelectedDayEvents(),
      ],
    );
  }

  Widget _buildSelectedDayEvents() {
    final events = _getEventsForDay(_selectedDay!);
    
    if (events.isEmpty) {
      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Center(
            child: Text(
              'No hay actividades programadas para este día',
              style: TextStyle(
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Actividades del ${_formatDate(_selectedDay!)}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final activity = events[index];
              return _buildEventCard(activity);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(ActivityModel activity) {
    final theme = Theme.of(context);
    final session = _getSessionForDay(activity, _selectedDay!);
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(activity.status),
          child: Icon(
            _getStatusIcon(activity.status),
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          activity.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (session != null)
              Text(
                'Sesión ${session.sessionNumber} - ${session.startTime} a ${session.endTime}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            if (activity.category != null)
              Text(
                activity.category!,
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.secondary,
                ),
              ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.arrow_forward_ios, size: 16),
          onPressed: () => _showActivityDetails(activity),
        ),
        onTap: () => _showActivityDetails(activity),
      ),
    );
  }

  // Helper methods
  List<ActivityModel> _getFilteredActivities(
    List<ActivityModel> activities,
    UserModel? user,
    String? currentUserId,
  ) {
    if (currentUserId == null) return [];

    // Función auxiliar para verificar si el usuario puede ver la actividad
    bool canUserSeeActivity(ActivityModel activity) {
      // SuperUser y ADMIN pueden ver todas las actividades
      if (user?.isSuperUser == true || user?.isAdmin == true) return true;
      
      // Usuarios normales solo ven actividades donde son responsables o participantes
      final isResponsible = activity.responsibleUsers.any((r) => r.userId == currentUserId);
      final isParticipant = activity.participants.any((p) => p.userId == currentUserId);
      
      return isResponsible || isParticipant;
    }

    return activities.where(canUserSeeActivity).toList();
  }

  void _generateEvents(List<ActivityModel> activities) {
    _events.clear();
    
    for (final activity in activities) {
      for (final session in activity.sessionDates) {
        final eventDate = DateTime(
          session.date.year,
          session.date.month,
          session.date.day,
        );
        
        if (_events[eventDate] == null) {
          _events[eventDate] = [];
        }
        _events[eventDate]!.add(activity);
      }
    }
  }

  List<ActivityModel> _getEventsForDay(DateTime day) {
    final eventDate = DateTime(day.year, day.month, day.day);
    return _events[eventDate] ?? [];
  }

  SessionDate? _getSessionForDay(ActivityModel activity, DateTime day) {
    try {
      return activity.sessionDates.firstWhere((session) {
        return session.date.year == day.year &&
               session.date.month == day.month &&
               session.date.day == day.day;
      });
    } catch (e) {
      return null;
    }
  }

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

  String _formatDate(DateTime date) {
    const months = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    
    return '${date.day} de ${months[date.month - 1]} de ${date.year}';
  }

  void _showActivityDetails(ActivityModel activity) {
    showDialog(
      context: context,
      builder: (context) => ActivityDetailsDialog(
        activity: activity,
        onActivityUpdate: widget.onActivityUpdate,
      ),
    );
  }
} 