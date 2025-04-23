import 'package:flutter/material.dart';

class HelpDialog {
  void showHelpDialog(context) {
    final PageController pageController = PageController();
    int currentPage = 0;

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Hilfe (${currentPage + 1}/3)'),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  content: SizedBox(
                    width: double.maxFinite,
                    child: PageView(
                      controller: pageController,
                      onPageChanged: (index) {
                        setState(() => currentPage = index);
                      },
                      children: const [
                        // Erste Seite
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Dateien hochladen',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text('1. Wählen Sie eine PDF-Datei aus'),
                            Text('2. Bestätigen Sie die Auswahl'),
                            Text('3. Die Datei wird automatisch hochgeladen'),
                          ],
                        ),
                        // Zweite Seite
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Dateiverwaltung',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text('• Dateien werden in der Liste angezeigt'),
                            Text('• Löschen über das Mülleimer-Symbol'),
                            Text(
                              '• Alle Dateien werden im Projekt gespeichert',
                            ),
                          ],
                        ),
                        // Dritte Seite
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Zusätzliche Funktionen',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text('• Automatische Verarbeitung der PDFs'),
                            Text('• Einfache Navigation zwischen Projekten'),
                            Text('• Schnelle Suche in allen Dokumenten'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed:
                          currentPage > 0
                              ? () => pageController.previousPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              )
                              : null,
                      child: const Text('Zurück'),
                    ),
                    TextButton(
                      onPressed:
                          currentPage < 2
                              ? () => pageController.nextPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              )
                              : () => Navigator.pop(context),
                      child: Text(currentPage < 2 ? 'Weiter' : 'Abschließen'),
                    ),
                  ],
                ),
          ),
    );
  }
}
