import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

/// Updated LoginScreen — identical to the original except:
/// • Adds an "Admin" role button alongside Student and Teacher.
/// • The admin role button uses AppGradients.orange.
class LoginScreen extends StatefulWidget {
  final VoidCallback onLogin;
  const LoginScreen({super.key, required this.onLogin});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLogin = true;
  String _role = 'student';
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nameCtrl     = TextEditingController();
  final _formKey      = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    bool ok;
    if (_isLogin) {
      ok = await auth.login(
          _emailCtrl.text.trim(), _passwordCtrl.text, _role);
    } else {
      ok = await auth.register(
          _emailCtrl.text.trim(), _passwordCtrl.text,
          _nameCtrl.text.trim(), _role);
    }
    if (ok && mounted) widget.onLogin();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1E1B4B), Color(0xFF4C1D95), Color(0xFF6B21A8)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(children: [
                    // ── Logo ──────────────────────────────────────────────
                    Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(
                        gradient: AppGradients.violet,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [BoxShadow(
                            color: AppColors.violet.withOpacity(0.5),
                            blurRadius: 20, offset: const Offset(0, 8))],
                      ),
                      child: const Icon(Icons.school_rounded,
                          color: Colors.white, size: 40),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _isLogin ? 'Welcome Back' : 'Create Account',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 28,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _isLogin
                          ? 'Sign in to continue your journey'
                          : 'Start your learning adventure',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.7), fontSize: 14),
                    ),
                    const SizedBox(height: 28),

                    // ── Name (register only) ───────────────────────────────
                    if (!_isLogin) ...[
                      _GlassField(
                        controller: _nameCtrl,
                        hint: 'Full Name',
                        icon: Icons.person_outline_rounded,
                        validator: (v) =>
                            v!.isEmpty ? 'Enter your name' : null,
                      ),
                      const SizedBox(height: 14),
                    ],

                    // ── Email ─────────────────────────────────────────────
                    _GlassField(
                      controller: _emailCtrl,
                      hint: 'your@email.com',
                      icon: Icons.mail_outline_rounded,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) =>
                          v!.isEmpty ? 'Enter your email' : null,
                    ),
                    const SizedBox(height: 14),

                    // ── Password ──────────────────────────────────────────
                    _GlassField(
                      controller: _passwordCtrl,
                      hint: '••••••••',
                      icon: Icons.lock_outline_rounded,
                      obscure: true,
                      validator: (v) =>
                          v!.length < 6 ? 'Min 6 characters' : null,
                    ),
                    const SizedBox(height: 20),

                    // ── Role selector ─────────────────────────────────────
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text('I am a',
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(height: 10),
                    // Row 1: Student + Teacher
                    Row(children: [
                      _RoleButton(
                        label: 'Student',
                        icon: Icons.person_rounded,
                        selected: _role == 'student',
                        activeGradient: AppGradients.violet,
                        onTap: () => setState(() => _role = 'student'),
                      ),
                      const SizedBox(width: 12),
                      _RoleButton(
                        label: 'Teacher',
                        icon: Icons.school_rounded,
                        selected: _role == 'teacher',
                        activeGradient: AppGradients.fuchsia,
                        onTap: () => setState(() => _role = 'teacher'),
                      ),
                    ]),
                    const SizedBox(height: 12),
                    // Row 2: Admin (full-width)
                    _RoleButton(
                      label: 'Admin',
                      icon: Icons.admin_panel_settings_rounded,
                      selected: _role == 'admin',
                      activeGradient: AppGradients.orange,
                      onTap: () => setState(() => _role = 'admin'),
                      fullWidth: true,
                    ),
                    const SizedBox(height: 24),

                    // ── Submit ────────────────────────────────────────────
                    GradientButton(
                      label: _isLogin ? 'Sign In' : 'Sign Up',
                      gradient: AppGradients.violet,
                      isLoading: auth.isLoading,
                      onPressed: _submit,
                    ),
                    const SizedBox(height: 18),

                    // ── Toggle ────────────────────────────────────────────
                    GestureDetector(
                      onTap: () => setState(() => _isLogin = !_isLogin),
                      child: Text(
                        _isLogin
                            ? "Don't have an account? Sign up"
                            : 'Already have an account? Sign in',
                        style: TextStyle(
                            color: Colors.purple.shade200,
                            fontSize: 13,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                  ]),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Shared sub-widgets (unchanged from original) ──────────────────────────────

class _GlassField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscure;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _GlassField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
        prefixIcon: Icon(icon, color: Colors.purple.shade300, size: 20),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: Colors.purple.shade300, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        errorStyle: const TextStyle(color: Colors.orange),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      ),
    );
  }
}

class _RoleButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final LinearGradient activeGradient;
  final VoidCallback onTap;
  final bool fullWidth;

  const _RoleButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.activeGradient,
    required this.onTap,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final button = GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: fullWidth ? double.infinity : null,
        padding: EdgeInsets.symmetric(
            vertical: 16, horizontal: fullWidth ? 24 : 0),
        decoration: BoxDecoration(
          gradient: selected ? activeGradient : null,
          color: selected ? null : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? Colors.transparent : Colors.white.withOpacity(0.2),
            width: 1.5,
          ),
          boxShadow: selected
              ? [BoxShadow(
                  color: activeGradient.colors.first.withOpacity(0.4),
                  blurRadius: 12, offset: const Offset(0, 4))]
              : [],
        ),
        child: fullWidth
            ? Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(icon, color: Colors.white, size: 22),
                const SizedBox(width: 10),
                Text(label, style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w600,
                    fontSize: 14)),
              ])
            : Column(children: [
                Icon(icon, color: Colors.white, size: 26),
                const SizedBox(height: 6),
                Text(label, style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w600,
                    fontSize: 13)),
              ]),
      ),
    );

    return fullWidth ? button : Expanded(child: button);
  }
}
