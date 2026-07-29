import 'package:flutter/material.dart';

import '../../resources_and_services/notes_logic.dart';
import 'feed_page.dart';
import 'friends_page.dart';
import 'note_editor_page.dart';
import 'note_list_tile.dart';
import 'notes_activation_required_page.dart';
import 'notes_auth_page.dart';
import 'notes_profile_page.dart';
import 'notes_toolbar.dart';
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
  int _selectedIndex = 0;

  static const _tabTitles = ['Notes', 'Feed', 'Friends'];

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
    ]);
  }

  String _friendly(
    Object error, {
    String fallback = 'Something went wrong. Please try again.',
  }) {
    return NotesLogic.userMessageForError(error, fallback: fallback);
  }

  void _updatePendingRequestsCount(int count) {
    if (!mounted) return;
    setState(() {
      _pendingRequestsCount = count;
    });
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
    return NotesLogic.filterNotes(
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
          builder: (_) => NoteEditorPage(
            note: note,
            isPublished: false,
            isFavorite: false,
            isPinned: false,
            onToggleFavorite: () => _toggleFavorite(note),
            onTogglePin: () => _togglePin(note),
            onTogglePublish: () => _togglePublish(note),
          ),
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

  Future<bool> _togglePublish(NoteItem note) async {
    final published = _publishedNoteIds.contains(note.id);

    if (!published) {
      List<FriendItem> friends;
      try {
        friends = await _logic.fetchFriends();
      } catch (error) {
        if (!mounted) return false;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _friendly(error, fallback: 'Could not check your friends list.'),
            ),
          ),
        );
        return false;
      }
      if (!mounted) return false;
      if (friends.isNotEmpty) {
        final confirmed = await _showPublishConfirmationDialog(friends);
        if (!confirmed) return false;
      }
    }

    try {
      if (published) {
        await _logic.unpublishNoteFromFriends(note.id);
      } else {
        await _logic.publishNoteToFriends(note);
      }
      await _loadPublishedNotes();
      if (!mounted) return true;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            published
                ? 'Note removed from your friends feed.'
                : 'Note published to your friends feed.',
          ),
        ),
      );
      return true;
    } catch (error) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _friendly(error, fallback: 'Could not update sharing right now.'),
          ),
        ),
      );
      return false;
    }
  }

  Future<bool> _showPublishConfirmationDialog(List<FriendItem> friends) async {
    const maxShown = 8;
    final shown =
        friends.take(maxShown).map((f) => '@${f.friend.username}').join(', ');
    final remaining = friends.length - maxShown;
    final usernamesText = remaining > 0 ? '$shown, and $remaining more' : shown;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Publish note?'),
          content: Text(
            'This will publish the note to your ${friends.length} '
            'friend${friends.length == 1 ? '' : 's'}: $usernamesText',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Publish'),
            ),
          ],
        );
      },
    );
    return confirmed ?? false;
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
        builder: (_) => NoteEditorPage(
          note: note,
          isPublished: _publishedNoteIds.contains(note.id),
          isFavorite: note.isFavorite,
          isPinned: note.isPinned,
          onToggleFavorite: () => _toggleFavorite(note),
          onTogglePin: () => _togglePin(note),
          onTogglePublish: () => _togglePublish(note),
        ),
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
      _selectedIndex = 0;
    });
  }

  Widget _buildNotesBody(List<NoteItem> notes) {
    if (_loadingNotes) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_notesError != null) {
      final cs = Theme.of(context).colorScheme;
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            color: cs.errorContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Failed to load notes:\n$_notesError',
                style: TextStyle(color: cs.onErrorContainer),
              ),
            ),
          ),
        ],
      );
    }

    if (notes.isEmpty) {
      final theme = Theme.of(context);
      final cs = theme.colorScheme;
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 60, 20, 120),
        children: [
          Card(
            color: cs.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(
                    Icons.sticky_note_2_outlined,
                    size: 40,
                    color: cs.primary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No notes yet',
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Create your first note to get started.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge,
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
        return NoteListTile(
          note: note,
          isPublished: _publishedNoteIds.contains(note.id),
          onTap: () => _openNote(note),
          onToggleFavorite: () => _toggleFavorite(note),
          onTogglePin: () => _togglePin(note),
          onTogglePublish: () => _togglePublish(note),
          onConfirmDismiss: () async {
            await _deleteNote(note);
            return false;
          },
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
        title: Text(_tabTitles[_selectedIndex]),
        actions: [
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
        child: IndexedStack(
          index: _selectedIndex,
          children: [
            _buildNotesTab(notes),
            const FeedPage(),
            FriendsPage(onPendingCountChanged: _updatePendingRequestsCount),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.sticky_note_2_outlined),
            selectedIcon: Icon(Icons.sticky_note_2_rounded),
            label: 'Notes',
          ),
          const NavigationDestination(
            icon: Icon(Icons.dynamic_feed_outlined),
            selectedIcon: Icon(Icons.dynamic_feed_rounded),
            label: 'Feed',
          ),
          NavigationDestination(
            icon: Badge.count(
              count: _pendingRequestsCount,
              isLabelVisible: _pendingRequestsCount > 0,
              child: const Icon(Icons.group_outlined),
            ),
            selectedIcon: Badge.count(
              count: _pendingRequestsCount,
              isLabelVisible: _pendingRequestsCount > 0,
              child: const Icon(Icons.group_rounded),
            ),
            label: 'Friends',
          ),
        ],
      ),
    );
  }

  Widget _buildNotesTab(List<NoteItem> notes) {
    return Column(
      children: [
        NotesToolbar(
          searchController: _searchController,
          activeFilter: _activeFilter,
          onFilterChanged: (filter) {
            setState(() {
              _activeFilter = filter;
            });
          },
          onCreateNote: _createAndOpenNote,
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadNotes,
            child: _buildNotesBody(notes),
          ),
        ),
      ],
    );
  }
}
