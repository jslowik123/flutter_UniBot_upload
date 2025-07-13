import 'package:flutter/material.dart';
import 'file_screen.dart';
import '/Services/project_service.dart';
import '/Services/snackbar_service.dart';
import '../Widgets/help_dialog.dart';
import '../Widgets/help_content.dart';
import '../Widgets/project_overview.dart';

class ProjectManagementScreen extends StatefulWidget {
  const ProjectManagementScreen({super.key});

  @override
  State<ProjectManagementScreen> createState() => _ProjectManagementScreenState();
}

class _ProjectManagementScreenState extends State<ProjectManagementScreen> {
  Map<String, dynamic>? _routeArgs;
  String? _projectName;
  bool _isInitialized = false;
  int _selectedIndex = 0;
  bool _hasShownServerError = false;

  // Notizen-Logik
  final ProjectService _projectService = ProjectService();
  final TextEditingController _projectInfoController = TextEditingController();
  String _initialProjectInfo = '';
  bool _isSavingProjectInfo = false;
  
  // Assessment-Logik
  String _projectAssessment = '';
  bool _isLoadingAssessment = false;

  // Wissensbasis-Logik
  String _projectKnowledge = '';
  bool _isLoadingKnowledge = false;

  // Beispielfragen-Logik
  Map<String, String> _exampleQuestions = {};
  bool _isLoadingExampleQuestions = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _routeArgs = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      _projectName = _routeArgs?['name'];
      print('DEBUG: Project name from route: $_projectName');
      print('DEBUG: Route args: $_routeArgs');
      
