import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/app_feedback.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/terms_service.dart';
import 'login_screen.dart';
import 'main_navigation_screen.dart';
import 'terms_screen.dart';
import 'verify_email_screen.dart';

/// Decides whether the signed-in user may enter the app. Shown after login,
/// after registration and from the splash screen.
///
/// A user reaches [MainNavigationScreen] only when:
///  1. they have accepted the current Terms of Service version, and
///  2. their email is verified.
///
/// Firestore rules enforce the same two conditions server-side; this gate
/// only decides which screen to show.
class AccessGate extends StatefulWidget {
  const AccessGate({super.key});

  @override
  State<AccessGate> createState() => _AccessGateState();
}

enum _Step { loading, needsTerms, needsVerification, allowed, error }

class _AccessGateState extends State<AccessGate> {
  final TermsService _termsService = TermsService();

  _Step _step = _Step.loading;
  bool _isRecording = false;
  bool _termsAutoShown = false;

  @override
  void initState() {
    super.initState();
    _evaluate();
  }

  Future<void> _evaluate() async {
    // Read the live user: after reload() the provider's cached User object
    // can still report emailVerified == false, which would loop back to the
    // verify screen.
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _goToLogin();
      return;
    }

    setState(() => _step = _Step.loading);

    // Step 1: email must be verified. Terms come right after, so a new
    // account sees them once, immediately after verifying.
    if (!user.emailVerified) {
      setState(() => _step = _Step.needsVerification);
      return;
    }

    try {
      final accepted = await _termsService.hasAcceptedCurrent(user.uid);
      if (!mounted) return;
      if (!accepted) {
        setState(() => _step = _Step.needsTerms);
        // Pop the Terms up automatically once; if saving fails the prompt
        // screen's button lets the user retry.
        if (!_termsAutoShown) {
          _termsAutoShown = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _step == _Step.needsTerms) _reviewTerms();
          });
        }
      } else {
        setState(() => _step = _Step.allowed);
      }
    } catch (_) {
      if (mounted) setState(() => _step = _Step.error);
    }
  }

  void _goToLogin() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    });
  }

  Future<void> _reviewTerms() async {
    final accepted = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const TermsScreen(requireAcceptance: true),
      ),
    );
    if (!mounted) return;

    if (accepted != true) {
      await _declineAndSignOut();
      return;
    }

    setState(() => _isRecording = true);
    try {
      await _termsService.recordAcceptance();
      if (mounted) await _evaluate();
    } catch (_) {
      if (!mounted) return;
      AppSnack.show(context, 'Could not save your acceptance. Check your '
              'connection and try again.', kind: SnackKind.error);
    } finally {
      if (mounted) setState(() => _isRecording = false);
    }
  }

  Future<void> _declineAndSignOut() async {
    await context.read<AuthProvider>().signOut();
    _goToLogin();
  }

  @override
  Widget build(BuildContext context) {
    switch (_step) {
      case _Step.allowed:
        return const MainNavigationScreen();
      case _Step.needsVerification:
        return VerifyEmailScreen(onVerified: _evaluate);
      case _Step.needsTerms:
        return _AcceptTermsPrompt(
          isBusy: _isRecording,
          onReview: _reviewTerms,
          onDecline: _declineAndSignOut,
        );
      case _Step.error:
        return Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Could not verify your account access. Check your '
                    'connection and try again.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _evaluate,
                    child: const Text('Retry'),
                  ),
                  TextButton(
                    onPressed: _declineAndSignOut,
                    child: const Text('Sign out'),
                  ),
                ],
              ),
            ),
          ),
        );
      case _Step.loading:
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
  }
}

/// Shown when a signed-in user has not accepted the current Terms version
/// (new registrations that were interrupted, existing users, or a new
/// Terms version).
class _AcceptTermsPrompt extends StatelessWidget {
  final bool isBusy;
  final VoidCallback onReview;
  final VoidCallback onDecline;

  const _AcceptTermsPrompt({
    required this.isBusy,
    required this.onReview,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(Icons.gavel_outlined, size: 72, color: AppColors.primary),
              const SizedBox(height: 16),
              const Text(
                'Terms of Service',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'You must review and accept the Terms of Service and User '
                'Agreement (version ${TermsService.currentVersion}) to use '
                'Campus Lost & Found.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: AppColors.muted),
              ),
              const SizedBox(height: 28),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: isBusy ? null : onReview,
                  child: isBusy
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Review and Accept'),
                ),
              ),
              TextButton(
                onPressed: isBusy ? null : onDecline,
                child: const Text('Decline and sign out'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}