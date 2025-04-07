import 'package:flutter/material.dart';

class NewFile extends StatelessWidget {
  final String? fileName;
  final Future<void> Function() pickFileFunc;
  final VoidCallback confirmSelectionFunc;
  final bool filePicked;

  const NewFile({
    required this.fileName,
    required this.pickFileFunc,
    required this.confirmSelectionFunc,
    required this.filePicked,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color.fromRGBO(158, 158, 158, 0.3),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: pickFileFunc,
                icon: const Icon(Icons.upload_file),
                label: const Text('Datei auswählen'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: confirmSelectionFunc,
                icon: const Icon(Icons.check),
                label: const Text('Bestätigen'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  backgroundColor: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(8.0),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              filePicked && fileName != null
                  ? 'Ausgewählte Datei: $fileName'
                  : 'Keine Datei ausgewählt',
              style: TextStyle(
                fontSize: 16,
                color: filePicked ? Colors.black87 : Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}