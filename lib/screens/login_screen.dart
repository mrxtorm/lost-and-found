import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/remembered_account.dart';
import '../providers/auth_provider.dart';
import 'forgot_password_screen.dart';
import 'main_navigation_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordFocusNode = FocusNode();

  bool _obscurePassword = true;

  // --- Account chooser state -------------------------------------------
  //
  // Remembered accounts are loaded from on-device storage (see
  // RememberedAccountsService), so this works even with no network
  // connection - the list simply won't include an account that has never
  // signed in on this device before.
  List<RememberedAccount> _rememberedAccounts = [];
  bool _loadingAccounts = true;
  RememberedAccount? _selectedAccount;
  bool _useAnotherAccount = false;

  @override
  void initState() {
    super.initState();
    _loadRememberedAccounts();
  }

  Future<void> _loadRememberedAccounts() async {
    final accounts = await context.read<AuthProvider>().getRememberedAccounts();
    if (!mounted) return;
    setState(() {
      _rememberedAccounts = accounts;
      _loadingAccounts = false;
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  bool get _showChooser =>
      !_loadingAccounts && _rememberedAccounts.isNotEmpty && !_useAnotherAccount;

  void _selectAccount(RememberedAccount account) {
    setState(() {
      _selectedAccount = account;
      _useAnotherAccount = true;
      _emailController.text = account.email;
    });
    // Give the form a beat to build before focusing the password field.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _passwordFocusNode.requestFocus();
    });
  }

  void _useAnotherAccountInstead() {
    setState(() {
      _selectedAccount = null;
      _useAnotherAccount = true;
      _emailController.clear();
      _passwordController.clear();
    });
  }

  void _backToChooser() {
    setState(() {
      _selectedAccount = null;
      _useAnotherAccount = false;
      _emailController.clear();
      _passwordController.clear();
    });
  }

  Future<void> _confirmRemoveAccount(RememberedAccount account) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Remove account"),
        content: Text(
          "Remove ${account.label} (${account.email}) from this device? "
          "You can always sign back in later.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text("Remove"),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await context.read<AuthProvider>().forgetRememberedAccount(account.uid);
    if (!mounted) return;
    setState(() {
      _rememberedAccounts.removeWhere((a) => a.uid == account.uid);
      if (_selectedAccount?.uid == account.uid) {
        _selectedAccount = null;
        _useAnotherAccount = _rememberedAccounts.isEmpty ? false : _useAnotherAccount;
        _emailController.clear();
      }
    });
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter email and password.")),
      );
      return;
    }

    final authProvider = context.read<AuthProvider>();

    try {
      final success = await authProvider.login(email, password);

      if (success && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  InputDecoration _fieldDecoration(String label, IconData icon, {Widget? suffix}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      suffixIcon: suffix,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      filled: true,
      fillColor: Colors.grey.shade50,
    );
  }

  MaterialColor _avatarColor(String seed) {
    const palette = [
      Colors.blue,
      Colors.teal,
      Colors.indigo,
      Colors.deepPurple,
      Colors.orange,
      Colors.pink,
    ];
    final index = seed.isEmpty ? 0 : seed.codeUnits.fold<int>(0, (a, b) => a + b) % palette.length;
    return palette[index];
  }

  Widget _accountAvatar(RememberedAccount account, {double radius = 24}) {
    final color = _avatarColor(account.uid);
    if (account.photoUrl != null && account.photoUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: NetworkImage(account.photoUrl!),
        backgroundColor: color.shade50,
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: color.shade50,
      child: Text(
        account.initial,
        style: TextStyle(
          color: color.shade700,
          fontWeight: FontWeight.bold,
          fontSize: radius * 0.75,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            children: [
              const SizedBox(height: 50),
              if (_selectedAccount != null)
                _accountAvatar(_selectedAccount!, radius: 46)
              else
                CircleAvatar(
                  radius: 46,
                  backgroundColor: Colors.blue.shade50,
                  child: Icon(
                    Icons.lock_outline,
                    size: 46,
                    color: Colors.blue.shade700,
                  ),
                ),
              const SizedBox(height: 20),
              Text(
                _showChooser
                    ? "Welcome back"
                    : (_selectedAccount != null
                        ? "Hi, ${_selectedAccount!.label}"
                        : "Welcome back"),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _showChooser
                    ? "Choose an account to continue"
                    : (_selectedAccount != null
                        ? "Enter your password to continue"
                        : "Log in to continue"),
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 28),
              if (_showChooser) _buildAccountChooser() else _buildForm(isLoading),
            ],
          ),
        ),
      ),
    );
  }

  /// The Facebook/Gmail-style account switcher: accounts that have signed
  /// in on this device before, remembered locally so they still show up
  /// after signing out - and even while offline, since nothing here needs
  /// a network call.
  Widget _buildAccountChooser() {
    return Column(
      children: [
        ..._rememberedAccounts.map(
          (account) => Card(
            margin: const EdgeInsets.only(bottom: 10),
            elevation: 0,
            color: Colors.grey.shade50,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              leading: _accountAvatar(account),
              title: Text(
                account.label,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(account.email),
              trailing: IconButton(
                icon: Icon(Icons.close, color: Colors.grey.shade500, size: 20),
                tooltip: "Remove from this device",
                onPressed: () => _confirmRemoveAccount(account),
              ),
              onTap: () => _selectAccount(account),
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: _useAnotherAccountInstead,
            icon: const Icon(Icons.person_add_alt),
            label: const Text("Add another account"),
          ),
        ),
      ],
    );
  }

  Widget _buildForm(bool isLoading) {
    return Column(
      children: [
        if (_selectedAccount != null && _rememberedAccounts.isNotEmpty)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _backToChooser,
              icon: const Icon(Icons.arrow_back, size: 18),
              label: const Text("Not you? Switch account"),
            ),
          ),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          readOnly: _selectedAccount != null,
          decoration: _fieldDecoration("University Email", Icons.email_outlined),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _passwordController,
          focusNode: _passwordFocusNode,
          obscureText: _obscurePassword,
          decoration: _fieldDecoration(
            "Password",
            Icons.lock_outline,
            suffix: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                color: Colors.grey.shade600,
              ),
              onPressed: () {
                setState(() => _obscurePassword = !_obscurePassword);
              },
            ),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ForgotPasswordScreen(),
                ),
              );
            },
            child: const Text("Forgot Password?"),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: isLoading ? null : _handleLogin,
            child: isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text("Login"),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Don't have an account?"),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const RegisterScreen(),
                  ),
                );
              },
              child: const Text("Register"),
            ),
          ],
        ),
      ],
    );
  }
}
