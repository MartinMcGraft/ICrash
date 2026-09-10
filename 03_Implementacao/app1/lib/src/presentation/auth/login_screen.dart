import 'package:flutter/material.dart';

import '../../common/app_services.dart';
import '../../common/l10n/app_localizations.dart';
import '../../common/repository_failure.dart';

/// Spec workstream A: email+password sign-in.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    final auth = AppServicesScope.of(context).auth;
    try {
      await auth.signInWithEmailPassword(_emailController.text.trim(), _passwordController.text);
    } on RepositoryFailure catch (failure) {
      if (!mounted) return;
      setState(() => _errorMessage = _messageFor(failure));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String _messageFor(RepositoryFailure failure) {
    final l10n = AppLocalizations.of(context);
    switch (failure.reason) {
      case RepositoryFailureReason.unauthenticated:
        return l10n.loginErrorInvalidCredentials;
      case RepositoryFailureReason.offline:
        return l10n.loginErrorOffline;
      default:
        return l10n.loginErrorGeneric;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(l10n.appTitle, style: Theme.of(context).textTheme.headlineMedium, textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  Text(l10n.loginTagline, style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    decoration: InputDecoration(labelText: l10n.loginEmailLabel, border: const OutlineInputBorder()),
                    validator: (value) => (value == null || value.trim().isEmpty) ? l10n.loginEmailRequired : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    autofillHints: const [AutofillHints.password],
                    decoration: InputDecoration(labelText: l10n.loginPasswordLabel, border: const OutlineInputBorder()),
                    validator: (value) => (value == null || value.isEmpty) ? l10n.loginPasswordRequired : null,
                    onFieldSubmitted: (_) => _submit(),
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Text(_errorMessage!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                  ],
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _isSubmitting ? null : _submit,
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(l10n.loginSubmit),
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
