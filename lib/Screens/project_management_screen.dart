import 'package:flutter/material.dart';
import 'dart:convert';
import 'file_screen.dart';
import '/Services/project_service.dart';
import '/Services/snackbar_service.dart';
import '../Widgets/help_dialog.dart';
import '../Widgets/project_help_content.dart';
import '../Widgets/help_content.dart';

class ProjectManagementScreen extends StatefulWidget {
  const ProjectManagementScreen({Key? key}) : super(key: key);

  @override
  State<ProjectManagementScreen> createState() => _ProjectManagementScreenState();
}

class _ProjectManagementScreenState extends State<ProjectManagementScreen> {
  Map<String, dynamic>? _routeArgs;
  String? _projectName;
  bool _isInitialized = false;
  int _selectedIndex = 0;

  // Notizen-Logik
  final ProjectService _projectService = ProjectService();
  final TextEditingController _projectInfoController = TextEditingController();
  String _initialProjectInfo = '';
  bool _isSavingProjectInfo = false;
  
  // Assessment-Logik
  String _projectAssessment = '';
  bool _isLoadingAssessment = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _routeArgs = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      _projectName = _routeArgs?['name'];
      _loadProjectInfo();
      _loadProjectAssessment();
      _projectInfoController.addListener(_onProjectInfoChanged);
      _isInitialized = true;
    }
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

  Future<void> _loadProjectInfo() async {
    if (_projectName == null) {
      _projectInfoController.text = '';
      _initialProjectInfo = '';
      setState(() {});
      return;
    }
    try {
      final info = await _projectService.getProjectInfo(_projectName!);
      _projectInfoController.text = info;
      _initialProjectInfo = info;
      setState(() {});
    } catch (e) {
      _projectInfoController.text = '';
      _initialProjectInfo = '';
      setState(() {});
    }
  }

  Future<void> _loadProjectAssessment() async {
    if (_projectName == null) {
      _projectAssessment = '';
      setState(() {});
      return;
    }
    setState(() => _isLoadingAssessment = true);
    try {
      final assessment = await _projectService.getProjectAssessmentData(_projectName!);
      _projectAssessment = assessment;
      setState(() {});
    } catch (e) {
      _projectAssessment = '';
      setState(() {});
    } finally {
      setState(() => _isLoadingAssessment = false);
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

  void _showAssessmentDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.analytics, color: Colors.blue),
            SizedBox(width: 8),
            Text('Projekt-Assessment'),
          ],
        ),
        content: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 600,
            maxHeight: 400,
          ),
          child: SingleChildScrollView(
            child: Text(
              _projectAssessment,
              style: TextStyle(fontSize: 14),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Schließen'),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog() {
    // Zeige je nach ausgewähltem Tab den entsprechenden Help-Content
    List<Map<String, dynamic>> helpPages;
    switch (_selectedIndex) {
      case 0: // Übersicht Tab
        helpPages = HelpContent.pages;
        break;
      case 1: // Dateien Tab
        helpPages = HelpContent.pages;
        break;
      default:
        helpPages = HelpContent.pages;
    }
    HelpDialog.show(context, helpPages);
  }

  // Neue Methode zum Extrahieren des Confidence-Werts
  double _extractConfidenceFromAssessment() {
    if (_projectAssessment.isEmpty) return 0.0;
    
    try {
      // Versuche JSON zu parsen, falls Assessment JSON-Daten enthält
      if (_projectAssessment.contains('{') && _projectAssessment.contains('}')) {
        final jsonStart = _projectAssessment.indexOf('{');
        final jsonEnd = _projectAssessment.lastIndexOf('}') + 1;
        final jsonString = _projectAssessment.substring(jsonStart, jsonEnd);
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
      
      final percentMatch = percentRegex.firstMatch(_projectAssessment);
      if (percentMatch != null) {
        final value = double.tryParse(percentMatch.group(1) ?? '0');
        if (value != null) return value.clamp(0.0, 100.0);
      }
      
      final numberMatch = numberRegex.firstMatch(_projectAssessment.toLowerCase());
      if (numberMatch != null) {
        final value = double.tryParse(numberMatch.group(1) ?? '0');
        if (value != null) return value.clamp(0.0, 100.0);
      }
      
    } catch (e) {
      // Bei Parsing-Fehlern: Versuche trotzdem eine Zahl zu finden
      final RegExp anyNumberRegex = RegExp(r'(\d+(?:\.\d+)?)');
      final matches = anyNumberRegex.allMatches(_projectAssessment);
      
      for (final match in matches) {
        final value = double.tryParse(match.group(1) ?? '0');
        if (value != null && value >= 0 && value <= 100) {
          return value;
        }
      }
    }
    
    return 0.0;
  }

  // Widget für den Confidence-Fortschrittsbalken
  Widget _buildConfidenceProgressBar() {
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
                  'Assessment Confidence',
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
                  'Vertrauen: $confidenceText',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                if (_projectAssessment.isNotEmpty)
                  TextButton.icon(
                    onPressed: _showAssessmentDialog,
                    icon: Icon(Icons.info_outline, size: 16),
                    label: Text('Details'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.blue,
                      padding: EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

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
    if (_projectAssessment.isEmpty) return [];
    
    List<Map<String, String>> keyValues = [];
    
    try {
      // Versuche JSON zu parsen
      if (_projectAssessment.contains('{') && _projectAssessment.contains('}')) {
        final jsonStart = _projectAssessment.indexOf('{');
        final jsonEnd = _projectAssessment.lastIndexOf('}') + 1;
        final jsonString = _projectAssessment.substring(jsonStart, jsonEnd);
        final Map<String, dynamic> assessmentData = json.decode(jsonString);
        
        // Wichtige Felder extrahieren
        final importantFields = {
          'confidence': 'Vertrauen',
          'overall_confidence': 'Gesamtvertrauen',
          'status': 'Status',
          'quality': 'Qualität',
          'completeness': 'Vollständigkeit',
          'relevance': 'Relevanz',
          'recommendations': 'Empfehlungen',
          'summary': 'Zusammenfassung',
        };
        
        for (final entry in assessmentData.entries) {
          String displayKey = importantFields[entry.key.toLowerCase()] ?? entry.key;
          String displayValue = entry.value.toString();
          
          // Formatiere spezielle Werte
          if (entry.key.toLowerCase().contains('confidence') && entry.value is num) {
            displayValue = '${(entry.value as num).toStringAsFixed(1)}%';
          }
          
          keyValues.add({
            'key': displayKey,
            'value': displayValue,
          });
        }
      }
    } catch (e) {
      // Fallback: Suche nach Pattern wie "Key: Value"
      final RegExp keyValueRegex = RegExp(r'([A-Za-z\s]+):\s*([^\n]+)', multiLine: true);
      final matches = keyValueRegex.allMatches(_projectAssessment);
      
      for (final match in matches) {
        final key = match.group(1)?.trim() ?? '';
        final value = match.group(2)?.trim() ?? '';
        
        if (key.isNotEmpty && value.isNotEmpty) {
          keyValues.add({
            'key': key,
            'value': value,
          });
        }
      }
    }
    
    return keyValues;
  }

  // Widget für schön formatierte Assessment-Anzeige
  Widget _buildFormattedAssessmentCard() {
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
                 IconButton(
                   onPressed: _isLoadingAssessment ? null : () async {
                     // Cache leeren um frische Daten zu bekommen
                     if (_projectName != null) {
                       _projectService.clearProjectCache(_projectName!);
                     }
                     await _loadProjectInfo();
                     await _loadProjectAssessment();
                   },
                   icon: _isLoadingAssessment 
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
            if (_isLoadingAssessment)
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
            else if (_projectAssessment.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Icon(Icons.analytics_outlined, size: 48, color: Colors.grey[400]),
                      SizedBox(height: 8),
                      Text(
                        'Noch kein Assessment verfügbar',
                        style: TextStyle(color: Colors.grey[600]),
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
                              color: kv['key']!.toLowerCase().contains('vertrauen') ||
                                     kv['key']!.toLowerCase().contains('confidence')
                                  ? Colors.blue[700]
                                  : Colors.black87,
                              fontWeight: kv['key']!.toLowerCase().contains('vertrauen') ||
                                          kv['key']!.toLowerCase().contains('confidence')
                                  ? FontWeight.w600
                                  : FontWeight.normal,
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
                  _formatAssessmentText(_projectAssessment),
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

  Widget _buildOverview() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: Column(
          children: [
            // Projekt-Notizen Card
            Card(
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
            
            // Confidence Progress Bar (nur anzeigen wenn Assessment vorhanden)
            if (_projectAssessment.isNotEmpty && !_isLoadingAssessment)
              _buildConfidenceProgressBar(),
            
            // Schön formatierte Assessment Card
            _buildFormattedAssessmentCard(),
          ],
        ),
      ),
    );
  }

  Widget _getSelectedScreen() {
    switch (_selectedIndex) {
      case 0:
        return _buildOverview();
      case 1:
        return FileScreen();
      default:
        return Center(child: Text('Unbekannter Bereich'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_projectName ?? 'Projekt Dashboard'),
        actions: [
          IconButton(
            icon: Icon(Icons.help_outline),
            onPressed: _showHelpDialog,
            tooltip: 'Hilfe',
          ),
        ],
      ),
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (int index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            labelType: NavigationRailLabelType.all,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: Text('Übersicht'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.insert_drive_file_outlined),
                selectedIcon: Icon(Icons.insert_drive_file),
                label: Text('Dateien'),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          // Hauptbereich
          Expanded(
            child: _getSelectedScreen(),
          ),
        ],
      ),
    );
  }
} 