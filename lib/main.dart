import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:project_tracking/services/database_service.dart';
import 'package:project_tracking/services/file_logging_service.dart';
import 'package:project_tracking/providers/tracking_provider.dart';
import 'package:project_tracking/screens/auth_screen.dart';
import 'package:project_tracking/screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env.development");

  var supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
  var supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
    throw StateError(
      'Missing environment variables: SUPABASE_URL and SUPABASE_ANON_KEY. '
      'Please add them to your .env.development file and rebuild the app.',
    );
  }

  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Project Tracking',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const AuthGate(),
    );
  }
}

/// Handles authentication state and routing
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final StreamSubscription<AuthState> _authSubscription;
  TrackingProvider? _trackingProvider;

  @override
  void initState() {
    super.initState();
    _authSubscription =
        Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      if (session != null && _trackingProvider == null) {
        _initializeServicesAndProvider();
      } else if (session == null) {
        setState(() {
          _trackingProvider = null;
        });
      }
    });
  }

  Future<void> _initializeServicesAndProvider() async {
    final dbService = SupabaseDatabaseService();
    await dbService.initialize();

    final fileService = FileLoggingService();
    await fileService.initialize();

    if (mounted) {
      setState(() {
        _trackingProvider = TrackingProvider(
            dbService: dbService, fileService: fileService);
      });
    }
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_trackingProvider != null) {
      return ChangeNotifierProvider.value(
        value: _trackingProvider!,
        child: const HomeScreen(),
      );
    }

    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) {
      return const AuthScreen();
    }

    // Services are initializing
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
