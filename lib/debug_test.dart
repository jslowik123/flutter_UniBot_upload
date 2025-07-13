import 'package:flutter/material.dart';
import 'Services/project_service.dart';
import 'Config/app_config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class DebugTest extends StatefulWidget {
  @override
  _DebugTestState createState() => _DebugTestState();
}

class _DebugTestState extends State<DebugTest> {
  final ProjectService _projectService = ProjectService();
  String _testResults = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _runTests();
  }

  void _runTests() async {
    setState(() {
      _isLoading = true;
      _testResults = 'Running tests...\n';
    });

    // Test 1: API Base URL
    setState(() {
      _testResults += 'API Base URL: ${AppConfig.apiBaseUrl}\n';
    });

    // Test 2: Simple HTTP GET
    try {
      final response = await http.get(Uri.parse('${AppConfig.apiBaseUrl}/'));
      setState(() {
        _testResults += 'Server response: ${response.statusCode}\n';
      });
    } catch (e) {
      setState(() {
        _testResults += 'Server connection error: $e\n';
      });
    }

    // Test 3: Project Info
    try {
      final info = await _projectService.getProjectInfo('test-project');
      setState(() {
        _testResults += 'Project Info: "${info.length} chars"\n';
        _testResults += 'First 100 chars: "${info.length > 100 ? info.substring(0, 100) : info}"\n';
      });
    } catch (e) {
      setState(() {
        _testResults += 'Project Info error: $e\n';
      });
    }

    // Test 4: Project Assessment
    try {
      final assessment = await _projectService.getProjectAssessmentData('test-project');
      setState(() {
        _testResults += 'Project Assessment: "${assessment.length} chars"\n';
      });
    } catch (e) {
      setState(() {
        _testResults += 'Project Assessment error: $e\n';
      });
    }

    // Test 5: Example Questions
    try {
      final questions = await _projectService.getExampleQuestions('test-project');
      setState(() {
        _testResults += 'Example Questions: $questions\n';
      });
    } catch (e) {
      setState(() {
        _testResults += 'Example Questions error: $e\n';
      });
    }

    setState(() {
      _isLoading = false;
      _testResults += '\n--- Tests completed ---';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Debug Test'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _runTests,
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (_isLoading) CircularProgressIndicator(),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  _testResults,
                  style: TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 