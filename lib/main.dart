import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/layout_screen.dart';
import 'services/auth_provider.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  runApp(
    ChangeNotifierProvider(
      create: (_) => AuthProvider()..loadFromPrefs(),
      child: const EduConnectApp(),
    ),
  );
}

class EduConnectApp extends StatelessWidget {
  const EduConnectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EduConnect',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const _RootRouter(),
    );
  }
}

class _RootRouter extends StatefulWidget {
  const _RootRouter();

  @override
  State<_RootRouter> createState() => _RootRouterState();
}

class _RootRouterState extends State<_RootRouter> {
  _Screen _current = _Screen.splash;

  void _onSplashDone() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (mounted) {
      // Load user data if token exists
      if (token != null) {
        await context.read<AuthProvider>().loadFromPrefs();
      }
      setState(() => _current = token != null ? _Screen.home : _Screen.login);
    }
  }

  Future<void> _onLogin() async {
    await context.read<AuthProvider>().loadFromPrefs();
    if (mounted) setState(() => _current = _Screen.home);
  }

  void _onLogout() {
    if (mounted) setState(() => _current = _Screen.login);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
      child: _buildScreen(),
    );
  }

  Widget _buildScreen() {
    switch (_current) {
      case _Screen.splash:
        return SplashScreen(key: const ValueKey('splash'), onDone: _onSplashDone);
      case _Screen.login:
        return LoginScreen(key: const ValueKey('login'), onLoginSuccess: _onLogin);
      case _Screen.home:
        return LayoutScreen(key: const ValueKey('home'), onLogout: _onLogout);
    }
  }
}

enum _Screen { splash, login, home }
