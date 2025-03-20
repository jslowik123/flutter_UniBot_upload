import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../Widgets/FileTile.dart';
import '../Widgets/newFile.dart';

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
        _importedFiles =
            result.items.map((Reference fileRef) {
              return {'name': fileRef.name, 'path': fileRef.fullPath};
            }).toList();
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
        type: FileType.any,
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Fehler beim Datei-Import: $e')));
    }
  }

  Future<void> _uploadFile() async {
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

  Future<void> _deleteFile(String path) async {
    try {
      final ref = FirebaseStorage.instance.ref().child(path);
      await ref.delete();
      setState(() {
        _importedFiles.removeWhere((file) => file['path'] == path);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Datei erfolgreich gelöscht'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fehler beim Löschen: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _confirmSelection() {
    if (_filePath != null && _fileName != null) {
      _uploadFile();
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
          IconButton(onPressed: () => _changeToChat(context), icon: Icon(Icons.chat)),
        ],
      ),

      body: Stack(
        children: [
          ListView.builder(
            padding: const EdgeInsets.only(bottom: 120.0),
            itemCount: _importedFiles.length,
            itemBuilder: (context, index) {
              return FileTile(
                _importedFiles[index],
                () => _deleteFile(_importedFiles[index]["path"]!),
              );
            },
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: newFile(
              fileName: _fileName,
              pickFileFunc: _pickFile, // Funktion direkt übergeben
              confirmSelectionFunc: _confirmSelection,
              filePicked: _filePicked,
            ),
          ),
        ],
      ),
    );
  }
}
