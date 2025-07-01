import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../shared/providers/theme_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuraciones'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/dashboard'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Theme Settings
          Card(
            child: ListTile(
              leading: const Icon(Icons.palette),
              title: const Text('Tema de la Aplicación'),
              subtitle: Consumer<ThemeProvider>(
                builder: (context, themeProvider, child) {
                  return Text(themeProvider.themeModeName);
                },
              ),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => _showThemeSelector(context),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Profile Settings
          Card(
            child: ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Perfil de Usuario'),
              subtitle: const Text('Editar información personal'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                // TODO: Navigate to profile
              },
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Notifications Settings
          Card(
            child: ListTile(
              leading: const Icon(Icons.notifications),
              title: const Text('Notificaciones'),
              subtitle: const Text('Configurar notificaciones'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                // TODO: Navigate to notifications
              },
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Security Settings
          Card(
            child: ListTile(
              leading: const Icon(Icons.security),
              title: const Text('Seguridad'),
              subtitle: const Text('Cambiar contraseña y configuración de seguridad'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                // TODO: Navigate to security
              },
            ),
          ),
          
          const SizedBox(height: 16),
          
          // About
          Card(
            child: ListTile(
              leading: const Icon(Icons.info),
              title: const Text('Acerca de'),
              subtitle: const Text('Información de la aplicación'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                // TODO: Show about dialog
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showThemeSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => const ThemeSelectorSheet(),
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