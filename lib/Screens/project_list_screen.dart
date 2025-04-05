import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart'; // Statt Storage
import '../Widgets/project_tile.dart';

class ProjectListScreen extends StatefulWidget {
  const ProjectListScreen({super.key});

  @override
  _ProjectListScreenState createState() => _ProjectListScreenState();
}

class _ProjectListScreenState extends State<ProjectListScreen> {
  final DatabaseReference _db = FirebaseDatabase.instance.ref(); // Realtime DB Referenz
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
      _fetchProjectsFromDatabase(); // Anpassung: von Storage zu Database
      _isInitialized = true;
    }
  }

  // Projekte aus der Realtime Database laden
  Future<void> _fetchProjectsFromDatabase() async {
    try {
      final snapshot = await _db.child('files').get(); // Holt alle Projekte unter 'files'
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        setState(() {
          projects = data.entries.map((entry) {
            return {
              'name': entry.key.toString(),
              'id': entry.key.toString(),
              'files': [], // Dateien werden ggf. separat geladen
            };
          }).toList();
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fehler beim Abrufen der Projekte: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Neues Projekt in der Realtime Database anlegen
  Future<void> _addProject(String projectName) async {
    try {
      final path = 'files/$projectName';
      await _db.child(path).set({}); // Leeren Knoten erstellen

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

  // Projekt und alle untergeordneten Dateien aus der Realtime Database löschen
  Future<void> _deleteProject(String id) async {
    try {
      await _db.child('files/$id').remove(); // Projektknoten komplett löschen

      setState(() {
        projects.removeWhere((project) => project['id'] == id);
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
                _addProject(controller.text.trim());
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
          constraints: const BoxConstraints(maxWidth: 800),
          child: ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: projects.length,
            itemBuilder: (context, index) {
              return ProjectTile(
                projects[index],
                _viewProject,
                _deleteProject,
              );
            },
          ),
        ),
      ),
    );
  }
}
