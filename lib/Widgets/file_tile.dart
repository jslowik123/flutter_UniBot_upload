import 'package:flutter/material.dart';

class FileTile extends StatelessWidget {
  final Map<String, dynamic> file;
  final Future<void> Function() deleteFileFunc;

  const FileTile({super.key, required this.file, required this.deleteFileFunc});

  @override
  Widget build(BuildContext context) {
    final List<String> keywords =
        (file['keywords'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];
    final List<String> summaryPoints =
        (file['summary'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];
    final String summaryDisplay =
        summaryPoints.isNotEmpty
            ? summaryPoints.join('\n')
            : 'Keine Zusammenfassung verfügbar';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: ExpansionTile(
        leading: const Icon(Icons.insert_drive_file, color: Colors.blue),
        title: Text(file['name']!),
        subtitle: Text("Am ${file['date']} hochgeladen."),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: deleteFileFunc,
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (keywords.isNotEmpty) ...[
                  const Text(
                    'Schlüsselwörter:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children:
                        keywords
                            .map(
                              (keyword) => Chip(
                                label: Text(keyword),
                                backgroundColor: Colors.blue.shade100,
                              ),
                            )
                            .toList(),
                  ),
                  const SizedBox(height: 16),
                ],
                const Text(
                  'Zusammenfassung:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(summaryDisplay),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
