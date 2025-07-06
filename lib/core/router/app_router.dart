import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../shared/providers/auth_provider.dart';
import '../../main.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/activities/presentation/screens/activities_screen.dart';
import '../../features/users/presentation/screens/users_screen.dart';
import '../../features/reports/presentation/screens/reports_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../widgets/navigation_wrapper.dart';
import '../widgets/fixed_layout.dart';
import '../widgets/activities_layout.dart';

class AppRouter {
  static GoRouter get router => GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final authProvider = context.read<AuthProvider>();
      
      print('Router: Current location: ${state.matchedLocation}');
      print('Router: Is authenticated: ${authProvider.isAuthenticated}');
      print('Router: User: ${authProvider.user?.email}');
      print('Router: Error: ${state.error}');
      
      // If user is not authenticated and trying to access protected routes
      if (!authProvider.isAuthenticated && state.matchedLocation != '/login') {
        print('Router: Redirecting to login');
        return '/login';
      }
      
      // If user is authenticated and on login page, redirect to dashboard
      if (authProvider.isAuthenticated && state.matchedLocation == '/login') {
        print('Router: Redirecting to dashboard');
        return '/dashboard';
      }
      
      // Protect users route - only ADMIN and SuperUser can access
      if (state.matchedLocation == '/users' && !authProvider.canManageUsers) {
        print('Router: User does not have permission to access users');
        return '/dashboard';
      }
      
      print('Router: No redirect needed');
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        redirect: (context, state) => '/dashboard',
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        name: 'dashboard',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const NavigationWrapper(
            route: '/dashboard',
            child: FixedLayout(
              child: DashboardScreen(),
            ),
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
        ),
      ),
      GoRoute(
        path: '/activities',
        name: 'activities',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const NavigationWrapper(
            route: '/activities',
            child: ActivitiesLayout(
              child: ActivitiesScreen(),
            ),
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
        ),
      ),
      GoRoute(
        path: '/users',
        name: 'users',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const NavigationWrapper(
            route: '/users',
            child: FixedLayout(
              child: UsersScreen(),
            ),
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
        ),
      ),
      GoRoute(
        path: '/reports',
        name: 'reports',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const NavigationWrapper(
            route: '/reports',
            child: FixedLayout(
              child: ReportsScreen(),
            ),
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
        ),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const NavigationWrapper(
            route: '/settings',
            child: FixedLayout(
              child: SettingsScreen(),
            ),
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
        ),
      ),
    ],
    errorBuilder: (context, state) {
      print('Router: Error occurred: ${state.error}');
      print('Router: Error location: ${state.matchedLocation}');
      
      return Scaffold(
        appBar: AppBar(
          title: const Text('Error'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              // Try to go back, if not possible go to dashboard
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/dashboard');
              }
            },
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Algo salió mal',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'Ha ocurrido un error inesperado.',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                if (state.error != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Error: ${state.error}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        // Try to go back, if not possible go to dashboard
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go('/dashboard');
                        }
                      },
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Volver'),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => context.go('/dashboard'),
                      icon: const Icon(Icons.dashboard),
                      label: const Text('Dashboard'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
} 