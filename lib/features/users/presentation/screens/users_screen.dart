import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../shared/providers/data_provider.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../../../core/widgets/bottom_navigation.dart';
import '../../../../shared/models/user_model.dart';
import '../../../../shared/models/model_extensions.dart';
import '../widgets/create_user_form.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../shared/services/firestore_service.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  @override
  void initState() {
    super.initState();
    print('UsersScreen: initState called');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('UsersScreen: Post frame callback, loading users...');
      final dataProvider = Provider.of<DataProvider>(context, listen: false);
      dataProvider.loadUsers();
    });
  }

  @override
  Widget build(BuildContext context) {
    print('UsersScreen: Building widget...');
    final primaryColor = Theme.of(context).colorScheme.primary;
    final backgroundColor = Theme.of(context).colorScheme.background;
    final cardColor = Theme.of(context).colorScheme.surface;
    final textColor = Theme.of(context).colorScheme.onBackground;
    final textSecondaryColor = Theme.of(context).colorScheme.onSurface.withOpacity(0.7);

    return Scaffold(
      backgroundColor: backgroundColor,
      bottomNavigationBar: const BottomNavigation(currentRoute: '/users'),
      appBar: AppBar(
        title: const Text('Gestión de Usuarios'),
        actions: [
          // Debug button
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: () async {
              print('UsersScreen: Debug button pressed');
              final firestoreService = FirestoreService();
              await firestoreService.debugFirestoreData();
            },
            tooltip: 'Debug Firestore',
          ),
          // Create test data button
          IconButton(
            icon: const Icon(Icons.data_array),
            onPressed: () async {
              print('UsersScreen: Create test data button pressed');
              final firestoreService = FirestoreService();
              await firestoreService.createTestData();
              // Refresh the data
              final dataProvider = Provider.of<DataProvider>(context, listen: false);
              await dataProvider.loadUsers();
            },
            tooltip: 'Crear Datos de Prueba',
          ),
          // Create user button (temporary for all users)
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () => _showCreateUserDialog(context),
            tooltip: 'Crear Usuario',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateUserDialog(context),
        backgroundColor: primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Consumer<DataProvider>(
        builder: (context, dataProvider, child) {
          print('UsersScreen: DataProvider state - isLoading: ${dataProvider.isLoading}, users count: ${dataProvider.users.length}, error: ${dataProvider.error}');
          
          if (dataProvider.isLoading) {
            print('UsersScreen: Showing loading widget');
            return const LoadingWidget();
          }

          if (dataProvider.error != null) {
            print('UsersScreen: Showing error: ${dataProvider.error}');
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
                    'Error al cargar usuarios',
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
                    onPressed: () => dataProvider.loadUsers(),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          final users = dataProvider.users;
          print('UsersScreen: Displaying ${users.length} users');

          if (users.isEmpty) {
            print('UsersScreen: No users found, showing empty state');
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 64,
                    color: textSecondaryColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No hay usuarios registrados',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Agrega el primer usuario usando el botón +',
                    style: TextStyle(color: textSecondaryColor),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              print('UsersScreen: Pull to refresh triggered');
              await dataProvider.loadUsers();
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                print('UsersScreen: Building user card ${index + 1}/${users.length} for ${user.email}');
                
                return _buildUserCard(
                  context,
                  user,
                  cardColor,
                  textColor,
                  textSecondaryColor,
                  primaryColor,
                  dataProvider,
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildUserCard(
    BuildContext context,
    UserModel user,
    Color cardColor,
    Color textColor,
    Color textSecondaryColor,
    Color primaryColor,
    DataProvider dataProvider,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: primaryColor,
          radius: 24,
          child: Text(
            user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          user.name.isNotEmpty ? user.name : 'Sin nombre',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              user.email,
              style: TextStyle(
                fontSize: 14,
                color: textSecondaryColor,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getRoleColor(user.appRole.name).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getRoleDisplayName(user.appRole.name),
                    style: TextStyle(
                      fontSize: 12,
                      color: _getRoleColor(user.appRole.name),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: user.isActive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    user.isActive ? 'Activo' : 'Inactivo',
                    style: TextStyle(
                      fontSize: 12,
                      color: user.isActive ? Colors.green : Colors.red,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, color: textSecondaryColor),
          onSelected: (value) => _handleUserAction(value, user, dataProvider),
          itemBuilder: (context) => [
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
            PopupMenuItem(
              value: 'toggle',
              child: Row(
                children: [
                  Icon(
                    user.isActive ? Icons.block : Icons.check_circle,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(user.isActive ? 'Desactivar' : 'Activar'),
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
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return Colors.red;
      case 'teacher':
        return Colors.blue;
      case 'student':
        return Colors.green;
      case 'parent':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getRoleDisplayName(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return 'Administrador';
      case 'teacher':
        return 'Profesor';
      case 'student':
        return 'Estudiante';
      case 'parent':
        return 'Padre';
      default:
        return 'Usuario';
    }
  }

  void _handleUserAction(String action, UserModel user, DataProvider dataProvider) {
    switch (action) {
      case 'edit':
        _showEditUserDialog(context, user);
        break;
      case 'toggle':
        _toggleUserStatus(user, dataProvider);
        break;
      case 'delete':
        _showDeleteUserDialog(context, user, dataProvider);
        break;
    }
  }

  void _toggleUserStatus(UserModel user, DataProvider dataProvider) {
    dataProvider.updateUser(
      user.uid, 
      user.copyWith(isActive: !user.isActive)
    );
  }

  void _showDeleteUserDialog(BuildContext context, UserModel user, DataProvider dataProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Usuario'),
        content: Text('¿Estás seguro de que quieres eliminar a ${user.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              dataProvider.deleteUser(user.uid);
              Navigator.of(context).pop();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _showCreateUserDialog(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateUserForm(),
      ),
    );
  }

  void _showEditUserDialog(BuildContext context, UserModel user) {
    // TODO: Implement edit user form
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Función de edición en desarrollo')),
    );
  }
} 
