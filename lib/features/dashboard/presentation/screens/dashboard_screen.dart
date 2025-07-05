import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../shared/providers/auth_provider.dart';
import '../../../../shared/providers/theme_provider.dart';
import '../../../../shared/providers/data_provider.dart';
import '../../../../core/widgets/animated_logo.dart';
import '../../../../core/widgets/navigation_card.dart';
import '../../../../core/widgets/stat_card.dart';
import '../../../../core/widgets/bottom_navigation.dart';
import '../../../../core/widgets/profile_menu.dart';
import '../../../../shared/models/activity_model.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Load data when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DataProvider>().loadAllData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final backgroundColor = Theme.of(context).colorScheme.surface;
    final cardColor = Theme.of(context).colorScheme.surface;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final textSecondaryColor = Theme.of(context).colorScheme.onSurface.withOpacity(0.7);

    return Scaffold(
      backgroundColor: backgroundColor,
      bottomNavigationBar: const BottomNavigation(currentRoute: '/dashboard'),
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          // Theme selector
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return PopupMenuButton<AppThemeMode>(
                icon: Icon(themeProvider.themeModeIcon),
                onSelected: (AppThemeMode mode) {
                  themeProvider.setThemeMode(mode);
                },
                itemBuilder: (BuildContext context) => [
                  const PopupMenuItem<AppThemeMode>(
                    value: AppThemeMode.light,
                    child: Row(
                      children: [
                        Icon(Icons.light_mode, color: Colors.orange),
                        SizedBox(width: 8),
                        Text('Claro'),
                      ],
                    ),
                  ),
                  const PopupMenuItem<AppThemeMode>(
                    value: AppThemeMode.dark,
                    child: Row(
                      children: [
                        Icon(Icons.dark_mode, color: Colors.blue),
                        SizedBox(width: 8),
                        Text('Oscuro'),
                      ],
                    ),
                  ),
                  const PopupMenuItem<AppThemeMode>(
                    value: AppThemeMode.system,
                    child: Row(
                      children: [
                        Icon(Icons.brightness_auto, color: Colors.grey),
                        SizedBox(width: 8),
                        Text('Sistema'),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              return IconButton(
                icon: CircleAvatar(
                  backgroundColor: primaryColor,
                  child: Text(
                    authProvider.user?.email?.substring(0, 1).toUpperCase() ?? 'U',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                onPressed: () => _showProfileMenu(context),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Animated Logo Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    primaryColor,
                    primaryColor.withOpacity(0.8),
                    primaryColor.withOpacity(0.6),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const AnimatedLogo(
                fontSize: 32,
                color: Colors.white,
                showSubtitle: true,
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Statistics Section
            Text(
              'Estadísticas',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 16),
            
            Consumer<DataProvider>(
              builder: (context, dataProvider, child) {
                final stats = dataProvider.dashboardStats;
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: StatCard(
                            title: 'Actividades',
                            value: '${stats['totalActivities'] ?? 0}',
                            icon: Icons.assignment,
                            color: primaryColor,
                            subtitle: 'Total de actividades',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: StatCard(
                            title: 'Usuarios Activos',
                            value: '${stats['totalUsers'] ?? 0}',
                            icon: Icons.people,
                            color: Colors.green,
                            subtitle: 'Usuarios registrados',
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 12),
                    
                    Row(
                      children: [
                        Expanded(
                          child: StatCard(
                            title: 'Pendientes',
                            value: '${stats['pendingActivities'] ?? 0}',
                            icon: Icons.schedule,
                            color: Colors.orange,
                            subtitle: 'Actividades por hacer',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: StatCard(
                            title: 'Completadas',
                            value: '${stats['completedActivities'] ?? 0}',
                            icon: Icons.check_circle,
                            color: Colors.green,
                            subtitle: 'Actividades finalizadas',
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
            
            const SizedBox(height: 24),
            
            // Navigation Section
            Text(
              'Navegación',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 16),
            
            Consumer<DataProvider>(
              builder: (context, dataProvider, child) {
                final stats = dataProvider.dashboardStats;
                return Column(
                  children: [
                    NavigationCard(
                      title: 'Actividades',
                      subtitle: 'Gestionar actividades escolares',
                      icon: Icons.assignment,
                      color: primaryColor,
                      route: '/activities',
                      count: stats['totalActivities'],
                    ),
                    NavigationCard(
                      title: 'Usuarios',
                      subtitle: 'Administrar usuarios del sistema',
                      icon: Icons.people,
                      color: Colors.green,
                      route: '/users',
                      count: stats['totalUsers'],
                    ),
                    const NavigationCard(
                      title: 'Reportes',
                      subtitle: 'Ver reportes y estadísticas',
                      icon: Icons.analytics,
                      color: Colors.orange,
                      route: '/reports',
                    ),
                  ],
                );
              },
            ),
            
            const SizedBox(height: 24),
            
            // Recent Activities
            Text(
              'Actividades Recientes',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 16),
            
            Consumer<DataProvider>(
              builder: (context, dataProvider, child) {
                if (dataProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                final recentActivities = dataProvider.activities.take(5).toList();
                
                if (recentActivities.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
                      ),
                    ),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.assignment_outlined,
                            size: 48,
                            color: textSecondaryColor,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No hay actividades recientes',
                            style: TextStyle(
                              color: textSecondaryColor,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                
                return Column(
                  children: recentActivities.take(3).map((activity) {
                    return _buildActivityCard(
                      context,
                      activity,
                      dataProvider,
                      cardColor,
                      textColor,
                      textSecondaryColor,
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityCard(
    BuildContext context,
    ActivityModel activity,
    DataProvider dataProvider,
    Color cardColor,
    Color textColor,
    Color textSecondaryColor,
  ) {
    final user = dataProvider.getUserById(activity.createdBy_uid);
    final timeAgo = _getTimeAgo(activity.createdAt);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
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
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    Text(
                      activity.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: textSecondaryColor,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.person,
                size: 12,
                color: textSecondaryColor,
              ),
              const SizedBox(width: 4),
              Text(
                user?.name ?? 'Usuario',
                style: TextStyle(
                  fontSize: 10,
                  color: textSecondaryColor,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _getActivityStatusColor(activity.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _getActivityStatusText(activity.status),
                  style: TextStyle(
                    fontSize: 10,
                    color: _getActivityStatusColor(activity.status),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            timeAgo,
            style: TextStyle(
              fontSize: 10,
              color: textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'in_progress':
        return Colors.blue;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
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

  String _getActivityStatusText(ActivityStatus status) {
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

  IconData _getActivityIcon(String type) {
    switch (type) {
      case 'assignment':
        return Icons.assignment;
      case 'exam':
        return Icons.quiz;
      case 'project':
        return Icons.work;
      case 'meeting':
        return Icons.meeting_room;
      default:
        return Icons.assignment;
    }
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return 'Hace ${difference.inDays} día${difference.inDays > 1 ? 's' : ''}';
    } else if (difference.inHours > 0) {
      return 'Hace ${difference.inHours} hora${difference.inHours > 1 ? 's' : ''}';
    } else if (difference.inMinutes > 0) {
      return 'Hace ${difference.inMinutes} minuto${difference.inMinutes > 1 ? 's' : ''}';
    } else {
      return 'Ahora mismo';
    }
  }

  void _showThemeSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => const ThemeSelectorSheet(),
    );
  }

  void _showProfileMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const ProfileMenu(),
    );
  }
}

class ThemeSelectorSheet extends StatelessWidget {
  const ThemeSelectorSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final backgroundColor = Theme.of(context).colorScheme.surface;
    final textColor = Theme.of(context).colorScheme.onSurface;

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: textColor.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Seleccionar Tema',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          const SizedBox(height: 16),
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return Column(
                children: [
                  _buildThemeOption(
                    context,
                    AppThemeMode.light,
                    'Claro',
                    Icons.light_mode,
                    themeProvider.themeMode == AppThemeMode.light,
                    primaryColor,
                    textColor,
                  ),
                  _buildThemeOption(
                    context,
                    AppThemeMode.dark,
                    'Oscuro',
                    Icons.dark_mode,
                    themeProvider.themeMode == AppThemeMode.dark,
                    primaryColor,
                    textColor,
                  ),
                  _buildThemeOption(
                    context,
                    AppThemeMode.system,
                    'Sistema',
                    Icons.brightness_auto,
                    themeProvider.themeMode == AppThemeMode.system,
                    primaryColor,
                    textColor,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildThemeOption(
    BuildContext context,
    AppThemeMode mode,
    String title,
    IconData icon,
    bool isSelected,
    Color primaryColor,
    Color textColor,
  ) {
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? primaryColor : textColor.withOpacity(0.7),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? primaryColor : textColor,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      trailing: isSelected
          ? Icon(
              Icons.check,
              color: primaryColor,
            )
          : null,
      onTap: () {
        context.read<ThemeProvider>().setThemeMode(mode);
        Navigator.pop(context);
      },
    );
  }
} 
