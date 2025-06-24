import 'package:flutter/material.dart';

class NewProjectScreen extends StatefulWidget {
  final Future<void> Function(String) onProjectCreated;
  const NewProjectScreen({Key? key, required this.onProjectCreated}) : super(key: key);

  @override
  State<NewProjectScreen> createState() => _NewProjectScreenState();
}

class _NewProjectScreenState extends State<NewProjectScreen> {
  int _currentStep = 0;
  final TextEditingController nameController = TextEditingController();
  final TextEditingController customCategoryController = TextEditingController();
  final List<String> categories = [
    'Informatik',
    'Wirtschaft',
    'Psychologie',
    'Medizin',
    'Sonstiges (eigene Kategorie eingeben)'
  ];
  String selectedCategory = 'Informatik';
  bool showCustomCategory = false;
  bool _dialogShown = false;

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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Neues Projekt erstellen'),
                  IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: 'Abbrechen',
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
              content: SizedBox(
                width: 350,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_currentStep == 0) ...[
                      const Text('Seite 1: Kategorie wählen (Platzhalter)'),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: selectedCategory,
                        items: categories.map((cat) => DropdownMenuItem(
                          value: cat,
                          child: Text(cat),
                        )).toList(),
                        onChanged: (value) {
                          setDialogState(() {
                            selectedCategory = value!;
                            showCustomCategory = value == categories.last;
                          });
                        },
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                      if (showCustomCategory) ...[
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: customCategoryController,
                          decoration: const InputDecoration(
                            labelText: 'Eigene Kategorie',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                    ] else if (_currentStep == 1) ...[
                      const Text('Seite 2: Projektnamen eingeben (Platzhalter)'),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          hintText: 'z.B. "Bachelorarbeit 2024"',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ] else if (_currentStep == 2) ...[
                      const Text('Seite 3: Zusammenfassung (Platzhalter)'),
                      const SizedBox(height: 16),
                      Text('Kategorie: ' + (showCustomCategory ? customCategoryController.text : selectedCategory)),
                      Text('Projektname: ' + nameController.text),
                    ],
                  ],
                ),
              ),
              actions: [
                if (_currentStep > 0)
                  TextButton(
                    onPressed: () {
                      setDialogState(() {
                        _currentStep--;
                      });
                    },
                    child: const Text('Zurück'),
                  ),
                if (_currentStep < 2)
                  ElevatedButton(
                    onPressed: () {
                      setDialogState(() {
                        _currentStep++;
                      });
                    },
                    child: const Text('Weiter'),
                  ),
                if (_currentStep == 2)
                  ElevatedButton(
                    onPressed: () async {
                      final name = nameController.text.trim();
                      String category = showCustomCategory ? customCategoryController.text.trim() : selectedCategory;
                      if (name.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Bitte einen Projektnamen eingeben'), backgroundColor: Colors.red),
                        );
                        return;
                      }
                      if (showCustomCategory && category.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Bitte eine eigene Kategorie eingeben'), backgroundColor: Colors.red),
                        );
                        return;
                      }
                      await widget.onProjectCreated('$category - $name');
                      Navigator.of(context).pop(); // Dialog
                      Navigator.of(context).pop(); // Seite
                    },
                    child: const Text('Erstellen'),
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