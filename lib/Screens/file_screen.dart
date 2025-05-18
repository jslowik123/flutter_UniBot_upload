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
  final _helpDialog = HelpDialog();
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
                    taskId: file['taskId'] ?? '',
                    state: 'PENDING',
                    status: 'Waiting',
                    progress: 0,
                    fileName: file['name'] ?? '',
                    fileID: file['path'] ?? '',
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
      // 1. Upload to Firebase
      _fileID = await _fileService.uploadToFirebase(
        _projectName!,
        _fileName!,
        _filePath!,
      );

      // 2. Start processing task
      final response = await _fileService.startTask(
        _filePath!,
        _fileBytes,
        _fileName!,
        _projectName!,
        _fileID!,
        [],
      );

      if (response['status'] == 'success' && response['task_id'] != null) {
        final taskId = response['task_id'];

        // 3. Update processing status in Firebase
        await _fileService.updateFileProcessingStatus(
          _projectName!,
          _fileID!,
          true,
          taskId,
        );

        // 4. Add to processing files list
        setState(() {
          _processingFiles.add(
            ProcessingStatus(
              taskId: taskId,
              state: 'PENDING',
              status: 'Warte auf Verarbeitung',
              progress: 0,
              fileName: _fileName!,
              fileID: _fileID!,
            ),
          );
        });

        _showSuccessSnackBar('Upload gestartet');
      } else {
        throw Exception(response['message'] ?? 'Unbekannter Fehler');
      }

      // 5. Reset state
      setState(() {
        _isLoading = false;
        _filePicked = false;
        _fileName = null;
        _filePath = null;
        _fileID = null;
      });
    } catch (e) {
      print('Upload Fehler: $e');
      // Cleanup if Firebase upload was successful but processing failed
      if (_fileID != null) {
        try {
          await _fileService.deleteFile(
            _fileName!,
            _projectName!,
            _fileID!,
            true,
          );
        } catch (deleteError) {
          print('Fehler beim Löschen: $deleteError');
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
      // Extrahieren der fileID aus dem Pfad
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
      // Extract only the fileID from the path
      final fileID = file.fileID.split('/').last;
      _fileService
          .updateFileProcessingStatus(_projectName!, fileID, false, null)
          .then((_) {
            if (mounted) {
              setState(() {
                _processingFiles.removeWhere((f) => f.taskId == file.taskId);
              });
              if (status.isComplete) {
                _fetchFilesFromDatabase();
              }
            }
          });
    } else {
      setState(() {
        final index = _processingFiles.indexWhere(
          (f) => f.taskId == file.taskId,
        );
        if (index != -1) {
          _processingFiles[index] =
              status.fileID.isEmpty
                  ? ProcessingStatus(
                    taskId: status.taskId,
                    state: status.state,
                    status: status.status,
                    progress: status.progress,
                    error: status.error,
                    fileName: status.fileName,
                    fileID: file.fileID,
                  )
                  : status;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_projectName ?? "unbekannt"),
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
