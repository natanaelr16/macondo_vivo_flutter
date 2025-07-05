import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../shared/providers/data_provider.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../../../shared/services/user_service.dart';
import '../../../../core/widgets/bottom_navigation.dart';
import '../../../../shared/models/user_model.dart';
import '../widgets/create_user_form.dart';
import '../widgets/edit_user_form.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../core/widgets/user_status_badge.dart';
import '../../../../core/widgets/provisional_password_display.dart';


class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  // Páginas y filtros
  final TextEditingController _searchController = TextEditingController();
  UserType _selectedUserType = UserType.ADMIN_STAFF; // Por defecto administrativo
  AppRole? _selectedAppRole;
  bool? _selectedStatus; // null = todos, true = activo, false = inactivo
  List<UserModel> _filteredUsers = [];
  int _lastUsersLength = 0;

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
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applyFilters(List<UserModel> allUsers) {
    setState(() {
      _filteredUsers = allUsers.where((user) {
        // Filtro especial para ADMIN001 - solo visible para sí mismo
        final currentUser = context.read<AuthProvider>().userData;
        if (user.uid == 'ADMIN001' && currentUser?.uid != 'ADMIN001') {
          return false;
        }

        // Filtro por búsqueda (nombre, email, documento)
        final searchTerm = _searchController.text.toLowerCase();
        final matchesSearch = searchTerm.isEmpty ||
            user.name.toLowerCase().contains(searchTerm) ||
            user.email.toLowerCase().contains(searchTerm) ||
            user.documentNumber.toLowerCase().contains(searchTerm);

        // Filtro por tipo de usuario (página actual)
        final matchesUserType = user.userType == _selectedUserType;

        // Filtro por rol de aplicación
        final matchesAppRole = _selectedAppRole == null || user.appRole == _selectedAppRole;

        // Filtro por estado (activo/inactivo)
        final matchesStatus = _selectedStatus == null || user.isActive == _selectedStatus;

        return matchesSearch && matchesUserType && matchesAppRole && matchesStatus;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    print('UsersScreen: Building widget...');
    final primaryColor = Theme.of(context).colorScheme.primary;
    final backgroundColor = Theme.of(context).colorScheme.surface;
    final cardColor = Theme.of(context).colorScheme.surface;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final textSecondaryColor = Theme.of(context).colorScheme.onSurface.withOpacity(0.7);

    return Scaffold(
      backgroundColor: backgroundColor,
      bottomNavigationBar: const BottomNavigation(currentRoute: '/users'),
      appBar: AppBar(
        centerTitle: false,
        title: const Padding(
          padding: EdgeInsets.only(left: 16),
          child: Text(
            'Gestión de Usuarios',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
        ),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        actions: [
          // Botón de filtros
          Consumer<DataProvider>(
            builder: (context, dataProvider, child) {
              return PopupMenuButton<String>(
                icon: Icon(
                  Icons.filter_list,
                  color: (_selectedAppRole != null || _selectedStatus != null) 
                      ? primaryColor 
                      : Theme.of(context).colorScheme.onSurface,
                ),
                onSelected: (value) {
                  setState(() {
                    switch (value) {
                      case 'role_user':
                        _selectedAppRole = _selectedAppRole == AppRole.USER ? null : AppRole.USER;
                        break;
                      case 'role_admin':
                        _selectedAppRole = _selectedAppRole == AppRole.ADMIN ? null : AppRole.ADMIN;
                        break;
                      case 'role_superuser':
                        _selectedAppRole = _selectedAppRole == AppRole.SuperUser ? null : AppRole.SuperUser;
                        break;
                      case 'status_active':
                        _selectedStatus = _selectedStatus == true ? null : true;
                        break;
                      case 'status_inactive':
                        _selectedStatus = _selectedStatus == false ? null : false;
                        break;
                    }
                    _applyFilters(dataProvider.users);
                  });
                },
                itemBuilder: (context) => [
                  // Título de Roles
                  PopupMenuItem(
                    enabled: false,
                    child: Text(
                      'ROLES',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'role_user',
                    child: Row(
        children: [
                        Icon(
                          Icons.person,
                          size: 16,
                          color: _selectedAppRole == AppRole.USER ? Colors.blue : Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Usuarios',
                          style: TextStyle(
                            color: _selectedAppRole == AppRole.USER ? Colors.blue : null,
                            fontWeight: _selectedAppRole == AppRole.USER ? FontWeight.bold : null,
                          ),
                        ),
                        if (_selectedAppRole == AppRole.USER) ...[
                          const Spacer(),
                          Icon(Icons.check, size: 16, color: Colors.blue),
                        ],
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'role_admin',
                    child: Row(
                      children: [
                        Icon(
                          Icons.admin_panel_settings,
                          size: 16,
                          color: _selectedAppRole == AppRole.ADMIN ? Colors.red : Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Administradores',
                          style: TextStyle(
                            color: _selectedAppRole == AppRole.ADMIN ? Colors.red : null,
                            fontWeight: _selectedAppRole == AppRole.ADMIN ? FontWeight.bold : null,
                          ),
                        ),
                        if (_selectedAppRole == AppRole.ADMIN) ...[
                          const Spacer(),
                          Icon(Icons.check, size: 16, color: Colors.red),
                        ],
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'role_superuser',
                    child: Row(
                      children: [
                        Icon(
                          Icons.admin_panel_settings,
                          size: 16,
                          color: _selectedAppRole == AppRole.SuperUser ? Colors.purple : Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'SuperUsers',
                          style: TextStyle(
                            color: _selectedAppRole == AppRole.SuperUser ? Colors.purple : null,
                            fontWeight: _selectedAppRole == AppRole.SuperUser ? FontWeight.bold : null,
                          ),
                        ),
                        if (_selectedAppRole == AppRole.SuperUser) ...[
                          const Spacer(),
                          Icon(Icons.check, size: 16, color: Colors.purple),
                        ],
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  // Título de Estado
                  PopupMenuItem(
                    enabled: false,
                    child: Text(
                      'ESTADO',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'status_active',
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 16,
                          color: _selectedStatus == true ? Colors.green : Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Usuarios Activos',
                          style: TextStyle(
                            color: _selectedStatus == true ? Colors.green : null,
                            fontWeight: _selectedStatus == true ? FontWeight.bold : null,
                          ),
                        ),
                        if (_selectedStatus == true) ...[
                          const Spacer(),
                          Icon(Icons.check, size: 16, color: Colors.green),
                        ],
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'status_inactive',
                    child: Row(
                      children: [
                        Icon(
                          Icons.cancel,
                          size: 16,
                          color: _selectedStatus == false ? Colors.red : Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Usuarios Inactivos',
                          style: TextStyle(
                            color: _selectedStatus == false ? Colors.red : null,
                            fontWeight: _selectedStatus == false ? FontWeight.bold : null,
                          ),
                        ),
                        if (_selectedStatus == false) ...[
                          const Spacer(),
                          Icon(Icons.check, size: 16, color: Colors.red),
                        ],
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
            onPressed: () => _showCreateUserDialog(context),
            backgroundColor: primaryColor,
            child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Consumer2<DataProvider, AuthProvider>(
        builder: (context, dataProvider, authProvider, child) {
          print('UsersScreen: DataProvider state - isLoading: [38;5;9m${dataProvider.isLoading}[0m, users count: ${dataProvider.users.length}, error: ${dataProvider.error}');
          print('UsersScreen: AuthProvider state - canManageUsers: ${authProvider.canManageUsers}');

          // Verificar permisos
          if (!authProvider.canManageUsers) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.lock_outline,
                      size: 64,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Acceso Denegado',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No tienes permisos para acceder a la gestión de usuarios.',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.of(context).pushReplacementNamed('/dashboard'),
                      icon: const Icon(Icons.dashboard),
                      label: const Text('Ir al Dashboard'),
                    ),
                  ],
                ),
              ),
            );
          }

          // Si los usuarios cambian, actualiza los filtros después del build
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_lastUsersLength != dataProvider.users.length) {
              _lastUsersLength = dataProvider.users.length;
              _filteredUsers = List<UserModel>.from(dataProvider.users);
              // Aplica los filtros actuales
              _applyFilters(dataProvider.users);
            }
          });

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
                  const Icon(
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

          return Column(
            children: [
              // Sección de búsqueda y tabs
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardColor,
                  border: Border(
                    bottom: BorderSide(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Buscador
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Buscar por nombre, email o documento...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  _applyFilters(users);
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surface,
                      ),
                      onChanged: (value) => _applyFilters(users),
                    ),
                    const SizedBox(height: 16),
                    
                    // Tabs de tipos de usuario
                    Row(
                      children: [
                        Expanded(
                          child: _buildTabChip(
                          label: 'Administrativo',
                          selected: _selectedUserType == UserType.ADMIN_STAFF,
                            onTap: () {
                            setState(() {
                                _selectedUserType = UserType.ADMIN_STAFF;
                              _applyFilters(users);
                            });
                          },
                          color: Colors.orange,
                        ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: _buildTabChip(
                          label: 'Docentes',
                          selected: _selectedUserType == UserType.DOCENTE,
                            onTap: () {
                            setState(() {
                                _selectedUserType = UserType.DOCENTE;
                              _applyFilters(users);
                            });
                          },
                          color: Colors.blue,
                        ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: _buildTabChip(
                          label: 'Estudiantes',
                          selected: _selectedUserType == UserType.ESTUDIANTE,
                            onTap: () {
                            setState(() {
                                _selectedUserType = UserType.ESTUDIANTE;
                              _applyFilters(users);
                            });
                          },
                          color: Colors.green,
                        ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: _buildTabChip(
                          label: 'Acudientes',
                          selected: _selectedUserType == UserType.ACUDIENTE,
                            onTap: () {
                            setState(() {
                                _selectedUserType = UserType.ACUDIENTE;
                              _applyFilters(users);
                            });
                          },
                          color: Colors.purple,
                        ),
                        ),
                      ],
                    ),
                    
                    // Contador de resultados
                    if (_filteredUsers.length != users.length || 
                        _selectedAppRole != null || 
                        _selectedStatus != null ||
                        _searchController.text.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                              '${_filteredUsers.length} de ${users.length} usuarios',
                              style: TextStyle(
                                fontSize: 12,
                                color: textSecondaryColor,
                              ),
                        ),
                      ),
                  ],
                ),
              ),
              
              // Lista de usuarios filtrados
              Expanded(
                child: _filteredUsers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.filter_list_off,
                              size: 64,
                              color: textSecondaryColor,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No se encontraron usuarios',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Intenta ajustar los filtros de búsqueda',
                              style: TextStyle(color: textSecondaryColor),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () async {
                          print('UsersScreen: Pull to refresh triggered');
                          await dataProvider.loadUsers();
                        },
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredUsers.length,
                          itemBuilder: (context, index) {
                            final user = _filteredUsers[index];
                            print('UsersScreen: Building user card ${index + 1}/${_filteredUsers.length} for ${user.email}');
                            
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
                      ),
              ),
            ],
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
    return GestureDetector(
      onTap: () => _showUserDetails(context, user, dataProvider),
      child: Container(
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
            radius: 22,
            child: Text(
              user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          title: Text(
            user.name.isNotEmpty ? user.name : 'Sin nombre',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                '${_getDocumentTypeDisplayName(user.documentType)}: ${user.documentNumber}',
                style: TextStyle(
                  fontSize: 13,
                  color: textSecondaryColor,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getUserTypeColor(user.userType).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _getUserTypeDisplayName(user.userType),
                      style: TextStyle(
                        fontSize: 11,
                        color: _getUserTypeColor(user.userType),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getRoleColor(user.appRole.name).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _getRoleDisplayName(user.appRole.name),
                      style: TextStyle(
                        fontSize: 11,
                        color: _getRoleColor(user.appRole.name),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: user.isActive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          user.isActive ? Icons.check_circle : Icons.cancel,
                          size: 12,
                          color: user.isActive ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          user.isActive ? 'Activo' : 'Inactivo',
                          style: TextStyle(
                            fontSize: 11,
                            color: user.isActive ? Colors.green : Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          trailing: Container(
            constraints: const BoxConstraints(maxWidth: 70),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                UserStatusBadge(
                  provisionalPasswordSet: user.provisionalPasswordSet,
                  status: user.status,
                  isActive: user.isActive,
                ),
                const SizedBox(width: 2),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 12,
                  color: textSecondaryColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'superuser':
        return Colors.purple;
      case 'admin':
        return Colors.red;
      case 'user':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _getRoleDisplayName(String role) {
    switch (role.toLowerCase()) {
      case 'superuser':
        return 'Super Usuario';
      case 'admin':
        return 'Administrador';
      case 'user':
        return 'Usuario';
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
        _deleteUser(user, dataProvider);
        break;
    }
  }

  Future<void> _toggleUserStatus(UserModel user, DataProvider dataProvider) async {
    try {
      print('UsersScreen: Iniciando toggleUserStatus para usuario: ${user.email}');
      final newStatus = !user.isActive;
      final statusText = newStatus ? 'activado' : 'desactivado';
      
      // Mostrar diálogo de confirmación
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('${newStatus ? 'Activar' : 'Desactivar'} Usuario'),
          content: Text(
            '¿Estás seguro de que quieres ${newStatus ? 'activar' : 'desactivar'} a ${user.name}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: newStatus ? Colors.green : Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text(newStatus ? 'Activar' : 'Desactivar'),
            ),
          ],
        ),
      );

      if (confirmed != true) {
        print('UsersScreen: Usuario canceló la operación');
        return;
      }

      print('UsersScreen: Usuario confirmó la operación, mostrando indicador de carga');
      // Mostrar indicador de carga
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      print('UsersScreen: Llamando a dataProvider.toggleUserStatus');
      // Llamar al servicio para cambiar el estado
      await dataProvider.toggleUserStatus(user.uid, newStatus);
      
      print('UsersScreen: Operación completada, cerrando indicador de carga');
      // Cerrar indicador de carga
      Navigator.of(context).pop();

      // Actualizar el estado local inmediatamente
      final updatedUsers = dataProvider.users.map((u) {
        if (u.uid == user.uid) {
          return u.copyWith(isActive: newStatus);
        }
        return u;
      }).toList();
      
      dataProvider.updateUsersLocally(updatedUsers);

      // Mostrar mensaje de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Usuario ${statusText} exitosamente'),
          backgroundColor: newStatus ? Colors.green : Colors.orange,
          duration: const Duration(seconds: 2),
        ),
      );

      print('UsersScreen: Recargando usuarios desde Firestore');
      // También recargar desde Firestore para sincronizar
      await dataProvider.loadUsers();

    } catch (e) {
      print('UsersScreen: Error en toggleUserStatus: $e');
      // Cerrar indicador de carga si está abierto
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      // Mostrar mensaje de error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cambiar estado: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  // Método específico para toggle dentro del modal con actualización inmediata
  Future<void> _toggleUserStatusInModal(UserModel user, DataProvider dataProvider) async {
    try {
      print('UsersScreen: Iniciando toggleUserStatusInModal para usuario: ${user.email}');
      print('UsersScreen: Estado actual del usuario: ${user.isActive}');
      final newStatus = !user.isActive;
      print('UsersScreen: Nuevo estado deseado: $newStatus');
      final statusText = newStatus ? 'activado' : 'desactivado';
      
      // Mostrar diálogo de confirmación
      final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
          title: Text('${newStatus ? 'Activar' : 'Desactivar'} Usuario'),
          content: Text(
            '¿Estás seguro de que quieres ${newStatus ? 'activar' : 'desactivar'} a ${user.name}?',
          ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: newStatus ? Colors.green : Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text(newStatus ? 'Activar' : 'Desactivar'),
            ),
          ],
        ),
      );

      if (confirmed != true) {
        print('UsersScreen: Usuario canceló la operación');
        return;
      }

      print('UsersScreen: Usuario confirmó la operación, mostrando indicador de carga');
      // Mostrar indicador de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      print('UsersScreen: Llamando a dataProvider.toggleUserStatus con uid: ${user.uid}, newStatus: $newStatus');
      // Llamar al servicio para cambiar el estado
      try {
        await dataProvider.toggleUserStatus(user.uid, newStatus);
        print('UsersScreen: dataProvider.toggleUserStatus completado exitosamente');
      } catch (e) {
        print('UsersScreen: ❌ Error en dataProvider.toggleUserStatus: $e');
        // Cerrar indicador de carga
        Navigator.of(context).pop();
        // Mostrar mensaje de error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cambiar estado: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
        return;
      }
      
      print('UsersScreen: Operación completada, cerrando indicador de carga');
      // Cerrar indicador de carga
      Navigator.of(context).pop();

      // Verificar que el cambio se aplicó correctamente
      final updatedUser = dataProvider.users.firstWhere(
        (u) => u.uid == user.uid,
        orElse: () => user,
      );
      print('UsersScreen: Usuario después de actualización: ${updatedUser.email}, isActive: ${updatedUser.isActive}');

      // Forzar la actualización del modal cerrando y abriendo nuevamente
      print('UsersScreen: Forzando actualización del modal...');
      Navigator.of(context).pop(); // Cerrar el modal actual
      
      // Abrir el modal nuevamente con el usuario actualizado
      _showUserDetails(context, updatedUser, dataProvider);
      
      print('UsersScreen: Modal actualizado con el nuevo estado');

      // Mostrar mensaje de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Usuario ${statusText} exitosamente'),
          backgroundColor: newStatus ? Colors.green : Colors.orange,
          duration: const Duration(seconds: 2),
        ),
      );

    } catch (e) {
      print('UsersScreen: Error en toggleUserStatusInModal: $e');
      // Cerrar indicador de carga si está abierto
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      // Mostrar mensaje de error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cambiar estado: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _deleteUser(UserModel user, DataProvider dataProvider) async {
    try {
      print('UsersScreen: Iniciando deleteUser para usuario: ${user.email}');
      // Verificar que el usuario no se esté eliminando a sí mismo
      final currentUser = context.read<AuthProvider>().userData;
      if (currentUser?.uid == user.uid) {
        print('UsersScreen: Intento de eliminarse a sí mismo');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No puedes eliminarte a ti mismo'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Verificar que un SuperUser no pueda eliminarse a sí mismo
      if (currentUser?.isSuperUser == true && currentUser?.uid == user.uid) {
        print('UsersScreen: SuperUser intentando eliminarse a sí mismo');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Los SuperUsers no pueden eliminarse a sí mismos'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Mostrar diálogo de confirmación
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Eliminar Usuario'),
          content: Text(
            '¿Estás seguro de que quieres eliminar a ${user.name}?\n\nEsta acción no se puede deshacer.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

      if (confirmed != true) {
        print('UsersScreen: Usuario canceló la eliminación');
        return;
      }

      print('UsersScreen: Usuario confirmó la eliminación, mostrando indicador de carga');
      // Mostrar indicador de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      print('UsersScreen: Llamando a dataProvider.deleteUser');
      // Llamar al servicio para eliminar el usuario
      await dataProvider.deleteUser(user.uid);
      
      print('UsersScreen: Usuario eliminado, cerrando indicador de carga');
      // Cerrar indicador de carga
      Navigator.of(context).pop();

      // Actualizar el estado local inmediatamente
      final updatedUsers = dataProvider.users.where((u) => u.uid != user.uid).toList();
      dataProvider.updateUsersLocally(updatedUsers);

      // Cerrar el modal de detalles si está abierto
      Navigator.of(context).pop();

      // Mostrar mensaje de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Usuario eliminado exitosamente'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      print('UsersScreen: Recargando usuarios desde Firestore');
      // También recargar desde Firestore para sincronizar
      await dataProvider.loadUsers();

    } catch (e) {
      print('UsersScreen: Error en deleteUser: $e');
      // Cerrar indicador de carga si está abierto
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      // Mostrar mensaje de error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al eliminar usuario: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _resetUserPassword(UserModel user, DataProvider dataProvider) async {
    try {
      print('UsersScreen: Iniciando resetUserPassword para usuario: ${user.email}');
      // Mostrar diálogo de confirmación
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Resetear Contraseña'),
          content: Text(
            '¿Estás seguro de que quieres resetear la contraseña de ${user.name}?\n\nSe generará una nueva contraseña provisional.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('Resetear'),
            ),
          ],
        ),
      );

      if (confirmed != true) {
        print('UsersScreen: Usuario canceló el reset de contraseña');
        return;
      }

      print('UsersScreen: Usuario confirmó el reset, mostrando indicador de carga');
      // Mostrar indicador de carga
    showDialog(
      context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      print('UsersScreen: Llamando a dataProvider.resetUserPassword');
      // Llamar al servicio para resetear la contraseña
      final newPassword = await dataProvider.resetUserPassword(user.uid);
      
      print('UsersScreen: Contraseña reseteada, cerrando indicador de carga');
      // Cerrar indicador de carga
      Navigator.of(context).pop();

      // Actualizar el estado local inmediatamente
      final updatedUsers = dataProvider.users.map((u) {
        if (u.uid == user.uid) {
          return u.copyWith(provisionalPasswordSet: true);
        }
        return u;
      }).toList();
      
      dataProvider.updateUsersLocally(updatedUsers);

      // Mostrar diálogo con la nueva contraseña
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Contraseña Provisional Generada'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Usuario: ${user.name}'),
              const SizedBox(height: 8),
              Text('Email: ${user.email}'),
              const SizedBox(height: 16),
              const Text(
                'Nueva contraseña provisional:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        newPassword,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy),
                      onPressed: () {
                        // TODO: Implementar copia al portapapeles
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Contraseña copiada al portapapeles'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Comparte esta contraseña con el usuario de forma segura.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
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

      // Mostrar mensaje de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Contraseña reseteada exitosamente'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

    } catch (e) {
      print('UsersScreen: Error en resetUserPassword: $e');
      // Cerrar indicador de carga si está abierto
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      // Mostrar mensaje de error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al resetear contraseña: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
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
    print('UsersScreen: Iniciando showEditUserDialog para usuario: ${user.email}');
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditUserForm(user: user),
      ),
    );
  }

  String _getUserTypeDisplayName(UserType userType) {
    switch (userType) {
      case UserType.DOCENTE:
        return 'Docente';
      case UserType.ADMIN_STAFF:
        return 'Administrativo';
      case UserType.ESTUDIANTE:
        return 'Estudiante';
      case UserType.ACUDIENTE:
        return 'Acudiente';
    }
  }

  Color _getUserTypeColor(UserType userType) {
    switch (userType) {
      case UserType.DOCENTE:
        return Colors.blue;
      case UserType.ADMIN_STAFF:
        return Colors.orange;
      case UserType.ESTUDIANTE:
        return Colors.green;
      case UserType.ACUDIENTE:
        return Colors.purple;
    }
  }

  String _getDocumentTypeDisplayName(DocumentType documentType) {
    switch (documentType) {
      case DocumentType.CC:
        return 'CC';
      case DocumentType.CE:
        return 'CE';
      case DocumentType.TI:
        return 'TI';
      case DocumentType.PASSPORT:
        return 'Pasaporte';
    }
  }

  Widget _buildTypeSpecificInfo(UserModel user) {
    final data = user.typeSpecificData;
    if (data == null) return const SizedBox.shrink();
    switch (user.userType) {
      case UserType.DOCENTE:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (data.areaOfStudy != null && data.areaOfStudy!.isNotEmpty)
              Text('Área: ${data.areaOfStudy}', style: const TextStyle(fontSize: 12)),
            if (data.schoolPosition != null)
              Text('Cargo: ${_getSchoolPositionDisplayName(data.schoolPosition!)}', style: const TextStyle(fontSize: 12)),
            if (data.teacherLevel != null)
              Text('Nivel: ${_getTeacherLevelDisplayName(data.teacherLevel!)}', style: const TextStyle(fontSize: 12)),
          ],
        );
      case UserType.ADMIN_STAFF:
        return data.profession != null && data.profession!.isNotEmpty
            ? Text('Profesión: ${data.profession}', style: const TextStyle(fontSize: 12))
            : const SizedBox.shrink();
      case UserType.ESTUDIANTE:
        return data.schoolGrade != null
            ? Text('Grado: ${_getSchoolGradeDisplayName(data.schoolGrade!)}', style: const TextStyle(fontSize: 12))
            : const SizedBox.shrink();
      case UserType.ACUDIENTE:
        return data.representedChildrenCount != null
            ? Text('Estudiantes a cargo: ${data.representedChildrenCount}', style: const TextStyle(fontSize: 12))
            : const SizedBox.shrink();
    }
  }

  String _getSchoolPositionDisplayName(SchoolPosition pos) {
    switch (pos) {
      case SchoolPosition.RECTOR:
        return 'Rector';
      case SchoolPosition.COORD_ACADEMICO_PRIMARIA:
        return 'Coord. Académico Primaria';
      case SchoolPosition.COORD_ACADEMICO_SECUNDARIA:
        return 'Coord. Académico Secundaria';
      case SchoolPosition.COORD_CONVIVENCIA:
        return 'Coord. Convivencia';
      case SchoolPosition.ADMINISTRATIVO:
        return 'Administrativo';
      case SchoolPosition.DOCENTE:
        return 'Docente';
    }
  }

  String _getTeacherLevelDisplayName(TeacherLevel level) {
    switch (level) {
      case TeacherLevel.TRANSICION:
        return 'Transición';
      case TeacherLevel.PRIMARIA:
        return 'Primaria';
      case TeacherLevel.BACHILLERATO:
        return 'Bachillerato';
    }
  }

  String _getSchoolGradeDisplayName(SchoolGrade grade) {
    switch (grade) {
      case SchoolGrade.PREESCOLAR:
        return 'Preescolar';
      case SchoolGrade.PRIMARIA_GRADO_1:
        return 'Primaria 1';
      case SchoolGrade.PRIMARIA_GRADO_2:
        return 'Primaria 2';
      case SchoolGrade.PRIMARIA_GRADO_3:
        return 'Primaria 3';
      case SchoolGrade.PRIMARIA_GRADO_4:
        return 'Primaria 4';
      case SchoolGrade.PRIMARIA_GRADO_5:
        return 'Primaria 5';
      case SchoolGrade.BACHILLERATO_GRADO_6:
        return 'Bachillerato 6';
      case SchoolGrade.BACHILLERATO_GRADO_7:
        return 'Bachillerato 7';
      case SchoolGrade.BACHILLERATO_GRADO_8:
        return 'Bachillerato 8';
      case SchoolGrade.BACHILLERATO_GRADO_9:
        return 'Bachillerato 9';
      case SchoolGrade.BACHILLERATO_GRADO_10:
        return 'Bachillerato 10';
      case SchoolGrade.BACHILLERATO_GRADO_11:
        return 'Bachillerato 11';
    }
  }

  Widget _buildTabChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? color : color.withOpacity(0.5),
            width: selected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : color,
            fontWeight: selected ? FontWeight.bold : FontWeight.w500,
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildActionIconButton({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon, color: color, size: 20),
      tooltip: tooltip,
    );
  }

  bool _canDeleteUser(UserModel user) {
    final currentUser = context.read<AuthProvider>().userData;
    
    // No se puede eliminar a sí mismo
    if (currentUser?.uid == user.uid) {
      return false;
    }
    
    // Solo SuperUsers pueden eliminar usuarios
    if (currentUser?.isSuperUser != true) {
      return false;
    }
    
    // No se puede eliminar a otro SuperUser
    if (user.isSuperUser) {
      return false;
    }
    
    return true;
  }

  void _showUserDetails(BuildContext context, UserModel user, DataProvider dataProvider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Consumer<DataProvider>(
        builder: (context, dataProvider, child) {
          print('UsersScreen: Consumer<DataProvider> rebuilding...');
          // Obtener el usuario actualizado del DataProvider
          final currentUser = dataProvider.users.firstWhere(
            (u) => u.uid == user.uid,
            orElse: () => user,
          );
          
          print('UsersScreen: Modal rebuilding with user: ${currentUser.email}, isActive: ${currentUser.isActive}, uid: ${currentUser.uid}');
          print('UsersScreen: Modal - Total users in DataProvider: ${dataProvider.users.length}');
          print('UsersScreen: Modal - Users with same UID: ${dataProvider.users.where((u) => u.uid == currentUser.uid).length}');
          
          return Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Header con botón de cerrar y editar
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                border: Border(
                  bottom: BorderSide(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                children: [
                  Text(
                    'Detalles del Usuario',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                          const SizedBox(width: 8),
                          // Mostrar insignia de verificado o llave según el estado
                          if (currentUser.provisionalPasswordSet == false) ...[
                            // Usuario verificado - mostrar insignia
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.green.withOpacity(0.3)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                    children: [
                                  Icon(
                                    Icons.verified,
                                    size: 16,
                                    color: Colors.green,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Verificado',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ] else ...[
                            // Usuario no verificado - mostrar llave
                      IconButton(
                              icon: Icon(
                                Icons.vpn_key,
                                color: Colors.orange,
                              ),
                              tooltip: 'Ver contraseña provisional',
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: const Text('Contraseña Provisional'),
                                    content: ProvisionalPasswordDisplay(
                                      userId: currentUser.uid,
                                      provisionalPasswordSet: currentUser.provisionalPasswordSet,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ],
                      ),
                      Row(
                        children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                        tooltip: 'Cerrar',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Contenido del modal
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Información básica
                    _buildInfoSection(
                      'Información Básica',
                      [
                            _buildInfoRow('Nombre', currentUser.name),
                            _buildInfoRow('Email', currentUser.email),
                            _buildInfoRow('Documento', '${_getDocumentTypeDisplayName(currentUser.documentType)}: ${currentUser.documentNumber}'),
                            if (currentUser.phone != null && currentUser.phone!.isNotEmpty)
                              _buildInfoRow('Teléfono', currentUser.phone!),
                          ],
                        ),
                        
                        // Información específica según el tipo
                        if (currentUser.typeSpecificData != null) ...[
                    const SizedBox(height: 24),
                          _buildTypeSpecificSection(currentUser),
                        ],
                    
                        const SizedBox(height: 24),
                        
                        // Información del sistema (al final)
                    _buildInfoSection(
                      'Información del Sistema',
                      [
                            _buildInfoRow('Tipo de Usuario', _getUserTypeDisplayName(currentUser.userType)),
                            _buildInfoRow('Rol', _getRoleDisplayName(currentUser.appRole.name)),
                            _buildInfoRow('Estado', currentUser.isActive ? 'Activo' : 'Inactivo'),
                            _buildInfoRow('Verificación', currentUser.provisionalPasswordSet == false ? 'Verificado' : 'Pendiente de verificación'),
                            _buildInfoRow('Fecha de Creación', _formatDate(currentUser.createdAt)),
                            _buildInfoRow('Última Actualización', _formatDate(currentUser.updatedAt)),
                          ],
                        ),
                        
                      const SizedBox(height: 24),
                        
                        // Botones de acción en una sola línea
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                            // Botón de Reset Contraseña
                            ElevatedButton.icon(
                              onPressed: () => _resetUserPassword(currentUser, dataProvider),
                              icon: const Icon(Icons.vpn_key, size: 16),
                              label: const Text(
                                'Reset Password',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                elevation: 1,
                              ),
                            ),
                            
                            // Botón Editar
                            _buildActionIconButton(
                              icon: Icons.edit,
                              color: Colors.blue,
                              tooltip: 'Editar usuario',
                            onPressed: () {
                              Navigator.of(context).pop();
                                _showEditUserDialog(context, currentUser);
                              },
                            ),
                            
                            // Botón Activar/Desactivar
                            _buildActionIconButton(
                              icon: currentUser.isActive ? Icons.block : Icons.check_circle,
                              color: currentUser.isActive ? Colors.red : Colors.green,
                              tooltip: currentUser.isActive ? 'Desactivar usuario' : 'Activar usuario',
                              onPressed: () => _toggleUserStatusInModal(currentUser, dataProvider),
                            ),
                            
                            // Botón Eliminar (solo si no es el usuario actual)
                            if (_canDeleteUser(currentUser)) ...[
                              _buildActionIconButton(
                                icon: Icons.delete,
                                color: Colors.red,
                                tooltip: 'Eliminar usuario',
                                onPressed: () => _deleteUser(currentUser, dataProvider),
                              ),
                            ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
          );
        },
      ),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
            ),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeSpecificSection(UserModel user) {
    final data = user.typeSpecificData!;
    String title = '';
    List<Widget> children = [];
    
    switch (user.userType) {
      case UserType.DOCENTE:
        title = 'Información del Docente';
        if (data.areaOfStudy != null && data.areaOfStudy!.isNotEmpty) {
          children.add(_buildInfoRow('Área de Estudio', data.areaOfStudy!));
        }
        if (data.schoolPosition != null) {
          children.add(_buildInfoRow('Cargo en la Institución', _getSchoolPositionDisplayName(data.schoolPosition!)));
        }
        if (data.teacherLevel != null) {
          children.add(_buildInfoRow('Nivel de Enseñanza', _getTeacherLevelDisplayName(data.teacherLevel!)));
        }
        if (data.educationLevel != null) {
          children.add(_buildInfoRow('Nivel Educativo', _getEducationLevelDisplayName(data.educationLevel!)));
        }
        if (data.educationLevelOther != null && data.educationLevelOther!.isNotEmpty) {
          children.add(_buildInfoRow('Otro Nivel Educativo', data.educationLevelOther!));
        }
        if (data.assignedToGradeLevel != null) {
          children.add(_buildInfoRow('Nivel Asignado', _getGradeLevelDisplayName(data.assignedToGradeLevel!)));
        }
        if (data.specialAssignment != null && data.specialAssignment!.isNotEmpty) {
          children.add(_buildInfoRow('Asignación Especial', data.specialAssignment!));
        }
        if (data.isPTA != null) {
          children.add(_buildInfoRow('Miembro PTA', data.isPTA! ? 'Sí' : 'No'));
        }
        if (data.teacherRoles != null && data.teacherRoles!.isNotEmpty) {
          final roles = data.teacherRoles!.map((role) => _getTeacherRoleDisplayName(role)).join(', ');
          children.add(_buildInfoRow('Roles Especiales', roles));
        }
        break;
      case UserType.ADMIN_STAFF:
        title = 'Información Administrativa';
        if (data.profession != null && data.profession!.isNotEmpty) {
          children.add(_buildInfoRow('Profesión', data.profession!));
        }
        break;
      case UserType.ESTUDIANTE:
        title = 'Información del Estudiante';
        if (data.schoolGrade != null) {
          children.add(_buildInfoRow('Grado Escolar', _getSchoolGradeDisplayName(data.schoolGrade!)));
        }
        break;
      case UserType.ACUDIENTE:
        title = 'Información del Acudiente';
        if (data.representedChildrenCount != null) {
          children.add(_buildInfoRow('Número de Estudiantes a Cargo', data.representedChildrenCount.toString()));
        }
        if (data.representedStudentUIDs != null && data.representedStudentUIDs!.isNotEmpty) {
          children.add(_buildInfoRow('Estudiantes Representados', '${data.representedStudentUIDs!.length} estudiantes'));
        }
        break;
    }
    
    if (children.isEmpty) return const SizedBox.shrink();
    
    return _buildInfoSection(title, children);
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _getEducationLevelDisplayName(EducationLevel level) {
    switch (level) {
      case EducationLevel.PROFESIONAL:
        return 'Profesional';
      case EducationLevel.MAESTRIA:
        return 'Maestría';
      case EducationLevel.OTRO:
        return 'Otro';
    }
  }

  String _getGradeLevelDisplayName(GradeLevel level) {
    switch (level) {
      case GradeLevel.PREESCOLAR:
        return 'Preescolar';
      case GradeLevel.PRIMARIA:
        return 'Primaria';
      case GradeLevel.BACHILLERATO:
        return 'Bachillerato';
    }
  }

  String _getTeacherRoleDisplayName(TeacherRole role) {
    switch (role) {
      case TeacherRole.REPRESENTANTE_CONSEJO_ACADEMICO:
        return 'Representante Consejo Académico';
      case TeacherRole.REPRESENTANTE_COMITE_CONVIVENCIA:
        return 'Representante Comité Convivencia';
      case TeacherRole.REPRESENTANTE_CONSEJO_DIRECTIVO:
        return 'Representante Consejo Directivo';
      case TeacherRole.LIDER_PROYECTO:
        return 'Líder de Proyecto';
      case TeacherRole.LIDER_AREA:
        return 'Líder de Área';
      case TeacherRole.DIRECTOR_GRUPO:
        return 'Director de Grupo';
      case TeacherRole.NINGUNO:
        return 'Ninguno';
    }
  }

  IconData _getRoleIcon(AppRole role) {
    switch (role) {
      case AppRole.SuperUser:
        return Icons.admin_panel_settings;
      case AppRole.ADMIN:
        return Icons.admin_panel_settings;
      case AppRole.USER:
        return Icons.person;
    }
  }
} 
