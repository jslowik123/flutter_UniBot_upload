import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
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

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _fetchFilesFromStorage();
      _isInitialized = true;
    }
  }

  Future<void> _fetchFilesFromStorage() async {
    final routeArgs =
    ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (routeArgs == null) return;

    final projectName = routeArgs['name'] ?? 'unbekannt';
    final storagePath = 'files/$projectName/';

    try {
      final ref = FirebaseStorage.instance.ref().child(storagePath);
      final result = await ref.listAll();

      setState(() {
        _importedFiles = result.items
            .map((Reference fileRef) {
          return {'name': fileRef.name, 'path': fileRef.fullPath};
        })
            .toList();
      });
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

  Future<void> _uploadFileToFirebase() async {
    if (_filePath == null || _fileName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Fehler: Keine Datei zum Hochladen ausgewählt'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final routeArgs =
    ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    if (routeArgs == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Fehler: Keine Projektinformationen verfügbar'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final file = File(_filePath!);
    final path = 'files/${routeArgs["name"]}/$_fileName';
    final ref = FirebaseStorage.instance.ref().child(path);

    try {
      await ref.putFile(file);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Datei $_fileName erfolgreich hochgeladen!'),
          backgroundColor: Colors.green,
        ),
      );

      setState(() {
        _filePicked = false;
        _importedFiles.add({'name': _fileName!, 'path': path});
        _filePath = null;
        _fileName = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fehler beim Hochladen: $e'),
          backgroundColor: Colors.red,
        ),
      );
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

      var uri = Uri.parse('http://deine-api-url/upload'); // Ersetze mit deiner API-URL

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

      setState(() {
        _isLoading = false;
        if (response.statusCode == 200) {
          _uploadStatus = 'API-Upload erfolgreich: $responseString';
          _filePicked = false;
          _importedFiles.add({'name': _fileName!, 'path': _filePath!});
          _filePath = null;
          _fileName = null;
        } else {
          _uploadStatus = 'API-Upload fehlgeschlagen: ${response.statusCode}';
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_uploadStatus!),
          backgroundColor:
          response.statusCode == 200 ? Colors.green : Colors.red,
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
        _uploadStatus = 'Fehler beim API-Upload: $e';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_uploadStatus!),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteFileFromFirebase(String path) async {
    try {
      final ref = FirebaseStorage.instance.ref().child(path);
      await ref.delete();
      setState(() {
        _importedFiles.removeWhere((file) => file['path'] == path);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Datei erfolgreich aus Firebase gelöscht'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fehler beim Löschen aus Firebase: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteFileFromApi(String fileName) async {
    try {
      setState(() {
        _isLoading = true;
      });

      var uri = Uri.parse('http://deine-api-url/delete'); // Ersetze mit deiner API-URL
      var response = await http.delete(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'file': fileName}), // Dateiname genau wie beim Upload
      );

      setState(() {
        _isLoading = false;
        if (response.statusCode == 200) {
          _importedFiles.removeWhere((file) => file['name'] == fileName);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Datei erfolgreich aus API gelöscht'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('API-Löschung fehlgeschlagen: ${response.statusCode}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fehler beim API-Löschen: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteFile(String path, String fileName) async {
    await _deleteFileFromFirebase(path);
    await _deleteFileFromApi(fileName);
  }

  void _confirmSelection() {
    if (_filePath != null && _fileName != null) {
      _uploadFileToApi(); // oder _uploadFileToFirebase();
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
    final routeArgs =
    ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final projectName = routeArgs?['name'] ?? "unbekannt";

    return Scaffold(
      appBar: AppBar(
        title: Text(projectName),
        actions: [
          IconButton(
            onPressed: () => _changeToChat(context),
            icon: Icon(Icons.chat),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 800),
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
                child: newFile(
                  fileName: _fileName,
                  pickFileFunc: _pickFile,
                  confirmSelectionFunc: _confirmSelection,
                  filePicked: _filePicked,
                ),
              ),
              if (_isLoading)
                Center(
                  child: CircularProgressIndicator(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}