import 'package:flutter/material.dart';

class NewFile extends StatefulWidget {
  final String? fileName;
  final Future<void> Function() pickFileFunc;
  final Function(String, {bool? hasTablesOrGraphics, String? pageNumbers}) confirmSelectionFunc;
  final bool filePicked;

  const NewFile({
    super.key,
    required this.fileName,
    required this.pickFileFunc,
    required this.confirmSelectionFunc,
    required this.filePicked,
  });

  @override
  State<NewFile> createState() => _NewFileState();
}

class _NewFileState extends State<NewFile> {
  late TextEditingController _textController;
  late TextEditingController _pageNumbersController;
  bool _hasTablesOrGraphics = false;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
    _pageNumbersController = TextEditingController();
  }

  @override
  void dispose() {
    _textController.dispose();
    _pageNumbersController.dispose();
    super.dispose();
  }

  void _handleConfirmSelection() {
    // Text speichern und an die Callback-Funktion übergeben
    final text = _textController.text;
    final pageNumbers = _hasTablesOrGraphics ? _pageNumbersController.text : null;
    widget.confirmSelectionFunc(
      text, 
      hasTablesOrGraphics: _hasTablesOrGraphics,
      pageNumbers: pageNumbers,
    );
    
    // Textfelder nach dem Bestätigen clearen
    _textController.clear();
    _pageNumbersController.clear();
    // Checkbox zurücksetzen
    setState(() {
      _hasTablesOrGraphics = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: EdgeInsets.all(widget.filePicked ? 24.0 : 16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color.fromRGBO(158, 158, 158, 0.3),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: widget.pickFileFunc,
                icon: const Icon(Icons.upload_file),
                label: const Text('Datei auswählen'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: _handleConfirmSelection,
                icon: const Icon(Icons.check),
                label: const Text('Bestätigen'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  backgroundColor: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(8.0),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              widget.filePicked && widget.fileName != null
                  ? 'Ausgewählte Datei: ${widget.fileName}'
                  : 'Keine Datei ausgewählt',
              style: TextStyle(
                fontSize: 16,
                color: widget.filePicked ? Colors.black87 : Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          // Checkbox erscheint nur wenn eine Datei ausgewählt wurde
          if (widget.filePicked) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Checkbox(
                        value: _hasTablesOrGraphics,
                        onChanged: (bool? value) {
                          setState(() {
                            _hasTablesOrGraphics = value ?? false;
                            if (!_hasTablesOrGraphics) {
                              _pageNumbersController.clear();
                            }
                          });
                        },
                        activeColor: Colors.blue,
                      ),
                      Expanded(
                        child: Text(
                          'Dokument enthält Tabellen, Grafiken oder Diagramme',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.blue[800],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Seitennummern-Eingabefeld erscheint nur wenn Checkbox aktiviert ist
                  if (_hasTablesOrGraphics) ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: _pageNumbersController,
                      decoration: InputDecoration(
                        labelText: 'Seitennummern mit Grafiken/Tabellen',
                        hintText: 'z.B. 1,2,3,4 (nur Zahlen, getrennt durch Kommas)',
                        helperText: 'Geben Sie die Seitennummern ein, auf denen sich Grafiken, Tabellen oder Diagramme befinden',
                        helperMaxLines: 2,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        fillColor: Colors.white,
                        filled: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      style: const TextStyle(fontSize: 14),
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: TextField(
                controller: _textController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Beschreibung oder Notizen...',
                  hintText: 'Geben Sie hier zusätzliche Informationen ein...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  fillColor: Colors.grey[50],
                  filled: true,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
