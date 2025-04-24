import 'package:flutter/material.dart';
import '../Widgets/project_tile.dart';
import '../Services/project_service.dart';
import '../Services/snackbar_service.dart';

class ProjectListScreen extends StatefulWidget {
  const ProjectListScreen({super.key});

  @override
  ProjectListScreenState createState() => ProjectListScreenState();
}

class ProjectListScreenState extends State<ProjectListScreen> {
  final ProjectService _projectService = ProjectService();
  final List<Map<String, dynamic>> _projects = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProjects();
  }

  Future<void> _fetchProjects() async {
    try {
      final projects = await _projectService.fetchProjects();
      setState(() {
        _projects.clear();
        _projects.addAll(projects);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      SnackbarService.showError(context, 'Fehler beim Laden der Projekte: $e');
    }
  }

  Future<void> _addProject(String projectName) async {
    try {
      await _projectService.addProject(projectName);
      await _fetchProjects();
      SnackbarService.showSuccess(context, 'Projekt "$projectName" erstellt');
    } catch (e) {
      SnackbarService.showError(
        context,
        'Fehler beim Erstellen des Projekts: $e',
      );
    }
  }

  Future<void> _deleteProject(String projectName) async {
    try {
      await _projectService.deleteProject(projectName);
      await _fetchProjects();
      SnackbarService.showSuccess(context, 'Projekt gelöscht');
    } catch (e) {
      SnackbarService.showError(
        context,
        'Fehler beim Löschen des Projekts: $e',
      );
    }
  }

  void _showDeleteConfirmationDialog(String projectName) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Projekt löschen'),
            content: Text(
              'Möchten Sie das Projekt "$projectName" wirklich löschen?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Abbrechen'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await _deleteProject(projectName);
                },
                child: const Text(
                  'Löschen',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }

  void _viewProject(BuildContext context, Map<String, dynamic> project) {
    Navigator.of(
      context,
    ).pushNamed('/projectView', arguments: {'name': project['name']});
  }

  void _showAddProjectDialog() {
    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Neues Projekt erstellen'),
            content: TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'Projektname eingeben',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Abbrechen'),
              ),
              TextButton(
                onPressed: () async {
                  final name = controller.text.trim();
                  if (name.isNotEmpty) {
                    await _addProject(name);
                    Navigator.pop(context);
                  } else {
                    SnackbarService.showError(
                      context,
                      'Bitte einen Projektname eingeben',
                    );
                  }
                },
                child: const Text('Erstellen'),
              ),
            ],
          ),
    );
  }

  Future<void> _updateProjectName(String oldName, String newName) async {
    try {
      await _projectService.updateProjectName(oldName, newName);
      await _fetchProjects();
      SnackbarService.showSuccess(
        context,
        'Projekt "$newName" wurde umbenannt',
      );
    } catch (e) {
      SnackbarService.showError(
        context,
        'Fehler beim Umbenennen des Projekts: $e',
      );
    }
  }

  Future<void> _editProject(String projectName) async {
    final TextEditingController controller = TextEditingController();
    controller.text = projectName;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Projekt bearbeiten'),
            content: TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'Neuen Projektnamen eingeben',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Abbrechen'),
              ),
              TextButton(
                onPressed: () async {
                  final newName = controller.text.trim();
                  if (newName.isNotEmpty && newName != projectName) {
                    await _updateProjectName(projectName, newName);
                    Navigator.pop(context);
                  } else {
                    SnackbarService.showError(
                      context,
                      'Bitte einen neuen Projektnamen eingeben',
                    );
                  }
                },
                child: const Text('Ändern'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Projekte'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddProjectDialog,
            tooltip: 'Neues Projekt hinzufügen',
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child:
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _projects.isEmpty
                  ? const Center(child: Text('Keine Projekte vorhanden'))
                  : ListView.builder(
                    padding: const EdgeInsets.all(8.0),
                    itemCount: _projects.length,
                    itemBuilder: (context, index) {
                      return ProjectTile(
                        project: _projects[index],
                        viewProjectFunc: _viewProject,
                        deleteProjectFunc: _showDeleteConfirmationDialog,
                        editProjectFunc: _editProject,
                      );
                    },
                  ),
        ),
      ),
    );
  }
}
