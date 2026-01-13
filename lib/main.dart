import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'core/providers/user_mode_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'data/services/supabase_service.dart';
import 'ui/screens/login_screen.dart';
import 'ui/layouts/main_layout.dart';
import 'core/theme/app_theme.dart';

import 'ui/screens/signup_screen.dart';

import 'package:firebase_core/firebase_core.dart';

import 'data/services/notification_service.dart';
import 'ui/screens/splash_screen.dart';
import 'ui/screens/welcome_screen.dart';
import 'ui/screens/forgot_password_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
  }
  await SupabaseService().initialize();
  debugPrint('Services initialized, starting app...');
  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => UserModeProvider())],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _showPerformanceOverlay = false;

  @override
  void initState() {
    super.initState();
    _initNotifications();
  }

  Future<void> _initNotifications() async {
    // Initialize notifications after the app has started
    debugPrint('Initializing notifications...');
    await NotificationService().initialize();
    debugPrint('Notifications initialized');
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Naija Property Connect',
      theme: AppTheme.lightTheme,
      routerConfig: _router,
      // Performance overlay for debugging
      showPerformanceOverlay: _showPerformanceOverlay,
      // Debug banner
      debugShowCheckedModeBanner: false,
      // Builder to add performance toggle button in debug mode
      builder: (context, child) {
        return Stack(
          children: [
            child ?? const SizedBox.shrink(),
            // Performance overlay toggle button (only in debug mode)
            if (const bool.fromEnvironment('dart.vm.product') == false)
              Positioned(
                bottom: 16,
                right: 16,
                child: FloatingActionButton(
                  mini: true,
                  backgroundColor: Colors.black54,
                  onPressed: () {
                    setState(() {
                      _showPerformanceOverlay = !_showPerformanceOverlay;
                    });
                  },
                  child: Icon(
                    _showPerformanceOverlay
                        ? Icons.speed
                        : Icons.speed_outlined,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

final _router = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const MainLayout()),
    GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
    GoRoute(
      path: '/welcome',
      builder: (context, state) => const WelcomeScreen(),
    ),
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(path: '/signup', builder: (context, state) => const SignupScreen()),
    GoRoute(
      path: '/forgot-password',
      builder: (context, state) => const ForgotPasswordScreen(),
    ),
  ],
  redirect: (context, state) {
    final session = Supabase.instance.client.auth.currentSession;
    final path = state.uri.toString();

    // Define public routes
    final isPublicRoute =
        path == '/splash' ||
        path == '/welcome' ||
        path == '/login' ||
        path == '/signup' ||
        path == '/forgot-password';

    // If not logged in
    if (session == null) {
      // If trying to access private route (like /), redirect to splash (or welcome/login)
      // Since initial is /splash, we usually land there.
      // If user manually types /, go to splash.
      if (!isPublicRoute) {
        return '/splash';
      }
      // Otherwise allow public route
      return null;
    }

    // If logged in
    if (isPublicRoute) {
      return '/';
    }

    return null;
  },
  refreshListenable: GoRouterRefreshStream(
    Supabase.instance.client.auth.onAuthStateChange,
  ),
);

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<AuthState> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
      (dynamic _) => notifyListeners(),
    );
  }

  late final dynamic _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
