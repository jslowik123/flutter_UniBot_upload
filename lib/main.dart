import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'Support/firebase_options.dart';
import 'Screens/project_list_screen.dart';
import 'Screens/file_screen.dart';
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
      debugShowCheckedModeBanner: false,

      title: "File Import",
      home: ProjectListScreen(), //ProjectListScreen(),
      routes: {'/projectView': (context) => FileScreen()},
    );
  }
}
