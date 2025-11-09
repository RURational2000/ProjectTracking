import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:project_tracking/services/database_service.dart';
import 'package:project_tracking/services/file_logging_service.dart';
import 'package:project_tracking/providers/tracking_provider.dart';
import 'package:project_tracking/screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
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
    Key? key,
    required this.dbService,
    required this.fileService,
  }) : super(key: key);

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
        home: const HomeScreen(),
      ),
    );
  }
}
