import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '/Widgets/file_tile.dart';
import '/Widgets/new_file.dart';
import '/Services/file_service.dart';
import '/Widgets/help_dialog.dart';
import '/Widgets/help_content.dart';
import '/Services/snackbar_service.dart';
import '../models/processing_status.dart';
import '../widgets/processing_status_tile.dart';
import '/Services/project_service.dart';

class FileScreen extends StatefulWidget {
  const FileScreen({super.key});

  @override
  State<FileScreen> createState() => _FileScreenState();
}

class _FileScreenState extends State<FileScreen> {
  final FileService _fileService = FileService();
  final ProjectService _projectService = ProjectService();
  final TextEditingController _projectInfoController = TextEditingController();
  String _initialProjectInfo = '';
  String? _filePath;
  String? _fileName;
  bool _filePicked = false;
  List<ProcessingStatus> _processingFiles = [];
  List<Map<String, dynamic>> _importedFiles = [];
  bool _isInitialized = false;
  bool _isLoading = false;
  bool _isSavingProjectInfo = false;
  Map<String, dynamic>? _routeArgs;
  late Uint8List _fileBytes;
  String? _projectName;
  String? _fileID;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    print('[didChangeDependencies] _isInitialized=$_isInitialized, _projectName=$_projectName');
    if (!_isInitialized) {
      _routeArgs =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      _projectName = _routeArgs?['name'];
      print('[didChangeDependencies] routeArgs=$_routeArgs, _projectName=$_projectName');
      _initializeScreen();
      _isInitialized = true;
    }
  }

  Future<void> _initializeScreen() async {
    if (_projectName == null) return;
    await _fetchFilesFromDatabase();
    await _loadProjectInfo();
  }

  Future<void> _loadProjectInfo() async {
    print('[loadProjectInfo] called for $_projectName');
    if (_projectName == null) {
      _projectInfoController.text = '';
      _initialProjectInfo = '';
      setState(() {});
      print('[loadProjectInfo] _projectName is null, set empty');
      return;
    }
    try {
      final info = await _projectService.getProjectInfo(_projectName!);
      _projectInfoController.text = info;
      _initialProjectInfo = info;
      setState(() {});
      print('[loadProjectInfo] loaded info: $info');
    } catch (e) {
      _projectInfoController.text = '';
      _initialProjectInfo = '';
      setState(() {});
      print('[loadProjectInfo] error: $e, set empty');
    }
  }

  Future<void> _saveProjectInfo() async {
    if (_projectName == null) return;
    setState(() => _isSavingProjectInfo = true);
    try {
      await _projectService.setProjectInfo(_projectName!, _projectInfoController.text);
      SnackbarService.showSuccess(context, 'Projektinfo gespeichert');
      _initialProjectInfo = _projectInfoController.text;
      setState(() {});
    } catch (e) {
      SnackbarService.showError(context, 'Fehler beim Speichern der Projektinfo');
    } finally {
      setState(() => _isSavingProjectInfo = false);
    }
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

  Future<void> _confirmSelection(String description) async {
    if (_filePath == null || _fileName == null || _projectName == null) {
      _showErrorSnackBar('Bitte wählen Sie zuerst eine Datei aus');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final processingStatus = await _fileService.processFileUpload(
        filePath: _filePath!,
        fileBytes: _fileBytes,
        fileName: _fileName!,
        projectName: _projectName!,
        additionalInfo: description,
      );

      setState(() {
        _processingFiles.add(processingStatus);
        _isLoading = false;
        _filePicked = false;
        _fileName = null;
        _filePath = null;
        _fileID = null;
      });

      _showSuccessSnackBar('Upload gestartet');
    } catch (e) {
      debugPrint('Upload Fehler: $e');
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
  void initState() {
    super.initState();
    _projectInfoController.addListener(_onProjectInfoChanged);
  }

  @override
  void dispose() {
    _projectInfoController.removeListener(_onProjectInfoChanged);
    _projectInfoController.dispose();
    super.dispose();
  }

  void _onProjectInfoChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    print('[build] _projectName=$_projectName, _isLoading=$_isLoading, _importedFiles=${_importedFiles.length}, _processingFiles=${_processingFiles.length}');
    return Scaffold(
      appBar: AppBar(
        title: Text(_projectName ?? "unbekannt"),
        actions: [
          IconButton(
            onPressed: () => HelpDialog.show(context, HelpContent.pages),
            icon: const Icon(Icons.help_outline),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Stack(
            children: [
              ListView(
                padding: const EdgeInsets.only(bottom: 120.0),
                children: [
                  Card(
                    margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 0),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Projekt-Notizen für den Chatbot',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              SizedBox(width: 8),
                              Tooltip(
                                message: 'Hier kannst du wichtige Hinweise, Ziele oder Kontext für dieses Projekt eintragen. Diese Infos werden dem Chatbot zusätzlich zu den Dokumenten bereitgestellt.',
                                child: Icon(Icons.info_outline, size: 18, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                          SizedBox(height: 12),
                          TextFormField(
                            controller: _projectInfoController,
                            minLines: 2,
                            maxLines: 6,
                            decoration: InputDecoration(
                              hintText: 'z.B. "Bitte beachte, dass ich im 3. Semester bin und mich besonders für Wahlpflichtmodule interessiere."',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerRight,
                            child: (_projectInfoController.text != _initialProjectInfo)
                                ? ElevatedButton.icon(
                                    onPressed: _isSavingProjectInfo ? null : _saveProjectInfo,
                                    icon: _isSavingProjectInfo
                                        ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                        : Icon(Icons.save),
                                    label: Text('Speichern'),
                                  )
                                : SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else ...[
                    if (_processingFiles.isEmpty && _importedFiles.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Center(child: Text('Keine Dateien vorhanden')),
                      ),
                    ..._processingFiles.map(
                      (file) => ProcessingStatusTile(
                        status: file,
                        onStatusUpdate: (status) => _handleStatusUpdate(file, status),
                        projectName: _projectName!,
                      ),
                    ),
                    ..._importedFiles.map(
                      (file) => FileTile(
                        file: file,
                        deleteFileFunc: () => _deleteFile(file['path']!, file['name']!),
                      ),
                    ),
                  ],
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
            ],
          ),
        ),
      ),
    );
  }
}
