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
  final Map<String, String> _projectKnowledgeCache = {};
  final Map<String, Map<String, String>> _exampleQuestionsCache = {};

  String getFormattedDate() {
    final DateTime now = DateTime.now();
    final DateFormat formatter = DateFormat('dd.MM.yyyy');
    return formatter.format(now);
  }

  Future<void> sendProjectAssessment(String projectName, String additionalInfo) async {
    try {
      final uri = Uri.parse('${AppConfig.apiBaseUrl}/trigger_assessment');
      final request = http.MultipartRequest('POST', uri)
        ..fields['namespace'] = projectName;

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final jsonResponse = json.decode(responseData);
      
      if (response.statusCode != 200 || jsonResponse['status'] != 'success') {
        throw Exception('Assessment-Trigger fehlgeschlagen: ${jsonResponse['message'] ?? response.statusCode}');
      }
    } catch (e) {
      throw Exception('Fehler beim Triggern der Projektbeurteilung: $e');
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
    
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.apiBaseUrl}/get_project_info?project_name=$projectName'),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('DEBUG: ProjectInfo API response: $data');
        
        // Handle different response formats
        if (data['status'] == 'success') {
          final info = data['data'] ?? '';
          _projectInfoCache[projectName] = info;
          return info;
        } else if (data['status'] == 'not_found') {
          // Keine Projektinfo vorhanden
          _projectInfoCache[projectName] = '';
          return '';
        } else {
          throw Exception('API Fehler: ${data['message'] ?? 'Unbekannter Fehler'}');
        }
      } else {
        throw Exception('HTTP Fehler: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Fehler beim Abrufen der Projektinfo: $e');
    }
  }

  Future<String> getProjectKnowledge(String projectName) async {
    if (_projectKnowledgeCache.containsKey(projectName)) {
      return _projectKnowledgeCache[projectName]!;
    }
    
    try {
      final assessmentRef = FirebaseDatabase.instance.ref().child('files').child(projectName).child('assessment');
      final snapshot = await assessmentRef.once();
      
      if (snapshot.snapshot.exists) {
        final data = snapshot.snapshot.value as Map<dynamic, dynamic>?;
        final knowledge = data?['wissensstand']?.toString() ?? '';
        print('DEBUG: ProjectKnowledge loaded from Firebase: "${knowledge.length} chars"');
        _projectKnowledgeCache[projectName] = knowledge;
        return knowledge;
      } else {
        print('DEBUG: No assessment data found in Firebase for $projectName');
        _projectKnowledgeCache[projectName] = '';
        return '';
      }
    } catch (e) {
      print('DEBUG: Error loading knowledge from Firebase: $e');
      _projectKnowledgeCache[projectName] = '';
      return '';
    }
  }

  Future<String> getProjectAssessmentData(String projectName) async {
    if (_projectAssessmentCache.containsKey(projectName)) {
      return _projectAssessmentCache[projectName]!;
    }
    
    try {
      final assessmentRef = FirebaseDatabase.instance.ref().child('files').child(projectName).child('assessment');
      final snapshot = await assessmentRef.once();
      
      if (snapshot.snapshot.exists) {
        final raw = snapshot.snapshot.value;
        Map<dynamic, dynamic>? data;
        if (raw is String) {
          // String (JSON-Text) -> Map
          data = json.decode(raw);
        } else if (raw is Map) {
          data = raw;
        } else {
          data = null;
        }
        
        if (data != null) {
          // Gebe den JSON-String der Assessment-Daten zurück (inkl. aller Felder)
          final jsonString = json.encode(data);
          print('DEBUG: ProjectAssessment loaded from Firebase (JSON): "${jsonString.length} chars"');
          _projectAssessmentCache[projectName] = jsonString;
          return jsonString;
        }
      }
      
      print('DEBUG: No assessment data found in Firebase for $projectName');
      _projectAssessmentCache[projectName] = '';
      return '';
    } catch (e) {
      print('DEBUG: Error loading assessment from Firebase: $e');
      _projectAssessmentCache[projectName] = '';
      return '';
    }
  }

  Future<void> setProjectInfo(String projectName, String info) async {
    try {
      final uri = Uri.parse('${AppConfig.apiBaseUrl}/set_project_info');
      final request = http.MultipartRequest('POST', uri)
        ..fields['project_name'] = projectName
        ..fields['info'] = info;

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final jsonResponse = json.decode(responseData);
      
      if (response.statusCode == 200 && jsonResponse['status'] == 'success') {
        _projectInfoCache[projectName] = info;
        // Assessment-Cache invalidieren, da sich die Projektinfo geändert hat
        _projectAssessmentCache.remove(projectName);
        _projectKnowledgeCache.remove(projectName);
      } else {
        throw Exception('API Fehler: ${jsonResponse['message'] ?? 'Unbekannter Fehler'}');
      }
    } catch (e) {
      throw Exception('Fehler beim Speichern der Projektinfo: $e');
    }
  }

  Future<Map<String, String>> getExampleQuestions(String projectName) async {
    if (_exampleQuestionsCache.containsKey(projectName)) {
      return _exampleQuestionsCache[projectName]!;
    }
    
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.apiBaseUrl}/get_example_questions/$projectName'),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('DEBUG: ExampleQuestions API response: $data');
        
        // Handle different status responses
        if (data['status'] == 'success') {
          final questions = <String, String>{};
          final questionData = data['data'] as List<dynamic>?;
          
          if (questionData != null) {
            // Konvertiere die Daten in das erwartete Format
            for (int i = 0; i < questionData.length && i < 3; i++) {
              final qa = questionData[i] as Map<String, dynamic>;
              final question = qa['question']?.toString() ?? '';
              final answer = qa['answer']?.toString() ?? '';
              
              if (question.isNotEmpty && answer.isNotEmpty) {
                questions['question${i + 1}'] = question;
                questions['answer${i + 1}'] = answer;
              }
            }
          }
          
          _exampleQuestionsCache[projectName] = questions;
          return questions;
        } else if (data['status'] == 'generating') {
          // Fragen werden gerade generiert
          return {'status': 'generating', 'message': 'Fragen werden generiert'};
        } else if (data['status'] == 'not_found') {
          // Keine Fragen vorhanden
          return {};
        } else {
          // Fehler
          throw Exception('API Fehler: ${data['message'] ?? 'Unbekannter Fehler'}');
        }
      } else {
        throw Exception('HTTP Fehler: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Fehler beim Abrufen der Beispielfragen: $e');
    }
  }

  // Methode zum Leeren des Caches für ein bestimmtes Projekt
  void clearProjectCache(String projectName) {
    _projectInfoCache.remove(projectName);
    _projectAssessmentCache.remove(projectName);
    _projectKnowledgeCache.remove(projectName);
    _exampleQuestionsCache.remove(projectName);
  }

  // Methode zum Leeren nur des Beispielfragen-Caches
  void clearExampleQuestionsCache(String projectName) {
    _exampleQuestionsCache.remove(projectName);
  }

  // Methode zum Initialisieren des Caches für alle Projekte
  Future<void> preloadAllProjectInfos(List<String> projectNames) async {
    for (final name in projectNames) {
      try {
        await getProjectInfo(name); // Lädt automatisch auch Assessment und Wissenstand
      } catch (_) {}
    }
  }
}
