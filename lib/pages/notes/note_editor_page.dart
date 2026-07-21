import 'package:flutter/material.dart';

import '../../resources_and_services/notes_logic.dart';

class NoteEditorPage extends StatefulWidget {
  const NoteEditorPage({super.key, required this.note});

  final NoteItem note;

  @override
  State<NoteEditorPage> createState() => _NoteEditorPageState();
}

class _NoteEditorPageState extends State<NoteEditorPage> {
  final NotesLogic _logic = NotesLogic();

  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  bool _saving = false;
  bool _deleting = false;
  bool _hasSavedOnce = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note.title);
    _contentController = TextEditingController(text: widget.note.content);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;

    final title = _titleController.text.trim();
    final content = _contentController.text;

    if (title.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Title cannot be empty.')),
        );
      }
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      await _logic.updateNote(
          noteId: widget.note.id, title: title, content: content);

      _hasSavedOnce = true;
      if (!mounted) return;
      setState(() {
        _saving = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            NotesLogic.userMessageForError(
              error,
              fallback: 'Could not save note right now.',
            ),
          ),
        ),
      );
    }
  }

  Future<bool> _onWillPop() async {
    await _save();
    return true;
  }

  Future<void> _confirmAndDelete() async {
    if (_deleting) return;

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Note'),
          content: const Text('Are you sure you want to delete this note?'),
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

    setState(() {
      _deleting = true;
    });

    try {
      await _logic.deleteNote(widget.note.id);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _deleting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            NotesLogic.userMessageForError(
              error,
              fallback: 'Could not delete note right now.',
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _onWillPop();
      },
      child: Scaffold(
        backgroundColor: cs.surfaceContainerLowest,
        appBar: AppBar(
          title: const Text('Edit Note'),
          scrolledUnderElevation: 0,
          actions: [
            IconButton(
              tooltip: 'Delete',
              onPressed: (_saving || _deleting) ? null : _confirmAndDelete,
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
                onPressed: (_saving || _deleting) ? null : _save,
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
        body: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Container(
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(22),
              border:
                  Border.all(color: cs.outlineVariant.withValues(alpha: 0.55)),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
              child: Column(
                children: [
                  TextField(
                    controller: _titleController,
                    style: const TextStyle(
                        fontSize: 28, fontWeight: FontWeight.w700),
                    decoration: InputDecoration(
                      hintText: 'Title',
                      border: InputBorder.none,
                      hintStyle: TextStyle(color: cs.onSurfaceVariant),
                    ),
                  ),
                  Divider(height: 1, color: cs.outlineVariant),
                  const SizedBox(height: 8),
                  Expanded(
                    child: TextField(
                      controller: _contentController,
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Start writing...',
                        hintStyle: TextStyle(color: cs.onSurfaceVariant),
                      ),
                    ),
                  ),
                  if (_hasSavedOnce)
                    Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: cs.secondaryContainer,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'Saved',
                          style: TextStyle(
                            color: cs.onSecondaryContainer,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
