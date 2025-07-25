import 'package:flutter/material.dart';
import 'dart:convert';

class ProjectAssessmentCard extends StatelessWidget {
  final String projectAssessment;
  final bool isLoadingAssessment;
  final VoidCallback? onRefresh;

  const ProjectAssessmentCard({
    super.key,
    required this.projectAssessment,
    required this.isLoadingAssessment,
    this.onRefresh,
  });

  // Methode zur Formatierung des Assessment-Textes
  String _formatAssessmentText(String text) {
    if (text.isEmpty) return text;
    
    // Entferne überflüssige Whitespaces und leere Zeilen
    String formatted = text.replaceAll(RegExp(r'\n\s*\n'), '\n\n');
    formatted = formatted.replaceAll(RegExp(r'^\s+', multiLine: true), '');
    
    return formatted.trim();
  }

  // Extrahiere Key-Value Paare aus dem Assessment
  List<Map<String, String>> _extractAssessmentKeyValues() {
    if (projectAssessment.isEmpty) return [];
    
    List<Map<String, String>> keyValues = [];
    
    try {
      // Versuche JSON zu parsen
      if (projectAssessment.contains('{') && projectAssessment.contains('}')) {
        final jsonStart = projectAssessment.indexOf('{');
        final jsonEnd = projectAssessment.lastIndexOf('}') + 1;
        final jsonString = projectAssessment.substring(jsonStart, jsonEnd);
        final Map<String, dynamic> assessmentData = json.decode(jsonString);
        
        // Reihenfolge und Labels der Felder (ohne wissensstand)
        final fieldOrder = [
          'vorhandene_dokumente',
          'fehlende_dokumente',
          'tipps',
        ];
        final fieldLabels = {
          'vorhandene_dokumente': 'Vorhandene Dokumente',
          'fehlende_dokumente': 'Fehlende Dokumente',
          'tipps': 'Tipps',
        };
        
        for (final field in fieldOrder) {
          if (assessmentData.containsKey(field)) {
            final value = assessmentData[field];
            String displayValue;
            if (value is List) {
              displayValue = value.map((e) => '• $e').join('\n');
            } else {
              displayValue = value.toString();
            }
            keyValues.add({
              'key': fieldLabels[field] ?? field,
              'value': displayValue,
            });
          }
        }
      }
    } catch (e) {
      // Fallback: Suche nach Pattern wie "Key: Value"
      final RegExp keyValueRegex = RegExp(r'([A-Za-z_äöüß\s]+):\s*([^\n]+)', multiLine: true);
      final matches = keyValueRegex.allMatches(projectAssessment);
      final allowedKeys = ['vorhandene_dokumente', 'fehlende_dokumente', 'tipps'];
      for (final match in matches) {
        final key = match.group(1)?.trim() ?? '';
        final value = match.group(2)?.trim() ?? '';
        for (final allowedKey in allowedKeys) {
          if (key.toLowerCase().contains(allowedKey)) {
            keyValues.add({'key': key, 'value': value});
            break;
          }
        }
      }
    }
    
    return keyValues;
  }

  @override
  Widget build(BuildContext context) {
    final keyValues = _extractAssessmentKeyValues();
    final hasStructuredData = keyValues.isNotEmpty;
    
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
                Icon(Icons.analytics, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Projekt-Assessment',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Spacer(),
                if (onRefresh != null)
                  IconButton(
                    onPressed: isLoadingAssessment ? null : onRefresh,
                    icon: isLoadingAssessment 
                      ? SizedBox(
                          width: 16, 
                          height: 16, 
                          child: CircularProgressIndicator(strokeWidth: 2)
                        )
                      : Icon(Icons.refresh),
                    tooltip: 'Assessment aktualisieren',
                    iconSize: 20,
                  ),
              ],
            ),
            SizedBox(height: 12),
            
            // Content
            if (isLoadingAssessment)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                      SizedBox(width: 12),
                      Text('Lade Assessment...'),
                    ],
                  ),
                ),
              )
            else if (projectAssessment.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Icon(Icons.analytics_outlined, size: 48, color: Colors.grey[400]),
                      SizedBox(height: 8),
                      Text(
                        'Noch kein Assessment verfügbar',
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Lade die ersten Dokumente hoch, um eine automatische Bewertung der Projektqualität und Vollständigkeit zu erhalten.',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else if (hasStructuredData)
              // Strukturierte Darstellung für JSON-Daten
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...keyValues.take(4).map((kv) => Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 120,
                          child: Text(
                            '${kv['key']}:',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            kv['value']!,
                            style: TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
                  if (keyValues.length > 4)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        '... und ${keyValues.length - 4} weitere Einträge',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                ],
              )
            else
              // Fallback für unstrukturierten Text
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _formatAssessmentText(projectAssessment),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: Colors.black87,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
} 