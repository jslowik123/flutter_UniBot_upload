import 'package:flutter/material.dart';
import 'file_screen.dart';
import '/Services/project_service.dart';
import '/Services/snackbar_service.dart';
import '../Widgets/help_dialog.dart';
import '../Widgets/help_content.dart';
import '../Widgets/project_overview.dart';
import 'chatbot_test_screen.dart';

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

  // Wissensbasis-Logik
  String _projectKnowledge = '';
  bool _isLoadingKnowledge = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _routeArgs = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      _projectName = _routeArgs?['name'];
      _loadProjectInfo();
      _loadProjectAssessment();
      _loadProjectKnowledge();
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

  Future<void> _loadProjectKnowledge() async {
    if (_projectName == null) {
      _projectKnowledge = '';
      setState(() {});
      return;
    }
    setState(() => _isLoadingKnowledge = true);
    try {
      final knowledge = await _projectService.getProjectKnowledge(_projectName!);
      _projectKnowledge = knowledge;
      setState(() {});
    } catch (e) {
      _projectKnowledge = '';
      setState(() {});
    } finally {
      setState(() => _isLoadingKnowledge = false);
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

  void _navigateToChatbot() {
    setState(() {
      _selectedIndex = 2; // Index für Chatbot Test Tab
    });
  }

  Widget _getSelectedScreen() {
    switch (_selectedIndex) {
      case 0:
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
          onNavigateToChatbot: _navigateToChatbot,
        );
      case 1:
        return FileScreen();
      case 2:
        return ChatbotTestScreen();
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
              NavigationRailDestination(
                icon: Icon(Icons.chat_outlined),
                selectedIcon: Icon(Icons.chat),
                label: Text('Chatbot Test'),
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