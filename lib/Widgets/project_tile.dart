import 'package:flutter/material.dart';

class ProjectTile extends StatelessWidget {

  final Map<String, dynamic> project;
  final Function viewProjectFunc;
  final Function deleteProjectFunc;

  const ProjectTile(this.project, this.viewProjectFunc, this.deleteProjectFunc);
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Colors.grey.shade300,
          width: 1.0,
        ),
      ),
      child: ListTile(
        onTap: () => viewProjectFunc(context, project),
        leading: CircleAvatar(
          backgroundColor: Colors.blue.shade100,
          child: const Icon(
            Icons.work,
            color: Colors.blueAccent,
          ),
        ),
        title: Text(
          project['name'],
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: const Text(
          'Projekt Details',
          style: TextStyle(color: Colors.grey),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("${project['name']} bearbeiten")),
                );
              },
              tooltip: 'Projekt bearbeiten',
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.redAccent),
              onPressed: () => deleteProjectFunc(project["id"]),
              tooltip: 'Projekt löschen',
            ),
          ],
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: 8.0,
        ),
      ),
    );
  }
}
