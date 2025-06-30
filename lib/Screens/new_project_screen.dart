import 'package:flutter/material.dart';

class NewProjectScreen extends StatefulWidget {
  final Future<void> Function(String, String) onProjectCreated;
  const NewProjectScreen({super.key, required this.onProjectCreated});

  @override
  State<NewProjectScreen> createState() => _NewProjectScreenState();
}

class _NewProjectScreenState extends State<NewProjectScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController goalsController = TextEditingController();
  bool _dialogShown = false;
  bool _isCreating = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_dialogShown) {
      _dialogShown = true;
      Future.delayed(Duration.zero, _showDialog);
    }
  }

  void _showDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.add_circle_outline, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('Neues Projekt erstellen'),
                  Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: 'Abbrechen',
                    onPressed: _isCreating ? null : () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
              content: SizedBox(
                width: 500,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Erstelle ein neues Projekt für deine Dokumente und den Chatbot.',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    SizedBox(height: 20),
                    
                    // Projektname
                    Text(
                      'Projektname',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    SizedBox(height: 8),
                    TextFormField(
                      controller: nameController,
                      decoration: InputDecoration(
                        hintText: 'z.B. "Master Wirtschaftsinformatik", "Fakultät WiWi"',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.folder_outlined),
                      ),
                      enabled: !_isCreating,
                    ),
                    SizedBox(height: 20),
                    
                    // Chatbot-Ziele
                    Row(
                      children: [
                        Text(
                          'Projekt-Notizen für den Chatbot',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        SizedBox(width: 8),
                        Tooltip(
                          message: 'Hier kannst du wichtige Hinweise, Ziele oder Kontext für dieses Projekt eintragen. Diese Infos benötigt der Chatbot um die bestmögliche Antwort zu geben.',
                          child: Icon(Icons.info_outline, size: 18, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    TextFormField(
                      controller: goalsController,
                      minLines: 2,
                      maxLines: 6,
                      decoration: InputDecoration(
                        hintText: 'z.B. "Das ist der Chatbot für den Bachelor und Master in Informatik"',
                        border: OutlineInputBorder(),
                      ),
                      enabled: !_isCreating,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: _isCreating ? null : () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pop();
                  },
                  child: Text('Abbrechen'),
                ),
                ElevatedButton.icon(
                  onPressed: _isCreating ? null : () async {
                    final name = nameController.text.trim();
                    final goals = goalsController.text.trim();
                    
                    if (name.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Bitte einen Projektnamen eingeben'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    
                                         if (goals.isEmpty) {
                       ScaffoldMessenger.of(context).showSnackBar(
                         const SnackBar(
                           content: Text('Bitte die Projekt-Notizen eingeben'),
                           backgroundColor: Colors.red,
                         ),
                       );
                       return;
                     }
                    
                    setDialogState(() {
                      _isCreating = true;
                    });
                    
                                         try {
                       await widget.onProjectCreated(name, goals);
                       Navigator.of(context).pop(); // Dialog
                       Navigator.of(context).pop(); // Seite
                       
                       // Projekt direkt öffnen
                       Navigator.of(context).pushNamed('/projectView', arguments: {'name': name});
                     } catch (e) {
                      setDialogState(() {
                        _isCreating = false;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Fehler beim Erstellen: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  icon: _isCreating 
                    ? SizedBox(
                        width: 16, 
                        height: 16, 
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
                      )
                    : Icon(Icons.add),
                  label: Text(_isCreating ? 'Erstelle...' : 'Projekt erstellen'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Leere Seite, Dialog wird automatisch angezeigt
    return const Scaffold(
      backgroundColor: Colors.transparent,
      body: SizedBox.shrink(),
    );
  }
} 