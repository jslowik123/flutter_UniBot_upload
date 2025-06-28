import 'package:flutter/material.dart';
import 'dart:convert';

class ProgressBar extends StatelessWidget {
  final String projectAssessment;
  final VoidCallback? onDetailsPressed;

  const ProgressBar({
    Key? key,
    required this.projectAssessment,
    this.onDetailsPressed,
  }) : super(key: key);

  // Methode zum Extrahieren des Confidence-Werts
  double _extractConfidenceFromAssessment() {
    if (projectAssessment.isEmpty) return 0.0;
    
    try {
      // Versuche JSON zu parsen, falls Assessment JSON-Daten enthält
      if (projectAssessment.contains('{') && projectAssessment.contains('}')) {
        final jsonStart = projectAssessment.indexOf('{');
        final jsonEnd = projectAssessment.lastIndexOf('}') + 1;
        final jsonString = projectAssessment.substring(jsonStart, jsonEnd);
        final Map<String, dynamic> assessmentData = json.decode(jsonString);
        
        // Suche nach confidence-Werten in verschiedenen möglichen Strukturen
        if (assessmentData.containsKey('confidence')) {
          final confidence = assessmentData['confidence'];
          if (confidence is num) {
            return (confidence as num).toDouble().clamp(0.0, 100.0);
          }
        }
        
        // Weitere mögliche Schlüssel für Confidence
        for (String key in ['overall_confidence', 'confidence_score', 'score']) {
          if (assessmentData.containsKey(key)) {
            final value = assessmentData[key];
            if (value is num) {
              return (value as num).toDouble().clamp(0.0, 100.0);
            }
          }
        }
      }
      
      // Fallback: Suche nach Zahlen mit % oder zwischen 0-100 im Text
      final RegExp percentRegex = RegExp(r'(\d+(?:\.\d+)?)\s*%');
      final RegExp numberRegex = RegExp(r'confidence.*?(\d+(?:\.\d+)?)');
      
      final percentMatch = percentRegex.firstMatch(projectAssessment);
      if (percentMatch != null) {
        final value = double.tryParse(percentMatch.group(1) ?? '0');
        if (value != null) return value.clamp(0.0, 100.0);
      }
      
      final numberMatch = numberRegex.firstMatch(projectAssessment.toLowerCase());
      if (numberMatch != null) {
        final value = double.tryParse(numberMatch.group(1) ?? '0');
        if (value != null) return value.clamp(0.0, 100.0);
      }
      
    } catch (e) {
      // Bei Parsing-Fehlern: Versuche trotzdem eine Zahl zu finden
      final RegExp anyNumberRegex = RegExp(r'(\d+(?:\.\d+)?)');
      final matches = anyNumberRegex.allMatches(projectAssessment);
      
      for (final match in matches) {
        final value = double.tryParse(match.group(1) ?? '0');
        if (value != null && value >= 0 && value <= 100) {
          return value;
        }
      }
    }
    
    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final confidence = _extractConfidenceFromAssessment();
    final progressValue = confidence / 100.0;
    
    Color progressColor;
    String confidenceText;
    
    if (confidence >= 80) {
      progressColor = Colors.green;
      confidenceText = 'Hoch';
    } else if (confidence >= 60) {
      progressColor = Colors.orange;
      confidenceText = 'Mittel';
    } else if (confidence >= 30) {
      progressColor = Colors.deepOrange;
      confidenceText = 'Niedrig';
    } else {
      progressColor = Colors.red;
      confidenceText = 'Sehr niedrig';
    }
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.trending_up, color: progressColor),
                SizedBox(width: 8),
                Text(
                  'Vollsändigkeit des Chatbots',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Spacer(),
                Text(
                  '${confidence.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: progressColor,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            LinearProgressIndicator(
              value: progressValue,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              minHeight: 8,
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Vollsändigkeit: $confidenceText',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 