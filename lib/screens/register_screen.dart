import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/app_feedback.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import 'access_gate.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  /// Errors only show after the first "Create account" tap, then update
  /// live as the user fixes them.
  bool _submitted = false;

  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  @override
  void initState() {
    super.initState();
    // Rebuild the strength meter / match tick as the user types.
    _passwordController.addListener(_refresh);
    _confirmPasswordController.addListener(_refresh);
  }

  void _refresh() => setState(() {});

  @override
  void dispose() {
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    FocusScope.of(context).unfocus();
    setState(() => _submitted = true);
    if (!(_formKey.currentState?.validate() ?? false)) {
      AppSnack.show(
        context,
        'Please fix the highlighted fields.',
        kind: SnackKind.error,
      );
      return;
    }

    final firstName = _firstNameController.text.trim();
    final middleName = _middleNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final name = [firstName, middleName, lastName]
        .where((part) => part.isNotEmpty)
        .join(' ');
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    final authProvider = context.read<AuthProvider>();

    try {
      final success = await authProvider.register(email, password, name);

      if (success && mounted) {
        // Best effort: if sending fails, the verify screen has a resend
        // button. AccessGate shows the Terms once, right after verification.
        try {
          await authProvider.sendEmailVerification();
        } catch (_) {}

        if (!mounted) return;
        await _showCheckEmailDialog(email);

        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const AccessGate()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        AppSnack.show(context, e.toString(), kind: SnackKind.info);
      }
    }
  }

  Future<void> _showCheckEmailDialog(String email) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(
          Icons.mark_email_unread_outlined,
          color: AppColors.primary,
          size: 40,
        ),
        title: const Text("Check your email"),
        content: Text(
          "We sent a verification link to $email.\n\n"
          "If you don't see it in your inbox, please check your Spam or Junk folder too.",
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("OK, got it"),
          ),
        ],
      ),
    );
  }

  // ---- validation ---------------------------------------------------------

  String? _required(String? value, String what) =>
      (value ?? '').trim().isEmpty ? 'Enter your $what' : null;

  String? _validateEmail(String? value) {
    final email = (value ?? '').trim();
    if (email.isEmpty) return 'Enter your university email';
    if (!_emailPattern.hasMatch(email)) return 'That email doesn\'t look right';
    return null;
  }

  String? _validatePassword(String? value) {
    final password = (value ?? '').trim();
    if (password.isEmpty) return 'Create a password';
    if (password.length < 6) return 'Use at least 6 characters';
    return null;
  }

  String? _validateConfirm(String? value) {
    if ((value ?? '').trim().isEmpty) return 'Type your password again';
    if (value!.trim() != _passwordController.text.trim()) {
      return 'Passwords don\'t match';
    }
    return null;
  }

  /// 0..4: length >= 6, length >= 10, mixed case, has number or symbol.
  int _strength(String password) {
    if (password.isEmpty) return 0;
    var score = 0;
    if (password.length >= 6) score++;
    if (password.length >= 10) score++;
    if (RegExp(r'[a-z]').hasMatch(password) &&
        RegExp(r'[A-Z]').hasMatch(password)) {
      score++;
    }
    if (RegExp(r'[0-9!@#\$%^&*(),.?":{}|<>_\-]').hasMatch(password)) score++;
    return password.length < 6 ? 1 : score.clamp(1, 4);
  }

  // ---- building blocks ----------------------------------------------------

  InputDecoration _fieldDecoration(
    String label,
    IconData? icon, {
    String? hint,
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: icon == null ? null : Icon(icon),
      suffixIcon: suffix,
      fillColor: AppColors.bg,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        borderSide: BorderSide.none,
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w800,
          color: AppColors.ink,
        ),
      ),
    );
  }

  Widget _strengthMeter() {
    final password = _passwordController.text.trim();
    if (password.isEmpty) return const SizedBox.shrink();

    final score = _strength(password);
    const labels = ['', 'Too weak', 'Okay', 'Good', 'Strong'];
    final colors = [
      AppColors.line,
      AppColors.lost,
      AppColors.warn,
      Color(0xFF65A30D),
      AppColors.found,
    ];
    final color = colors[score];

    Widget tip(bool ok, String text) {
      return Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Row(
          children: [
            Icon(
              ok ? Icons.check_circle_rounded : Icons.circle_outlined,
              size: 17,
              color: ok ? AppColors.found : AppColors.muted,
            ),
            const SizedBox(width: 8),
            Text(
              text,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: ok ? FontWeight.w600 : FontWeight.w500,
                color: ok ? AppColors.ink : AppColors.muted,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 10, 4, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              for (var i = 1; i <= 4; i++) ...[
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 5,
                    decoration: BoxDecoration(
                      color: i <= score ? color : AppColors.track,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                if (i < 4) const SizedBox(width: 6),
              ],
              const SizedBox(width: 12),
              SizedBox(
                width: 64,
                child: Text(
                  labels[score],
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          tip(password.length >= 6, 'At least 6 characters (required)'),
          tip(
            RegExp(r'[a-z]').hasMatch(password) &&
                RegExp(r'[A-Z]').hasMatch(password),
            'Upper and lowercase letters',
          ),
          tip(
            RegExp(r'[0-9!@#\$%^&*(),.?":{}|<>_\-]').hasMatch(password),
            'A number or symbol',
          ),
        ],
      ),
    );
  }

  Widget _visibilityToggle(bool obscured, VoidCallback onPressed) {
    return IconButton(
      tooltip: obscured ? 'Show password' : 'Hide password',
      icon: Icon(
        obscured ? Icons.visibility_off_outlined : Icons.visibility_outlined,
        color: AppColors.muted,
      ),
      onPressed: onPressed,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;
    final confirm = _confirmPasswordController.text.trim();
    final passwordsMatch =
        confirm.isNotEmpty && confirm == _passwordController.text.trim();

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Form(
            key: _formKey,
            autovalidateMode: _submitted
                ? AutovalidateMode.onUserInteraction
                : AutovalidateMode.disabled,
            child: AutofillGroup(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // HEADER
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Image.asset(
                      'assets/icon/app_icon.png',
                      width: 64,
                      height: 64,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Create your account',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.6,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Join FoundIt to report lost items and help return '
                    'found ones. It only takes a minute.',
                    style: TextStyle(
                      fontSize: 15.5,
                      height: 1.45,
                      color: AppColors.muted,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // NAME
                  _sectionLabel('Your name'),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _firstNameController,
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.givenName],
                          validator: (v) => _required(v, 'first name'),
                          decoration: _fieldDecoration(
                            'First name',
                            Icons.person_outline_rounded,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _lastNameController,
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.familyName],
                          validator: (v) => _required(v, 'last name'),
                          decoration: _fieldDecoration('Last name', null),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _middleNameController,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.middleName],
                    decoration: _fieldDecoration(
                      'Middle name (optional)',
                      Icons.badge_outlined,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ACCOUNT
                  _sectionLabel('Account details'),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autocorrect: false,
                    autofillHints: const [AutofillHints.email],
                    validator: _validateEmail,
                    decoration: _fieldDecoration(
                      'University email',
                      Icons.alternate_email_rounded,
                      hint: 'name@university.edu',
                    ),
                  ),
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Text(
                      'We\'ll send a link here to verify it\'s you.',
                      style: TextStyle(fontSize: 13.5, color: AppColors.muted),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.newPassword],
                    validator: _validatePassword,
                    decoration: _fieldDecoration(
                      'Password',
                      Icons.lock_outline_rounded,
                      suffix: _visibilityToggle(
                        _obscurePassword,
                        () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                      ),
                    ),
                  ),
                  _strengthMeter(),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.newPassword],
                    validator: _validateConfirm,
                    onFieldSubmitted: (_) {
                      if (!isLoading) _handleRegister();
                    },
                    decoration: _fieldDecoration(
                      'Confirm password',
                      Icons.lock_reset_rounded,
                      suffix: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (passwordsMatch)
                            const Icon(
                              Icons.check_circle_rounded,
                              color: AppColors.found,
                              semanticLabel: 'Passwords match',
                            ),
                          _visibilityToggle(
                            _obscureConfirmPassword,
                            () => setState(
                              () => _obscureConfirmPassword =
                                  !_obscureConfirmPassword,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // SUBMIT
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton(
                      onPressed: isLoading ? null : _handleRegister,
                      child: isLoading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                color: Colors.white,
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Create account',
                                  style: TextStyle(
                                    fontSize: 16.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Icon(Icons.arrow_forward_rounded, size: 20),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          'Already have an account?',
                          style: TextStyle(
                            fontSize: 15,
                            color: AppColors.muted,
                          ),
                        ),
                        TextButton(
                          onPressed: isLoading
                              ? null
                              : () => Navigator.maybePop(context),
                          child: const Text(
                            'Log in',
                            style: TextStyle(fontSize: 15),
                          ),
                        ),
                      ],
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
