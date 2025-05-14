import 'package:flutter/material.dart';
import '../models/processing_status.dart';

class ProcessingStatusTile extends StatelessWidget {
  final ProcessingStatus status;

  const ProcessingStatusTile({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: ListTile(
        leading: _buildLeadingIcon(),
        title: Text(status.fileName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(_getStatusMessage()),
            if (status.isProcessing) ...[
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: status.progress / 100,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                  status.isError ? Colors.red : Colors.blue,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLeadingIcon() {
    if (status.isComplete) {
      return const Icon(Icons.check_circle, color: Colors.green);
    } else if (status.isError) {
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
    if (status.isComplete) {
      return 'Verarbeitung abgeschlossen';
    } else if (status.isError) {
      return 'Fehler: ${status.error ?? status.status}';
    } else {
      return '${status.status} (${status.progress}%)';
    }
  }
}
