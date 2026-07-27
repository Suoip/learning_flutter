import 'package:flutter/material.dart';

import '../../resources_and_services/educator_logic.dart';

/// Create/edit form for one educator video entry. Null [video] = create
/// mode; non-null = edit mode (adds a delete action). This is metadata-only
/// - title, description, and a free-text duration-label placeholder like
/// "12:34" - no real video file upload exists or is planned yet.
class EducatorVideoFormPage extends StatefulWidget {
  const EducatorVideoFormPage({super.key, this.video});

  final EducatorVideoItem? video;

  @override
  State<EducatorVideoFormPage> createState() => _EducatorVideoFormPageState();
}

class _EducatorVideoFormPageState extends State<EducatorVideoFormPage> {
  final EducatorLogic _logic = EducatorLogic();
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _durationController;

  bool _saving = false;
  bool _deleting = false;

  bool get _isEditing => widget.video != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.video?.title ?? '');
    _descriptionController =
        TextEditingController(text: widget.video?.description ?? '');
    _durationController =
        TextEditingController(text: widget.video?.durationLabel ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || _deleting) return;
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) return;

    setState(() => _saving = true);

    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    final durationLabel = _durationController.text.trim();

    try {
      if (_isEditing) {
        await _logic.updateVideo(
          videoId: widget.video!.id,
          title: title,
          description: description,
          durationLabel: durationLabel.isEmpty ? null : durationLabel,
        );
      } else {
        await _logic.createVideo(
          title: title,
          description: description,
          durationLabel: durationLabel.isEmpty ? null : durationLabel,
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            EducatorLogic.userMessageForError(
              error,
              fallback: 'Could not save this video right now.',
            ),
          ),
        ),
      );
    }
  }

  Future<void> _confirmAndDelete() async {
    if (_saving || _deleting || !_isEditing) return;

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Video'),
          content: const Text('Are you sure you want to delete this video?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) return;

    setState(() => _deleting = true);

    try {
      await _logic.deleteVideo(widget.video!.id);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _deleting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            EducatorLogic.userMessageForError(
              error,
              fallback: 'Could not delete this video right now.',
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final busy = _saving || _deleting;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Video' : 'New Video'),
        actions: [
          if (_isEditing)
            IconButton(
              tooltip: 'Delete',
              onPressed: busy ? null : _confirmAndDelete,
              icon: _deleting
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.delete_outline_rounded),
            ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilledButton.icon(
              onPressed: busy ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check_rounded),
              label: const Text('Save'),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _titleController,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'Title',
                    hintText: 'e.g. Dart Null Safety in 12 Minutes',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  validator: (value) {
                    if ((value ?? '').trim().isEmpty) {
                      return 'Title is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _descriptionController,
                  minLines: 4,
                  maxLines: 10,
                  textInputAction: TextInputAction.newline,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    hintText: 'What will viewers learn from this video?',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _durationController,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    labelText: 'Duration (optional)',
                    hintText: 'e.g. 12:34',
                    prefixIcon: const Icon(Icons.timer_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'This is metadata only - no video file is uploaded yet.',
                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
