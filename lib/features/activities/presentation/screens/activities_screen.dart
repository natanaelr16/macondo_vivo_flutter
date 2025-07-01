import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/providers/data_provider.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../../../core/widgets/bottom_navigation.dart';
import '../../../../shared/models/activity_model.dart';
import '../../../../shared/models/model_extensions.dart';
import '../widgets/create_activity_form.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../shared/services/firestore_service.dart';
import 'activity_detail_screen.dart';

enum ActivityFilter {
  recent,
  all,
  active,
  completed,
  inactive,
}

class ActivitiesScreen extends StatefulWidget {
  const ActivitiesScreen({super.key});

  @override
  State<ActivitiesScreen> createState() => _ActivitiesScreenState();
}

class _ActivitiesScreenState extends State<ActivitiesScreen> {
  ActivityFilter _currentFilter = ActivityFilter.recent;
  String _searchQuery = '';

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
    final backgroundColor = Theme.of(context).colorScheme.background;
    final cardColor = Theme.of(context).colorScheme.surface;
    final textColor = Theme.of(context).colorScheme.onBackground;
    final textSecondaryColor = Theme.of(context).colorScheme.onSurface.withOpacity(0.7);

    return Scaffold(
      backgroundColor: backgroundColor,
      bottomNavigationBar: const BottomNavigation(currentRoute: '/activities'),
      appBar: AppBar(
        title: const Text('Actividades'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCreateActivityDialog(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateActivityDialog(context),
        backgroundColor: primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Consumer<DataProvider>(
        builder: (context, dataProvider, child) {
          print('ActivitiesScreen: DataProvider state - isLoading: ${dataProvider.isLoading}, activities count: ${dataProvider.activities.length}, error: ${dataProvider.error}');
          
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
                  Icon(
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
          final filteredActivities = _getFilteredActivities(allActivities);
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
              // Search bar
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
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
              ),
              
              // Filter chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _buildFilterChip('Recientes', ActivityFilter.recent),
                    const SizedBox(width: 8),
                    _buildFilterChip('Todas', ActivityFilter.all),
                    const SizedBox(width: 8),
                    _buildFilterChip('Activas', ActivityFilter.active),
                    const SizedBox(width: 8),
                    _buildFilterChip('Completadas', ActivityFilter.completed),
                    const SizedBox(width: 8),
                    _buildFilterChip('Inactivas', ActivityFilter.inactive),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Activities count
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Text(
                      '${filteredActivities.length} actividad${filteredActivities.length == 1 ? '' : 'es'}',
                      style: TextStyle(
                        fontSize: 14,
                        color: textSecondaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Activities list
              Expanded(
                child: filteredActivities.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.filter_list,
                              size: 64,
                              color: textSecondaryColor,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No hay actividades que coincidan',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Intenta cambiar los filtros o la búsqueda',
                              style: TextStyle(color: textSecondaryColor),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () async {
                          print('ActivitiesScreen: Pull to refresh triggered');
                          await dataProvider.loadActivities();
                        },
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredActivities.length,
                          itemBuilder: (context, index) {
                            final activity = filteredActivities[index];
                            print('ActivitiesScreen: Building activity card ${index + 1}/${filteredActivities.length} for ${activity.title}');
                            
                            return _buildSimpleActivityCard(
                              context,
                              activity,
                              cardColor,
                              textColor,
                              textSecondaryColor,
                              primaryColor,
                              dataProvider,
                            );
                          },
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterChip(String label, ActivityFilter filter) {
    final isSelected = _currentFilter == filter;
    
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _currentFilter = filter;
        });
      },
      backgroundColor: Theme.of(context).colorScheme.surface,
      selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
      checkmarkColor: Theme.of(context).colorScheme.primary,
      labelStyle: TextStyle(
        color: isSelected 
            ? Theme.of(context).colorScheme.primary 
            : Theme.of(context).colorScheme.onSurface,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }

  List<ActivityModel> _getFilteredActivities(List<ActivityModel> activities) {
    List<ActivityModel> filtered = activities;
    
    // Apply status filter
    switch (_currentFilter) {
      case ActivityFilter.recent:
        // Sort by creation date and take the most recent 5
        filtered = activities
            .where((activity) => 
                _searchQuery.isEmpty ||
                activity.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                activity.description.toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        filtered = filtered.take(5).toList();
        break;
        
      case ActivityFilter.all:
        filtered = activities
            .where((activity) => 
                _searchQuery.isEmpty ||
                activity.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                activity.description.toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList();
        break;
        
      case ActivityFilter.active:
        filtered = activities
            .where((activity) => 
                activity.status == ActivityStatus.ACTIVA &&
                (_searchQuery.isEmpty ||
                activity.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                activity.description.toLowerCase().contains(_searchQuery.toLowerCase())))
            .toList();
        break;
        
      case ActivityFilter.completed:
        filtered = activities
            .where((activity) => 
                activity.status == ActivityStatus.COMPLETADA &&
                (_searchQuery.isEmpty ||
                activity.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                activity.description.toLowerCase().contains(_searchQuery.toLowerCase())))
            .toList();
        break;
        
      case ActivityFilter.inactive:
        filtered = activities
            .where((activity) => 
                activity.status == ActivityStatus.INACTIVA &&
                (_searchQuery.isEmpty ||
                activity.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                activity.description.toLowerCase().contains(_searchQuery.toLowerCase())))
            .toList();
        break;
    }
    
    return filtered;
  }

  Widget _buildSimpleActivityCard(
    BuildContext context,
    ActivityModel activity,
    Color cardColor,
    Color textColor,
    Color textSecondaryColor,
    Color primaryColor,
    DataProvider dataProvider,
  ) {
    final user = dataProvider.getUserById(activity.createdBy_uid);
    final timeAgo = _getTimeAgo(activity.createdAt);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _navigateToActivityDetail(activity),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getActivityStatusColor(activity.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getActivityIcon(activity.category ?? "general"),
                      color: _getActivityStatusColor(activity.status),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activity.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          activity.description,
                          style: TextStyle(
                            fontSize: 14,
                            color: textSecondaryColor,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, color: textSecondaryColor),
                    onSelected: (value) => _handleActivityAction(value, activity, dataProvider),
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
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getActivityStatusColor(activity.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getActivityStatusDisplayName(activity.status),
                      style: TextStyle(
                        fontSize: 12,
                        color: _getActivityStatusColor(activity.status),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getTypeColor(activity.category ?? "general").withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getTypeDisplayName(activity.category ?? "general"),
                      style: TextStyle(
                        fontSize: 12,
                        color: _getTypeColor(activity.category ?? "general"),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Creado por: ${user?.name ?? 'Usuario desconocido'} • $timeAgo',
                style: TextStyle(
                  fontSize: 12,
                  color: textSecondaryColor,
                ),
              ),
              if (activity.responsibleUsers.isNotEmpty) ...[
                const SizedBox(height: 4),
                ResponsibleUsersWidget(
                  responsibleUsers: activity.responsibleUsers,
                  textSecondaryColor: textSecondaryColor,
                ),
              ],
              if (activity.completionPercentage != null) ...[
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: activity.completionPercentage! / 100,
                  backgroundColor: Colors.grey.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                ),
                const SizedBox(height: 4),
                Text(
                  '${activity.completionPercentage!.toStringAsFixed(1)}% completado',
                  style: TextStyle(
                    fontSize: 12,
                    color: textSecondaryColor,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToActivityDetail(ActivityModel activity) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ActivityDetailScreen(
          activityId: activity.activityId,
        ),
      ),
    );
  }

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

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} día${difference.inDays == 1 ? '' : 's'}';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hora${difference.inHours == 1 ? '' : 's'}';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minuto${difference.inMinutes == 1 ? '' : 's'}';
    } else {
      return 'Ahora mismo';
    }
  }

  void _handleActivityAction(String action, ActivityModel activity, DataProvider dataProvider) {
    switch (action) {
      case 'view':
        _navigateToActivityDetail(activity);
        break;
      case 'edit':
        _showEditActivityDialog(context, activity);
        break;
      case 'complete':
        _completeActivity(activity, dataProvider);
        break;
      case 'delete':
        _showDeleteActivityDialog(context, activity, dataProvider);
        break;
    }
  }

  void _completeActivity(ActivityModel activity, DataProvider dataProvider) {
    dataProvider.updateActivity(
      activity.activityId, 
      activity.copyWith(status: ActivityStatus.COMPLETADA)
    );
  }

  void _showDeleteActivityDialog(BuildContext context, ActivityModel activity, DataProvider dataProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Actividad'),
        content: Text('¿Estás seguro de que quieres eliminar "${activity.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              dataProvider.deleteActivity(activity.activityId);
              Navigator.of(context).pop();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _showCreateActivityDialog(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateActivityForm(),
      ),
    );
  }

  void _showEditActivityDialog(BuildContext context, ActivityModel activity) {
    // TODO: Implement edit activity form
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Función de edición en desarrollo')),
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
