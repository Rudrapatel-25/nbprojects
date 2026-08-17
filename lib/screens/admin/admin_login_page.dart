import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/site_content.dart';
import '../../services/content_repository.dart';
import '../../widgets/luxury.dart';

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _form = GlobalKey<FormState>();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ContentRepository().signIn(
        _email.text.trim(),
        _password.text.trim(),
      );
      if (mounted) context.go('/admin');
    } on FirebaseAuthException catch (error) {
      setState(() => _error = error.message ?? 'Sign in failed');
    } catch (_) {
      setState(() => _error = 'Sign in failed');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = SiteContent.defaults();
    final colors = SiteColors(content.palette);
    return SiteScope(
      colors: colors,
      content: content,
      child: Scaffold(
        backgroundColor: colors.background,
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Container(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(36),
              decoration: BoxDecoration(
                color: colors.surface,
                border: Border.all(color: colors.brass.withValues(alpha: 0.45)),
              ),
              child: Form(
                key: _form,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'NB DEVELOPER',
                      style: GoogleFonts.cinzel(
                        color: colors.brass,
                        letterSpacing: 4,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Admin Panel',
                      style: GoogleFonts.playfairDisplay(
                        color: colors.text,
                        fontSize: 36,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sign in with the Firebase admin credentials to edit the live enquiry page.',
                      style: GoogleFonts.outfit(color: colors.muted),
                    ),
                    const SizedBox(height: 28),
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) =>
                          value == null || value.isEmpty ? 'Required' : null,
                      decoration: const InputDecoration(labelText: 'Email'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _password,
                      obscureText: true,
                      validator: (value) =>
                          value == null || value.isEmpty ? 'Required' : null,
                      onFieldSubmitted: (_) => _login(),
                      decoration: const InputDecoration(labelText: 'Password'),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 14),
                      Text(_error!, style: TextStyle(color: colors.brass)),
                    ],
                    const SizedBox(height: 28),
                    LuxuryButton(
                      label: _loading ? 'Signing in...' : 'Enter Studio',
                      onPressed: _loading ? () {} : _login,
                    ),
                    const SizedBox(height: 18),
                    TextButton(
                      onPressed: () => context.go('/'),
                      child: Text(
                        'Back to website',
                        style: GoogleFonts.outfit(color: colors.muted),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
