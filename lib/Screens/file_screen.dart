import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import '../Widgets/file_tile.dart';
import '../Widgets/new_file.dart';
import 'package:intl/intl.dart';

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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _routeArgs = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
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
          if (value is Map && value.containsKey('name') && value.containsKey('date')) {
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

  Future<String?> _uploadFileToFirebase(String fileName, String filePath) async {
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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Datei erfolgreich hochgeladen')),
      );
      return null;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler beim Upload: $e')),
      );
      return e.toString();
    }
  }

  Future<void> _uploadFileToPinecone() async {
    return;
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
  }

  void _confirmSelection() {
    if (_filePath != null && _fileName != null) {
      _uploadFileToFirebase(_fileName!, _filePath!);
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
            children: [_importedFiles.isEmpty ? const Center(child: Text('Keine Dateien vorhanden.', ))
              : ListView.builder(
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