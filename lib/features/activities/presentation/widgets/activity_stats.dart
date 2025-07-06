import 'package:flutter/material.dart';
import '../../../../shared/models/activity_model.dart';
import '../../../../shared/providers/data_provider.dart';
import '../../../../shared/providers/auth_provider.dart';

class ActivityStats extends StatelessWidget {
  final List<ActivityModel> activities;

  const ActivityStats({
    super.key,
    required this.activities,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stats = _calculateStats();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.bar_chart, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Estadísticas de Actividades',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Stats Grid
            _buildStatsGrid(stats, theme),
            const SizedBox(height: 20),

            // Status Distribution
            _buildStatusDistribution(stats, theme),
            const SizedBox(height: 16),

            // Category Distribution
            _buildCategoryDistribution(stats, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(Map<String, dynamic> stats, ThemeData theme) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          'Total Actividades',
          '${stats['totalActivities']}',
          Icons.assignment,
          Colors.blue,
          theme,
        ),
        _buildStatCard(
          'Actividades Activas',
          '${stats['activeActivities']}',
          Icons.play_circle,
          Colors.green,
          theme,
        ),
        _buildStatCard(
          'Actividades Completadas',
          '${stats['completedActivities']}',
          Icons.check_circle,
          Colors.orange,
          theme,
        ),
        _buildStatCard(
          'Promedio Sesiones',
          '${stats['avgSessions']}',
          Icons.calendar_today,
          Colors.purple,
          theme,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    ThemeData theme,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: color,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusDistribution(Map<String, dynamic> stats, ThemeData theme) {
    final statusData = stats['statusDistribution'] as Map<String, int>;
    final total = statusData.values.fold(0, (sum, count) => sum + count);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Distribución por Estado',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...statusData.entries.map((entry) {
          final percentage = total > 0 ? (entry.value / total) * 100 : 0;
          final color = _getStatusColor(entry.key);
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _getStatusLabel(entry.key),
                    style: theme.textTheme.bodySmall,
                  ),
                ),
                Text(
                  '${entry.value}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '(${percentage.toStringAsFixed(1)}%)',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildCategoryDistribution(Map<String, dynamic> stats, ThemeData theme) {
    final categoryData = stats['categoryDistribution'] as Map<String, int>;
    
    if (categoryData.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Distribución por Categoría',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No hay categorías definidas',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      );
    }

    final total = categoryData.values.fold(0, (sum, count) => sum + count);
    final sortedCategories = categoryData.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Distribución por Categoría',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...sortedCategories.take(5).map((entry) {
          final percentage = total > 0 ? (entry.value / total) * 100 : 0;
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    entry.key,
                    style: theme.textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '${entry.value}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '(${percentage.toStringAsFixed(1)}%)',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
        if (sortedCategories.length > 5)
          Text(
            '... y ${sortedCategories.length - 5} categorías más',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
      ],
    );
  }

  // Helper methods
  Map<String, dynamic> _calculateStats() {
    final totalActivities = activities.length;
    final activeActivities = activities
        .where((a) => a.status == ActivityStatus.ACTIVA)
        .length;
    final completedActivities = activities
        .where((a) => a.status == ActivityStatus.COMPLETADA)
        .length;
    final inactiveActivities = activities
        .where((a) => a.status == ActivityStatus.INACTIVA)
        .length;

    // Calcular promedio de sesiones
    final totalSessions = activities.fold<int>(
        0, (sum, activity) => sum + activity.numberOfSessions);
    final avgSessions = totalActivities > 0 
        ? (totalSessions / totalActivities).toStringAsFixed(1)
        : '0';

    // Distribución por estado
    final statusDistribution = {
      'ACTIVA': activeActivities,
      'COMPLETADA': completedActivities,
      'INACTIVA': inactiveActivities,
    };

    // Distribución por categoría
    final categoryDistribution = <String, int>{};
    for (final activity in activities) {
      if (activity.category != null) {
        categoryDistribution[activity.category!] = 
            (categoryDistribution[activity.category!] ?? 0) + 1;
      }
    }

    return {
      'totalActivities': totalActivities,
      'activeActivities': activeActivities,
      'completedActivities': completedActivities,
      'inactiveActivities': inactiveActivities,
      'avgSessions': avgSessions,
      'statusDistribution': statusDistribution,
      'categoryDistribution': categoryDistribution,
    };
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'ACTIVA':
        return Colors.orange;
      case 'COMPLETADA':
        return Colors.green;
      case 'INACTIVA':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'ACTIVA':
        return 'Activas';
      case 'COMPLETADA':
        return 'Completadas';
      case 'INACTIVA':
        return 'Inactivas';
      default:
        return status;
    }
  }
} 