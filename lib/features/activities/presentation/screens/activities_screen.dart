import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../../shared/providers/data_provider.dart';
import '../../../../core/widgets/bottom_navigation.dart';
import '../../../../shared/models/activity_model.dart';
import '../../../../shared/models/user_model.dart';
import '../widgets/create_activity_form.dart';
import '../../../../core/widgets/loading_widget.dart';
import 'activity_detail_screen.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../../../core/widgets/fixed_bottom_navigation.dart';
import '../../../../core/widgets/main_layout.dart';

enum ActivityFilter {
  all,
  myActivities,
  active,
  completed,
  inactive,
}

enum ActivityView {
  list,
  calendar,
}

class ActivitiesScreen extends StatefulWidget {
  const ActivitiesScreen({super.key});

  @override
  State<ActivitiesScreen> createState() => _ActivitiesScreenState();
}

class _ActivitiesScreenState extends State<ActivitiesScreen> {
  ActivityFilter _currentFilter = ActivityFilter.all;
  ActivityView _currentView = ActivityView.list;
  String _searchQuery = '';
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    print('ActivitiesScreen: initState called');
    
    // Load activities when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('ActivitiesScreen: Post frame callback, loading activities...');
      final dataProvider = Provider.of<DataProvider>(context, listen: false);
      dataProvider.loadActivities();
    });
  }

  @override
  Widget build(BuildContext context) {
    print('ActivitiesScreen: Building widget...');
    
    final primaryColor = Theme.of(context).colorScheme.primary;
    final backgroundColor = Theme.of(context).colorScheme.surface;
    final cardColor = Theme.of(context).colorScheme.surface;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final textSecondaryColor = Theme.of(context).colorScheme.onSurface.withOpacity(0.7);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Actividades Educativas'),
        actions: [
          // View toggle buttons
          Row(
            children: [
              IconButton(
                icon: Icon(
                  Icons.view_list,
                  color: _currentView == ActivityView.list ? primaryColor : textSecondaryColor,
                ),
                onPressed: () {
                  setState(() => _currentView = ActivityView.list);
                },
              ),
              IconButton(
                icon: Icon(
                  Icons.calendar_today,
                  color: _currentView == ActivityView.calendar ? primaryColor : textSecondaryColor,
                ),
                onPressed: () {
                  setState(() => _currentView = ActivityView.calendar);
                },
              ),
            ],
          ),
        ],
      ),
      // Ocultar botón flotante en vista de calendario
      floatingActionButton: _currentView == ActivityView.calendar 
          ? null 
          : Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                // Solo mostrar botón de crear para ADMIN y SuperUser
                final user = authProvider.userData;
                if (user == null || (user.appRole != AppRole.ADMIN && user.appRole != AppRole.SuperUser)) {
                  return const SizedBox.shrink();
                }
                
                return FloatingActionButton(
                  onPressed: () => _showCreateActivityDialog(context),
                  backgroundColor: primaryColor,
                  child: const Icon(Icons.add, color: Colors.white),
                );
              },
            ),
      body: Consumer2<DataProvider, AuthProvider>(
        builder: (context, dataProvider, authProvider, child) {
          print('ActivitiesScreen: DataProvider state - isLoading: ${dataProvider.isLoading}, activities count: ${dataProvider.activities.length}, error: ${dataProvider.error}');
          print('ActivitiesScreen: AuthProvider state - user: ${authProvider.userData?.email}, role: ${authProvider.userData?.appRole}');
          
          if (dataProvider.isLoading) {
            print('ActivitiesScreen: Showing loading widget');
            return const LoadingWidget();
          }

          if (dataProvider.error != null) {
            print('ActivitiesScreen: Showing error: ${dataProvider.error}');
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error al cargar actividades',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    dataProvider.error!,
                    style: TextStyle(color: textSecondaryColor),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => dataProvider.loadActivities(),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          final allActivities = dataProvider.activities;
          final filteredActivities = _getFilteredActivities(allActivities, authProvider);
          final myActivitiesCount = _getMyActivitiesCount(allActivities, authProvider);
          print('ActivitiesScreen: Displaying ${filteredActivities.length} filtered activities out of ${allActivities.length} total');

          if (allActivities.isEmpty) {
            print('ActivitiesScreen: No activities found, showing empty state');
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.assignment_outlined,
                    size: 64,
                    color: textSecondaryColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No hay actividades registradas',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Agrega la primera actividad usando el botón +',
                    style: TextStyle(color: textSecondaryColor),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Solo mostrar búsqueda y filtros en vista de lista
              if (_currentView == ActivityView.list) ...[
                // Search and filter bar
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Search bar
                      TextField(
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Buscar actividades...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: cardColor,
                        ),
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Filter chips with scroll indicators
                      Column(
                        children: [
                          // Filter chips scrollable
                          Container(
                            height: 50,
                            child: Stack(
                              children: [
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: [
                                      const SizedBox(width: 4), // Left padding
                                      _buildFilterChip('Todas', ActivityFilter.all),
                                      const SizedBox(width: 8),
                                      _buildFilterChip('Mis Actividades ($myActivitiesCount)', ActivityFilter.myActivities),
                                      const SizedBox(width: 8),
                                      _buildFilterChip('Activas', ActivityFilter.active),
                                      const SizedBox(width: 8),
                                      _buildFilterChip('Completadas', ActivityFilter.completed),
                                      const SizedBox(width: 8),
                                      _buildFilterChip('Inactivas', ActivityFilter.inactive),
                                      const SizedBox(width: 4), // Right padding
                                    ],
                                  ),
                                ),
                                
                                // Left gradient indicator
                                Positioned(
                                  left: 0,
                                  top: 0,
                                  bottom: 0,
                                  child: Container(
                                    width: 20,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                        colors: [
                                          cardColor,
                                          cardColor.withOpacity(0.0),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                
                                // Right gradient indicator
                                Positioned(
                                  right: 0,
                                  top: 0,
                                  bottom: 0,
                                  child: Container(
                                    width: 20,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.centerRight,
                                        end: Alignment.centerLeft,
                                        colors: [
                                          cardColor,
                                          cardColor.withOpacity(0.0),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          // Scroll hint text below the chips
                          const SizedBox(height: 4),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.swipe_left,
                                    size: 12,
                                    color: primaryColor,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    'Deslizar',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: primaryColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Informational messages
                _buildInfoMessages(authProvider, myActivitiesCount),
                
                const SizedBox(height: 16),
              ],
              
              // Content based on view
              Expanded(
                child: _currentView == ActivityView.list
                    ? _buildActivitiesList(filteredActivities, textColor, cardColor, primaryColor)
                    : _buildCalendarView(filteredActivities, textColor, cardColor, primaryColor),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildInfoMessages(AuthProvider authProvider, int myActivitiesCount) {
    final user = authProvider.userData;
    if (user == null) return const SizedBox.shrink();

    // Mensaje para usuarios normales en pestaña "Todas"
    if (user.appRole == AppRole.USER && _currentFilter == ActivityFilter.all) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blue.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.blue, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '💡 Información de privacidad: Solo puedes ver los detalles de actividades donde estés asignado como participante o responsable.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.blue[700],
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Mensaje para pestaña "Mis Actividades"
    if (_currentFilter == ActivityFilter.myActivities) {
      final myActivities = _getMyActivities(user);
      final asParticipant = myActivities.where((a) => 
        a.participants.any((p) => p.userId == user.uid)
      ).length;
      final asResponsible = myActivities.where((a) => 
        a.responsibleUsers.any((r) => r.userId == user.uid)
      ).length;

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.person_outline, color: Colors.green, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '👤 Mis Actividades: Mostrando $asParticipant como participante y $asResponsible como responsable.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.green[700],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  List<ActivityModel> _getMyActivities(UserModel user) {
    final dataProvider = Provider.of<DataProvider>(context, listen: false);
    return dataProvider.activities.where((activity) {
      final isParticipant = activity.participants.any((p) => p.userId == user.uid);
      final isResponsible = activity.responsibleUsers.any((r) => r.userId == user.uid);
      return isParticipant || isResponsible;
    }).toList();
  }

  int _getMyActivitiesCount(List<ActivityModel> activities, AuthProvider authProvider) {
    final user = authProvider.userData;
    if (user == null) return 0;

    return activities.where((activity) {
      final isParticipant = activity.participants.any((p) => p.userId == user.uid);
      final isResponsible = activity.responsibleUsers.any((r) => r.userId == user.uid);
      return isParticipant || isResponsible;
    }).length;
  }

  Widget _buildActivitiesList(List<ActivityModel> activities, Color textColor, Color cardColor, Color primaryColor) {
    final searchFilteredActivities = activities.where((activity) {
      if (_searchQuery.isEmpty) return true;
      return activity.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             activity.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             (activity.category?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
    }).toList();

    if (searchFilteredActivities.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: textColor.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(
              'No se encontraron actividades',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Intenta con otros términos de búsqueda',
              style: TextStyle(color: textColor.withOpacity(0.7)),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: searchFilteredActivities.length,
      itemBuilder: (context, index) {
        final activity = searchFilteredActivities[index];
        return _buildActivityCard(activity, textColor, cardColor, primaryColor);
      },
    );
  }

  Widget _buildCalendarView(List<ActivityModel> activities, Color textColor, Color cardColor, Color primaryColor) {
    // Get activities for the selected day
    List<ActivityModel> dayActivities = [];
    if (_selectedDay != null) {
      dayActivities = activities.where((activity) {
        return activity.sessionDates.any((session) {
          return session.date.year == _selectedDay!.year &&
                 session.date.month == _selectedDay!.month &&
                 session.date.day == _selectedDay!.day;
        });
      }).toList();
    }

    return Column(
      children: [
        // Compact Calendar widget
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TableCalendar<ActivityModel>(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            calendarFormat: CalendarFormat.month,
            eventLoader: (day) {
              return activities.where((activity) {
                return activity.sessionDates.any((session) {
                  return session.date.year == day.year &&
                         session.date.month == day.month &&
                         session.date.day == day.day;
                });
              }).toList();
            },
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            onPageChanged: (focusedDay) {
              setState(() {
                _focusedDay = focusedDay;
              });
            },
            // Compact calendar style
            calendarStyle: CalendarStyle(
              selectedDecoration: BoxDecoration(
                color: primaryColor,
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: primaryColor.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              markerDecoration: BoxDecoration(
                color: primaryColor,
                shape: BoxShape.circle,
              ),
              // Reduce sizes for compact view
              cellMargin: const EdgeInsets.all(2),
              cellPadding: const EdgeInsets.all(4),
              defaultTextStyle: const TextStyle(fontSize: 12),
              weekendTextStyle: const TextStyle(fontSize: 12),
              outsideTextStyle: const TextStyle(fontSize: 10),
              selectedTextStyle: const TextStyle(fontSize: 12, color: Colors.white),
              todayTextStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            // Compact header style
            headerStyle: HeaderStyle(
              titleCentered: true,
              formatButtonVisible: false,
              titleTextStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              leftChevronIcon: const Icon(Icons.chevron_left, size: 20),
              rightChevronIcon: const Icon(Icons.chevron_right, size: 20),
              headerPadding: const EdgeInsets.symmetric(vertical: 8),
            ),
            // Compact days of week style
            daysOfWeekStyle: const DaysOfWeekStyle(
              weekdayStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
              weekendStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Activities for selected day
        Expanded(
          child: _selectedDay == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.calendar_today, size: 48, color: textColor.withOpacity(0.5)),
                      const SizedBox(height: 12),
                      Text(
                        'Selecciona una fecha',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Para ver las actividades del día',
                        style: TextStyle(color: textColor.withOpacity(0.7), fontSize: 12),
                      ),
                    ],
                  ),
                )
              : dayActivities.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.event_busy, size: 48, color: textColor.withOpacity(0.5)),
                          const SizedBox(height: 12),
                          Text(
                            'No hay actividades',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Para el ${_formatDate(_selectedDay!)}',
                            style: TextStyle(color: textColor.withOpacity(0.7), fontSize: 12),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: dayActivities.length,
                      itemBuilder: (context, index) {
                        final activity = dayActivities[index];
                        return _buildCompactActivityCard(activity, textColor, cardColor, primaryColor);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildActivityCard(ActivityModel activity, Color textColor, Color cardColor, Color primaryColor) {
    final progress = _calculateProgress(activity);
    final nextSession = _getNextSession(activity);
    final statusColor = _getStatusColor(activity.status);
    final statusIcon = _getStatusIcon(activity.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border(
          left: BorderSide(color: statusColor, width: 4),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showActivityDetails(activity),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with status and category
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, size: 16, color: statusColor),
                          const SizedBox(width: 4),
                          Text(
                            _getStatusLabel(activity.status),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: statusColor,
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
                        activity.category ?? 'General',
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
                
                // Title
                Text(
                  activity.title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Description (truncated)
                Text(
                  activity.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    color: textColor.withOpacity(0.7),
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Session info
                if (nextSession != null) ...[
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 16, color: textColor.withOpacity(0.6)),
                      const SizedBox(width: 4),
                      Text(
                        'Próxima sesión: ${_formatDate(nextSession.date)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: textColor.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
                
                // Progress bar
                Column(
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
                            color: textColor.withOpacity(0.7),
                          ),
                        ),
                        Text(
                          '${progress['percentage']}%',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: progress['percentage'] / 100,
                      backgroundColor: textColor.withOpacity(0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _showActivityDetails(activity),
                        child: const Text('Detalles'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _completeSession(activity),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Completar Sesión'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactActivityCard(ActivityModel activity, Color textColor, Color cardColor, Color primaryColor) {
    final progress = _calculateProgress(activity);
    final statusColor = _getStatusColor(activity.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
        border: Border(
          left: BorderSide(color: statusColor, width: 3),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => _showActivityDetails(activity),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Status indicator
                Container(
                  width: 4,
                  height: 40,
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title and status
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              activity.title,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: textColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _getStatusLabel(activity.status),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: statusColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 4),
                      
                      // Category and progress
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              activity.category ?? 'General',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: primaryColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Row(
                              children: [
                                Expanded(
                                  child: LinearProgressIndicator(
                                    value: progress['percentage'] / 100,
                                    backgroundColor: textColor.withOpacity(0.1),
                                    valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                                    minHeight: 4,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '${progress['percentage']}%',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 4),
                      
                      // Participants and sessions info
                      Row(
                        children: [
                          Icon(Icons.people, size: 12, color: textColor.withOpacity(0.6)),
                          const SizedBox(width: 4),
                          Text(
                            '${activity.participants.length} participantes',
                            style: TextStyle(
                              fontSize: 10,
                              color: textColor.withOpacity(0.6),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(Icons.event, size: 12, color: textColor.withOpacity(0.6)),
                          const SizedBox(width: 4),
                          Text(
                            '${activity.numberOfSessions} sesiones',
                            style: TextStyle(
                              fontSize: 10,
                              color: textColor.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Arrow indicator
                Icon(
                  Icons.chevron_right,
                  size: 16,
                  color: textColor.withOpacity(0.4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, ActivityFilter filter) {
    final isSelected = _currentFilter == filter;
    final primaryColor = Theme.of(context).colorScheme.primary;
    
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _currentFilter = filter;
        });
      },
      selectedColor: primaryColor.withOpacity(0.2),
      checkmarkColor: primaryColor,
      labelStyle: TextStyle(
        color: isSelected ? primaryColor : Theme.of(context).colorScheme.onSurface,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }

  String _getFilterDescription(ActivityFilter filter) {
    switch (filter) {
      case ActivityFilter.all:
        return 'Mostrando todas las actividades';
      case ActivityFilter.myActivities:
        return 'Mostrando mis actividades';
      case ActivityFilter.active:
        return 'Mostrando actividades activas';
      case ActivityFilter.completed:
        return 'Mostrando actividades completadas';
      case ActivityFilter.inactive:
        return 'Mostrando actividades inactivas';
    }
  }

  List<ActivityModel> _getFilteredActivities(List<ActivityModel> activities, AuthProvider authProvider) {
    final user = authProvider.userData;
    if (user == null) return [];

    switch (_currentFilter) {
      case ActivityFilter.all:
        return activities;
      case ActivityFilter.myActivities:
        return activities.where((activity) {
          // SuperUser and ADMIN see all activities
          if (user.appRole == AppRole.SuperUser || user.appRole == AppRole.ADMIN) {
            return true;
          }
          // Regular users see only activities where they are participants or responsible
          final isParticipant = activity.participants.any((p) => p.userId == user.uid);
          final isResponsible = activity.responsibleUsers.any((r) => r.userId == user.uid);
          return isParticipant || isResponsible;
        }).toList();
      case ActivityFilter.active:
        return activities.where((activity) => activity.status == ActivityStatus.ACTIVA).toList();
      case ActivityFilter.completed:
        return activities.where((activity) => activity.status == ActivityStatus.COMPLETADA).toList();
      case ActivityFilter.inactive:
        return activities.where((activity) => activity.status == ActivityStatus.INACTIVA).toList();
    }
  }

  Map<String, dynamic> _calculateProgress(ActivityModel activity) {
    final participants = activity.participants;
    final totalParticipants = participants.length;
    final totalSessions = activity.numberOfSessions;
    final totalRequiredCompletions = totalParticipants * totalSessions;
    
    final completions = activity.sessionCompletions;
    final validCompletions = completions.where((c) => 
      c.status == CompletionStatus.APPROVED || c.status == CompletionStatus.COMPLETED
    ).length;
    
    final percentage = totalRequiredCompletions > 0 
        ? (validCompletions / totalRequiredCompletions * 100).round()
        : 0;
    
    return {
      'percentage': percentage,
      'current': validCompletions,
      'total': totalRequiredCompletions,
      'isComplete': validCompletions >= totalRequiredCompletions,
    };
  }

  SessionDate? _getNextSession(ActivityModel activity) {
    final now = DateTime.now();
    final upcomingSessions = activity.sessionDates.where((session) {
      return session.date.isAfter(now);
    }).toList();
    
    if (upcomingSessions.isEmpty) return null;
    
    upcomingSessions.sort((a, b) => a.date.compareTo(b.date));
    
    return upcomingSessions.first;
  }

  Color _getStatusColor(ActivityStatus status) {
    switch (status) {
      case ActivityStatus.ACTIVA:
        return const Color(0xFFFF5722); // Orange
      case ActivityStatus.COMPLETADA:
        return const Color(0xFF4CAF50); // Green
      case ActivityStatus.INACTIVA:
        return const Color(0xFF9E9E9E); // Grey
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showCreateActivityDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CreateActivityForm(),
    );
  }

  void _showActivityDetails(ActivityModel activity) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ActivityDetailScreen(activity: activity),
      ),
    );
  }

  void _completeSession(ActivityModel activity) {
    // TODO: Implement session completion logic
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Completando sesión de: ${activity.title}'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}

// Widget para mostrar los responsables con carga dinámica
class ResponsibleUsersWidget extends StatefulWidget {
  final List<Participant> responsibleUsers;
  final Color textSecondaryColor;

  const ResponsibleUsersWidget({
    super.key,
    required this.responsibleUsers,
    required this.textSecondaryColor,
  });

  @override
  State<ResponsibleUsersWidget> createState() => _ResponsibleUsersWidgetState();
}

class _ResponsibleUsersWidgetState extends State<ResponsibleUsersWidget> {
  final Map<String, String> _userNames = {};
  final Map<String, bool> _loadingStates = {};

  @override
  void initState() {
    super.initState();
    _loadUserNames();
  }

  Future<void> _loadUserNames() async {
    final dataProvider = Provider.of<DataProvider>(context, listen: false);
    
    for (final participant in widget.responsibleUsers) {
      final userId = participant.userId;
      
      // Check if already loaded
      if (_userNames.containsKey(userId)) continue;
      
      setState(() {
        _loadingStates[userId] = true;
      });
      
      try {
        // Try to get from local cache first
        final userModel = dataProvider.getUserById(userId);
        if (userModel != null) {
          setState(() {
            _userNames[userId] = userModel.name;
            _loadingStates[userId] = false;
          });
        } else {
          // Load from Firestore
          final user = await dataProvider.loadUserById(userId);
          setState(() {
            _userNames[userId] = user?.name ?? 'Usuario no encontrado';
            _loadingStates[userId] = false;
          });
        }
      } catch (e) {
        print('Error loading user $userId: $e');
        setState(() {
          _userNames[userId] = 'Error al cargar';
          _loadingStates[userId] = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = _loadingStates.values.any((loading) => loading);
    final userNames = widget.responsibleUsers.map((participant) {
      return _userNames[participant.userId] ?? 'Cargando...';
    }).toList();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.person_outline,
          size: 14,
          color: widget.textSecondaryColor,
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            'Responsable${userNames.length > 1 ? 's' : ''}: ${userNames.join(', ')}',
            style: TextStyle(
              fontSize: 12,
              color: widget.textSecondaryColor,
            ),
          ),
        ),
      ],
    );
  }
} 
