import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '/Widgets/file_tile.dart';
import '/Widgets/new_file.dart';

class FileScreen extends StatefulWidget {
  const FileScreen({super.key});

  @override
  State<FileScreen> createState() => _FileScreenState();
}

class _FileScreenState extends State<FileScreen> {
  String? _filePath;
  String? _fileName;
  bool _filePicked = false;
  List<Map<String, String>> _importedFiles = [];
  bool _isInitialized = false;
  bool _isLoading = false;
  final DatabaseReference _db = FirebaseDatabase.instance.ref();
  Map<String, dynamic>? _routeArgs;
  late File _file;
  final String baseUrl = 'http://127.0.0.1:8000/';
  String? _projectName;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _routeArgs =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      _projectName = _routeArgs?['name'];
      print('Project name set to: $_projectName');
      _fetchFilesFromDatabase();
      _isInitialized = true;
    }
  }

  String getFormattedDate() {
    final DateTime now = DateTime.now();
    final DateFormat formatter = DateFormat('dd.MM.yyyy');
    return formatter.format(now);
  }

  Future<void> _fetchFilesFromDatabase() async {
    final projectName = _routeArgs?['name'] ?? 'unbekannt';
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
        setState(() {
          _importedFiles = loadedFiles;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fehler beim Abrufen der Dateien: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
      );
      if (result != null) {
        if (kIsWeb) {
          // Für Web: Speichern der Bytes statt File-Objekt
          _file = File(result.files.single.path!);
          setState(() {
            _filePath = result.files.single.path;
            _fileName = result.files.single.name;
            _filePicked = true;
          });
        } else {
          // Für Desktop/Mobile
          _file = File(result.files.single.path!);
          setState(() {
            _filePath = result.files.single.path;
            _fileName = result.files.single.name;
            _filePicked = true;
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Fehler beim Datei-Import: $e')));
    }
  }

  Future<String?> _uploadFileToFirebase(
    String fileName,
    String filePath,
  ) async {
    final projectName = _routeArgs?['name'] ?? 'unbekannt';
    final databasePath = 'files/$projectName';

    try {
      Map<String, dynamic> data = {
        'name': fileName,
        'path': filePath,
        'date': getFormattedDate(),
      };

      DatabaseReference newFileRef = _db.child(databasePath).push();
      await newFileRef.set(data);

      setState(() {
        _importedFiles.add({
          'name': fileName,
          'path': '$databasePath/${newFileRef.key}',
          'date': data['date'],
        });
        _filePicked = false;
        _fileName = null;
        _filePath = null;
      });

      return null;
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Fehler beim Upload: $e')));
      return e.toString();
    }
  }

  Future<String?> _uploadFileToPinecone(File file) async {
    try {
      if (_projectName == null) {
        print('Fehler: Projektname ist nicht gesetzt');
        return 'Project name is not set';
      }

      print('Starte Upload...');
      print('Verwende Datei: ${file.path}');
      print('Verwende Namespace: $_projectName');

      final uri = Uri.parse('${baseUrl}upload');
      final request = http.MultipartRequest('POST', uri);

      if (kIsWeb) {
        // Für Web: Verwende die Bytes direkt
        request
          ..files.add(
            http.MultipartFile.fromBytes(
              'file',
              await file.readAsBytes(),
              filename: file.path.split('/').last,
            ),
          )
          ..fields['namespace'] = 'test456';
      } else {
        // Für Desktop/Mobile
        request.files.add(
          await http.MultipartFile.fromPath(
            'file',
            file.path,
            filename: file.path.split('/').last,
          ),
        );
        request.fields['namespace'] = _projectName!;
      }

      print('Sende Request...');
      final response = await request.send();
      final responseData = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        print('Upload erfolgreich!');
        print('Response: $responseData');
        return null;
      } else {
        print('Upload fehlgeschlagen: ${response.statusCode}');
        print('Response: $responseData');
        throw Exception(
          'Upload fehlgeschlagen: ${response.statusCode} - $responseData',
        );
      }
    } catch (e) {
      print('Fehler beim Upload: $e');
      return e.toString();
    }
  }

  Future<String?> _deleteFileFromDatabase(String path) async {
    try {
      await _db.child(path).remove();
      setState(() {
        _importedFiles.removeWhere((file) => file['path'] == path);
      });
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> _deleteFileFromPinecone(String fileName) async {
    try {
      if (_projectName == null) {
        return 'Project name is not set';
      }

      var uri = Uri.parse('$baseUrl/delete');
      var request = http.MultipartRequest('POST', uri);
      request.fields['file_name'] = fileName;
      request.fields['namespace'] = _projectName!;

      var response = await request.send();
      if (response.statusCode == 200) {
        return null;
      } else {
        return response.reasonPhrase;
      }
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> _deleteFile(String path, String fileName) async {
    setState(() => _isLoading = true);
    try {
      final databaseError = await _deleteFileFromDatabase(path);
      final pineconeError = await _deleteFileFromPinecone(fileName);
      if (databaseError != null) {
        throw Exception('Database deletion failed: $databaseError');
      }
      if (pineconeError != null) {
        throw Exception('Pinecone deletion failed: $pineconeError');
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Datei erfolgreich gelöscht.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fehler beim Upload: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _confirmSelection() async {
    if (_filePath != null && _fileName != null) {
      setState(() => _isLoading = true);
      try {
        final pineconeError = await _uploadFileToPinecone(_file);
        if (pineconeError != null) {
          _importedFiles.add({
            'name': "Upload von ${_fileName!} fehlgeschlagen",
            'path': _filePath!,
            'date': getFormattedDate(),
          });
          setState(() {
            _filePicked = false;
            _fileName = null;
            _filePath = null;
          });
          throw Exception('Pinecone upload failed: $pineconeError');
        }
        {
          final firebaseError = await _uploadFileToFirebase(
            _fileName!,
            _filePath!,
          );
          if (firebaseError != null) {
            throw Exception('Firebase upload failed: $firebaseError');
          }
        }

        // Only show success snackbar if both uploads were successful
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Datei erfolgreich hochgeladen und verarbeitet'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Upload: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Fehler: Bitte wählen Sie zuerst eine Datei aus'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _changeToChat(BuildContext context) {
    Navigator.of(context).pushNamed('/LLMChat');
  }

  @override
  Widget build(BuildContext context) {
    final projectName = _routeArgs?['name'] ?? "unbekannt";

    return Scaffold(
      appBar: AppBar(
        title: Text(projectName),
        actions: [
          IconButton(
            onPressed: () => _changeToChat(context),
            icon: const Icon(Icons.chat),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Stack(
            children: [
              _importedFiles.isEmpty
                  ? const Center(child: Text('Keine Dateien vorhanden.'))
                  : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 120.0),
                    itemCount: _importedFiles.length,
                    itemBuilder: (context, index) {
                      final file = _importedFiles[index];
                      return FileTile(
                        file: file,
                        deleteFileFunc:
                            () => _deleteFile(file['path']!, file['name']!),
                      );
                    },
                  ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: NewFile(
                  fileName: _fileName,
                  pickFileFunc: _pickFile,
                  confirmSelectionFunc: _confirmSelection,
                  filePicked: _filePicked,
                ),
              ),
              if (_isLoading) const Center(child: CircularProgressIndicator()),
            ],
          ),
        ),
      ),
    );
  }
}
