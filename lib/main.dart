import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/widgets/theme_wrapper.dart';
import 'shared/providers/theme_provider.dart';
import 'shared/providers/auth_provider.dart';
import 'shared/providers/data_provider.dart';
import 'shared/providers/navigation_provider.dart';
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
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
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

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  late AnimationController _inController;
  late AnimationController _outController;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideIn;
  late Animation<double> _fadeOut;
  late Animation<Offset> _slideOut;

  bool _isLoading = false;
  bool _isExiting = false;
  bool _showPassword = false;

  @override
  void initState() {
    super.initState();
    _inController = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _outController = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    _fadeIn = CurvedAnimation(parent: _inController, curve: Curves.easeOut);
    _slideIn = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(CurvedAnimation(parent: _inController, curve: Curves.easeOut));
    _fadeOut = CurvedAnimation(parent: _outController, curve: Curves.easeIn);
    _slideOut = Tween<Offset>(begin: Offset.zero, end: const Offset(0, -0.2)).animate(CurvedAnimation(parent: _outController, curve: Curves.easeIn));
    _inController.forward();
  }

  @override
  void dispose() {
    _inController.dispose();
    _outController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final backgroundColor = Theme.of(context).colorScheme.surface;
    final cardColor = Theme.of(context).colorScheme.surface;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final textSecondaryColor = Theme.of(context).colorScheme.onSurface.withOpacity(0.7);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animación para el logo de Macondo Vivo
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
                  // Animación para el formulario de login
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 40.0, end: 0.0),
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.easeOut,
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: 1 - (value / 40.0),
                        child: Transform.translate(
                          offset: Offset(0, value),
                          child: child,
                        ),
                      );
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
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
                          obscureText: !_showPassword,
                          decoration: InputDecoration(
                            labelText: 'Contraseña',
                            prefixIcon: Icon(Icons.lock, color: textSecondaryColor),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _showPassword ? Icons.visibility : Icons.visibility_off,
                                color: textSecondaryColor,
                              ),
                              onPressed: () {
                                setState(() {
                                  _showPassword = !_showPassword;
                                });
                              },
                              tooltip: _showPassword ? 'Ocultar contraseña' : 'Ver contraseña',
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 400),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 48,
                                  height: 52,
                                  child: CircularProgressIndicator(strokeWidth: 3),
                                )
                              : SizedBox(
                                  width: double.infinity,
                                  height: 52,
                                  child: ElevatedButton(
                                    onPressed: _handleLogin,
                                    child: const Text(
                                      'Iniciar Sesión',
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ),
                        ),
                        const SizedBox(height: 16),
                        Consumer<ThemeProvider>(
                          builder: (context, themeProvider, child) => Center(
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: primaryColor.withOpacity(0.3)),
                              ),
                              child: IconButton(
                                icon: Icon(
                                  themeProvider.themeModeIcon,
                                  size: 20,
                                  color: primaryColor,
                                ),
                                onPressed: _showThemeSelector,
                                padding: const EdgeInsets.all(8),
                                constraints: const BoxConstraints(),
                                splashRadius: 20,
                                tooltip: 'Cambiar tema',
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(bottom: 24.0, top: 8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Tecnologías usadas',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildTechLogo('assets/logos/flutter.png'),
                _buildTechLogo('assets/logos/firebase.png'),
                _buildTechLogo('assets/logos/dart.png'),
              ],
            ),
          ],
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
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Por favor completa todos los campos'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }
    setState(() => _isLoading = true);
    final authProvider = context.read<AuthProvider>();
    final dataProvider = context.read<DataProvider>();
    final success = await authProvider.signIn(
      _emailController.text.trim(),
      _passwordController.text,
    );
    if (success && mounted) {
      await authProvider.refreshState();
      await dataProvider.loadAllData();
      setState(() {
        _isExiting = true;
        _isLoading = false;
      });
      await _outController.forward();
      if (mounted) {
        context.go('/dashboard');
      }
    } else if (mounted && authProvider.error != null) {
      setState(() => _isLoading = false);
      final errorMsg = _firebaseErrorToSpanish(authProvider.error!);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } else {
      setState(() => _isLoading = false);
    }
  }

  String _firebaseErrorToSpanish(String error) {
    if (error.contains('user-not-found')) {
      return 'No existe una cuenta con ese correo.';
    } else if (error.contains('wrong-password')) {
      return 'La contraseña es incorrecta.';
    } else if (error.contains('invalid-email')) {
      return 'El correo electrónico no es válido.';
    } else if (error.contains('too-many-requests')) {
      return 'Demasiados intentos fallidos. Intenta de nuevo más tarde.';
    } else if (error.contains('network-request-failed')) {
      return 'Error de red. Verifica tu conexión a internet.';
    } else if (error.contains('user-disabled')) {
      return 'Esta cuenta ha sido deshabilitada.';
    }
    // Mensaje genérico para otros errores
    return 'Error al iniciar sesión. Verifica tus credenciales.';
  }

  Widget _buildTechLogo(String assetPath) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: Opacity(
        opacity: 0.6,
        child: SizedBox(
          width: 75,
          height: 75,
          child: Image.asset(assetPath),
        ),
      ),
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
