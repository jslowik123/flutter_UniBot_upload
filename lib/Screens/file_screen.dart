import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '/Widgets/file_tile.dart';
import '/Widgets/new_file.dart';
import '/Services/file_service.dart';
import '/Widgets/help_dialog.dart';
import '/Services/snackbar_service.dart';
import '../models/processing_status.dart';
import '../widgets/processing_status_tile.dart';

class FileScreen extends StatefulWidget {
  const FileScreen({super.key});

  @override
  State<FileScreen> createState() => _FileScreenState();
}

class _FileScreenState extends State<FileScreen> {
  final FileService _fileService = FileService();
  String? _filePath;
  String? _fileName;
  bool _filePicked = false;
  List<ProcessingStatus> _processingFiles = [];
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
      _initializeScreen();
      _isInitialized = true;
    }
  }

  Future<void> _initializeScreen() async {
    if (_projectName == null) return;
    await _fetchFilesFromDatabase();
  }

  Future<void> _fetchFilesFromDatabase() async {
    if (_projectName == null) return;

    try {
      List files = await _fileService.fetchFiles(_projectName!);
      setState(() => _importedFiles = files[0]);
      setState(() {
        _processingFiles =
            (files[1] as List<dynamic>)
                .map<ProcessingStatus>(
                  (file) => ProcessingStatus(
                    status: file['status'] ?? 'Warte auf Verarbeitung',
                    progress: file['progress'] ?? 0,
                    fileName: file['name'] ?? '',
                    fileID: file['path'] ?? '',
                    processing: true,
                  ),
                )
                .toList();
      });
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

      final response = await _fileService.startTask(
        _filePath!,
        _fileBytes,
        _fileName!,
        _projectName!,
        _fileID!,
        [],
      );

      if (response['status'] == 'success') {
        setState(() {
          _processingFiles.add(
            ProcessingStatus(
              status: 'Verarbeitung gestartet',
              progress: 0,
              fileName: _fileName!,
              fileID: '$_projectName/$_fileID',
              processing: true,
            ),
          );
        });

        _showSuccessSnackBar('Upload gestartet');
      } else {
        throw Exception(response['message'] ?? 'Unbekannter Fehler');
      }

      setState(() {
        _isLoading = false;
        _filePicked = false;
        _fileName = null;
        _filePath = null;
        _fileID = null;
      });
    } catch (e) {
      debugPrint('Upload Fehler: $e');
      if (_fileID != null) {
        try {
          await _fileService.deleteFile(
            _fileName!,
            _projectName!,
            _fileID!,
            true,
          );
        } catch (deleteError) {
          debugPrint('Fehler beim Löschen: $deleteError');
        }
      }
      _showErrorSnackBar('Fehler beim Upload: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteFile(String path, String fileName) async {
    if (_projectName == null) return;

    setState(() => _isLoading = true);
    try {
      final fileID = path.split('/').last;
      await _fileService.deleteFile(fileName, _projectName!, fileID, false);
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

  void _handleStatusUpdate(ProcessingStatus file, ProcessingStatus status) {
    if (status.isComplete || status.isError) {
      setState(() {
        _processingFiles.removeWhere((f) => f.fileID == file.fileID);
      });
      _fetchFilesFromDatabase();
    } else {
      if (mounted) {
        setState(() {
          final index = _processingFiles.indexWhere(
            (f) => f.fileID == file.fileID,
          );
          if (index != -1) {
            _processingFiles[index] = status;
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_projectName ?? "unbekannt"),
        actions: [
          IconButton(
            onPressed: () => HelpDialog.show(context),
            icon: const Icon(Icons.help_outline),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Stack(
            children: [
              !_isLoading && _importedFiles.isEmpty && _processingFiles.isEmpty
                  ? const Center(child: Text('Keine Dateien vorhanden.'))
                  : ListView(
                    padding: const EdgeInsets.only(bottom: 120.0),
                    children: [
                      ..._processingFiles.map(
                        (file) => ProcessingStatusTile(
                          status: file,
                          onStatusUpdate:
                              (status) => _handleStatusUpdate(file, status),
                          projectName: _projectName!,
                        ),
                      ),
                      ..._importedFiles.map(
                        (file) => FileTile(
                          file: file,
                          deleteFileFunc:
                              () => _deleteFile(file['path']!, file['name']!),
                        ),
                      ),
                    ],
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
