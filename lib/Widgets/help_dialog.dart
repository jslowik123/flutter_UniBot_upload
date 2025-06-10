import 'package:flutter/material.dart';
import 'help_content.dart';

class HelpDialog extends StatefulWidget {
  const HelpDialog({super.key});

  @override
  State<HelpDialog> createState() => _HelpDialogState();

  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12.0),
              child: const SizedBox(
                width: 900,
                height: 700,
                child: HelpDialog(),
              ),
            ),
          ),
    );
  }
}

class _HelpDialogState extends State<HelpDialog> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.grey[800],
        elevation: 1,
        title: Text(
          'Hilfe (${_currentPage + 1}/${HelpContent.pages.length})',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: Colors.grey[800],
          ),
        ),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(Icons.close, color: Colors.grey[600]),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: PageView.builder(
        controller: _pageController,
        onPageChanged: (index) => setState(() => _currentPage = index),
        itemCount: HelpContent.pages.length,
        itemBuilder: (context, index) => _buildPage(HelpContent.pages[index]),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildPage(Map<String, dynamic> page) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      child: SingleChildScrollView(
        child: Card(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _getPageIconColor(_currentPage).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getPageIcon(_currentPage),
                        color: _getPageIconColor(_currentPage),
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        page['title'],
                        style: Theme.of(
                          context,
                        ).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                ...page['content'].map<Widget>(
                  (text) => _buildContentItem(text),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getPageIcon(int pageIndex) {
    switch (pageIndex) {
      case 0:
        return Icons.upload_file;
      case 1:
        return Icons.chat_bubble_outline;
      case 2:
        return Icons.tips_and_updates;
      case 3:
        return Icons.help_outline;
      default:
        return Icons.info_outline;
    }
  }

  Color _getPageIconColor(int pageIndex) {
    switch (pageIndex) {
      case 0:
        return Colors.green;
      case 1:
        return Colors.blue;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  Widget _buildContentItem(String text) {
    if (_isQuestion(text)) {
      return _buildQuestionItem(text);
    } else if (_isSectionHeader(text)) {
      return _buildSectionHeader(text);
    } else if (_isBulletPoint(text)) {
      return _buildBulletPoint(text);
    } else {
      return _buildRegularText(text);
    }
  }

  Widget _buildQuestionItem(String text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(width: 4, color: Colors.blue[400]!)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.help_outline, color: Colors.blue[600], size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: Colors.grey[800],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 12),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 16,
          color: Colors.grey[700],
        ),
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    final cleanText = text.substring(2); // Remove "• "
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: Colors.grey[500],
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              cleanText,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegularText(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: TextStyle(fontSize: 14, color: Colors.grey[700], height: 1.6),
      ),
    );
  }

  bool _isQuestion(String text) => text.endsWith('?');
  bool _isSectionHeader(String text) => text.endsWith(':');
  bool _isBulletPoint(String text) => text.startsWith('•');

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ElevatedButton.icon(
            onPressed: _currentPage > 0 ? _previousPage : null,
            icon: const Icon(Icons.arrow_back, size: 18),
            label: const Text('Zurück'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[200],
              foregroundColor: Colors.grey[700],
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          Row(
            children: List.generate(
              HelpContent.pages.length,
              (index) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color:
                      index == _currentPage
                          ? Colors.grey[600]
                          : Colors.grey[300],
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          ElevatedButton.icon(
            onPressed: _nextPageOrClose,
            icon: Icon(
              _isLastPage ? Icons.check : Icons.arrow_forward,
              size: 18,
            ),
            label: Text(_isLastPage ? 'Abschließen' : 'Weiter'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[700],
              foregroundColor: Colors.white,
              elevation: 1,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool get _isLastPage => _currentPage >= HelpContent.pages.length - 1;

  void _previousPage() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _nextPageOrClose() {
    if (_isLastPage) {
      Navigator.pop(context);
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }
}
