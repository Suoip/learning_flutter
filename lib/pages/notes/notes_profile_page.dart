import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../resources_and_services/notes_logic.dart';
import 'password_form_section.dart';
import 'profile_avatar_section.dart';
import 'username_form_section.dart';

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

    // picked.name (not picked.path) - on web, XFile.path is a blob: URL,
    // not the original filename, so the extension must come from .name.
    final sanitizedExtension = NotesLogic.extensionFromFileName(picked.name);

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
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
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
                  ProfileAvatarSection(
                    profile: _profile,
                    uploadingAvatar: _uploadingAvatar,
                    onPickAvatar: _pickAndUploadAvatar,
                  ),
                  const SizedBox(height: 14),
                  UsernameFormSection(
                    formKey: _usernameFormKey,
                    controller: _usernameController,
                    saving: _savingUsername,
                    onSave: _saveUsername,
                  ),
                  const SizedBox(height: 14),
                  PasswordFormSection(
                    formKey: _passwordFormKey,
                    passwordController: _passwordController,
                    confirmPasswordController: _confirmPasswordController,
                    saving: _savingPassword,
                    onSave: _savePassword,
                  ),
                ],
              ),
            ),
    );
  }
}
