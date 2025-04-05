import 'Screens/file_screen.dart';
import 'package:flutter/material.dart';
import 'Screens/project_list_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'Support/firebase_options.dart';
import 'Screens/llm_interface.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "File Import",
      home: ProjectListScreen(),
      routes:{
        '/projectView': (context) => FileScreen(),
        '/LLMChat': (context) => LLMInterface(),
      },
    );
  }
}
