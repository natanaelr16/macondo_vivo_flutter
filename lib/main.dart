import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;

import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/widgets/theme_wrapper.dart';
import 'shared/providers/theme_provider.dart';
import 'shared/providers/auth_provider.dart';
import 'shared/providers/data_provider.dart';
import 'core/widgets/text_logo.dart';
import 'shared/models/user_model.dart';
import 'shared/models/activity_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('Main: Initializing Firebase...');
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  print('Main: Firebase initialized successfully');
  
  // Debug: Create test data if needed
  // await _createTestDataIfNeeded();
  
  print('Main: Starting app...');
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => DataProvider()),
      ],
      child: const MacondoVivoApp(),
    ),
  );
}

Future<void> _createTestDataIfNeeded() async {
  try {
    print('Debug: Checking if test data exists...');
    final firestore = FirebaseFirestore.instance;
    
    // Check if we have any users
    final usersSnapshot = await firestore.collection('users').limit(1).get();
    print('Debug: Found ${usersSnapshot.docs.length} existing users');
    
    if (usersSnapshot.docs.isEmpty) {
      print('Debug: No users found, creating test data...');
      await _createTestUser();
    }
    
    // Check if we have any activities
    final activitiesSnapshot = await firestore.collection('activities').limit(1).get();
    print('Debug: Found ${activitiesSnapshot.docs.length} existing activities');
    
    if (activitiesSnapshot.docs.isEmpty) {
      print('Debug: No activities found, creating test activity...');
      await _createTestActivity();
    }
    
    print('Debug: Test data check completed');
  } catch (e) {
    print('Debug: Error creating test data: $e');
  }
}

