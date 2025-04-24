import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:intl/intl.dart';
import 'dart:convert';
import '../Config/app_config.dart';

class FileService {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  Future<List<Map<String, String>>> fetchFiles(String projectName) async {
    final databasePath = 'files/$projectName';
    try {
      final snapshot = await _db.child(databasePath).get();
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        final List<Map<String, String>> loadedFiles = [];
        data.forEach((key, value) {
          if (value is Map &&
              value.containsKey('name') &&
              value.containsKey('date')) {
            loadedFiles.add({
              'name': value['name'] as String,
              'path': '$databasePath/$key',
              'date': value['date'] as String,
            });
          }
        });
        return loadedFiles;
      }
      return [];
    } catch (e) {
      throw Exception('Fehler beim Abrufen der Dateien: $e');
    }
  }

  Future<void> uploadToFirebase(
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
      await _db.child(databasePath).push().set(data);
    } catch (e) {
      throw Exception('Fehler beim Firebase-Upload: $e');
    }
  }

  Future<void> uploadToPinecone(File file, String projectName) async {
    try {
      final uri = Uri.parse('${AppConfig.apiBaseUrl}/upload');
      final request = http.MultipartRequest('POST', uri);

      if (kIsWeb) {
        request
          ..files.add(
            http.MultipartFile.fromBytes(
              'file',
              await file.readAsBytes(),
              filename: file.path.split('/').last,
            ),
          )
          ..fields['namespace'] = projectName;
      } else {
        request
          ..files.add(
            await http.MultipartFile.fromPath(
              'file',
              file.path,
              filename: file.path.split('/').last,
            ),
          )
          ..fields['namespace'] = projectName;
      }

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final jsonResponse = json.decode(responseData);

      if (response.statusCode != 200 || jsonResponse['status'] != 'success') {
        throw Exception(
          'Upload fehlgeschlagen: ${jsonResponse['message'] ?? response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Fehler beim Pinecone-Upload: $e');
    }
  }

  Future<void> deleteFromFirebase(String path) async {
    try {
      await _db.child(path).remove();
    } catch (e) {
      throw Exception('Fehler beim Löschen aus Firebase: $e');
    }
  }

  Future<void> deleteFromPinecone(String fileName, String projectName) async {
    try {
      final uri = Uri.parse('${AppConfig.apiBaseUrl}/delete');
      final request =
          http.MultipartRequest('POST', uri)
            ..fields['file_name'] = fileName
            ..fields['namespace'] = projectName;

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final jsonResponse = json.decode(responseData);

      if (response.statusCode != 200 || jsonResponse['status'] != 'success') {
        throw Exception(
          'Löschen fehlgeschlagen: ${jsonResponse['message'] ?? response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Fehler beim Löschen aus Pinecone: $e');
    }
  }


  Future<String> sendMessageToBot(String message) async {
    try {
      final uri = Uri.parse('${AppConfig.apiBaseUrl}/send_message');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'user_input': message}),
      );

      final jsonResponse = json.decode(response.body);

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
