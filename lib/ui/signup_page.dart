import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../constants/app_colors.dart';
import '../logic/auth/auth_bloc.dart';
import '../logic/auth/auth_event.dart';
import '../logic/auth/auth_state.dart';
import 'home_page.dart';
import '../services/api_client.dart';
import '../repositories/guest_transfer_repository.dart';
import 'login_page.dart';

/// MealMate account creation screen for Windows and Android.
class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();

  ({DateTime date, int? budget, Object? plan})? _guestSnapshot;
  bool _transferring = false;
  String? _transferError;

  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    HomePage.registrationTransferPending = false;
    super.dispose();
  }

  void _signUp() {
    if (!_formKey.currentState!.validate()) return;

    _guestSnapshot = HomePage.guestSnapshot();
    HomePage.registrationTransferPending = true;
    _transferError = null;
    context.read<AuthBloc>().add(
      AuthRegisterRequested(
        name: _name.text.trim(),
        email: _email.text.trim(),
        password: _password.text,
      ),
    );
  }

  Future<void> _onAuthenticated() async {
    if (!mounted || _transferring) return;
    final snapshot = _guestSnapshot;
    if (snapshot != null && (snapshot.budget != null || snapshot.plan != null)) {
      setState(() { _transferring = true; _transferError = null; });
      try {
        await GuestTransferRepository(context.read<ApiClient>()).transfer(
          date: snapshot.date,
          guestBudget: snapshot.budget,
          guestPlan: snapshot.plan,
        );
        if (!mounted) return;
        _guestSnapshot = null;
      } catch (error) {
        if (!mounted) return;
        setState(() {
          _transferring = false;
          _transferError = 'Account created, but guest data transfer failed: $error';
        });
        return; // Keep snapshot available for Retry; do not silently lose data.
      }
      if (!mounted) return;
      setState(() => _transferring = false);
    }
    if (!mounted) return;

    // The transfer has completed; permit authenticated Home GET requests.
    HomePage.registrationTransferPending = false;
    HomePage.refreshAfterTransfer();

    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.popUntil((route) => route.isFirst);
    } else {
      navigator.pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const HomePage()),
      );
    }
    // Refresh after navigation so the Home session loader fetches
    // the transferred budget and meal plan from PostgreSQL.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      HomePage.refreshAfterTransfer();
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listenWhen: (previous, current) =>
          previous.status != current.status && current.isAuthenticated,
      listener: (context, _) => _onAuthenticated(),
      builder: (context, authState) {
        return Scaffold(
          backgroundColor: AppColors.cream,
          body: Stack(
            children: [
              const Positioned.fill(child: _BackgroundLeaves()),
              SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 72, 20, 32),
                    child: Container(
                      width: 520,
                      padding: const EdgeInsets.fromLTRB(34, 34, 34, 30),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFCF8),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: const Color(0xFFEDE8E0)),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x1B213321),
                            blurRadius: 38,
                            offset: Offset(0, 14),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_transferring) const LinearProgressIndicator(),
                            if (_transferError != null) ...[
                              Text(_transferError!, style: const TextStyle(color: Colors.red)),
                              const SizedBox(height: 8),
                              ElevatedButton(
                                onPressed: _onAuthenticated,
                                child: const Text('Retry guest data transfer'),
                              ),
                              const SizedBox(height: 12),
                            ],
                            Image.asset(
                              'assets/img/logo.png',
                              height: 76,
                              fit: BoxFit.contain,
                              errorBuilder: (_, _, _) => const Icon(
                                Icons.restaurant_menu_rounded,
                                size: 66,
                                color: AppColors.orange,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Create Account',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 7),
                            const Text(
                              'Save your plans, favorites and expenses.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 15,
                                color: AppColors.textMuted,
                              ),
                            ),
                            const SizedBox(height: 26),
                            TextFormField(
                              controller: _name,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.name],
                              validator: (value) {
                                final name = (value ?? '').trim();
                                if (name.isEmpty) {
                                  return 'Please enter your name.';
                                }
                                if (name.length < 2) {
                                  return 'Name must be at least 2 characters.';
                                }
                                return null;
                              },
                              decoration: _inputDecoration(
                                'Full name',
                                Icons.person_outline_rounded,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _email,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.email],
                              validator: (value) {
                                final email = (value ?? '').trim();
                                if (email.isEmpty) {
                                  return 'Please enter your email.';
                                }
                                if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                                    .hasMatch(email)) {
                                  return 'Please enter a valid email.';
                                }
                                return null;
                              },
                              decoration: _inputDecoration(
                                'Email',
                                Icons.mail_outline_rounded,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _password,
                              obscureText: !_passwordVisible,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.newPassword],
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter a password.';
                                }
                                if (value.length < 8) {
                                  return 'Password must be at least 8 characters.';
                                }
                                return null;
                              },
                              decoration:
                                  _inputDecoration(
                                    'Password',
                                    Icons.lock_outline_rounded,
                                  ).copyWith(
                                    suffixIcon: IconButton(
                                      tooltip: _passwordVisible
                                          ? 'Hide password'
                                          : 'Show password',
                                      icon: Icon(
                                        _passwordVisible
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                      ),
                                      onPressed: () => setState(
                                        () => _passwordVisible =
                                            !_passwordVisible,
                                      ),
                                    ),
                                  ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _confirmPassword,
                              obscureText: !_confirmPasswordVisible,
                              textInputAction: TextInputAction.done,
                              autofillHints: const [AutofillHints.newPassword],
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please confirm your password.';
                                }
                                if (value != _password.text) {
                                  return 'Passwords do not match.';
                                }
                                return null;
                              },
                              onFieldSubmitted: (_) => _signUp(),
                              decoration:
                                  _inputDecoration(
                                    'Confirm password',
                                    Icons.lock_outline_rounded,
                                  ).copyWith(
                                    suffixIcon: IconButton(
                                      tooltip: _confirmPasswordVisible
                                          ? 'Hide password'
                                          : 'Show password',
                                      icon: Icon(
                                        _confirmPasswordVisible
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                      ),
                                      onPressed: () => setState(
                                        () => _confirmPasswordVisible =
                                            !_confirmPasswordVisible,
                                      ),
                                    ),
                                  ),
                            ),
                            if (authState.errorMessage != null) ...[
                              const SizedBox(height: 18),
                              _ErrorBanner(message: authState.errorMessage!),
                            ],
                            const SizedBox(height: 24),
                            SizedBox(
                              height: 56,
                              child: ElevatedButton(
                                onPressed: (authState.isSubmitting || _transferring || authState.isAuthenticated)
                                    ? null
                                    : _signUp,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.orange,
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor: AppColors.orange
                                      .withValues(alpha: 0.55),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                ),
                                child: authState.isSubmitting
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.4,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text(
                                        'Sign Up',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Wrap(
                              alignment: WrapAlignment.center,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                const Text(
                                  'Already have an account? ',
                                  style: TextStyle(fontSize: 15),
                                ),
                                TextButton(
                                  onPressed: () {
                                    final navigator = Navigator.of(context);
                                    if (navigator.canPop()) {
                                      navigator.pop();
                                    } else {
                                      navigator.pushReplacement(
                                        MaterialPageRoute<void>(
                                          builder: (_) => const LoginPage(),
                                        ),
                                      );
                                    }
                                  },
                                  style: TextButton.styleFrom(
                                    foregroundColor: AppColors.orange,
                                  ),
                                  child: const Text(
                                    'Log In',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 18,
                top: 16,
                child: SafeArea(
                  child: TextButton.icon(
                    onPressed: () {
                      final navigator = Navigator.of(context);
                      if (navigator.canPop()) {
                        navigator.pop();
                      } else {
                        navigator.pushReplacement(
                          MaterialPageRoute<void>(
                            builder: (_) => const HomePage(),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.arrow_back_rounded, size: 22),
                    label: const Text('Back'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.green,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: const Color(0xFF40464A)),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Color(0xFFE4E2DE)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: AppColors.orange, width: 1.6),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(
        color: AppColors.errorBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF3C7A8)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 20,
            color: Color(0xFFC05621),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 13.5, color: Color(0xFF8A3B12)),
            ),
          ),
        ],
      ),
    );
  }
}

class _BackgroundLeaves extends StatelessWidget {
  const _BackgroundLeaves();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: -120,
            right: -110,
            child: _circle(320, const Color(0xFFE7F2D2)),
          ),
          Positioned(
            bottom: -190,
            left: -120,
            child: _circle(410, const Color(0xFFE7F3D1)),
          ),
          Positioned(
            bottom: -90,
            right: -80,
            child: _circle(240, const Color(0xFFF8E9D6)),
          ),
        ],
      ),
    );
  }

  Widget _circle(double diameter, Color color) => Container(
    width: diameter,
    height: diameter,
    decoration: BoxDecoration(shape: BoxShape.circle, color: color),
  );
}
