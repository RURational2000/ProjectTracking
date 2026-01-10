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
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final session = snapshot.hasData ? snapshot.data!.session : null;

        if (session != null) {
          // User is signed in - initialize services and show home screen
          return FutureBuilder(
            future: _initializeServices(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              if (snapshot.hasError) {
                return Scaffold(
                  body: Center(
                    child: Text('Error initializing: ${snapshot.error}'),
                  ),
                );
              }

              final services = snapshot.data as _Services;
              return ChangeNotifierProvider(
                create: (_) => TrackingProvider(
                  dbService: services.dbService,
                  fileService: services.fileService,
                ),
                child: const HomeScreen(),
              );
            },
          );
        } else {
          // User is not signed in
          return const AuthScreen();
        }
      },
    );
  }

  Future<_Services> _initializeServices() async {
    final DatabaseService dbService = SupabaseDatabaseService();
    await dbService.initialize();

    final fileService = FileLoggingService();
    await fileService.initialize();

    return _Services(dbService: dbService, fileService: fileService);
  }
}

class _Services {
  final DatabaseService dbService;
  final FileLoggingService fileService;

  _Services({required this.dbService, required this.fileService});
}
