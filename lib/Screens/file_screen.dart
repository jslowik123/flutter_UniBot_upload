import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import '../Widgets/file_tile.dart';
import '../Widgets/new_file.dart';

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
  String? _uploadStatus;
  final DatabaseReference _db = FirebaseDatabase.instance.ref();
  Map<String, dynamic>? _routeArgs; // ✅ Argumente zwischenspeichern

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _routeArgs = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      _fetchFilesFromDatabase();
      _isInitialized = true;
    }
  }

  Future<void> _fetchFilesFromDatabase() async {
    final projectName = _routeArgs?['name'] ?? 'unbekannt';
    final databasePath = 'files/$projectName';

    try {
      final snapshot = await _db.child(databasePath).get();
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        setState(() {
          _importedFiles = data.entries
              .map((entry) => {
            'name': entry.value['name'] as String,
            'path': '$databasePath/${entry.key}'
          })
              .toList();
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
        setState(() {
          _filePath = result.files.single.path;
          _fileName = result.files.single.name;
          _filePicked = true;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler beim Datei-Import: $e')),
      );
    }
  }

  Future<String?> _saveFileNameToDatabase(String fileName) async {
    final projectName = _routeArgs?['name'] ?? 'unbekannt';
    final databasePath = 'files/$projectName';

    try {
      final newFileRef = _db.child(databasePath).push();
      await newFileRef.set({'name': fileName});
      return newFileRef.key;
    } catch (e) {
      throw Exception('Fehler beim Speichern des Dateinamens: $e');
    }
  }

  Future<void> _uploadFileToApi() async {
    if (_filePath == null || _fileName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Fehler: Keine Datei zum Hochladen ausgewählt'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        _uploadStatus = null;
      });

      final file = File(_filePath!);
      final fileBytes = await file.readAsBytes();

      var uri = null;//Uri.parse('https://flutter-test-f9ed4-default-rtdb.europe-west1.firebasedatabase.app/');

      var request = http.MultipartRequest('POST', uri)
        ..files.add(
          http.MultipartFile.fromBytes(
            'file',
            fileBytes,
            filename: _fileName,
          ),
        );

      var response = await request.send();
      var responseString = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        await _saveFileNameToDatabase(_fileName!);

        setState(() {
          _uploadStatus = 'Upload erfolgreich: $responseString';
          _filePicked = false;
          _importedFiles.add({'name': _fileName!, 'path': _filePath!});
          _filePath = null;
          _fileName = null;
        });
      } else {
        setState(() {
          _uploadStatus = 'Upload fehlgeschlagen: ${response.statusCode}';
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_uploadStatus!),
          backgroundColor: response.statusCode == 200 ? Colors.green : Colors.red,
        ),
      );
    } catch (e) {
      setState(() {
        _uploadStatus = 'Fehler beim Upload: $e';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_uploadStatus!),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteFileFromDatabase(String path) async {
    try {
      await _db.child(path).remove();
      setState(() {
        _importedFiles.removeWhere((file) => file['path'] == path);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Datei erfolgreich aus Database gelöscht'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fehler beim Löschen aus Database: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteFile(String path, String fileName) async {
    await _deleteFileFromDatabase(path);
    // await _deleteFileFromApi(fileName); // optional
  }

  void _confirmSelection() {
    if (_filePath != null && _fileName != null) {
      _uploadFileToApi();
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
              ListView.builder(
                padding: const EdgeInsets.only(bottom: 120.0),
                itemCount: _importedFiles.length,
                itemBuilder: (context, index) {
                  final file = _importedFiles[index];
                  return FileTile(
                    file,
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
              if (_isLoading)
                const Center(
                  child: CircularProgressIndicator(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
