import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/models.dart';

class QuestionEditorCard extends StatefulWidget {
  final Question? question;
  final int questionNumber;
  final Function(Question) onSave;
  final VoidCallback onDelete;
  final bool isExpanded;
  final VoidCallback onToggleExpand;

  const QuestionEditorCard({
    super.key,
    this.question,
    required this.questionNumber,
    required this.onSave,
    required this.onDelete,
    this.isExpanded = false,
    required this.onToggleExpand,
  });

  @override
  State<QuestionEditorCard> createState() => _QuestionEditorCardState();
}

class _QuestionEditorCardState extends State<QuestionEditorCard> {
  late TextEditingController _questionController;
  late TextEditingController _optionAController;
  late TextEditingController _optionBController;
  late TextEditingController _optionCController;
  late TextEditingController _optionDController;
  String _correctAnswer = 'A';

  @override
  void initState() {
    super.initState();
    _questionController = TextEditingController(text: widget.question?.questionText ?? '');
    _optionAController = TextEditingController(text: widget.question?.optionA ?? '');
    _optionBController = TextEditingController(text: widget.question?.optionB ?? '');
    _optionCController = TextEditingController(text: widget.question?.optionC ?? '');
    _optionDController = TextEditingController(text: widget.question?.optionD ?? '');
    _correctAnswer = widget.question?.correctAnswer ?? 'A';
  }

  @override
  void didUpdateWidget(covariant QuestionEditorCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.question != oldWidget.question) {
      _questionController.text = widget.question?.questionText ?? '';
      _optionAController.text = widget.question?.optionA ?? '';
      _optionBController.text = widget.question?.optionB ?? '';
      _optionCController.text = widget.question?.optionC ?? '';
      _optionDController.text = widget.question?.optionD ?? '';
      _correctAnswer = widget.question?.correctAnswer ?? 'A';
    }
  }

  @override
  void dispose() {
    _questionController.dispose();
    _optionAController.dispose();
    _optionBController.dispose();
    _optionCController.dispose();
    _optionDController.dispose();
    super.dispose();
  }

  bool get _isValid {
    return _questionController.text.trim().isNotEmpty &&
        _optionAController.text.trim().isNotEmpty &&
        _optionBController.text.trim().isNotEmpty &&
        _optionCController.text.trim().isNotEmpty &&
        _optionDController.text.trim().isNotEmpty;
  }

  void _saveQuestion() {
    if (!_isValid) return;

    final question = Question(
      questionId: widget.question?.questionId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      questionText: _questionController.text.trim(),
      optionA: _optionAController.text.trim(),
      optionB: _optionBController.text.trim(),
      optionC: _optionCController.text.trim(),
      optionD: _optionDController.text.trim(),
      correctAnswer: _correctAnswer,
    );
    widget.onSave(question);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.isExpanded ? theme.primaryColor : Colors.grey.shade200,
          width: widget.isExpanded ? 2 : 1,
        ),
        boxShadow: widget.isExpanded
            ? [
                BoxShadow(
                  color: theme.primaryColor.withValues(alpha: 0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Column(
        children: [
          // Header - Always visible
          InkWell(
            onTap: widget.onToggleExpand,
            borderRadius: BorderRadius.vertical(
              top: const Radius.circular(16),
              bottom: Radius.circular(widget.isExpanded ? 0 : 16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: widget.isExpanded
                          ? theme.primaryColor
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '${widget.questionNumber}',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: widget.isExpanded ? Colors.white : Colors.grey.shade600,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _questionController.text.isEmpty
                          ? 'New Question'
                          : _questionController.text,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: _questionController.text.isEmpty
                            ? Colors.grey.shade400
                            : Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (!widget.isExpanded && _isValid)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle, size: 14, color: Colors.green.shade600),
                          const SizedBox(width: 4),
                          Text(
                            'Complete',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.green.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(width: 8),
                  Icon(
                    widget.isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: Colors.grey.shade400,
                  ),
                ],
              ),
            ),
          ),

          // Expandable content
          if (widget.isExpanded)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 1),
                  const SizedBox(height: 16),

                  // Question Text
                  Text(
                    'Question',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _questionController,
                    maxLines: 3,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Enter your question here...',
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Options Section
                  Text(
                    'Options',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap the radio button to mark the correct answer',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 12),

                  _buildOptionField(theme, 'A', _optionAController),
                  const SizedBox(height: 10),
                  _buildOptionField(theme, 'B', _optionBController),
                  const SizedBox(height: 10),
                  _buildOptionField(theme, 'C', _optionCController),
                  const SizedBox(height: 10),
                  _buildOptionField(theme, 'D', _optionDController),

                  const SizedBox(height: 20),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: widget.onDelete,
                          icon: const Icon(Icons.delete_outline, size: 18),
                          label: const Text('Delete'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: _isValid ? _saveQuestion : null,
                          icon: const Icon(Icons.check_rounded, size: 18),
                          label: const Text('Save Question'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            disabledBackgroundColor: Colors.grey.shade300,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 200.ms),
        ],
      ),
    );
  }

  Widget _buildOptionField(ThemeData theme, String label, TextEditingController controller) {
    final isCorrect = _correctAnswer == label;

    return Row(
      children: [
        // Radio button for correct answer
        GestureDetector(
          onTap: () => setState(() => _correctAnswer = label),
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isCorrect ? Colors.green : Colors.grey.shade300,
                width: 2,
              ),
              color: isCorrect ? Colors.green : Colors.transparent,
            ),
            child: isCorrect
                ? const Icon(Icons.check, size: 14, color: Colors.white)
                : null,
          ),
        ),
        const SizedBox(width: 12),

        // Option label
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: isCorrect ? Colors.green.shade50 : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Center(
            child: Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                color: isCorrect ? Colors.green : Colors.grey.shade600,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Text field
        Expanded(
          child: TextField(
            controller: controller,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Option $label',
              filled: true,
              fillColor: isCorrect ? Colors.green.shade50 : Colors.grey.shade50,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: isCorrect ? Colors.green.shade200 : Colors.transparent,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: isCorrect ? Colors.green.shade200 : Colors.transparent,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: isCorrect ? Colors.green : theme.primaryColor,
                  width: 2,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
