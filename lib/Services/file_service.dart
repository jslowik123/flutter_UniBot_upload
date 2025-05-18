import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:intl/intl.dart';
import 'dart:convert';
import '../Config/app_config.dart';
import '../models/processing_status.dart';

class FileService {
  final DatabaseReference _db = FirebaseDatabase.instance.ref().child(
    AppConfig.firebaseFilesPath,
  );

  Future<List<List<Map<String, dynamic>>>> fetchFiles(
    String projectName,
  ) async {
    try {
      final snapshot = await _db.child(projectName).get();
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        final List<Map<String, dynamic>> loadedFiles = [];
        final List<Map<String, dynamic>> processingFiles = [];
        data.forEach((key, value) {
          if (value is Map) {
            final fileData = <String, dynamic>{
              'name': value['name'] as String? ?? '',
              'path': '$projectName/$key',
              'date': value['date'] as String? ?? '',
            };

            if (value.containsKey('keywords')) {
              fileData['keywords'] = value['keywords'];
            }

            if (value.containsKey('summary')) {
              fileData['summary'] = value['summary'] as String? ?? '';
            }
            if (value['processing'] == true) {
              fileData['processing'] = value['processing'];
              fileData['progress'] = value['progress'] ?? 0;
              fileData['status'] = value['status'] ?? 'Warte auf Verarbeitung';
              processingFiles.add(fileData);
            } else {
              fileData['processing'] = false;
              loadedFiles.add(fileData);
            }
          }
        });
        return [loadedFiles, processingFiles];
      }
      return [];
    } catch (e) {
      throw Exception('Fehler beim Abrufen der Dateien: $e');
    }
  }

  Future<String> uploadToFirebase(
    String projectName,
    String fileName,
    String filePath,
  ) async {
    try {
      Map<String, dynamic> data = {
        'name': fileName,
        'path': filePath,
        'date': DateFormat('dd.MM.yyyy').format(DateTime.now()),
        'processing': true,
        'progress': 0,
        'status': 'Warte auf Verarbeitung',
      };
      final newRef = _db.child(projectName).push();
      await newRef.set(data);
      return newRef.key ?? '';
    } catch (e) {
      throw Exception('Fehler beim Firebase-Upload: $e');
    }
  }

  Future<Map<String, dynamic>> startTask(
    String filePath,
    Uint8List fileBytes,
    String fileName,
    String projectName,
    String fileID,
    List<String> taskIDs,
  ) async {
    try {
      final uri = Uri.parse('${AppConfig.apiBaseUrl}/upload');
      final request = http.MultipartRequest('POST', uri);

      request.fields['namespace'] = projectName;
      request.fields['fileID'] = fileID;

      if (kIsWeb) {
        request.files.add(
          http.MultipartFile.fromBytes('file', fileBytes, filename: fileName),
        );
      } else {
        request.files.add(
          await http.MultipartFile.fromPath(
            'file',
            filePath,
            filename: fileName,
          ),
        );
      }

      final response = await request.send();
      final responseBody = await http.Response.fromStream(response);
      final jsonResponse = json.decode(responseBody.body);

      if (response.statusCode != 200 || jsonResponse['status'] != 'success') {
        throw Exception(
          'Upload fehlgeschlagen: ${jsonResponse['message'] ?? response.statusCode}',
        );
      }

      await updateFileProcessingStatus(
        projectName,
        fileID,
        true,
        'Verarbeitung gestartet',
        0,
      );

      return jsonResponse;
    } catch (e) {
      print('Fehler bei uploadToPinecone: $e');
      throw Exception('Fehler beim Upload: $e');
    }
  }

  Future<void> deleteFile(
    String fileName,
    String projectName,
    String fileID,
    bool justFirebase,
  ) async {
    try {
      final uri = Uri.parse('${AppConfig.apiBaseUrl}/delete');
      final request =
          http.MultipartRequest('POST', uri)
            ..fields['file_name'] = fileName
            ..fields['namespace'] = projectName
            ..fields['fileID'] = fileID
            ..fields['just_firebase'] = justFirebase.toString();

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final jsonResponse = json.decode(responseData);

      if (response.statusCode != 200 || jsonResponse['status'] != 'success') {
        throw Exception(
          'Löschen fehlgeschlagen: ${jsonResponse['message'] ?? response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Fehler beim Löschen der Dei: $e');
    }
  }

  Future<void> deleteAllVectors(String projectName) async {
    try {
      final uri = Uri.parse('${AppConfig.apiBaseUrl}/delete_all');
      final request = http.MultipartRequest('POST', uri)
        ..fields['namespace'] = projectName;

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final jsonResponse = json.decode(responseData);

      if (response.statusCode != 200 || jsonResponse['status'] != 'success') {
        throw Exception(
          'Löschen aller Vektoren fehlgeschlagen: ${jsonResponse['message'] ?? response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Fehler beim Löschen aller Vektoren: $e');
    }
  }

  Future<String> sendMessageToBot(String message, String projectName) async {
    try {
      final uri = Uri.parse('${AppConfig.apiBaseUrl}/send_message');
      final request =
          http.MultipartRequest('POST', uri)
            ..fields['user_input'] = message
            ..fields['namespace'] = projectName;

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final jsonResponse = json.decode(responseData);

      if (response.statusCode != 200 || jsonResponse['status'] != 'success') {
        throw Exception(
          'Bot-Antwort fehlgeschlagen: ${jsonResponse['message']}',
        );
      }

      return jsonResponse['response'];
    } catch (e) {
      throw Exception('Fehler bei der Bot-Kommunikation: $e');
    }
  }

  Future<void> startBot() async {
    try {
      final uri = Uri.parse('${AppConfig.apiBaseUrl}/start_bot');
      final response = await http.post(uri);

      final jsonResponse = json.decode(response.body);

      if (response.statusCode != 200 || jsonResponse['status'] != 'success') {
        throw Exception('Bot-Start fehlgeschlagen: ${jsonResponse['message']}');
      }
    } catch (e) {
      throw Exception('Fehler beim Starten des Bots: $e');
    }
  }

  Future<void> updateFileProcessingStatus(
    String projectName,
    String fileID,
    bool isProcessing,
    String status,
    int progress,
  ) async {
    try {
      final updates = <String, dynamic>{
        'processing': isProcessing,
        'progress': progress,
        'status': status,
      };
      await _db.child('$projectName/$fileID').update(updates);
    } catch (e) {
      print('Fehler beim Update des Processing-Status: $e');
    }
  }
}
