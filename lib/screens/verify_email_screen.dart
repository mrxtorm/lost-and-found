import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import 'login_screen.dart';

/// Blocks access until the signed-in user has opened the verification link
/// that Firebase emailed them. [onVerified] runs once the check succeeds.
class VerifyEmailScreen extends StatefulWidget {
  final VoidCallback onVerified;

  const VerifyEmailScreen({super.key, required this.onVerified});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  static const int _resendCooldownSeconds = 60;

  bool _isChecking = false;
  bool _isSending = false;
  int _cooldown = 0;
  Timer? _cooldownTimer;

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _checkVerified() async {
    setState(() => _isChecking = true);
    try {
      final verified =
          await context.read<AuthProvider>().reloadAndCheckVerified();
      if (!mounted) return;
      if (verified) {
        widget.onVerified();
      } else {
        _showMessage('Your email is not verified yet. Open the link we sent '
            'you, then tap this button again.');
      }
    } catch (_) {
      _showMessage('Could not check verification. Check your connection and '
          'try again.');
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  Future<void> _resend() async {
    setState(() => _isSending = true);
    try {
      await context.read<AuthProvider>().sendEmailVerification();
      _showMessage('Verification email sent.');
      _startCooldown();
    } catch (e) {
      _showMessage(e.toString());
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _startCooldown() {
    _cooldownTimer?.cancel();
    setState(() => _cooldown = _resendCooldownSeconds);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() => _cooldown--);
      if (_cooldown <= 0) timer.cancel();
    });
  }

  Future<void> _signOut() async {
    await context.read<AuthProvider>().signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final email = context.watch<AuthProvider>().user?.email ?? 'your email';

    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Verify Your Email'),
          centerTitle: true,
          automaticallyImplyLeading: false,
        ),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              Icon(
                Icons.mark_email_read_outlined,
                size: 72,
                color: Colors.blue.shade700,
              ),
              const SizedBox(height: 16),
              Text(
                'Check your inbox',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'We sent a verification link to $email. Open it, then come '
                'back and tap the button below. Check your spam folder if you '
                'cannot find it.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 28),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isChecking ? null : _checkVerified,
                  child: _isChecking
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text("I've Verified My Email"),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: (_isSending || _cooldown > 0) ? null : _resend,
                child: Text(
                  _cooldown > 0
                      ? 'Resend email ($_cooldown s)'
                      : 'Resend verification email',
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _signOut,
                child: const Text('Use a different account'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
