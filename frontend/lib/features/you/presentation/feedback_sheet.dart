import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:gym_app/core/theme/app_theme.dart';
import 'package:gym_app/services/api_client.dart';

/// "Help us improve" feedback form, shown as a modal bottom sheet from the
/// You tab. Submissions are only ever reviewed in the Django admin panel —
/// there is no in-app screen that lists them back.
Future<void> showHelpUsImproveSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => const _FeedbackSheet(),
  );
}

class _FeedbackSheet extends StatefulWidget {
  const _FeedbackSheet();

  @override
  State<_FeedbackSheet> createState() => _FeedbackSheetState();
}

class _FeedbackSheetState extends State<_FeedbackSheet> {
  static const _categories = {
    'suggestion': 'Suggestion',
    'bug': 'Report a bug',
    'feature_request': 'Request a feature',
    'other': 'Other',
  };

  final _messageController = TextEditingController();
  String _category = 'suggestion';
  XFile? _attachment;
  Uint8List? _attachmentBytes;
  bool _submitting = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _pickAttachment() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 2000,
      imageQuality: 85,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    setState(() {
      _attachment = picked;
      _attachmentBytes = bytes;
    });
  }

  Future<void> _submit() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please describe what we can improve.')),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      await ApiClient.I.submitFeedback(
        category: _category,
        message: message,
        attachmentBytes: _attachmentBytes,
        attachmentFilename: _attachment?.name,
      );
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thanks! Your feedback was sent.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Couldn't send your feedback. Please try again."),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Help us improve',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          const Text(
            'Suggest something, report a bug, or request a feature — '
            'attach a screenshot if it helps.',
            style: TextStyle(color: AppTheme.mut, fontSize: 13),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _category,
            decoration: const InputDecoration(
              labelText: 'Category',
              border: OutlineInputBorder(),
            ),
            items: _categories.entries
                .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                .toList(),
            onChanged: (v) => setState(() => _category = v ?? _category),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _messageController,
            maxLines: 5,
            minLines: 3,
            decoration: const InputDecoration(
              labelText: 'What can we improve?',
              alignLabelWithHint: true,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: _submitting ? null : _pickAttachment,
                icon: const Icon(Icons.image_outlined),
                label: Text(_attachment == null ? 'Attach image' : 'Change image'),
              ),
              if (_attachment != null) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _attachment!.name,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppTheme.mut, fontSize: 12),
                  ),
                ),
                IconButton(
                  tooltip: 'Remove attachment',
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: _submitting
                      ? null
                      : () => setState(() {
                            _attachment = null;
                            _attachmentBytes = null;
                          }),
                ),
              ],
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Send feedback'),
            ),
          ),
        ],
      ),
    );
  }
}
