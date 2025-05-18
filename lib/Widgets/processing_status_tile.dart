import 'package:flutter/material.dart';
import '../models/processing_status.dart';
import '../services/file_service.dart';
import 'package:firebase_database/firebase_database.dart';
import '../config/app_config.dart';
import 'dart:async';

class ProcessingStatusTile extends StatefulWidget {
  final ProcessingStatus status;
  final Function onStatusUpdate;
  final String projectName;
  const ProcessingStatusTile({
    super.key,
    required this.status,
    required this.onStatusUpdate,
    required this.projectName,
  });

  @override
  State<ProcessingStatusTile> createState() => _ProcessingStatusTileState();
}

class _ProcessingStatusTileState extends State<ProcessingStatusTile> {
  final FileService _fileService = FileService();
  late DatabaseReference _statusRef;
  StreamSubscription<DatabaseEvent>? _statusSubscription;

  @override
  void initState() {
    super.initState();
    _setupFirebaseListener();
  }

  @override
  void dispose() {
    _statusSubscription?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(ProcessingStatusTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.status.fileID != widget.status.fileID ||
        oldWidget.projectName != widget.projectName) {
      _statusSubscription?.cancel();
      _setupFirebaseListener();
    }
  }

  void _setupFirebaseListener() {
    final fileId = widget.status.fileID.split('/').last;
    _statusRef = FirebaseDatabase.instance
        .ref()
        .child(AppConfig.firebaseFilesPath)
        .child(widget.projectName)
        .child(fileId);

    _statusSubscription = _statusRef.onValue.listen(
      (event) {
        if (!mounted) return;

        final data = event.snapshot.value as Map<dynamic, dynamic>?;
        if (data != null) {
          final status = ProcessingStatus.fromFirebase(
            data,
            widget.status.fileName,
            widget.status.fileID,
          );

          widget.onStatusUpdate(status);
        }
      },
      onError: (error) {
        print('Firebase listener error: $error');
        if (mounted) {
          widget.onStatusUpdate(
            ProcessingStatus(
              status: 'Verbindungsfehler',
              progress: 0,
              error: error.toString(),
              fileName: widget.status.fileName,
              fileID: widget.status.fileID,
              processing: false,
            ),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: ListTile(
        leading: _buildLeadingIcon(),
        title: Text(widget.status.fileName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(_getStatusMessage()),
            if (widget.status.isProcessing || widget.status.progress > 0) ...[
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: widget.status.progress / 100,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                  widget.status.isError ? Colors.red : Colors.blue,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLeadingIcon() {
    if (widget.status.isComplete) {
      return const Icon(Icons.check_circle, color: Colors.green);
    } else if (widget.status.isError) {
      return const Icon(Icons.error, color: Colors.red);
    } else {
      return const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }
  }

  String _getStatusMessage() {
    if (widget.status.isError) {
      return 'Fehler: ${widget.status.error ?? widget.status.status}';
    } else {
      return '${widget.status.status} (${widget.status.progress}%)';
    }
  }
}
