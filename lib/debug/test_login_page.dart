// TEMPORARY test login — exercises SessionService end to end, then
// pushes the debug screen on success. Point MaterialApp home here:
//   home: const TestLoginPage(),
//
// Deliberately standalone (not the real AuthBloc flow) so it can be
// deleted once SessionService is threaded into the real auth stack.

import 'package:flutter/material.dart';

import '../core/auth/session_service.dart';
import 'debug_sync_screen.dart';

class TestLoginPage extends StatefulWidget {
  const TestLoginPage({super.key});

  @override
  State<TestLoginPage> createState() => _TestLoginPageState();
}

class _TestLoginPageState extends State<TestLoginPage> {
  final _session = SessionService();

  final _url = TextEditingController(text: 'http://192.168.0.100:8091');
  final _user = TextEditingController();
  final _pass = TextEditingController();
  bool _online = true;
  bool _busy = false;
  String? _message;

  @override
  void dispose() {
    _url.dispose();
    _user.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final result = await _session.login(
        serverUrl: _url.text.trim(),
        username: _user.text.trim(),
        password: _pass.text.trim(),
        online: _online,
      );

      final ok = result == LoginResult.onlineFirstSync ||
          result == LoginResult.onlineReturning ||
          result == LoginResult.offline;

      setState(() => _message = 'Result: ${result.name}');

      if (ok && mounted) {
        // Hand the session's live db to the debug screen.
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => DebugSyncScreen(session: _session),
        ));
      }
    } catch (e) {
      setState(() => _message = 'Error: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Test login (SessionService)')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _url,
              decoration: const InputDecoration(
                  labelText: 'Server URL', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _user,
              decoration: const InputDecoration(
                  labelText: 'Username', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _pass,
              obscureText: true,
              decoration: const InputDecoration(
                  labelText: 'Password', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('Online'),
              subtitle: Text(_online
                  ? 'authenticate against server'
                  : 'verify against stored hash (offline)'),
              value: _online,
              onChanged: _busy ? null : (v) => setState(() => _online = v),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _busy ? null : _login,
              child: _busy
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Log in'),
            ),
            const SizedBox(height: 16),
            if (_message != null)
              Text(_message!,
                  style: const TextStyle(fontFamily: 'monospace')),
          ],
        ),
      ),
    );
  }
}