      // Alle Felder parallel laden für bessere Performance
      if (_projectName != null) {
        _loadProjectInfo();
        _loadProjectAssessment();
        _loadProjectKnowledge();
        _loadExampleQuestions();
      }
      
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
      print('DEBUG: ProjectInfo loaded: "${info.length} chars - ${info.isEmpty ? 'EMPTY' : info.substring(0, info.length > 50 ? 50 : info.length)}..."');
      _projectInfoController.text = info;
      _initialProjectInfo = info;
      setState(() {});
    } catch (e) {
      _projectInfoController.text = '';
      _initialProjectInfo = '';
      setState(() {});
      // Stille Fehlerbehandlung - andere Felder sollen trotzdem laden
      // Informiere über Server-Probleme nur einmal
      if (mounted && !_hasShownServerError) {
        _hasShownServerError = true;
        SnackbarService.showError(context, 'Verbindung zum Server nicht möglich');
      }
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
      print('DEBUG: ProjectAssessment loaded: "${assessment.length} chars - ${assessment.isEmpty ? 'EMPTY' : assessment.substring(0, assessment.length > 50 ? 50 : assessment.length)}..."');
      _projectAssessment = assessment;
      setState(() {});
    } catch (e) {
      _projectAssessment = '';
      setState(() {});
      // Stille Fehlerbehandlung - andere Felder sollen trotzdem laden
    } finally {
      setState(() => _isLoadingAssessment = false);
    }
  }

  Future<void> _loadProjectKnowledge() async {
    if (_projectName == null) {
      _projectKnowledge = '';
      setState(() {});
      return;
    }
    setState(() => _isLoadingKnowledge = true);
    try {
      final knowledge = await _projectService.getProjectKnowledge(_projectName!);
      print('DEBUG: ProjectKnowledge loaded: "${knowledge.length} chars - ${knowledge.isEmpty ? 'EMPTY' : knowledge.substring(0, knowledge.length > 50 ? 50 : knowledge.length)}..."');
      _projectKnowledge = knowledge;
      setState(() {});
    } catch (e) {
      _projectKnowledge = '';
      setState(() {});
      // Stille Fehlerbehandlung - andere Felder sollen trotzdem laden
    } finally {
      setState(() => _isLoadingKnowledge = false);
    }
  }

  Future<void> _loadExampleQuestions() async {
    if (_projectName == null) {
      _exampleQuestions = {};
      setState(() {});
      return;
    }
    setState(() => _isLoadingExampleQuestions = true);
          try {
        final questions = await _projectService.getExampleQuestions(_projectName!);
        print('DEBUG: ExampleQuestions loaded: $questions');
        
        // Prüfe den Status der Antwort
        if (questions.containsKey('status')) {
          if (questions['status'] == 'generating') {
            _exampleQuestions = {'status': 'generating', 'message': 'Fragen werden generiert'};
          } else {
            // Andere Status oder Fehler
            _exampleQuestions = {};
          }
        } else {
          // Normale Fragen erhalten
          _exampleQuestions = questions;
        }
        setState(() {});
      } catch (e) {
      _exampleQuestions = {};
      setState(() {});
      // Stille Fehlerbehandlung - andere Felder sollen trotzdem laden
    } finally {
      setState(() => _isLoadingExampleQuestions = false);
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

  Future<void> _refreshAssessment() async {
    // Cache leeren um frische Daten zu bekommen
    if (_projectName != null) {
      _projectService.clearProjectCache(_projectName!);
    }
    await _loadProjectInfo();
    await _loadProjectAssessment();
  }

  Future<void> _refreshKnowledge() async {
    // Cache leeren um frische Daten zu bekommen
    if (_projectName != null) {
      _projectService.clearProjectCache(_projectName!);
    }
    await _loadProjectKnowledge();
  }

  Future<void> _refreshExampleQuestions() async {
    if (_projectName == null) return;
    
    // Cache für Beispielfragen leeren um frische Daten zu bekommen
    _projectService.clearExampleQuestionsCache(_projectName!);
    
    setState(() => _isLoadingExampleQuestions = true);
    try {
      // Lade die Beispielfragen neu
      final questions = await _projectService.getExampleQuestions(_projectName!);
      
      // Prüfe den Status der Fragen
      if (questions.containsKey('status') && questions['status'] == 'generating') {
        _exampleQuestions = {'status': 'generating', 'message': 'Fragen werden generiert'};
        SnackbarService.showSuccess(context, 'Beispielfragen werden noch generiert...');
      } else if (questions.isNotEmpty) {
        _exampleQuestions = questions;
        SnackbarService.showSuccess(context, 'Beispielfragen aktualisiert');
      } else {
        _exampleQuestions = {};
        SnackbarService.showSuccess(context, 'Beispielfragen aktualisiert');
      }
      setState(() {});
    } catch (e) {
      _exampleQuestions = {};
      setState(() {});
      SnackbarService.showError(context, 'Fehler beim Aktualisieren der Beispielfragen');
    } finally {
      setState(() => _isLoadingExampleQuestions = false);
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

  Widget _getSelectedScreen() {
    switch (_selectedIndex) {
      case 0:
        print('DEBUG: Building ProjectOverview with:');
        print('  - projectInfoController text: "${_projectInfoController.text}"');
        print('  - initialProjectInfo: "$_initialProjectInfo"');
        print('  - projectAssessment: "${_projectAssessment.length} chars"');
        print('  - projectKnowledge: "${_projectKnowledge.length} chars"');
        print('  - exampleQuestions: $_exampleQuestions');
        return ProjectOverview(
          projectInfoController: _projectInfoController,
          initialProjectInfo: _initialProjectInfo,
          isSavingProjectInfo: _isSavingProjectInfo,
          projectAssessment: _projectAssessment,
          isLoadingAssessment: _isLoadingAssessment,
          onSaveProjectInfo: _saveProjectInfo,
          onRefreshAssessment: _refreshAssessment,
          onShowAssessmentDialog: _showAssessmentDialog,
          projectKnowledge: _projectKnowledge,
          isLoadingKnowledge: _isLoadingKnowledge,
          onRefreshKnowledge: _refreshKnowledge,
          // onNavigateToChatbot entfernt
          exampleQuestions: _exampleQuestions,
          isLoadingExampleQuestions: _isLoadingExampleQuestions,
          onRefreshExampleQuestions: _refreshExampleQuestions,
        );
      case 1:
        return FileScreen();
      // case 2 entfernt (ChatbotTestScreen)
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
              // Chatbot-Test Tab entfernt
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