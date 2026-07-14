import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../resources_and_services/notes_logic.dart';

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
    _loadProfile();
    _loadNotes();
    _loadPendingRequestsBadge();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
      MaterialPageRoute(builder: (_) => const _NotesSocialPage()),
    );
    await _loadPendingRequestsBadge();
    await _loadPublishedNotes();
  }

  Future<void> _openProfile() async {
    final updatedProfile = await Navigator.of(context).push<UserProfile>(
      MaterialPageRoute(
        builder: (_) => const _NotesProfilePage(),
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
          builder: (_) => _NoteEditorPage(note: note),
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
        builder: (_) => _NoteEditorPage(note: note),
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
    final isLoggedIn = _logic.currentUser != null;
    if (!isLoggedIn) {
      return _NotesAuthPage(
        onAuthenticated: _onAuthenticated,
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
                  : _ProfileAvatar(
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

class _NotesAuthPage extends StatefulWidget {
  const _NotesAuthPage({required this.onAuthenticated});

  final Future<void> Function() onAuthenticated;

  @override
  State<_NotesAuthPage> createState() => _NotesAuthPageState();
}

class _NotesAuthPageState extends State<_NotesAuthPage> {
  final NotesLogic _logic = NotesLogic();
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isRegister = false;
  bool _loading = false;
  String? _errorText;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) return;

    setState(() {
      _loading = true;
      _errorText = null;
    });

    final username = _usernameController.text.trim().toLowerCase();
    final password = _passwordController.text;

    try {
      if (_isRegister) {
        await _logic.signUpWithUsername(username: username, password: password);
      } else {
        await _logic.signInWithUsername(username: username, password: password);
      }

      await widget.onAuthenticated();
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorText = NotesLogic.userMessageForError(
          error,
          fallback: 'Could not complete authentication.',
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              cs.primaryContainer.withValues(alpha: 0.75),
              cs.surfaceContainerLowest,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: Card(
                  elevation: 0,
                  color: cs.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(26),
                    side: BorderSide(
                        color: cs.outlineVariant.withValues(alpha: 0.5)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Icon(
                            Icons.sticky_note_2_outlined,
                            size: 36,
                            color: cs.primary,
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Welcome to Notes',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 27, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Sign in or create an account with username and password.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: cs.onSurfaceVariant),
                          ),
                          const SizedBox(height: 22),
                          SegmentedButton<bool>(
                            segments: const [
                              ButtonSegment<bool>(
                                  value: false, label: Text('Login')),
                              ButtonSegment<bool>(
                                  value: true, label: Text('Register')),
                            ],
                            selected: {_isRegister},
                            onSelectionChanged: (value) {
                              setState(() {
                                _isRegister = value.first;
                                _errorText = null;
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _usernameController,
                            textInputAction: TextInputAction.next,
                            autocorrect: false,
                            decoration: InputDecoration(
                              labelText: 'Username',
                              hintText: 'e.g. John_Doe123',
                              prefixIcon:
                                  const Icon(Icons.person_outline_rounded),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            validator: (value) {
                              final input = value?.trim() ?? '';
                              if (input.isEmpty) return 'Username is required';
                              if (!NotesLogic.isValidUsername(input)) {
                                return 'Use 3-30 chars: letters, numbers, _, -, .';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: true,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _submit(),
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon:
                                  const Icon(Icons.lock_outline_rounded),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            validator: (value) {
                              final input = value ?? '';
                              if (input.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                          ),
                          if (_errorText != null) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.red.shade100),
                              ),
                              child: Text(
                                _errorText!,
                                style: TextStyle(color: Colors.red.shade700),
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: _loading ? null : _submit,
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(48),
                            ),
                            child: _loading
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : Text(
                                    _isRegister ? 'Create Account' : 'Login'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({
    required this.username,
    required this.avatarUrl,
    required this.radius,
  });

  final String? username;
  final String? avatarUrl;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final fallbackName = (username ?? '').trim();
    final initial =
        fallbackName.isEmpty ? '?' : fallbackName.substring(0, 1).toUpperCase();

    final hasAvatar = (avatarUrl ?? '').isNotEmpty;

    return CircleAvatar(
      radius: radius,
      foregroundImage: hasAvatar ? NetworkImage(avatarUrl!) : null,
      child: Text(
        initial,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: radius * 0.75,
        ),
      ),
    );
  }
}

class _NotesProfilePage extends StatefulWidget {
  const _NotesProfilePage();

  @override
  State<_NotesProfilePage> createState() => _NotesProfilePageState();
}

class _NotesProfilePageState extends State<_NotesProfilePage> {
  final NotesLogic _logic = NotesLogic();
  final ImagePicker _imagePicker = ImagePicker();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _usernameFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();

  UserProfile? _profile;
  bool _loading = true;
  bool _savingUsername = false;
  bool _savingPassword = false;
  bool _uploadingAvatar = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final profile = await _logic.fetchCurrentProfile();
      if (!mounted) return;
      _usernameController.text = profile.username;
      setState(() {
        _profile = profile;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = NotesLogic.userMessageForError(
          error,
          fallback: 'Could not load profile right now.',
        );
      });
    }
  }

  Future<void> _pickAndUploadAvatar() async {
    if (_uploadingAvatar) return;

    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1200,
      maxHeight: 1200,
    );
    if (picked == null) return;

    final filePath = picked.path.toLowerCase();
    final dotIndex = filePath.lastIndexOf('.');
    final rawExtension =
        dotIndex > -1 ? filePath.substring(dotIndex + 1) : 'jpg';
    final extension = rawExtension.replaceAll(RegExp(r'[^a-z0-9]'), '');
    final sanitizedExtension = extension.isEmpty ? 'jpg' : extension;

    setState(() {
      _uploadingAvatar = true;
      _error = null;
    });

    try {
      final bytes = await picked.readAsBytes();
      final updatedProfile = await _logic.uploadProfileAvatar(
        bytes: bytes,
        extension: sanitizedExtension,
      );
      if (!mounted) return;
      setState(() {
        _profile = updatedProfile;
        _uploadingAvatar = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile picture updated.')));
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _uploadingAvatar = false;
        _error = NotesLogic.userMessageForError(
          error,
          fallback: 'Could not update profile picture.',
        );
      });
    }
  }

  Future<void> _saveUsername() async {
    final valid = _usernameFormKey.currentState?.validate() ?? false;
    if (!valid || _savingUsername || _profile == null) return;

    setState(() {
      _savingUsername = true;
      _error = null;
    });

    try {
      final updatedProfile =
          await _logic.updateUsername(_usernameController.text);
      if (!mounted) return;
      setState(() {
        _profile = updatedProfile;
        _savingUsername = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Username updated.')));
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _savingUsername = false;
        _error = NotesLogic.userMessageForError(
          error,
          fallback: 'Could not update username.',
        );
      });
    }
  }

  Future<void> _savePassword() async {
    final valid = _passwordFormKey.currentState?.validate() ?? false;
    if (!valid || _savingPassword) return;

    setState(() {
      _savingPassword = true;
      _error = null;
    });

    try {
      await _logic.updatePassword(_passwordController.text);
      if (!mounted) return;
      _passwordController.clear();
      _confirmPasswordController.clear();
      setState(() {
        _savingPassword = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Password updated.')));
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _savingPassword = false;
        _error = NotesLogic.userMessageForError(
          error,
          fallback: 'Could not update password.',
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Profile'),
        scrolledUnderElevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(_profile),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                children: [
                  if (_error != null) ...[
                    Card(
                      color: Colors.red.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          _error!,
                          style: TextStyle(color: Colors.red.shade700),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: cs.outlineVariant.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        children: [
                          _ProfileAvatar(
                            username: _profile?.username,
                            avatarUrl: _profile?.avatarUrl,
                            radius: 44,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '@${_profile?.username ?? ''}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed:
                                _uploadingAvatar ? null : _pickAndUploadAvatar,
                            icon: _uploadingAvatar
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : const Icon(Icons.photo_camera_outlined),
                            label: const Text('Change profile picture'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: cs.outlineVariant.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                      child: Form(
                        key: _usernameFormKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Username',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextFormField(
                              controller: _usernameController,
                              decoration: InputDecoration(
                                labelText: 'Username',
                                prefixIcon:
                                    const Icon(Icons.person_outline_rounded),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              validator: (value) {
                                final input = value?.trim() ?? '';
                                if (input.isEmpty) {
                                  return 'Username is required';
                                }
                                if (!NotesLogic.isValidUsername(input)) {
                                  return 'Use 3-30 chars: letters, numbers, _, -, .';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            FilledButton(
                              onPressed: _savingUsername ? null : _saveUsername,
                              child: _savingUsername
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    )
                                  : const Text('Save username'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: cs.outlineVariant.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                      child: Form(
                        key: _passwordFormKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Change password',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: true,
                              decoration: InputDecoration(
                                labelText: 'New password',
                                prefixIcon:
                                    const Icon(Icons.lock_outline_rounded),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              validator: (value) {
                                final input = value ?? '';
                                if (input.length < 6) {
                                  return 'Password must be at least 6 characters';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 10),
                            TextFormField(
                              controller: _confirmPasswordController,
                              obscureText: true,
                              decoration: InputDecoration(
                                labelText: 'Confirm new password',
                                prefixIcon:
                                    const Icon(Icons.lock_reset_outlined),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              validator: (value) {
                                if ((value ?? '') != _passwordController.text) {
                                  return 'Passwords do not match';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            FilledButton(
                              onPressed: _savingPassword ? null : _savePassword,
                              child: _savingPassword
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    )
                                  : const Text('Update password'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _NotesSocialPage extends StatefulWidget {
  const _NotesSocialPage();

  @override
  State<_NotesSocialPage> createState() => _NotesSocialPageState();
}

class _NotesSocialPageState extends State<_NotesSocialPage> {
  final NotesLogic _logic = NotesLogic();
  final TextEditingController _searchController = TextEditingController();

  List<ProfilePreview> _searchResults = [];
  List<FriendRequestItem> _incomingRequests = [];
  List<FriendRequestItem> _outgoingRequests = [];
  List<FriendItem> _friends = [];
  List<SharedNoteFeedItem> _feed = [];
  bool _loading = true;
  bool _searching = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _friendly(Object error, {String fallback = 'Something went wrong.'}) {
    return NotesLogic.userMessageForError(error, fallback: fallback);
  }

  Future<void> _loadAll() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final incomingFuture = _logic.fetchIncomingFriendRequests();
      final outgoingFuture = _logic.fetchOutgoingFriendRequests();
      final friendsFuture = _logic.fetchFriends();
      final feedFuture = _logic.fetchFriendsFeed();
      final results = await Future.wait([
        incomingFuture,
        outgoingFuture,
        friendsFuture,
        feedFuture,
      ]);
      if (!mounted) return;
      setState(() {
        _incomingRequests = results[0] as List<FriendRequestItem>;
        _outgoingRequests = results[1] as List<FriendRequestItem>;
        _friends = results[2] as List<FriendItem>;
        _feed = results[3] as List<SharedNoteFeedItem>;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = _friendly(error, fallback: 'Could not load social data.');
      });
    }
  }

  Future<void> _searchUsers() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _searching = true;
    });
    try {
      final users = await _logic.searchUsersByUsername(query);
      if (!mounted) return;
      setState(() {
        _searchResults = users;
        _searching = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _searching = false;
        _error = _friendly(error, fallback: 'Could not search users.');
      });
    }
  }

  Future<void> _sendRequest(String username) async {
    try {
      await _logic.sendFriendRequestByUsername(username);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Friend request sent.')),
      );
      await _loadAll();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text(_friendly(error, fallback: 'Could not send request.'))),
      );
    }
  }

  Future<void> _respondRequest(String requestId, bool accept) async {
    try {
      await _logic.respondToFriendRequest(requestId: requestId, accept: accept);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(accept
                ? 'Friend request accepted.'
                : 'Friend request declined.')),
      );
      await _loadAll();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text(_friendly(error, fallback: 'Could not update request.'))),
      );
    }
  }

  Future<void> _toggleLike(SharedNoteFeedItem item) async {
    try {
      await _logic.toggleFeedLike(item.id);
      await _loadAll();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text(_friendly(error, fallback: 'Could not update like.'))),
      );
    }
  }

  Future<void> _openCommentsSheet(SharedNoteFeedItem item) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _FeedCommentsSheet(
        logic: _logic,
        item: item,
      ),
    );
    if (!mounted) return;
    await _loadAll();
  }

  Widget _buildFriendsTab() {
    final cs = Theme.of(context).colorScheme;
    return RefreshIndicator(
      onRefresh: _loadAll,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
        children: [
          if (_error != null) ...[
            Card(
              color: Colors.red.shade50,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  _error!,
                  style: TextStyle(color: Colors.red.shade700),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) => _searchUsers(),
                      decoration: InputDecoration(
                        labelText: 'Find users by username',
                        hintText: 'Type a username to send a friend request',
                        prefixIcon: const Icon(Icons.search_rounded),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  FilledButton(
                    onPressed: _searching ? null : _searchUsers,
                    child: _searching
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Search'),
                  ),
                ],
              ),
            ),
          ),
          if (_searchController.text.trim().isNotEmpty &&
              !_searching &&
              _searchResults.isEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'No users found. Make sure the username is correct.',
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
          ],
          if (_searchResults.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Text(
              'Search results',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            ..._searchResults.map((user) {
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: _ProfileAvatar(
                  username: user.username,
                  avatarUrl: user.avatarUrl,
                  radius: 18,
                ),
                title: Text('@${user.username}'),
                trailing: FilledButton(
                  onPressed: () => _sendRequest(user.username),
                  child: const Text('Add'),
                ),
              );
            }),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              const Text(
                'Incoming requests',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: 8),
              if (_incomingRequests.isNotEmpty)
                Badge.count(count: _incomingRequests.length),
            ],
          ),
          const SizedBox(height: 6),
          if (_incomingRequests.isEmpty)
            Text(
              'No pending incoming requests.',
              style: TextStyle(color: cs.onSurfaceVariant),
            )
          else
            ..._incomingRequests.map((request) {
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 5),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    children: [
                      _ProfileAvatar(
                        username: request.counterpart.username,
                        avatarUrl: request.counterpart.avatarUrl,
                        radius: 16,
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Text('@${request.counterpart.username}')),
                      TextButton(
                        onPressed: () => _respondRequest(request.id, false),
                        child: const Text('Decline'),
                      ),
                      FilledButton(
                        onPressed: () => _respondRequest(request.id, true),
                        child: const Text('Accept'),
                      ),
                    ],
                  ),
                ),
              );
            }),
          const SizedBox(height: 14),
          const Text(
            'Sent requests',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          if (_outgoingRequests.isEmpty)
            Text(
              'No pending outgoing requests.',
              style: TextStyle(color: cs.onSurfaceVariant),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _outgoingRequests
                  .map((request) =>
                      Chip(label: Text('@${request.counterpart.username}')))
                  .toList(),
            ),
          const SizedBox(height: 14),
          Text(
            'Friends (${_friends.length})',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          if (_friends.isEmpty)
            Text(
              'No friends yet.',
              style: TextStyle(color: cs.onSurfaceVariant),
            )
          else
            ..._friends.map((friend) {
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: _ProfileAvatar(
                  username: friend.friend.username,
                  avatarUrl: friend.friend.avatarUrl,
                  radius: 18,
                ),
                title: Text('@${friend.friend.username}'),
                subtitle: Text(
                  'Friends since ${NotesLogic.formatUpdatedTime(friend.createdAt)}',
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildFeedTab() {
    final cs = Theme.of(context).colorScheme;
    if (_feed.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadAll,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 70, 20, 120),
          children: [
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side:
                    BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
              ),
              child: const Padding(
                padding: EdgeInsets.all(22),
                child: Column(
                  children: [
                    Icon(Icons.dynamic_feed_outlined, size: 36),
                    SizedBox(height: 8),
                    Text(
                      'No shared notes yet',
                      style:
                          TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'When your friends publish notes, they will appear here.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAll,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
        itemCount: _feed.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final item = _feed[index];
          return Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _ProfileAvatar(
                        username: item.authorUsername,
                        avatarUrl: item.authorAvatarUrl,
                        radius: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '@${item.authorUsername}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            Text(
                              NotesLogic.formatUpdatedTime(item.publishedAt),
                              style: TextStyle(
                                fontSize: 12,
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    item.title,
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Text(item.content.isEmpty ? '(No content)' : item.content),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      IconButton(
                        tooltip: item.isLikedByCurrentUser ? 'Unlike' : 'Like',
                        onPressed: () => _toggleLike(item),
                        icon: Icon(
                          item.isLikedByCurrentUser
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          color: item.isLikedByCurrentUser
                              ? Colors.pink.shade500
                              : cs.onSurfaceVariant,
                        ),
                      ),
                      Text('${item.likeCount}'),
                      const SizedBox(width: 10),
                      IconButton(
                        tooltip: 'Comments',
                        onPressed: () => _openCommentsSheet(item),
                        icon: const Icon(Icons.mode_comment_outlined),
                      ),
                      Text('${item.commentCount}'),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: cs.secondaryContainer,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'Read-only',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: cs.onSecondaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: cs.surfaceContainerLowest,
        appBar: AppBar(
          title: const Text('Friends & Feed'),
          scrolledUnderElevation: 0,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Friends', icon: Icon(Icons.group_outlined)),
              Tab(text: 'Feed', icon: Icon(Icons.dynamic_feed_outlined)),
            ],
          ),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _buildFriendsTab(),
                  _buildFeedTab(),
                ],
              ),
      ),
    );
  }
}

class _FeedCommentsSheet extends StatefulWidget {
  const _FeedCommentsSheet({
    required this.logic,
    required this.item,
  });

  final NotesLogic logic;
  final SharedNoteFeedItem item;

  @override
  State<_FeedCommentsSheet> createState() => _FeedCommentsSheetState();
}

class _FeedCommentsSheetState extends State<_FeedCommentsSheet> {
  final TextEditingController _commentController = TextEditingController();
  List<FeedCommentItem> _comments = [];
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  String _friendly(Object error, {String fallback = 'Something went wrong.'}) {
    return NotesLogic.userMessageForError(error, fallback: fallback);
  }

  Future<void> _loadComments() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rows = await widget.logic.fetchFeedComments(widget.item.id);
      if (!mounted) return;
      setState(() {
        _comments = rows;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = _friendly(error, fallback: 'Could not load comments.');
      });
    }
  }

  Future<void> _addComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty || _saving) return;

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.logic
          .addFeedComment(sharedNoteId: widget.item.id, content: content);
      _commentController.clear();
      await _loadComments();
      if (!mounted) return;
      setState(() {
        _saving = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = _friendly(error, fallback: 'Could not post comment.');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 8,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Comments',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            if (_error != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _error!,
                  style: TextStyle(color: Colors.red.shade700),
                ),
              ),
            const SizedBox(height: 8),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _comments.length,
                  itemBuilder: (context, index) {
                    final comment = _comments[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: _ProfileAvatar(
                        username: comment.authorUsername,
                        avatarUrl: comment.authorAvatarUrl,
                        radius: 14,
                      ),
                      title: Text('@${comment.authorUsername}'),
                      subtitle: Text(comment.content),
                      trailing: Text(
                        DateFormat('MMM d').format(comment.createdAt.toLocal()),
                        style:
                            TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    minLines: 1,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Write a comment...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _saving ? null : _addComment,
                  child: _saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Post'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NoteEditorPage extends StatefulWidget {
  const _NoteEditorPage({required this.note});

  final NoteItem note;

  @override
  State<_NoteEditorPage> createState() => _NoteEditorPageState();
}

class _NoteEditorPageState extends State<_NoteEditorPage> {
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
