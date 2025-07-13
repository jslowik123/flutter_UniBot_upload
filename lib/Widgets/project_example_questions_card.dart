import 'package:flutter/material.dart';

class ProjectExampleQuestionsCard extends StatelessWidget {
  final Map<String, String> exampleQuestions;
  final bool isLoadingQuestions;
  final VoidCallback? onRefresh;

  const ProjectExampleQuestionsCard({
    super.key,
    required this.exampleQuestions,
    required this.isLoadingQuestions,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    print('DEBUG: ProjectExampleQuestionsCard build - questions: $exampleQuestions, isLoading: $isLoadingQuestions');
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    Icons.help_outline,
                    color: Colors.green[700],
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Beispielfragen für den Chatbot',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.green[700],
                      ),
                    ),
                  ),
                  if (onRefresh != null)
                    IconButton(
                      icon: isLoadingQuestions 
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.green[700]!),
                            ),
                          )
                        : Icon(
                            Icons.refresh,
                            color: Colors.green[700],
                          ),
                      onPressed: isLoadingQuestions ? null : onRefresh,
                      tooltip: 'Neue Beispielfragen laden',
                    ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Content
              if (isLoadingQuestions)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.green[700]!),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Lade Beispielfragen...',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else if (exampleQuestions.containsKey('status') && exampleQuestions['status'] == 'generating')
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.orange[700]!),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Fragen werden generiert...',
                          style: TextStyle(
                            color: Colors.orange[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else if (exampleQuestions.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.grey[600],
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Keine Beispielfragen verfügbar',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (int i = 1; i <= 3; i++)
                      if (exampleQuestions.containsKey('question$i') && 
                          exampleQuestions.containsKey('answer$i'))
                        Container(
                          margin: const EdgeInsets.only(bottom: 16.0),
                          padding: const EdgeInsets.all(12.0),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green[200]!),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: Colors.green[700],
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        '$i',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      exampleQuestions['question$i']!,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.green[800],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Padding(
                                padding: const EdgeInsets.only(left: 32.0),
                                child: Text(
                                  exampleQuestions['answer$i']!,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.green[700],
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
} 