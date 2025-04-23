import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:intl/intl.dart';

class FileService {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();
  final String baseUrl = 'http://127.0.0.1:8000/';

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
      final uri = Uri.parse('${baseUrl}upload');
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

      if (response.statusCode != 200) {
        throw Exception(
          'Upload fehlgeschlagen: ${response.statusCode} - $responseData',
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
      final uri = Uri.parse('$baseUrl/delete');
      final request =
          http.MultipartRequest('POST', uri)
            ..fields['file_name'] = fileName
            ..fields['namespace'] = projectName;

      final response = await request.send();
      if (response.statusCode != 200) {
        throw Exception(
          'Löschen aus Pinecone fehlgeschlagen: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Fehler beim Löschen aus Pinecone: $e');
    }
  }
}
