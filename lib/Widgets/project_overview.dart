import 'package:flutter/material.dart';
import 'project_notes_card.dart';
import 'progress_bar.dart';
import 'project_assessment_card.dart';
import 'project_knowledge_card.dart';
import 'project_example_questions_card.dart';

class ProjectOverview extends StatelessWidget {
  final TextEditingController projectInfoController;
  final String initialProjectInfo;
  final bool isSavingProjectInfo;
  final String projectAssessment;
  final bool isLoadingAssessment;
  final VoidCallback? onSaveProjectInfo;
  final VoidCallback? onRefreshAssessment;
  final VoidCallback? onShowAssessmentDialog;
  final String projectKnowledge;
  final bool isLoadingKnowledge;
  final VoidCallback? onRefreshKnowledge;
  final Map<String, String> exampleQuestions;
  final bool isLoadingExampleQuestions;
  final VoidCallback? onRefreshExampleQuestions;

  const ProjectOverview({
    super.key,
    required this.projectInfoController,
    required this.initialProjectInfo,
    required this.isSavingProjectInfo,
    required this.projectAssessment,
    required this.isLoadingAssessment,
    this.onSaveProjectInfo,
    this.onRefreshAssessment,
    this.onShowAssessmentDialog,
    required this.projectKnowledge,
    required this.isLoadingKnowledge,
    this.onRefreshKnowledge,
    required this.exampleQuestions,
    required this.isLoadingExampleQuestions,
    this.onRefreshExampleQuestions,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Projekt-Notizen Card
              ProjectNotesCard(
                controller: projectInfoController,
                initialProjectInfo: initialProjectInfo,
                isSavingProjectInfo: isSavingProjectInfo,
                onSave: onSaveProjectInfo,
              ),
              
              // Confidence Progress Bar (immer anzeigen)
              ProgressBar(
                projectAssessment: projectAssessment,
                onDetailsPressed: onShowAssessmentDialog,
                isLoading: isLoadingAssessment,
              ),
              
              // Schön formatierte Assessment Card
              ProjectAssessmentCard(
                projectAssessment: projectAssessment,
                isLoadingAssessment: isLoadingAssessment,
                onRefresh: onRefreshAssessment,
              ),

              // Schön formatierte Wissensbasis Card
              ProjectKnowledgeCard(
                projectKnowledge: projectKnowledge,
                isLoadingKnowledge: isLoadingKnowledge,
                onRefreshKnowledge: onRefreshKnowledge,
                projectAssessment: projectAssessment,
              ),

              // Beispielfragen Card
              ProjectExampleQuestionsCard(
                exampleQuestions: exampleQuestions,
                isLoadingQuestions: isLoadingExampleQuestions,
                onRefresh: onRefreshExampleQuestions,
              ),
            ],
          ),
        ),
      ),
    );
  }
} 