import 'package:flutter/material.dart';
import 'file_screen.dart';
import '/Services/project_service.dart';
import '/Services/snackbar_service.dart';

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
            // Assessment ListTile Card
            Card(
              margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 0),
              elevation: 2,
              child: ListTile(
                leading: Icon(Icons.analytics, color: Colors.blue),
                title: Text(
                  'Projekt-Assessment',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                subtitle: _isLoadingAssessment
                    ? Row(
                        children: [
                          SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                          SizedBox(width: 8),
                          Text('Lade Assessment...'),
                        ],
                      )
                    : _projectAssessment.isEmpty
                        ? Text('Noch kein Assessment verfügbar')
                        : Text(
                            _projectAssessment,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                trailing: _projectAssessment.isNotEmpty
                    ? Icon(Icons.expand_more, color: Colors.grey)
                    : null,
                onTap: _projectAssessment.isNotEmpty
                    ? () => _showAssessmentDialog()
                    : null,
              ),
            ),
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