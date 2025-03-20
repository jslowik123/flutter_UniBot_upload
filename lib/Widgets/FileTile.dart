import 'package:flutter/material.dart';

class FileTile extends StatelessWidget {
  final Map<String, String> file;
  final Future<void> Function() deleteFileFunc;

  const FileTile(this.file, this.deleteFileFunc);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(
        Icons.insert_drive_file,
        color: Colors.blue,
      ),
      title: Text(file['name']!),
      subtitle: Text(file['path']!),
      trailing: IconButton(
        icon: const Icon(Icons.delete, color: Colors.red),
        onPressed: deleteFileFunc,
      ),
    );
  }
}