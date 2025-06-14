// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'routes/app_routes.dart'; // Ensure this path is correct

// Global ValueNotifier to control the theme mode from anywhere in the app
final ValueNotifier<ThemeMode> themeModeNotifier =
    ValueNotifier(ThemeMode.system);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // Define your custom light theme
  ThemeData _buildLightTheme() {
    const ColorScheme lightColorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xFF0D47A1), // Deep Blue (Primary color for light mode)
      onPrimary: Colors.white, // Text color on primary (already white)
      secondary:
          Color(0xFF4DD0E1), // Vibrant Cyan (Accent color for light mode)
      onSecondary: Colors.white, // Text color on secondary
      error: Color(0xFFD32F2F), // Error red
      onError: Colors.white,
      surface: Colors.white, // Card/Surface background
      onSurface: Colors.black, // Text on white surface (default text)
      outline: Color(0xFFB0BEC5), // Light grey for borders
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: lightColorScheme,
      fontFamily: 'Roboto',
      scaffoldBackgroundColor:
          lightColorScheme.surface, // Explicitly set scaffold background
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: lightColorScheme.primary,
          foregroundColor: lightColorScheme.onPrimary, // This will be white
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          // Option 1: Keep accent color as it provides contrast on light background
          foregroundColor: const Color(0xFFFF6F00),
          // Option 2: If you truly want white text on TextButtons, use this
          // foregroundColor: Colors.white, // BE CAREFUL: May be invisible on light backgrounds
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: lightColorScheme.primary,
        foregroundColor: lightColorScheme.onPrimary,
        elevation: 4,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightColorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: lightColorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide:
              BorderSide(color: lightColorScheme.outline.withOpacity(0.7)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
              color: lightColorScheme.primary,
              width: 2), // Primary color when focused
        ),
        labelStyle: TextStyle(color: lightColorScheme.onSurface),
        hintStyle:
            TextStyle(color: lightColorScheme.onSurface.withOpacity(0.6)),
      ),
    );
  }

  // Define your custom dark theme
  ThemeData _buildDarkTheme() {
    // Added debug print
    const ColorScheme darkColorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: Color(
          0xFF2196F3), // Material Blue 500 (Primary color for dark mode - slightly lighter for visibility)
      onPrimary: Colors.white, // <--- CHANGED THIS TO WHITE
      secondary:
          Color(0xFF00E5FF), // Cyan Accent 700 (Accent color for dark mode)
      onSecondary: Colors.black, // Text color on secondary
      error: Color(0xFFEF9A9A), // Lighter red for error in dark mode
      onError: Colors.black,
      background: Color(
          0xFF121212), // Very dark grey background (default text will be white)
      onBackground: Colors
          .white, // Text on dark background (ensures default text is white)
      surface:
          Color(0xFF1E1E1E), // Slightly lighter dark grey for cards/surfaces
      onSurface:
          Colors.white, // Text on dark surface (ensures default text is white)
      outline: Color(0xFF424242), // Dark grey for borders
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: darkColorScheme,
      fontFamily: 'Roboto',
      scaffoldBackgroundColor:
          darkColorScheme.background, // Explicitly set scaffold background
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: darkColorScheme.primary,
          foregroundColor: darkColorScheme.onPrimary, // This will now be white
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          // Option 1: Keep accent color as it provides good contrast on dark background
          foregroundColor: darkColorScheme.secondary,
          // Option 2: If you truly want white text on TextButtons, use this
          // foregroundColor: Colors.white,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: darkColorScheme.primary,
        foregroundColor: darkColorScheme.onPrimary,
        elevation: 4,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkColorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: darkColorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide:
              BorderSide(color: darkColorScheme.outline.withOpacity(0.7)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: darkColorScheme.primary, width: 2),
        ),
        labelStyle: TextStyle(color: darkColorScheme.onSurface),
        hintStyle: TextStyle(color: darkColorScheme.onSurface.withOpacity(0.6)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (context, currentThemeMode, child) {
        return MaterialApp(
          title: 'Application Réseau',
          theme: _buildLightTheme(), // Your custom light theme
          darkTheme: _buildDarkTheme(), // Your custom dark theme
          themeMode: currentThemeMode, // Controlled by the ValueNotifier
          debugShowCheckedModeBanner: false,
          // CRUCIAL: Use builder to ensure theme is applied to the Navigator and all routes
          builder: (context, navigator) {
            return Theme(
              data: Theme.of(context), // Inherit the currently resolved theme
              child:
                  navigator!, // The navigator widget responsible for displaying routes
            );
          },
          initialRoute: AppRoutes.home, // Use the constant from your routes
          onGenerateRoute:
              AppRoutes.generateRoute, // Use your custom route generator
        );
      },
    );
  }
}
