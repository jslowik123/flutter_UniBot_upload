import 'package:flutter/material.dart';
import 'dart:convert';

class ProjectKnowledgeCard extends StatelessWidget {
  final String projectKnowledge;
  final bool isLoadingKnowledge;
  final VoidCallback? onRefreshKnowledge;
  final String? projectAssessment;
  // onNavigateToChatbot entfernt
  
  const ProjectKnowledgeCard({
    super.key, 
    required this.projectKnowledge, 
    required this.isLoadingKnowledge, 
    this.onRefreshKnowledge,
    this.projectAssessment,
    // onNavigateToChatbot entfernt
  });

  String _extractWissensstand() {
    if (projectAssessment == null || projectAssessment!.isEmpty) return '';
    
    try {
      if (projectAssessment!.contains('{') && projectAssessment!.contains('}')) {
        final jsonStart = projectAssessment!.indexOf('{');
        final jsonEnd = projectAssessment!.lastIndexOf('}') + 1;
        final jsonString = projectAssessment!.substring(jsonStart, jsonEnd);
        final Map<String, dynamic> assessmentData = json.decode(jsonString);
        
        for (final entry in assessmentData.entries) {
          if (entry.key.toLowerCase() == 'wissensstand') {
            return entry.value.toString();
          }
        }
      }
    } catch (e) {
      final RegExp wissenstandRegex = RegExp(r'wissensstand:\s*([^\n]+)', caseSensitive: false, multiLine: true);
      final match = wissenstandRegex.firstMatch(projectAssessment!);
      if (match != null) {
        return match.group(1)?.trim() ?? '';
      }
    }
    
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final wissensstand = _extractWissensstand();
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 0),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.library_books, color: Colors.green),
                SizedBox(width: 8),
                Text(
                  'Projekt-Wissensbasis',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Spacer(),
                if (onRefreshKnowledge != null)
                  IconButton(
                    onPressed: isLoadingKnowledge ? null : onRefreshKnowledge,
                    icon: isLoadingKnowledge 
                      ? SizedBox(
                          width: 16, 
                          height: 16, 
                          child: CircularProgressIndicator(strokeWidth: 2)
                        )
                      : Icon(Icons.refresh),
                    tooltip: 'Wissensbasis aktualisieren',
                    iconSize: 20,
                  ),
              ],
            ),
            SizedBox(height: 12),
            
            // Content
            if (isLoadingKnowledge)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                      SizedBox(width: 12),
                      Text('Lade Wissensbasis...'),
                    ],
                  ),
                ),
              )
            else if (projectKnowledge.isEmpty && wissensstand.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Icon(Icons.library_books_outlined, size: 48, color: Colors.grey[400]),
                      SizedBox(height: 8),
                      Text(
                        'Noch keine Wissensbasis verfügbar',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Wissensbasis Text anzeigen (falls vorhanden)
                  if (projectKnowledge.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        border: Border.all(color: Colors.green[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        projectKnowledge,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.4,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  // Wissensstand als ListTile anzeigen (falls vorhanden)
                  if (wissensstand.isNotEmpty) ...[
                    if (projectKnowledge.isNotEmpty) SizedBox(height: 12),
                    Text(
                      wissensstand,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.4,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                  // Chatbot-Button entfernt
                ],
              ),
          ],
        ),
      ),
    );
  }
}