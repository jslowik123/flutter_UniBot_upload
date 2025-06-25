import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_uni_bot/Config/app_config.dart';
import 'Support/firebase_options.dart';
import 'Screens/project_list_screen.dart';
import 'Screens/file_screen.dart';
import 'Screens/server_unavailable_screen.dart';
import 'package:http/http.dart' as http;
import 'Screens/project_management_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late Future<bool> _serverCheck;

  @override
  void initState() {
    super.initState();
    _serverCheck = _checkServer();
  }

  Future<bool> _checkServer() async {
    try {
      final response = await http.get(Uri.parse(AppConfig.apiBaseUrl));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  void _retry() {
    setState(() {
      _serverCheck = _checkServer();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "File Import",
      home: FutureBuilder<bool>(
        future: _serverCheck,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          } else if (snapshot.hasError || snapshot.data == false) {
            return ServerUnavailableScreen(onRetry: _retry);
          } else {
            return ProjectListScreen();
          }
        },
      ),
      routes: {'/projectView': (context) => ProjectManagementScreen()},
    );
  }
}
