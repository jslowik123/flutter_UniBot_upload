import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:intl/intl.dart';
import 'dart:convert';
import 'dart:io';
import '../Config/app_config.dart';
import '../models/processing_status.dart';

class FileService {
  final DatabaseReference _db = FirebaseDatabase.instance.ref().child(
    AppConfig.firebaseFilesPath,
  );
  final FirebaseStorage _storage = FirebaseStorage.instance;

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
          // Skip project-level metadata keys like 'date' and 'summary'
          if (key == 'date' || key == 'summary') {
            return; // Skip this entry
          }

          if (value is Map) {
            final fileData = <String, dynamic>{
              'name': value['name'] as String? ?? '',
              'path': '$projectName/$key',
              'date': value['date'] as String? ?? '',
            };

            if (value.containsKey('keywords')) {
              fileData['keywords'] = value['keywords'];
            }

            // Storage-URL hinzufügen, falls vorhanden
            if (value.containsKey('storageURL')) {
              fileData['storageURL'] = value['storageURL'] as String?;
            }

            // Additional Info hinzufügen, falls vorhanden
            if (value.containsKey('additional_info')) {
              fileData['additional_info'] = value['additional_info'] as String?;
            }

            if (value.containsKey('summary')) {
              final summaryData = value['summary'];
              if (summaryData is Map) {
                // If summary is a Map, extract its string values
                fileData['summary'] =
                    summaryData.values.whereType<String>().toList();
              } else if (summaryData is String) {
                // If summary is a String, treat it as a single bullet point
                fileData['summary'] = [summaryData];
              } else if (summaryData is List) {
                // If summary is already a List, ensure it contains only strings
                fileData['summary'] = summaryData.whereType<String>().toList();
              } else {
                // Otherwise, or if null, initialize as an empty list
                fileData['summary'] = <String>[];
              }
            } else {
              fileData['summary'] = <String>[];
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
    String hasTablesOrGraphics,
  ) async {
    try {
      Map<String, dynamic> data = {
        'name': fileName,
        'path': filePath,
        'date': DateFormat('dd.MM.yyyy').format(DateTime.now()),
        'processing': true,
        'progress': 0,
        'status': 'Warte auf Verarbeitung',
        'hasTablesOrGraphics': hasTablesOrGraphics,
      };
      final newRef = _db.child(projectName).push();
      await newRef.set(data);
      return newRef.key ?? '';
    } catch (e) {
      throw Exception('Fehler beim Firebase-Upload: $e');
    }
  }

  /// Lädt eine Datei in Firebase Storage hoch
  Future<String> uploadFileToStorage(
    String projectName,
    String fileName,
    String filePath,
    bool hasTablesOrGraphics,
    Uint8List? fileBytes,
  ) async {
    try {
      // Erstelle den Storage-Pfad: /files/project/dateiname
      final storageRef = _storage.ref().child('files/$projectName/$fileName');
      
      UploadTask uploadTask;
      
      if (fileBytes != null) {
        // Verwende Bytes wenn verfügbar (funktioniert auf allen Plattformen)
        uploadTask = storageRef.putData(
          fileBytes,
          SettableMetadata(
            contentType: 'application/pdf',
            customMetadata: {
              'project': projectName,
              'uploadDate': DateTime.now().toIso8601String(), 
              'hasTablesOrGraphics': hasTablesOrGraphics.toString(),
            },
          ),
        );
      } else {
        // Fallback: Verwende Datei-Pfad für Mobile/Desktop
        final file = File(filePath);
        uploadTask = storageRef.putFile(
          file,
          SettableMetadata(
            contentType: 'application/pdf',
            customMetadata: {
              'project': projectName,
              'uploadDate': DateTime.now().toIso8601String(),
            },
          ),
        );
      }

      final snapshot = await uploadTask;
      final downloadURL = await snapshot.ref.getDownloadURL();
      
      debugPrint('Datei erfolgreich zu Firebase Storage hochgeladen: $downloadURL');
      return downloadURL;
    } catch (e) {
      debugPrint('Fehler beim Upload zu Firebase Storage: $e');
      throw Exception('Fehler beim Storage-Upload: $e');
    }
  }

  /// Löscht eine Datei aus Firebase Storage
  Future<void> deleteFileFromStorage(
    String projectName,
    String fileName,
  ) async {
    try {
      // Erstelle den Storage-Pfad: /files/project/dateiname
      final storageRef = _storage.ref().child('files/$projectName/$fileName');
      
      await storageRef.delete();
      debugPrint('Datei erfolgreich aus Firebase Storage gelöscht: $fileName');
    } catch (e) {
      debugPrint('Fehler beim Löschen aus Firebase Storage: $e');
      // Fehler nicht werfen, da die Datei möglicherweise bereits gelöscht wurde
      // oder nicht existiert
    }
  }

  Future<Map<String, dynamic>> startTask(
    String filePath,
    Uint8List fileBytes,
    String fileName,
    String projectName,
    String fileID,
    String additionalInfo,
    List<String> taskIDs,
    bool hasTablesOrGraphics,
    String? pageNumbers,
  ) async {
    try {
      // 1. Zuerst Datei zu Firebase Storage hochladen
      String? storageURL;
      try {
        storageURL = await uploadFileToStorage(
          projectName,
          fileName,
          filePath,
          hasTablesOrGraphics,
          kIsWeb ? fileBytes : null,
        );
        
        // Speichere die Storage-URL in der Datenbank
        await _db.child('$projectName/$fileID').update({
          'storageURL': storageURL,
        });
      } catch (storageError) {
        debugPrint('Warnung: Storage-Upload fehlgeschlagen: $storageError');
        // Setze trotzdem mit der API-Verarbeitung fort
      }
      if (additionalInfo.isEmpty) {
        additionalInfo = 'Keine zusätzlichen Informationen';
      }
      // 2. Dann normale API-Verarbeitung starten
      final uri = Uri.parse('${AppConfig.apiBaseUrl}/upload');
      final request = http.MultipartRequest('POST', uri);

      request.fields['namespace'] = projectName;
      request.fields['fileID'] = fileID;
      request.fields['additionalInfo'] = additionalInfo;
      request.fields['hasTablesOrGraphics'] = hasTablesOrGraphics.toString();
      if (pageNumbers != null && pageNumbers.isNotEmpty) {
        // Parse die Seitennummern und sende als kommagetrennte String-Liste
        debugPrint('Original pageNumbers: "$pageNumbers"');
        final pageList = pageNumbers
            .split(',')
            .map((page) => page.trim())
            .where((page) => page.isNotEmpty)
            .where((page) => int.tryParse(page) != null) // Validiere, dass es eine Zahl ist
            .toList(); // Behalte als String-Liste
        final cleanedPageNumbers = pageList.join(',');
        debugPrint('Cleaned pageNumbers: "$cleanedPageNumbers"');
        request.fields['numberPages'] = cleanedPageNumbers;
      } else {
        debugPrint('pageNumbers is null or empty: "$pageNumbers"');
      }

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
        // Wenn API-Upload fehlschlägt, lösche die Storage-Datei wieder
        if (storageURL != null) {
          await deleteFileFromStorage(projectName, fileName);
        }
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
      debugPrint('Fehler bei uploadToPinecone: $e');
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
      // 1. Zuerst aus Firebase Storage löschen
      await deleteFileFromStorage(projectName, fileName);

      // 2. Dann normale API-Löschung
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
      throw Exception('Fehler beim Löschen der Datei: $e');
    }
  }

  Future<void> deleteAllVectors(String projectName) async {
    try {
      // 1. Zuerst alle Dateien aus Firebase Storage löschen
      await deleteAllFilesFromStorage(projectName);

      // 2. Dann normale API-Löschung aller Vektoren
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

  /// Löscht alle Dateien eines Projekts aus Firebase Storage
  Future<void> deleteAllFilesFromStorage(String projectName) async {
    try {
      final projectRef = _storage.ref().child('files/$projectName');
      
      // Liste alle Dateien im Projekt-Ordner auf
      final listResult = await projectRef.listAll();
      
      // Lösche alle gefundenen Dateien
      for (final item in listResult.items) {
        try {
          await item.delete();
          debugPrint('Datei aus Storage gelöscht: ${item.name}');
        } catch (e) {
          debugPrint('Fehler beim Löschen von ${item.name}: $e');
          // Einzelne Fehler nicht weiterwerfen, damit andere Dateien trotzdem gelöscht werden
        }
      }
      
      debugPrint('Alle Dateien für Projekt $projectName aus Storage gelöscht');
    } catch (e) {
      debugPrint('Fehler beim Löschen aller Storage-Dateien: $e');
      // Fehler nicht weiterwerfen, da dies ein sekundärer Prozess ist
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
      debugPrint('Fehler beim Update des Processing-Status: $e');
    }
  }

  /// Verarbeitet den kompletten File Upload Workflow
  Future<ProcessingStatus> processFileUpload({
    required String filePath,
    required Uint8List fileBytes,
    required String fileName,
    required String projectName,
    required String additionalInfo,
    bool hasTablesOrGraphics = false,
    String? pageNumbers,
  }) async {
    String? fileID;
    
    try {
      // 1. Upload zu Firebase Database
      fileID = await uploadToFirebase(projectName, fileName, filePath, hasTablesOrGraphics.toString());
      
      // 2. Task starten (beinhaltet Storage Upload und API Call)
      final response = await startTask(
        filePath,
        fileBytes,
        fileName,
        projectName,
        fileID,
        additionalInfo,
        [],
        hasTablesOrGraphics,
        pageNumbers,
      );

      if (response['status'] != 'success') {
        throw Exception(response['message'] ?? 'Unbekannter Fehler');
      }

      // 3. Beschreibung und Seitennummern speichern falls vorhanden
      final updates = <String, dynamic>{};
      if (additionalInfo.isNotEmpty) {
        updates['additional_info'] = additionalInfo;
      }
      if (pageNumbers != null && pageNumbers.isNotEmpty) {
        final pageList = pageNumbers
            .split(',')
            .map((page) => page.trim())
            .where((page) => page.isNotEmpty)
            .where((page) => int.tryParse(page) != null)
            .toList();
        updates['pageNumbers'] = pageList;
      }
      if (updates.isNotEmpty) {
        await _db.child('$projectName/$fileID').update(updates);
      }

      // 4. ProcessingStatus Objekt zurückgeben
      return ProcessingStatus(
        status: 'Verarbeitung gestartet',
        progress: 0,
        fileName: fileName,
        fileID: '$projectName/$fileID',
        processing: true,
      );
      
    } catch (e) {
      // Cleanup bei Fehler
      if (fileID != null) {
        try {
          await deleteFile(fileName, projectName, fileID, true);
        } catch (deleteError) {
          debugPrint('Fehler beim Cleanup: $deleteError');
        }
      }
      throw Exception('Fehler beim File Upload: $e');
    }
  }
}
