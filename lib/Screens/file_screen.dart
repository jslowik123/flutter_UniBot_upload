import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '/Widgets/file_tile.dart';
import '/Widgets/new_file.dart';
import '/Services/file_service.dart';
import '/Widgets/help_dialog.dart';
import '/Services/snackbar_service.dart';

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
  List<Map<String, dynamic>> _importedFiles = [];
  bool _isInitialized = false;
  bool _isLoading = false;
  Map<String, dynamic>? _routeArgs;
  late Uint8List _fileBytes;
  String? _projectName;
  String? _fileID;

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
      SnackbarService.showError(context, 'Fehler beim Laden der Dateien: $e');
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
        _filePath = result.files.single.path;
        _fileName = result.files.single.name;
        if (kIsWeb) {
          final bytes = result.files.single.bytes;
          if (bytes != null) {
            _fileBytes = bytes;
          }
        } else {
          _filePath = result.files.single.path;
          _fileBytes = Uint8List(0);
        }
        setState(() => _filePicked = true);
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
      _fileID = await _fileService.uploadToFirebase(
        _projectName!,
        _fileName!,
        _filePath!,
      );
      print('File ID: $_fileID');

      try {
        final successMessage = await _fileService.uploadToPinecone(
          _filePath!,
          _fileBytes,
          _fileName!,
          _projectName!,
          _fileID!,
        );

        print('Success message: $successMessage');
        await _fetchFilesFromDatabase();
        _showSuccessSnackBar(successMessage);
      } catch (pineconeError) {
        // Bei Pinecone-Fehler: Dokument aus Firebase löschen
        if (_fileID != null) {
          await _fileService.deleteFromFirebase(
            'files/${_projectName!}/$_fileID',
          );
          print('Firebase-Eintrag nach Pinecone-Fehler gelöscht: $_fileID');
        }
        rethrow; // Fehler weiterwerfen für die catch-Klausel außen
      }

      setState(() {
        _isLoading = false;
        _filePicked = false;
        _fileName = null;
        _filePath = null;
        _fileID = null;
      });
    } catch (e) {
      _showErrorSnackBar('Fehler beim Upload: $e');
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
              if (!_isLoading && _importedFiles.isEmpty)
                const Center(child: Text('Keine Dateien vorhanden.'))
              else if (!_isLoading && _importedFiles.isNotEmpty)
                ListView.builder(
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
              if (_isLoading)
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(
                        _filePicked
                            ? 'Datei wird verarbeitet...\nDies kann einen Moment dauern.'
                            : 'Lade...',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
