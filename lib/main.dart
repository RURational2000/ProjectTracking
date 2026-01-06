import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:project_tracking/services/database_service.dart';
import 'package:project_tracking/services/file_logging_service.dart';
import 'package:project_tracking/providers/tracking_provider.dart';
import 'package:project_tracking/screens/auth_screen.dart';
import 'package:project_tracking/screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding
      .ensureInitialized(); // Required for async operations in main
  await dotenv.load(fileName: ".env.development");

  // Initialize sqflite for desktop platforms
  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  // const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  var supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
  var supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
    throw Exception(
      'Missing required environment variables: SUPABASE_URL and SUPABASE_ANON_KEY. '
      'Configure these with --dart-define before running the app.',
    );
  }

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  // Initialize services
  final dbService = DatabaseService();
  await dbService.initialize();

  final fileService = FileLoggingService();
  await fileService.initialize();

  runApp(MyApp(dbService: dbService, fileService: fileService));
}

class MyApp extends StatelessWidget {
  final DatabaseService dbService;
  final FileLoggingService fileService;

  const MyApp({
    super.key,
    required this.dbService,
    required this.fileService,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TrackingProvider(
        dbService: dbService,
        fileService: fileService,
      ),
      child: MaterialApp(
        title: 'Project Tracking',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
        ),
        home: StreamBuilder<AuthState>(
          stream: Supabase.instance.client.auth.onAuthStateChange,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final session = snapshot.data?.session ??
                Supabase.instance.client.auth.currentSession;

            if (session != null) {
              return const HomeScreen();
            }
            return const AuthScreen();
          },
        ),
      ),
    );
  }
}
