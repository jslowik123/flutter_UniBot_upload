import 'package:flutter/material.dart';
import 'help_content.dart';

class HelpDialog {
  void showHelpDialog(context) {
    final PageController pageController = PageController();
    int currentPage = 0;

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 1000,
                    maxHeight: 1000,
                    minHeight: 1000,
                    minWidth: 1000,
                  ),
                  child: AlertDialog(
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Hilfe (${currentPage + 1}/${HelpContent.pages.length})',
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    content: SizedBox(
                      width: 600,
                      height: 500,
                      child: PageView(
                        controller: pageController,
                        onPageChanged: (index) {
                          setState(() => currentPage = index);
                        },
                        children:
                            HelpContent.pages.map((page) {
                              return SingleChildScrollView(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      page['title'],
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    ...page['content'].map<Widget>((text) {
                                      final isBold =
                                          text.endsWith(
                                            ':',
                                          ) || // Section headers
                                          text.endsWith('?') || // Questions
                                          text.startsWith('•'); // Bullet points
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 4,
                                        ),
                                        child: Text(
                                          text,
                                          style: TextStyle(
                                            fontWeight:
                                                isBold
                                                    ? FontWeight.bold
                                                    : FontWeight.normal,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ],
                                ),
                              );
                            }).toList(),
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
                            currentPage < HelpContent.pages.length - 1
                                ? () => pageController.nextPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                )
                                : () => Navigator.pop(context),
                        child: Text(
                          currentPage < HelpContent.pages.length - 1
                              ? 'Weiter'
                              : 'Abschließen',
                        ),
                      ),
                    ],
                  ),
                ),
          ),
    );
  }
}
