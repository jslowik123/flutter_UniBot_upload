import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: LLMInterface(),
    );
  }
}

class LLMInterface extends StatefulWidget {
  @override
  _LLMInterfaceState createState() => _LLMInterfaceState();
}

class _LLMInterfaceState extends State<LLMInterface> {
  final TextEditingController _controller = TextEditingController();
  String _output = '';

  Future<void> _generateText() async {
    final prompt = _controller.text;
    if (prompt.isEmpty) return;

    try {
      final response = await http.post(
        Uri.parse('http://localhost:8000/generate'), // Ersetze mit deiner API-URL
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'prompt': prompt}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _output = data['text'];
        });
      } else {
        setState(() {
          _output = 'Fehler: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _output = 'Fehler: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('LLM App')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(labelText: 'Eingabe'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _generateText,
              child: Text('Generieren'),
            ),
            SizedBox(height: 20),
            Text(
              'Antwort: $_output',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}