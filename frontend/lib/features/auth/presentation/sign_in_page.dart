import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:gym_app/core/state/auth_state.dart';
import 'package:gym_app/services/api_client.dart';

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
  String? _error;

  Future<void> _submit() async {
    if (_username.text.isEmpty || _password.text.isEmpty) {
      setState(() => _error = 'Username and password are required.');
      return;
    }
    setState(() { _busy = true; _error = null; });
    try {
      final result = await ApiClient.I.register(
        username: _username.text.trim(),
        email: _email.text.trim(),
        password: _password.text,
      );
      ref.read(accessTokenProvider.notifier).state = result['access'] as String;
      ref.read(currentUsernameProvider.notifier).state =
          (result['user'] as Map)['username'] as String;
      if (mounted) context.go('/');
    } catch (e) {
      setState(() => _error = e.toString());
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
          appBar: AppBar(title: const Text('Create Account / Sign In')),
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
            const Text('Welcome', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 32),
            TextField(
              controller: _username,
              decoration: const InputDecoration(labelText: 'Username', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _email,
              decoration: const InputDecoration(labelText: 'Email (optional)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _password,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder()),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(_error!, style: const TextStyle(color: Colors.redAccent)),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _busy ? null : _submit,
                child: _busy
                    ? const CircularProgressIndicator()
                    : const Text('Create Account & Sign In'),
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
