import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../resources_and_services/notes_logic.dart';
import 'profile_avatar.dart';

class NotesProfilePage extends StatefulWidget {
  const NotesProfilePage({super.key});

  @override
  State<NotesProfilePage> createState() => _NotesProfilePageState();
}

class _NotesProfilePageState extends State<NotesProfilePage> {
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
                          ProfileAvatar(
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
