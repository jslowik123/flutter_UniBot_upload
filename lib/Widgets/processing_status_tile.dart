import 'package:flutter/material.dart';
import '../models/processing_status.dart';
import '../services/file_service.dart';

class ProcessingStatusTile extends StatefulWidget {
  final ProcessingStatus status;
  final Function onStatusUpdate;
  const ProcessingStatusTile({
    super.key,
    required this.status,
    required this.onStatusUpdate,
  });

  @override
  State<ProcessingStatusTile> createState() => _ProcessingStatusTileState();
}

class _ProcessingStatusTileState extends State<ProcessingStatusTile> {
  final FileService _fileService = FileService();

  @override
  void initState() {
    super.initState();
    _startPolling();
  }

  void _startPolling() {
    if (!mounted) return;

    _fileService.startStatusPolling(
      widget.status.taskId,
      widget.status.fileName,
      (status) {
        if (mounted) {
          widget.onStatusUpdate(status);
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
            if (widget.status.isProcessing) ...[
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
    if (widget.status.isComplete) {
      return 'Verarbeitung abgeschlossen';
    } else if (widget.status.isError) {
      return 'Fehler: ${widget.status.error ?? widget.status.status}';
    } else {
      return '${widget.status.status} (${widget.status.progress}%)';
    }
  }
}
