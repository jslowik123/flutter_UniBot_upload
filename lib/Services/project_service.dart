import 'package:firebase_database/firebase_database.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../Config/app_config.dart';
import 'dart:convert';

class ProjectService {
  final DatabaseReference _db = FirebaseDatabase.instance.ref().child(
    AppConfig.firebaseFilesPath,
  );

  // In-Memory-Cache für Projektinfos und Assessments
  final Map<String, String> _projectInfoCache = {};
  final Map<String, String> _projectAssessmentCache = {};

  String getFormattedDate() {
    final DateTime now = DateTime.now();
    final DateFormat formatter = DateFormat('dd.MM.yyyy');
    return formatter.format(now);
  }
  Future<void> sendProjectAssessment(String projectName, String additionalInfo) async {
    try {
      final uri = Uri.parse('${AppConfig.apiBaseUrl}/get_assessment_data');
      final request = http.MultipartRequest('POST', uri)
        ..fields['namespace'] = projectName
        ..fields['additional_info'] = additionalInfo;

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final jsonResponse = json.decode(responseData);
    } catch (e) {
      throw Exception('Fehler beim Abrufen der Projektbeurteilung: $e');
    }
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

  String _replaceUmlauts(String text) {
    return text
        .replaceAll('Ä', 'Ae')
        .replaceAll('Ö', 'Oe')
        .replaceAll('Ü', 'Ue')
        .replaceAll('ä', 'ae')
        .replaceAll('ö', 'oe')
        .replaceAll('ü', 'ue')
        .replaceAll('ß', 'ss');
  }

  Future<void> addProject(String projectName) async {
    final sanitizedProjectName = _replaceUmlauts(projectName);
    final response = await http.post(
      Uri.parse('${AppConfig.apiBaseUrl}/create_namespace'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {'namespace': sanitizedProjectName, 'dimension': '1536'},
    );

    if (response.statusCode != 200) {
      final responseData = json.decode(response.body);
      throw Exception('Failed to create namespace: ${responseData['message']}');
    }

    final newProjectRef = _db.child(sanitizedProjectName);
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
    final sanitizedOldName = _replaceUmlauts(oldName);
    final sanitizedNewName = _replaceUmlauts(newName);

    final oldProjectRef = _db.child(sanitizedOldName);
    final newProjectRef = _db.child(sanitizedNewName);

    final snapshot = await oldProjectRef.once();
    final data = snapshot.snapshot.value as Map<dynamic, dynamic>;

    await newProjectRef.set(data);
    await oldProjectRef.remove();
  }

  Future<String> getProjectInfo(String projectName) async {
    if (_projectInfoCache.containsKey(projectName)) {
      return _projectInfoCache[projectName]!;
    }
    final response = await http.get(
      Uri.parse('${AppConfig.apiBaseUrl}/get_project_info?project_name=$projectName'),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final info = data['info'] ?? '';
      final assessment = data['assessment'] ?? '';
      
      // Beide Werte im Cache speichern
      _projectInfoCache[projectName] = info;
      _projectAssessmentCache[projectName] = assessment;
      
      return info;
    } else {
      throw Exception('Fehler beim Abrufen der Projektinfo');
    }
  }

  Future<String> getProjectAssessmentData(String projectName) async {
    if (_projectAssessmentCache.containsKey(projectName)) {
      return _projectAssessmentCache[projectName]!;
    }
    
    // Falls noch nicht im Cache, hole beide Werte
    await getProjectInfo(projectName);
    return _projectAssessmentCache[projectName] ?? '';
  }

  Future<void> setProjectInfo(String projectName, String info) async {
    final response = await http.post(
      Uri.parse('${AppConfig.apiBaseUrl}/set_project_info'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {'project_name': projectName, 'info': info},
    );
    if (response.statusCode == 200) {
      _projectInfoCache[projectName] = info;
      // Assessment-Cache invalidieren, da sich die Projektinfo geändert hat
      _projectAssessmentCache.remove(projectName);
    } else {
      throw Exception('Fehler beim Speichern der Projektinfo');
    }
  }

  // Methode zum Initialisieren des Caches für alle Projekte
  Future<void> preloadAllProjectInfos(List<String> projectNames) async {
    for (final name in projectNames) {
      try {
        await getProjectInfo(name); // Lädt automatisch auch das Assessment
      } catch (_) {}
    }
  }
}
