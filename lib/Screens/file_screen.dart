import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '/Widgets/file_tile.dart';
import '/Widgets/new_file.dart';
import '/Services/file_service.dart';
import '/Widgets/help_dialog.dart';

class FileScreen extends StatefulWidget {
  const FileScreen({super.key});

  @override
  State<FileScreen> createState() => _FileScreenState();
}

class _FileScreenState extends State<FileScreen> {
  final FileService _fileService = FileService();
  final _helpDialog = HelpDialog();
  String? _filePath;
  String? _fileName;
  bool _filePicked = false;
  List<Map<String, String>> _importedFiles = [];
  bool _isInitialized = false;
  bool _isLoading = false;
  Map<String, dynamic>? _routeArgs;
  late File _file;
  String? _projectName;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _routeArgs =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      _projectName = _routeArgs?['name'];
      _fetchFilesFromDatabase();
      _isInitialized = true;
    }
  }

  Future<void> _fetchFilesFromDatabase() async {
    if (_projectName == null) return;

    try {
      final files = await _fileService.fetchFiles(_projectName!);
      setState(() => _importedFiles = files);
    } catch (e) {
      _showErrorSnackBar('Fehler beim Abrufen der Dateien: $e');
    }
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
      );

      if (result != null) {
        _file = File(result.files.single.path!);
        setState(() {
          _filePath = result.files.single.path;
          _fileName = result.files.single.name;
          _filePicked = true;
        });
      }
    } catch (e) {
      _showErrorSnackBar('Fehler beim Datei-Import: $e');
    }
  }

  Future<void> _confirmSelection() async {
    if (_filePath == null || _fileName == null || _projectName == null) {
      _showErrorSnackBar('Bitte wählen Sie zuerst eine Datei aus');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _fileService.uploadToPinecone(_file, _projectName!);
      await _fileService.uploadToFirebase(
        _projectName!,
        _fileName!,
        _filePath!,
      );

      _showSuccessSnackBar('Datei erfolgreich hochgeladen und verarbeitet');
      await _fetchFilesFromDatabase();

      setState(() {
        _filePicked = false;
        _fileName = null;
        _filePath = null;
      });
    } catch (e) {
      _showErrorSnackBar('Fehler beim Upload: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteFile(String path, String fileName) async {
    if (_projectName == null) return;

    setState(() => _isLoading = true);
    try {
      await _fileService.deleteFromFirebase(path);
      await _fileService.deleteFromPinecone(fileName, _projectName!);

      _showSuccessSnackBar('Datei erfolgreich gelöscht');
      await _fetchFilesFromDatabase();
    } catch (e) {
      _showErrorSnackBar('Fehler beim Löschen: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    final projectName = _projectName ?? "unbekannt";

    return Scaffold(
      appBar: AppBar(
        title: Text(projectName),
        actions: [
          IconButton(
            onPressed: () => _helpDialog.showHelpDialog(context),
            icon: const Icon(Icons.help_outline),
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
