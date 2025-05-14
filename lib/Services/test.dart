import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import "package:flutter_uni_bot/Services/file_service.dart";
import "package:flutter_uni_bot/config/app_config.dart";

class DocumentUploadScreen extends StatefulWidget {
  const DocumentUploadScreen({super.key});

  @override
  DocumentUploadScreenState createState() => DocumentUploadScreenState();
}

class DocumentUploadScreenState extends State<DocumentUploadScreen> {
  final FileService _fileService = FileService();
  final TextEditingController _taskIdController = TextEditingController();
  String? _taskId;
  String _status = '';
  final bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    // SSL-Verifizierung deaktivieren (nur für Testzwecke!)
    HttpOverrides.global = MyHttpOverrides();
  }

  @override
  void dispose() {
    _taskIdController.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _checkTaskStatus() async {
    final taskId = _taskIdController.text.trim();
    if (taskId.isEmpty) {
      setState(() {
        _status = 'Bitte Task-ID eingeben';
      });
      return {'state': 'ERROR', 'status': 'Keine Task-ID angegeben'};
    }
    print('Checking task status for ID: $taskId');
    setState(() => _isLoading = true);
    try {
      // Entferne Leerzeichen aus der Task-ID und erstelle die URL
      final cleanTaskId = taskId.replaceAll(' ', '');
      final response = await http.get(
        Uri.parse('${AppConfig.apiBaseUrl}/task_status/$cleanTaskId'),
      );
      print('Response Status Code: ${response.statusCode}');
      print('Response Headers: ${response.headers}');
      final result = json.decode(response.body);
      print('Task Status Response: $result');

      String statusMessage = '';
      if (result['state'] == 'PENDING') {
        statusMessage = 'Warte auf Ausführung (${result['progress']}%)';
      } else if (result['state'] == 'PROCESSING') {
        statusMessage = '${result['status']} (${result['progress']}%)';
      } else if (result['state'] == 'FAILURE') {
        statusMessage = 'Fehler: ${result['error']}';
      } else {
        statusMessage = '${result['status']} (${result['progress']}%)';
      }

      setState(() {
        _status = 'Status: ${result['state']}\n$statusMessage';
      });
      return result;
    } catch (e) {
      print('Status-Abfrage URL: ${AppConfig.apiBaseUrl}/task_status/$taskId');
      print('Fehler Details: $e');
      setState(() {
        _status = 'Fehler bei Status-Abfrage: $e';
      });
      return {'state': 'ERROR', 'status': e.toString()};
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String? _filePath;
  String? _fileName;
  bool _filePicked = false;
  bool _isLoading = false;
  late Uint8List _fileBytes;
  final String _projectName = 'neuertest';
  String? _fileID;

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
      );

      if (result != null) {
        _filePath = result.files.single.path;
        _fileName = result.files.single.name;
        final bytes = result.files.single.bytes;
        if (bytes != null) {
          _fileBytes = bytes;
        } else {
          _fileBytes = await File(_filePath!).readAsBytes();
        }
        setState(() => _filePicked = true);
      }
    } catch (e) {
      print('Fehler beim Datei-Import: $e');
    }
  }

  Future<void> _confirmSelection() async {
    if (_filePath == null || _fileName == null) {
      setState(() {
        _status = 'Bitte wählen Sie zuerst eine Datei aus';
      });
      return;
    }

    setState(() => _isLoading = true);
    try {
      _fileID = await _fileService.uploadToFirebase(
        _projectName,
        _fileName!,
        _filePath!,
      );
      print('File ID: $_fileID');

      try {
        final response = await _fileService.uploadToPinecone(
          _filePath!,
          _fileBytes,
          _fileName!,
          _projectName,
          _fileID!,
          [],
        );

        if (response['status'] == 'success' && response['task_id'] != null) {
          setState(() {
            _taskId = response['task_id'];
            _taskIdController.text = _taskId!;
            _status = 'Upload erfolgreich. Task ID: $_taskId';
          });
          _startStatusPolling();
        } else {
          setState(() {
            _status =
                'Upload fehlgeschlagen: ${response['message'] ?? 'Unbekannter Fehler'}';
          });
        }
      } catch (uploadError) {
        print('Upload Fehler: $uploadError');
        if (_fileID != null) {
          try {
            await _fileService.deleteFile(
              _fileName!,
              _projectName,
              _fileID!,
              true,
            );
          } catch (deleteError) {
            print('Fehler beim Löschen: $deleteError');
          }
        }
        setState(() {
          _status = 'Upload fehlgeschlagen: $uploadError';
        });
      }
    } catch (e) {
      print('Fehler beim Upload: $e');
      setState(() {
        _status = 'Fehler: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
        _filePicked = false;
        _fileName = null;
        _filePath = null;
        _fileID = null;
      });
    }
  }

  void _startStatusPolling() {
    if (_taskId == null) return;

    Future.delayed(Duration(seconds: 2), () async {
      if (!mounted) return;

      var statusResult = await _checkTaskStatus();

      if (statusResult['status'] == 'SUCCESS') {
        setState(() {
          _status = 'Verarbeitung abgeschlossen (100%)';
          _isLoading = false;
        });
      } else if (statusResult['status'] == 'FAILURE') {
        setState(() {
          _status = 'Fehler: ${statusResult['error']}';
          _isLoading = false;
        });
      } else if (statusResult['status'] != 'ERROR') {
        _startStatusPolling();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Document Upload')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isLoading) CircularProgressIndicator(),
            SizedBox(height: 20),
            Text(_status, textAlign: TextAlign.center),
            SizedBox(height: 20),
            TextField(
              controller: _taskIdController,
              decoration: InputDecoration(
                labelText: 'Task ID',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _isLoading ? null : _pickFile,
                  child: Text('PDF auswählen'),
                ),
                ElevatedButton(
                  onPressed: _isLoading ? null : _confirmSelection,
                  child: Text('Upload bestätigen'),
                ),
                ElevatedButton(
                  onPressed: _isLoading ? null : _checkTaskStatus,
                  child: Text('Status prüfen'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}
