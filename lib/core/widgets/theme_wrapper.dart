import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../shared/providers/theme_provider.dart';

class ThemeWrapper extends StatefulWidget {
  final Widget child;
  
  const ThemeWrapper({
    super.key,
    required this.child,
  });

  @override
  State<ThemeWrapper> createState() => _ThemeWrapperState();
}

class _ThemeWrapperState extends State<ThemeWrapper> {
  bool _isChangingTheme = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        // If theme is changing, show a loading indicator briefly
        if (_isChangingTheme) {
          return MaterialApp(
            home: Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Cambiando tema...',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return widget.child;
      },
    );
  }

  // Method to safely change theme
  static void safeChangeTheme(BuildContext context, AppThemeMode newMode) {
    final wrapperState = context.findAncestorStateOfType<_ThemeWrapperState>();
    if (wrapperState != null) {
      wrapperState._changeTheme(context, newMode);
    }
  }

  void _changeTheme(BuildContext context, AppThemeMode newMode) {
    setState(() {
      _isChangingTheme = true;
    });

    // Add a small delay to prevent navigation issues
    Future.delayed(const Duration(milliseconds: 100), () {
      final themeProvider = context.read<ThemeProvider>();
      themeProvider.setThemeMode(newMode);
      
      setState(() {
        _isChangingTheme = false;
      });
    });
  }
} 