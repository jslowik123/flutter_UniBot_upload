import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../Widgets/ProjectTile.dart';


class ProjectListScreen extends StatefulWidget {
  const ProjectListScreen({super.key});

  @override
  _ProjectListScreenState createState() => _ProjectListScreenState();
}

class _ProjectListScreenState extends State<ProjectListScreen> {
  List<Map<String, dynamic>> projects = [];
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _fetchProjectsFromStorage();
      _isInitialized = true;
    }
  }

  Future<void> _fetchProjectsFromStorage() async {
    try {
      final ref = FirebaseStorage.instance.ref().child('files/');
      final result = await ref.listAll();

      setState(() {
        projects = result.prefixes.map((Reference folderRef) {
          return {
            'name': folderRef.name,
            'id': folderRef.name,
            'files': [],
          };
        }).toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fehler beim Abrufen der Projekte: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _addProject(String projectName) async {
    try {
      final ref = FirebaseStorage.instance.ref().child('files/$projectName/.keep');
      await ref.putString('');

      setState(() {
        projects.add({
          'name': projectName,
          'id': projectName,
          'files': [],
        });
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Projekt $projectName erstellt'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fehler beim Erstellen des Projekts: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _deleteProject(String id) async {
    try {
      final projectIndex = projects.indexWhere((project) => project['id'] == id);
      if (projectIndex == -1) {
        throw Exception('Projekt mit ID $id nicht gefunden');
      }

      final projectName = projects[projectIndex]['name'];
      final ref = FirebaseStorage.instance.ref().child('files/$projectName');

      final result = await ref.listAll();
      for (var fileRef in result.items) {
        await fileRef.delete();
      }

      setState(() {
        projects.removeAt(projectIndex);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Projekt gelöscht'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fehler beim Löschen des Projekts: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _viewProject(BuildContext context, Map<String, dynamic> project) {
    Navigator.of(context).pushNamed('/projectView', arguments: project);
  }

  void _showAddProjectDialog() {
    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Neues Projekt erstellen'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Projektname eingeben'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                _addProject(controller.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Erstellen'),
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
          constraints: BoxConstraints(maxWidth: 800),
          child: ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: projects.length,
            itemBuilder: (context, index) {
              return ProjectTile(projects[index],_viewProject,_deleteProject, );
            },
          ),
        ),
      ),
    );
  }
}