import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'providers/app_state.dart';
import 'screens/landing_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/scanner_screen.dart';
import 'screens/reporter_screen.dart';
import 'screens/training_screen.dart';


void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(),
      child: const AegisApp(),
    ),
  );
}

class AegisApp extends StatelessWidget {
  const AegisApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aegis AI Phishing Detector',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFFEF4444),
        scaffoldBackgroundColor: const Color(0xFF000000),
        textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFEF4444),
          secondary: Color(0xFFDC2626),
          surface: Color(0xFF1A0000),
        ),
      ),
      home: const MainNavigationShell(),
    );
  }
}

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  bool _launched = false;

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    // Step 1: Show Landing Screen if the user hasn't clicked launch
    if (!_launched) {
      return LandingScreen(
        onLaunch: () {
          setState(() {
            _launched = true;
          });
        },
      );
    }

    // Step 2: Show Auth Screen if the user is not authenticated
    if (!appState.isAuthenticated) {
      return AuthScreen(
        onAuthSuccess: () {
          // Authentication completes and updates AppState
        },
      );
    }

    // Step 3: Show Main Console layout with navigation
    return const ConsoleLayoutShell();
  }
}

class ConsoleLayoutShell extends StatelessWidget {
  const ConsoleLayoutShell({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    // Map the activeTab string to the corresponding widget
    Widget bodyWidget;
    switch (appState.activeTab) {
      case 'scanner':
        bodyWidget = const ScannerScreen();
        break;
      case 'reporter':
        bodyWidget = const ReporterScreen();
        break;
      case 'training':
        bodyWidget = const TrainingScreen();
        break;
      case 'dashboard':
      default:
        bodyWidget = const DashboardScreen();
        break;
    }

    return Scaffold(
      body: bodyWidget,
      bottomNavigationBar: _buildGlassyBottomNavBar(context, appState),
    );
  }

  Widget _buildGlassyBottomNavBar(BuildContext context, AppState appState) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A0000).withOpacity(0.8),
        border: Border(
          top: BorderSide(
            color: Colors.white.withOpacity(0.06),
          ),
        ),
      ),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(
                    context: context,
                    appState: appState,
                    tabName: 'dashboard',
                    label: 'Dashboard',
                    icon: Icons.dashboard_customize_rounded,
                  ),
                  _buildNavItem(
                    context: context,
                    appState: appState,
                    tabName: 'scanner',
                    label: 'Scanner',
                    icon: Icons.security_rounded,
                  ),

                  _buildNavItem(
                    context: context,
                    appState: appState,
                    tabName: 'reporter',
                    label: 'Reporter',
                    icon: Icons.campaign_rounded,
                  ),
                  _buildNavItem(
                    context: context,
                    appState: appState,
                    tabName: 'training',
                    label: 'Academy',
                    icon: Icons.school_rounded,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required AppState appState,
    required String tabName,
    required String label,
    required IconData icon,
  }) {
    final bool isActive = appState.activeTab == tabName;
    final Color color = isActive ? const Color(0xFFEF4444) : const Color(0xFF64748B);

    return InkWell(
      onTap: () {
        appState.setActiveTab(tabName);
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.outfit(
                color: color,
                fontSize: 10,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
