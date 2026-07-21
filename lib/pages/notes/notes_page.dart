import 'package:flutter/material.dart';

import '../../resources_and_services/notes_logic.dart';
import 'note_editor_page.dart';
import 'notes_activation_required_page.dart';
import 'notes_auth_page.dart';
import 'notes_profile_page.dart';
import 'notes_social_page.dart';
import 'profile_avatar.dart';

class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  final NotesLogic _logic = NotesLogic();
  final TextEditingController _searchController = TextEditingController();

  List<NoteItem> _notes = [];
  UserProfile? _profile;
  Set<String> _publishedNoteIds = {};
  int _pendingRequestsCount = 0;
  bool _loadingNotes = true;
  bool _loadingProfile = true;
  String? _notesError;
  String _searchQuery = '';
  NoteQuickFilter _activeFilter = NoteQuickFilter.all;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
    _bootstrapForCurrentUser();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _bootstrapForCurrentUser() async {
    final user = _logic.currentUser;
    if (user != null && !NotesLogic.isUserEmailConfirmed(user)) {
      await _logout();
      return;
    }

    await Future.wait([
      _loadProfile(),
      _loadNotes(),
      _loadPendingRequestsBadge(),
    ]);
  }

  Future<void> _loadNotes() async {
    final user = _logic.currentUser;
    if (user == null) {
      setState(() {
        _notes = [];
        _profile = null;
        _loadingNotes = false;
        _loadingProfile = false;
      });
      return;
    }

    setState(() {
      _loadingNotes = true;
      _notesError = null;
    });

    try {
      final parsed = await _logic.fetchNotesForCurrentUser();

      if (!mounted) return;
      setState(() {
        _notes = parsed;
        _loadingNotes = false;
      });
      await _loadPublishedNotes();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadingNotes = false;
        _notesError = _friendly(error, fallback: 'Could not load your notes.');
      });
    }
  }

  Future<void> _loadProfile() async {
    final user = _logic.currentUser;
    if (user == null) {
      if (!mounted) return;
      setState(() {
        _profile = null;
        _loadingProfile = false;
      });
      return;
    }

    if (mounted) {
      setState(() {
        _loadingProfile = true;
      });
    }

    try {
      final profile = await _logic.fetchCurrentProfile();
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _loadingProfile = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _profile = null;
        _loadingProfile = false;
      });
    }
  }

  Future<void> _onAuthenticated() async {
    final user = _logic.currentUser;
    if (!NotesLogic.isUserEmailConfirmed(user)) {
      await _logic.signOut();
      throw Exception(NotesLogic.activationRequiredMessage);
    }

    await Future.wait([
      _loadNotes(),
      _loadProfile(),
      _loadPendingRequestsBadge(),
      _loadPublishedNotes(),
    ]);
  }

  String _friendly(
    Object error, {
    String fallback = 'Something went wrong. Please try again.',
  }) {
    return NotesLogic.userMessageForError(error, fallback: fallback);
  }

  Future<void> _loadPendingRequestsBadge() async {
    try {
      final count = await _logic.fetchIncomingRequestCount();
      if (!mounted) return;
      setState(() {
        _pendingRequestsCount = count;
      });
    } catch (_) {}
  }

  Future<void> _loadPublishedNotes() async {
    try {
      final ids = await _logic.fetchPublishedNoteIdsForCurrentUser();
      if (!mounted) return;
      setState(() {
        _publishedNoteIds = ids;
      });
    } catch (_) {}
  }

  Future<void> _openSocialPage() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const NotesSocialPage()),
    );
    await _loadPendingRequestsBadge();
    await _loadPublishedNotes();
  }

  Future<void> _openProfile() async {
    final updatedProfile = await Navigator.of(context).push<UserProfile>(
      MaterialPageRoute(
        builder: (_) => const NotesProfilePage(),
      ),
    );

    if (!mounted || updatedProfile == null) return;
    setState(() {
      _profile = updatedProfile;
    });
  }

  List<NoteItem> get _filteredNotes {
    return _logic.filterNotes(
      notes: _notes,
      searchQuery: _searchQuery,
      filter: _activeFilter,
    );
  }

  Future<void> _createAndOpenNote() async {
    final title = await _showCreateNoteDialog();
    if (!mounted || title == null || title.trim().isEmpty) return;

    final user = _logic.currentUser;
    if (user == null) return;

    try {
      final note = await _logic.createNote(title.trim());

      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => NoteEditorPage(note: note),
        ),
      );
      await _loadNotes();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text(_friendly(error, fallback: 'Could not create note.'))),
      );
    }
  }

  Future<void> _togglePin(NoteItem note) async {
    try {
      await _logic.togglePin(note);
      await _loadNotes();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(_friendly(error, fallback: 'Could not update pin.'))),
      );
    }
  }

  Future<void> _toggleFavorite(NoteItem note) async {
    try {
      await _logic.toggleFavorite(note);
      await _loadNotes();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(_friendly(error, fallback: 'Could not update favorite.')),
        ),
      );
    }
  }

  Future<void> _togglePublish(NoteItem note) async {
    final published = _publishedNoteIds.contains(note.id);
    try {
      if (published) {
        await _logic.unpublishNoteFromFriends(note.id);
      } else {
        await _logic.publishNoteToFriends(note);
      }
      await _loadPublishedNotes();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            published
                ? 'Note removed from your friends feed.'
                : 'Note published to your friends feed.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _friendly(error, fallback: 'Could not update sharing right now.'),
          ),
        ),
      );
    }
  }

  Future<void> _deleteNote(NoteItem note) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Note'),
          content:
              Text('Delete "${note.title}"? This action cannot be undone.'),
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

    try {
      await _logic.deleteNote(note.id);
      await _loadNotes();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Note deleted')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text(_friendly(error, fallback: 'Could not delete note.'))),
      );
    }
  }

  Future<String?> _showCreateNoteDialog() async {
    String draftTitle = '';
    final value = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('New Note'),
          content: TextField(
            autofocus: true,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              labelText: 'Title',
              hintText: 'Enter note title',
            ),
            onChanged: (value) {
              draftTitle = value;
            },
            onSubmitted: (value) => Navigator.of(context).pop(value),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(draftTitle),
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
    return value;
  }

  Future<void> _openNote(NoteItem note) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NoteEditorPage(note: note),
      ),
    );
    await _loadNotes();
  }

  Future<void> _logout() async {
    await _logic.signOut();
    if (!mounted) return;
    setState(() {
      _notes = [];
      _profile = null;
      _publishedNoteIds = {};
      _pendingRequestsCount = 0;
      _searchController.clear();
      _loadingNotes = false;
      _loadingProfile = false;
      _notesError = null;
    });
  }

  Widget _filterChip({
    required NoteQuickFilter filter,
    required String label,
    required IconData icon,
  }) {
    final selected = _activeFilter == filter;
    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
      selected: selected,
      onSelected: (_) {
        setState(() {
          _activeFilter = filter;
        });
      },
    );
  }

  Widget _buildNotesBody(List<NoteItem> notes) {
    if (_loadingNotes) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_notesError != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            color: Colors.red.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Failed to load notes:\n$_notesError',
                style: TextStyle(color: Colors.red.shade800),
              ),
            ),
          ),
        ],
      );
    }

    if (notes.isEmpty) {
      final cs = Theme.of(context).colorScheme;
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 60, 20, 120),
        children: [
          Card(
            elevation: 0,
            color: cs.surfaceContainerHighest,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
            child: const Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(Icons.sticky_note_2_outlined, size: 40),
                  SizedBox(height: 12),
                  Text(
                    'No notes yet',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Create your first note to get started.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 120),
      itemCount: notes.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final note = notes[index];
        final preview = note.content.trim().isEmpty
            ? 'No additional text'
            : note.content.trim().replaceAll('\n', ' ');
        final updatedText = NotesLogic.formatUpdatedTime(note.updatedAt);
        final isPublished = _publishedNoteIds.contains(note.id);
        final cs = Theme.of(context).colorScheme;

        return Dismissible(
          key: ValueKey(note.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.red.shade400,
              borderRadius: BorderRadius.circular(18),
            ),
            child:
                const Icon(Icons.delete_outline_rounded, color: Colors.white),
          ),
          confirmDismiss: (_) async {
            await _deleteNote(note);
            return false;
          },
          child: Card(
            elevation: 0,
            color: cs.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side:
                  BorderSide(color: cs.outlineVariant.withValues(alpha: 0.55)),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => _openNote(note),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              if (note.isPinned) ...[
                                const Icon(
                                  Icons.push_pin_rounded,
                                  size: 16,
                                  color: Colors.deepOrange,
                                ),
                                const SizedBox(width: 6),
                              ],
                              Expanded(
                                child: Text(
                                  note.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: note.isFavorite ? 'Unfavorite' : 'Favorite',
                          onPressed: () => _toggleFavorite(note),
                          icon: Icon(
                            note.isFavorite
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            color: note.isFavorite
                                ? Colors.amber.shade700
                                : cs.onSurfaceVariant,
                          ),
                        ),
                        IconButton(
                          tooltip: note.isPinned ? 'Unpin' : 'Pin',
                          onPressed: () => _togglePin(note),
                          icon: Icon(
                            note.isPinned
                                ? Icons.push_pin_rounded
                                : Icons.push_pin_outlined,
                            color: note.isPinned
                                ? Colors.deepOrange
                                : cs.onSurfaceVariant,
                          ),
                        ),
                        IconButton(
                          tooltip: isPublished
                              ? 'Unpublish from friends'
                              : 'Publish to friends',
                          onPressed: () => _togglePublish(note),
                          icon: Icon(
                            isPublished
                                ? Icons.public_rounded
                                : Icons.public_outlined,
                            color: isPublished
                                ? Colors.teal.shade600
                                : cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      updatedText,
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      preview,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: cs.onSurfaceVariant, height: 1.3),
                    ),
                    if (isPublished) ...[
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: cs.tertiaryContainer,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            'Shared with friends',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: cs.onTertiaryContainer,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _logic.currentUser;
    final isLoggedIn = user != null;
    if (!isLoggedIn) {
      return NotesAuthPage(
        onAuthenticated: _onAuthenticated,
      );
    }
    if (!NotesLogic.isUserEmailConfirmed(user)) {
      return NotesActivationRequiredPage(
        onSignOut: _logout,
      );
    }

    final notes = _filteredNotes;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Notes'),
        scrolledUnderElevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 2),
            child: IconButton(
              tooltip: 'Friends & feed',
              onPressed: _openSocialPage,
              icon: Badge.count(
                count: _pendingRequestsCount,
                isLabelVisible: _pendingRequestsCount > 0,
                child: const Icon(Icons.groups_outlined),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: IconButton(
              tooltip: 'Profile',
              onPressed: _loadingProfile ? null : _openProfile,
              icon: _loadingProfile
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : ProfileAvatar(
                      username: _profile?.username,
                      avatarUrl: _profile?.avatarUrl,
                      radius: 14,
                    ),
            ),
          ),
          IconButton(
            tooltip: 'Sign out',
            onPressed: _logout,
            icon: const Icon(Icons.logout_rounded),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: cs.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                          color: cs.outlineVariant.withValues(alpha: 0.55)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Search by title',
                              prefixIcon: const Icon(Icons.search_rounded),
                              filled: true,
                              fillColor: cs.surfaceContainerHighest
                                  .withValues(alpha: 0.45),
                              contentPadding:
                                  const EdgeInsets.symmetric(horizontal: 14),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        FilledButton.icon(
                          onPressed: _createAndOpenNote,
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('New'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _filterChip(
                          filter: NoteQuickFilter.all,
                          label: 'All',
                          icon: Icons.view_agenda_outlined,
                        ),
                        const SizedBox(width: 8),
                        _filterChip(
                          filter: NoteQuickFilter.pinned,
                          label: 'Pinned',
                          icon: Icons.push_pin_outlined,
                        ),
                        const SizedBox(width: 8),
                        _filterChip(
                          filter: NoteQuickFilter.favorites,
                          label: 'Favorites',
                          icon: Icons.star_border_rounded,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadNotes,
                child: _buildNotesBody(notes),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
