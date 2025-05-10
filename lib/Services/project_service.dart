import 'package:firebase_database/firebase_database.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../Config/app_config.dart';
import 'dart:convert';

class ProjectService {
  final DatabaseReference _db = FirebaseDatabase.instance.ref().child(
    AppConfig.firebaseFilesPath,
  );

  String getFormattedDate() {
    final DateTime now = DateTime.now();
    final DateFormat formatter = DateFormat('dd.MM.yyyy');
    return formatter.format(now);
  }

  Future<List<Map<String, dynamic>>> fetchProjects() async {
    final snapshot = await _db.once();
    final data = snapshot.snapshot.value as Map<dynamic, dynamic>?;
    final List<Map<String, dynamic>> projects = [];

    if (data != null) {
      data.forEach((key, value) {
        projects.add({'name': key.toString(), 'data': value});
      });
    }
    return projects;
  }

  Future<void> addProject(String projectName) async {
    final response = await http.post(
      Uri.parse('${AppConfig.apiBaseUrl}/create_namespace'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {'namespace': projectName, 'dimension': '1536'},
    );

    if (response.statusCode != 200) {
      final responseData = json.decode(response.body);
      throw Exception('Failed to create namespace: ${responseData['message']}');
    }

    final newProjectRef = _db.child(projectName);
    await newProjectRef.set({"date": getFormattedDate()});
  }

 Future<void> deleteProject(String projectName) async {
    try {
      final uri = Uri.parse('${AppConfig.apiBaseUrl}/delete_namespace');
      final request = http.MultipartRequest('POST', uri)
        ..fields['namespace'] = projectName;

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final jsonResponse = json.decode(responseData);

      if (response.statusCode != 200 || jsonResponse['status'] != 'success') {
        throw Exception(
          'Namespace-Löschung fehlgeschlagen: ${jsonResponse['message'] ?? response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Fehler beim Löschen des Namespaces: $e');
    }
  }

  Future<void> updateProjectName(String oldName, String newName) async {
    final oldProjectRef = _db.child(oldName);
    final newProjectRef = _db.child(newName);

    final snapshot = await oldProjectRef.once();
    final data = snapshot.snapshot.value as Map<dynamic, dynamic>;

    await newProjectRef.set(data);
    await oldProjectRef.remove();
  }
}
