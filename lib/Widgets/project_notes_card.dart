import 'package:flutter/material.dart';

class ProjectNotesCard extends StatelessWidget {
  final TextEditingController controller;
  final String initialProjectInfo;
  final bool isSavingProjectInfo;
  final VoidCallback? onSave;

  const ProjectNotesCard({
    super.key,
    required this.controller,
    required this.initialProjectInfo,
    required this.isSavingProjectInfo,
    this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 0),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(
                  'Projekt-Notizen für den Chatbot',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                SizedBox(width: 8),
                Tooltip(
                  message: 'WICHTIG: Diese Notizen sind essentiell für die Vollständigkeits-Bewertung! Ohne diese Angaben kann das System nicht einschätzen, welche Dokumente für dein Projekt relevant sind. Trage hier wichtige Hinweise, Ziele oder Kontext ein.',
                  child: Icon(Icons.info_outline, size: 18, color: Colors.grey[600]),
                ),
              ],
            ),
            SizedBox(height: 12),
            TextFormField(
              controller: controller,
              minLines: 2,
              maxLines: 6,
              decoration: InputDecoration(
                hintText: 'z.B. "Das ist der Chatbot für den Bachelor und Master in Informatik"',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: (controller.text != initialProjectInfo)
                  ? ElevatedButton.icon(
                      onPressed: isSavingProjectInfo ? null : onSave,
                      icon: isSavingProjectInfo
                          ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : Icon(Icons.save),
                      label: Text('Speichern'),
                    )
                  : SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
} 