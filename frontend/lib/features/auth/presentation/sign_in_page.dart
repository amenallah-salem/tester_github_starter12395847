import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:gym_app/core/state/auth_state.dart';
import 'package:gym_app/services/api_client.dart';
import 'package:gym_app/features/plan/state/plan_notifier.dart';
import 'package:gym_app/features/progress/state/workout_sessions.dart';

class SignInPage extends ConsumerStatefulWidget {
  const SignInPage({super.key});
  @override
  ConsumerState<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends ConsumerState<SignInPage> {
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  bool _registering = false;
  String? _error;
  Map<String, List<String>> _fieldErrors = const {};

  @override
  void dispose() {
    _username.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_username.text.isEmpty || _password.text.isEmpty) {
      setState(() => _error = 'Username and password are required.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _fieldErrors = const {};
    });
    try {
      final result = _registering
          ? await ApiClient.I.register(
              username: _username.text.trim(),
              email: _email.text.trim(),
              password: _password.text,
            )
          : await ApiClient.I.login(
              username: _username.text.trim(),
              password: _password.text,
            );
      ref.read(accessTokenProvider.notifier).state = result['access'] as String;
      ApiClient.I.accessToken = result['access'] as String;
      if (result['refresh'] case final String refresh) {
        ref.read(refreshTokenProvider.notifier).state = refresh;
        ApiClient.I.refreshToken = refresh;
      }
      await ref.read(planNotifierProvider.notifier).refreshFromApi();
      await ref.read(workoutSessionsProvider.notifier).loadRemote();
      final user = result['user'];
      ref.read(currentUsernameProvider.notifier).state =
          user is Map ? user['username'] as String : _username.text.trim();
      await persistAuth(
        access: result['access'] as String,
        refresh: result['refresh'] as String?,
        username: ref.read(currentUsernameProvider) ?? _username.text.trim(),
      );
      if (mounted) context.go('/');
    } catch (error) {
      if (!mounted) return;
      if (error is ApiException) {
        setState(() {
          _error = error.fieldErrors.isEmpty ? error.message : null;
          _fieldErrors = error.fieldErrors;
        });
      } else {
        setState(() {
          _error = 'Unable to complete the request: $error';
          _fieldErrors = const {};
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Scaffold(
          appBar: AppBar(
            title: Text(_registering ? 'Create account' : 'Sign in'),
          ),
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Welcome',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: _username,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                if (_registering)
                  TextField(
                    controller: _email,
                    decoration: const InputDecoration(
                      labelText: 'Email (optional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                if (_registering) const SizedBox(height: 16),
                const SizedBox(height: 16),
                TextField(
                  controller: _password,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                  ),
                ),
                if (_error != null || _fieldErrors.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  if (_error != null)
                    Text(
                      _error!,
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  ..._fieldErrors.entries.expand(
                    (entry) => entry.value.map(
                      (message) => Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '${entry.key}: $message',
                            style: const TextStyle(color: Colors.redAccent),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _busy ? null : _submit,
                    child: _busy
                        ? const CircularProgressIndicator()
                        : Text(_registering ? 'Create account' : 'Sign in'),
                  ),
                ),
                TextButton(
                  onPressed: _busy
                      ? null
                      : () => setState(() => _registering = !_registering),
                  child: Text(
                    _registering
                        ? 'Already have an account? Sign in'
                        : 'New here? Create an account',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
