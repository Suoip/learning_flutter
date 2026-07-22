import 'package:flutter/material.dart';

import '../../resources_and_services/notes_logic.dart';

class NotesAuthPage extends StatefulWidget {
  const NotesAuthPage({super.key, required this.onAuthenticated});

  final Future<void> Function() onAuthenticated;

  @override
  State<NotesAuthPage> createState() => _NotesAuthPageState();
}

class _NotesAuthPageState extends State<NotesAuthPage> {
  final NotesLogic _logic = NotesLogic();
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isRegister = false;
  bool _loading = false;
  String? _errorText;
  String? _infoText;
  String? _pendingConfirmationEmail;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) return;

    setState(() {
      _loading = true;
      _errorText = null;
      _infoText = null;
      if (_isRegister) {
        _pendingConfirmationEmail = null;
      }
    });

    final username = _usernameController.text.trim().toLowerCase();
    final email = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text;

    try {
      if (_isRegister) {
        final confirmPassword = _confirmPasswordController.text;
        if (password != confirmPassword) {
          setState(() {
            _loading = false;
            _errorText = 'Passwords do not match.';
          });
          return;
        }

        final authenticated = await _logic.signUpWithUsername(
          username: username,
          email: email,
          password: password,
        );

        if (!mounted) return;
        if (!authenticated) {
          setState(() {
            _loading = false;
            _isRegister = false;
            _passwordController.clear();
            _confirmPasswordController.clear();
            _pendingConfirmationEmail = email;
            _infoText =
                'Account created. Check your email to confirm it, then log in with your email.';
          });
          return;
        }
      } else {
        await _logic.signInWithEmail(email: email, password: password);
        _pendingConfirmationEmail = null;
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

  Future<void> _resendConfirmationEmail() async {
    final email = (_pendingConfirmationEmail ?? '').trim().toLowerCase();
    if (!NotesLogic.isValidEmail(email)) {
      setState(() {
        _errorText = 'Register first to enable email confirmation resend.';
        _infoText = null;
      });
      return;
    }

    setState(() {
      _loading = true;
      _errorText = null;
      _infoText = null;
    });

    try {
      await _logic.resendSignupConfirmationEmail(email: email);
      if (!mounted) return;
      setState(() {
        _loading = false;
        _infoText =
            'Confirmation email sent to $email. Check your inbox and spam folder.';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorText = NotesLogic.userMessageForError(
          error,
          fallback: 'Could not resend confirmation email.',
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
                            'Sign in with email, or register with username, email, and password.',
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
                                _infoText = null;
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                          if (_isRegister) ...[
                            TextFormField(
                              controller: _usernameController,
                              textInputAction: TextInputAction.next,
                              autocorrect: false,
                              decoration: InputDecoration(
                                labelText: 'Username',
                                hintText: 'e.g. john_doe123',
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
                          ],
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            autocorrect: false,
                            decoration: InputDecoration(
                              labelText: 'Email',
                              hintText: 'you@example.com',
                              prefixIcon:
                                  const Icon(Icons.alternate_email_rounded),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            validator: (value) {
                              final input = value?.trim() ?? '';
                              if (input.isEmpty) return 'Email is required';
                              if (!NotesLogic.isValidEmail(input)) {
                                return 'Enter a valid email address';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: true,
                            textInputAction: _isRegister
                                ? TextInputAction.next
                                : TextInputAction.done,
                            onFieldSubmitted: (_) {
                              if (!_isRegister) _submit();
                            },
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
                          if (_isRegister) ...[
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _confirmPasswordController,
                              obscureText: true,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _submit(),
                              decoration: InputDecoration(
                                labelText: 'Confirm password',
                                prefixIcon:
                                    const Icon(Icons.lock_reset_rounded),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              validator: (value) {
                                if (!_isRegister) return null;
                                final input = value ?? '';
                                if (input.isEmpty) {
                                  return 'Please confirm your password';
                                }
                                if (input != _passwordController.text) {
                                  return 'Passwords do not match';
                                }
                                return null;
                              },
                            ),
                          ],
                          if (_infoText != null) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.blue.shade100),
                              ),
                              child: Text(
                                _infoText!,
                                style: TextStyle(color: Colors.blue.shade700),
                              ),
                            ),
                          ],
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
                          if (_pendingConfirmationEmail != null) ...[
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed:
                                  _loading ? null : _resendConfirmationEmail,
                              child: const Text('Resend confirmation email'),
                            ),
                          ],
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
