import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:intl/intl.dart';
import 'dart:convert';
import '../Config/app_config.dart';

class FileService {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  Future<List<Map<String, dynamic>>> fetchFiles(String projectName) async {
    final databasePath = 'files/$projectName';
    try {
      final snapshot = await _db.child(databasePath).get();
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        final List<Map<String, dynamic>> loadedFiles = [];
        data.forEach((key, value) {
          if (value is Map) {
            final fileData = <String, dynamic>{
              'name': value['name'] as String? ?? '',
              'path': '$databasePath/$key',
              'date': value['date'] as String? ?? '',
            };

            if (value.containsKey('keywords')) {
              fileData['keywords'] = value['keywords'];
            }

            if (value.containsKey('summary')) {
              fileData['summary'] = value['summary'] as String? ?? '';
            }

            loadedFiles.add(fileData);
          }
        });
        return loadedFiles;
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
    final databasePath = 'files/$projectName';
    try {
      Map<String, dynamic> data = {
        'name': fileName,
        'path': filePath,
        'date': DateFormat('dd.MM.yyyy').format(DateTime.now()),
      };
      final newRef = _db.child(databasePath).push();
      await newRef.set(data);
      return newRef.key ?? '';
    } catch (e) {
      throw Exception('Fehler beim Firebase-Upload: $e');
    }
  }

  Future<String> uploadToPinecone(
    String filePath,
    Uint8List fileBytes,
    String fileName,
    String projectName,
    String fileID,
  ) async {
    try {
      final uri = Uri.parse('${AppConfig.apiBaseUrl}/upload');
      final request = http.MultipartRequest('POST', uri);

      // Sicherstellen, dass alle erforderlichen Parameter im korrekten Format übergeben werden
      request.fields['namespace'] = projectName;
      request.fields['fileID'] = fileID;

      // Debug-Info
      print('Uploading to Pinecone with fileID: $fileID');
      print('File name: $fileName');
      print('Namespace: $projectName');

      if (kIsWeb) {
        request.files.add(
          http.MultipartFile.fromBytes('file', fileBytes, filename: fileName),
        );
      } else {
        // Handle mobile upload
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

      // Debug-Info für Response
      print('Response status: ${response.statusCode}');
      print('Response body: ${responseBody.body}');

      final jsonResponse = json.decode(responseBody.body);

      if (response.statusCode != 200 || jsonResponse['status'] != 'success') {
        throw Exception(
          'Upload fehlgeschlagen: ${jsonResponse['message'] ?? response.statusCode}',
        );
      }
      return jsonResponse['message'] ?? 'Upload erfolgreich';
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
}