Future<void> _createTestUser() async {
  try {
    final firestore = FirebaseFirestore.instance;
    
    // Create a test user document directly in Firestore
    final testUser = UserModel(
      uid: 'test_user_123',
      email: 'admin@macondo.test',
      firstName: 'Admin',
      lastName: 'Test',
      documentType: DocumentType.CC,
      documentNumber: '12345678',
      phone: '555-1234',
      userType: UserType.ADMIN_STAFF,
      appRole: AppRole.SuperUser,
      status: UserStatus.VERIFIED,
      isActive: true,
      provisionalPasswordSet: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    await firestore.collection('users').doc('test_user_123').set(testUser.toFirestore());
    print('Debug: Test user created successfully');
  } catch (e) {
    print('Debug: Error creating test user: $e');
  }
}

Future<void> _createTestActivity() async {
  try {
    final firestore = FirebaseFirestore.instance;
    
    // Create a test activity document directly in Firestore
    final testActivity = ActivityModel(
      activityId: 'test_activity_123',
      title: 'Actividad de Prueba',
      description: 'Esta es una actividad de prueba para verificar que el sistema funciona correctamente.',
      numberOfSessions: 2,
      sessionDates: [
        SessionDate(
          sessionNumber: 1,
          date: DateTime.now().add(const Duration(days: 7)),
          startTime: '09:00',
          endTime: '11:00',
          location: 'Aula 101',
        ),
        SessionDate(
          sessionNumber: 2,
          date: DateTime.now().add(const Duration(days: 14)),
          startTime: '14:00',
          endTime: '16:00',
          location: 'Aula 102',
        ),
      ],
      materials: ['Material de prueba'],
      objectives: ['Objetivo de prueba'],
      responsibleUsers: [
        Participant(
          userId: 'test_user_123',
          status: 'COMPLETADA',
        ),
      ],
      participants: [
        Participant(
          userId: 'test_user_123',
          status: 'PENDIENTE',
        ),
      ],
      status: ActivityStatus.ACTIVA,
      adminCanEdit: true,
      createdBy_uid: 'test_user_123',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      sessionCompletions: [],
    );
    
    await firestore.collection('activities').doc('test_activity_123').set(testActivity.toFirestore());
    print('Debug: Test activity created successfully');
  } catch (e) {
    print('Debug: Error creating test activity: $e');
  }
}

class MacondoVivoApp extends StatefulWidget {
  const MacondoVivoApp({super.key});

  @override
  State<MacondoVivoApp> createState() => _MacondoVivoAppState();
}

class _MacondoVivoAppState extends State<MacondoVivoApp> {

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        print('MacondoVivoApp: Building with theme mode: ${themeProvider.themeMode}');
        return ThemeWrapper(
          child: MaterialApp.router(
            title: 'Macondo Vivo',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: _getThemeMode(themeProvider.themeMode),
            routerConfig: AppRouter.router,
          ),
        );
      },
    );
  }

  ThemeMode _getThemeMode(AppThemeMode providerMode) {
    switch (providerMode) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.system:
        return ThemeMode.system;
    }
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final backgroundColor = Theme.of(context).colorScheme.background;
    final cardColor = Theme.of(context).colorScheme.surface;
    final textColor = Theme.of(context).colorScheme.onBackground;
    final textSecondaryColor = Theme.of(context).colorScheme.onSurface.withOpacity(0.7);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Text Logo
                const TextLogo(
                  fontSize: 48,
                  showSubtitle: true,
                ),
                
                const SizedBox(height: 32),
                
                // Subtitle
                Text(
                  'Inicia sesión para continuar',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 48),
                
                // Debug button (temporary)
                Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                    return Column(
                      children: [
                        Text(
                          'Debug Info:',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                                            Text(
                      'Authenticated: ${authProvider?.isAuthenticated ?? false}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      'User: ${authProvider?.user?.email ?? "None"}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                        const SizedBox(height: 16),
                      ],
                    );
                  },
                ),
                
                // Login Form
                Column(
                  children: [
                    TextField(
                      controller: _emailController,
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        labelText: 'Correo Electrónico',
                        prefixIcon: Icon(Icons.email, color: textSecondaryColor),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passwordController,
                      style: TextStyle(color: textColor),
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Contraseña',
                        prefixIcon: Icon(Icons.lock, color: textSecondaryColor),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Login Button
                    Consumer<AuthProvider>(
                      builder: (context, authProvider, child) {
                        return SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: authProvider?.isLoading == true ? null : _handleLogin,
                            child: authProvider?.isLoading == true
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Text(
                                    'Iniciar Sesión',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                  ),
                          ),
                        );
                      },
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Info about Firebase authentication
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: primaryColor.withOpacity(0.3)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Autenticación Firebase',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: primaryColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Esta aplicación usa Firebase Authentication para conectarse a tu base de datos existente de Macondo Vivo.',
                            style: TextStyle(
                              fontSize: 14,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Usa las mismas credenciales que usas en la aplicación web.',
                            style: TextStyle(
                              fontSize: 12,
                              color: textSecondaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Theme selector
                    Consumer<ThemeProvider>(
                      builder: (context, themeProvider, child) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: primaryColor.withOpacity(0.3)),
                          ),
                          child: InkWell(
                            onTap: _showThemeSelector,
                            borderRadius: BorderRadius.circular(20),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    themeProvider.themeModeIcon,
                                    size: 16,
                                    color: primaryColor,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    themeProvider.themeModeName,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: primaryColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.arrow_drop_down,
                                    size: 16,
                                    color: primaryColor,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Manual navigation button (for testing)
                    ElevatedButton(
                      onPressed: () {
                        print('Manual navigation to dashboard');
                        context.go('/dashboard');
                      },
                      child: const Text('Ir al Dashboard (Manual)'),
                    ),
                    
                    const SizedBox(height: 24),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showThemeSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => const ThemeSelectorSheet(),
    );
  }

  Future<void> _handleLogin() async {
    print('LoginScreen: Starting login process...');
    
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      print('LoginScreen: Empty fields detected');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Por favor completa todos los campos'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final dataProvider = context.read<DataProvider>();
    
    print('LoginScreen: Calling authProvider.signIn...');
    final success = await authProvider.signIn(
      _emailController.text.trim(),
      _passwordController.text,
    );

    print('LoginScreen: Sign in result: $success');
    print('LoginScreen: AuthProvider isAuthenticated: ${authProvider.isAuthenticated}');
    print('LoginScreen: AuthProvider user: ${authProvider.user?.email}');

    if (success && mounted) {
      print('LoginScreen: Login successful, showing welcome message');
      
      // Force refresh the auth state
      await authProvider.refreshState();
      
      // Initialize data
      await dataProvider.loadAllData();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('¡Bienvenido, ${authProvider.user?.email}!'),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
      
      // Force router refresh by navigating
      if (mounted) {
        print('LoginScreen: Forcing navigation to dashboard');
        context.go('/dashboard');
      }
    } else if (mounted && authProvider.error != null) {
      print('LoginScreen: Login failed, showing error: ${authProvider.error}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.error!),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
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
