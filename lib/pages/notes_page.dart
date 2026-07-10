import 'package:flutter/material.dart';

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
	bool _loadingNotes = true;
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
		_loadNotes();
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
				_loadingNotes = false;
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
		} catch (error) {
			if (!mounted) return;
			setState(() {
				_loadingNotes = false;
				_notesError = error.toString();
			});
		}
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
				SnackBar(content: Text('Could not create note: $error')),
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
				SnackBar(content: Text('Could not update pin: $error')),
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
				SnackBar(content: Text('Could not update favorite: $error')),
			);
			}
		}

	Future<void> _deleteNote(NoteItem note) async {
		final shouldDelete = await showDialog<bool>(
			context: context,
			builder: (context) {
				return AlertDialog(
					title: const Text('Delete Note'),
					content: Text('Delete "${note.title}"? This action cannot be undone.'),
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
				SnackBar(content: Text('Could not delete note: $error')),
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
			_searchController.clear();
			_loadingNotes = false;
			_notesError = null;
		});
	}

	@override
	Widget build(BuildContext context) {
		final isLoggedIn = _logic.currentUser != null;

		if (!isLoggedIn) {
			return _NotesAuthPage(
				onAuthenticated: _loadNotes,
			);
		}

		final notes = _filteredNotes;

		return Scaffold(
			appBar: AppBar(
				title: const Text('Notes'),
				actions: [
					IconButton(
						tooltip: 'Sign out',
						onPressed: _logout,
						icon: const Icon(Icons.logout_rounded),
					),
				],
			),
			body: SafeArea(
				child: Column(
					children: [
						Padding(
							padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
							child: SingleChildScrollView(
								scrollDirection: Axis.horizontal,
								child: Row(
									children: [
										ChoiceChip(
											label: const Text('All'),
											selected: _activeFilter == NoteQuickFilter.all,
											onSelected: (_) {
												setState(() {
													_activeFilter = NoteQuickFilter.all;
												});
											},
										),
										const SizedBox(width: 8),
										ChoiceChip(
											label: const Text('Pinned'),
											selected: _activeFilter == NoteQuickFilter.pinned,
											onSelected: (_) {
												setState(() {
													_activeFilter = NoteQuickFilter.pinned;
												});
											},
										),
										const SizedBox(width: 8),
										ChoiceChip(
											label: const Text('Favorites'),
											selected: _activeFilter == NoteQuickFilter.favorites,
											onSelected: (_) {
												setState(() {
													_activeFilter = NoteQuickFilter.favorites;
												});
											},
										),
									],
								),
							),
						),
						const SizedBox(height: 8),
						Expanded(
							child: RefreshIndicator(
								onRefresh: _loadNotes,
								child: _loadingNotes
										? const Center(child: CircularProgressIndicator())
										: _notesError != null
												? ListView(
														physics: const AlwaysScrollableScrollPhysics(),
														children: [
															Padding(
																padding: const EdgeInsets.all(20),
																child: Text(
																	'Failed to load notes:\n$_notesError',
																	style: const TextStyle(color: Colors.red),
																),
															),
														],
													)
												: notes.isEmpty
														? ListView(
																physics: const AlwaysScrollableScrollPhysics(),
																children: const [
																	SizedBox(height: 120),
																	Center(
																		child: Text(
																			'No notes yet. Create your first note.',
																			style: TextStyle(
																				fontSize: 16,
																				color: Colors.black54,
																			),
																		),
																	),
																],
															)
														: ListView.separated(
																padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
																itemCount: notes.length,
																separatorBuilder: (_, __) => const SizedBox(height: 12),
																itemBuilder: (context, index) {
																	final note = notes[index];
																	final preview = note.content.trim().isEmpty
																			? 'No additional text'
																			: note.content.trim().replaceAll('\n', ' ');
																	final updatedText = NotesLogic.formatUpdatedTime(note.updatedAt);

																	return Dismissible(
																		key: ValueKey(note.id),
																		direction: DismissDirection.endToStart,
																		background: Container(
																			alignment: Alignment.centerRight,
																			padding: const EdgeInsets.symmetric(horizontal: 20),
																			decoration: BoxDecoration(
																				color: Colors.red.shade400,
																				borderRadius: BorderRadius.circular(14),
																			),
																			child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
																		),
																		confirmDismiss: (_) async {
																			await _deleteNote(note);
																			return false;
																		},
																		child: Material(
																			color: const Color(0xFFFFFDF8),
																			borderRadius: BorderRadius.circular(14),
																			child: InkWell(
																				borderRadius: BorderRadius.circular(14),
																				onTap: () => _openNote(note),
																				child: Padding(
																					padding: const EdgeInsets.all(14),
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
																												Text(
																													note.title,
																													maxLines: 1,
																													overflow: TextOverflow.ellipsis,
																													style: const TextStyle(
																														fontSize: 18,
																														fontWeight: FontWeight.w700,
																													),
																												),
																									],
																										),
																									),
																									IconButton(
																										tooltip: note.isFavorite ? 'Unfavorite' : 'Favorite',
																										onPressed: () => _toggleFavorite(note),
																										icon: Icon(
																											note.isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
																											color: note.isFavorite ? Colors.amber.shade700 : Colors.black45,
																										),
																									),
																									IconButton(
																										tooltip: note.isPinned ? 'Unpin' : 'Pin',
																										onPressed: () => _togglePin(note),
																										icon: Icon(
																											note.isPinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
																											color: note.isPinned ? Colors.deepOrange : Colors.black45,
																										),
																									),
																								],
																							),
																							Text(
																								updatedText,
																								style: const TextStyle(
																									fontSize: 12,
																									color: Colors.black45,
																								),
																							),
																							const SizedBox(height: 6),
																							Text(
																								preview,
																								maxLines: 2,
																								overflow: TextOverflow.ellipsis,
																								style: const TextStyle(
																									color: Colors.black54,
																								),
																							),
																						],
																					),
																				),
																			),
																		),
																	);
																},
															),
							),
						),
						Container(
							padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
							decoration: const BoxDecoration(
								color: Color(0xFFFAFAFA),
								border: Border(top: BorderSide(color: Color(0xFFD9D9D9))),
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
												fillColor: Colors.white,
												contentPadding: const EdgeInsets.symmetric(horizontal: 14),
												border: OutlineInputBorder(
													borderRadius: BorderRadius.circular(24),
													borderSide: BorderSide.none,
												),
											),
										),
									),
									const SizedBox(width: 10),
									FloatingActionButton.small(
										onPressed: _createAndOpenNote,
										child: const Icon(Icons.edit_rounded),
									),
								],
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
				_errorText = error.toString().replaceFirst('Exception: ', '');
			});
		}
	}

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			appBar: AppBar(title: const Text('Notes Login')),
			body: SafeArea(
				child: Center(
					child: SingleChildScrollView(
						padding: const EdgeInsets.all(20),
						child: ConstrainedBox(
							constraints: const BoxConstraints(maxWidth: 420),
							child: Form(
								key: _formKey,
								child: Column(
									crossAxisAlignment: CrossAxisAlignment.stretch,
									children: [
										const Text(
											'Welcome to Notes',
											textAlign: TextAlign.center,
											style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
										),
										const SizedBox(height: 8),
										const Text(
											'Sign in or create an account with username and password.',
											textAlign: TextAlign.center,
											style: TextStyle(color: Colors.black54),
										),
										const SizedBox(height: 24),
										SegmentedButton<bool>(
											segments: const [
												ButtonSegment<bool>(value: false, label: Text('Login')),
												ButtonSegment<bool>(value: true, label: Text('Register')),
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
											decoration: const InputDecoration(
												labelText: 'Username',
												hintText: 'e.g. John_Doe123',
												border: OutlineInputBorder(),
											),
											validator: (value) {
												final input = value?.trim() ?? '';
												if (input.isEmpty) return 'Username is required';
														final allowed = RegExp(r'^[a-zA-Z0-9_.-]{3,30}$');
												if (!allowed.hasMatch(input)) {
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
											decoration: const InputDecoration(
												labelText: 'Password',
												border: OutlineInputBorder(),
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
											Text(
												_errorText!,
												style: const TextStyle(color: Colors.red),
											),
										],
										const SizedBox(height: 16),
										FilledButton(
											onPressed: _loading ? null : _submit,
											child: _loading
													? const SizedBox(
															height: 18,
															width: 18,
															child: CircularProgressIndicator(strokeWidth: 2),
														)
													: Text(_isRegister ? 'Create Account' : 'Login'),
										),
									],
								),
							),
						),
					),
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
			await _logic.updateNote(noteId: widget.note.id, title: title, content: content);

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
				SnackBar(content: Text('Save failed: $error')),
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
				SnackBar(content: Text('Delete failed: $error')),
			);
		}
	}

	@override
	Widget build(BuildContext context) {
		return PopScope(
			canPop: true,
			onPopInvokedWithResult: (didPop, result) async {
				if (didPop) return;
				await _onWillPop();
			},
			child: Scaffold(
				appBar: AppBar(
					title: const Text('Edit Note'),
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
						IconButton(
							tooltip: 'Save',
							onPressed: (_saving || _deleting) ? null : _save,
							icon: _saving
									? const SizedBox(
											height: 18,
											width: 18,
											child: CircularProgressIndicator(strokeWidth: 2),
										)
									: const Icon(Icons.check_rounded),
						),
					],
				),
				body: Padding(
					padding: const EdgeInsets.all(16),
					child: Column(
						children: [
							TextField(
								controller: _titleController,
								style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
								decoration: const InputDecoration(
									border: InputBorder.none,
									hintText: 'Title',
								),
							),
							const Divider(height: 1),
							const SizedBox(height: 8),
							Expanded(
								child: TextField(
									controller: _contentController,
									maxLines: null,
									expands: true,
									textAlignVertical: TextAlignVertical.top,
									decoration: const InputDecoration(
										border: InputBorder.none,
										hintText: 'Start writing...',
									),
								),
							),
							if (_hasSavedOnce)
								const Align(
									alignment: Alignment.centerRight,
									child: Text(
										'Saved',
										style: TextStyle(color: Colors.black45, fontSize: 12),
									),
								),
						],
					),
				),
			),
		);
	}
}
