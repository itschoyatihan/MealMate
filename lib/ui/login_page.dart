import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../logic/auth/auth_bloc.dart';
import '../logic/auth/auth_event.dart';
import '../logic/auth/auth_state.dart';
import 'home_page.dart';
import 'signup_page.dart';

/// MealMate desktop-first login screen.
/// Authentication and registration will be connected in later steps.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  static const Color orange = Color(0xFFFF7900);
  static const Color green = Color(0xFF073F23);
  static const Color cream = Color(0xFFFFF8F0);

  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _passwordVisible = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _goBack() {
    final nav = Navigator.of(context);
    if (nav.canPop()) {
      nav.pop();
    } else {
      nav.pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const HomePage()),
      );
    }
  }

  void _logIn() {
    if (!_formKey.currentState!.validate()) return;

    context.read<AuthBloc>().add(
      AuthLoginRequested(email: _email.text.trim(), password: _password.text),
    );
  }

  void _signUp() {
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => const SignUpPage()));
  }

  void _onAuthenticated() {
    if (!mounted) return;

    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.popUntil((route) => route.isFirst);
    } else {
      navigator.pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const HomePage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listenWhen: (previous, current) =>
          previous.status != current.status && current.isAuthenticated,
      listener: (context, _) => _onAuthenticated(),
      builder: (context, authState) {
        return Scaffold(
          backgroundColor: cream,
          resizeToAvoidBottomInset: true,
          body: LayoutBuilder(
            builder: (context, size) {
              final wide = size.maxWidth >= 800;
              final isSmallMobile = size.maxWidth < 600;
              return Stack(
                children: [
                  const Positioned.fill(child: _BackgroundLeaves()),
                  Center(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        isSmallMobile ? 12 : 24,
                        isSmallMobile ? 76 : 24,
                        isSmallMobile ? 12 : 24,
                        24,
                      ),
                      child: Container(
                        width: wide ? 1040 : 520,
                        height: wide ? 580 : null,
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
                        clipBehavior: Clip.antiAlias,
                        child: wide
                            ? Row(
                                children: [
                                  Expanded(child: _brandPanel()),
                                  Expanded(
                                    child: _formPanel(
                                      wide: true,
                                      authState: authState,
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _brandPanel(compact: true),
                                  _formPanel(wide: false, authState: authState),
                                ],
                              ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 30,
                    top: 22,
                    child: SafeArea(
                      child: TextButton.icon(
                        onPressed: _goBack,
                        icon: const Icon(Icons.arrow_back_rounded, size: 23),
                        label: const Text('Back to Home'),
                        style: TextButton.styleFrom(foregroundColor: green),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _brandPanel({bool compact = false}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 20 : 48,
        vertical: compact ? 25 : 50,
      ),
      decoration: compact
          ? null
          : const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFFF9F1), Color(0xFFF0F8DF)],
              ),
            ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/img/logo.png',
            height: compact ? 72 : 116,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => Icon(
              Icons.restaurant_menu_rounded,
              size: compact ? 65 : 105,
              color: orange,
            ),
          ),
          const SizedBox(height: 14),
          RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: compact ? 32 : 52,
                fontWeight: FontWeight.w800,
                letterSpacing: -1.8,
              ),
              children: const [
                TextSpan(
                  text: 'Meal',
                  style: TextStyle(color: green),
                ),
                TextSpan(
                  text: 'Mate',
                  style: TextStyle(color: orange),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Plan · Eat · Save',
            style: TextStyle(fontSize: compact ? 17 : 20, color: green),
          ),
          if (!compact) ...[
            const SizedBox(height: 34),
            Image.asset(
              'assets/img/bowl.png',
              height: 210,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => const Icon(
                Icons.ramen_dining_rounded,
                color: orange,
                size: 150,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _formPanel({required bool wide, required AuthState authState}) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        wide ? 54 : 28,
        wide ? 56 : 12,
        wide ? 54 : 28,
        wide ? 56 : 32,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Log In',
            style: TextStyle(
              fontSize: wide ? 38 : 32,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF171717),
            ),
          ),
          const SizedBox(height: 9),
          const Text(
            'Welcome back to MealMate',
            style: TextStyle(fontSize: 16, color: Color(0xFF6B6B6B)),
          ),
          const SizedBox(height: 32),
          Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  validator: (value) {
                    final email = (value ?? '').trim();
                    if (email.isEmpty) return 'Please enter your email.';
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
                const SizedBox(height: 18),
                TextFormField(
                  controller: _password,
                  obscureText: !_passwordVisible,
                  autofillHints: const [AutofillHints.password],
                  validator: (value) => (value == null || value.isEmpty)
                      ? 'Please enter your password.'
                      : null,
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
                            () => _passwordVisible = !_passwordVisible,
                          ),
                        ),
                      ),
                  onFieldSubmitted: (_) => _logIn(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 27),
          if (authState.errorMessage != null) ...[
            _ErrorBanner(message: authState.errorMessage!),
            const SizedBox(height: 18),
          ],
          SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: authState.isSubmitting ? null : _logIn,
              style: ElevatedButton.styleFrom(
                backgroundColor: orange,
                foregroundColor: Colors.white,
                disabledBackgroundColor: orange.withValues(alpha: 0.55),
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
                      'Log In',
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text(
                "Don't have an account? ",
                style: TextStyle(fontSize: 15),
              ),
              TextButton(
                onPressed: _signUp,
                style: TextButton.styleFrom(foregroundColor: orange),
                child: const Text(
                  'Sign Up',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: const Color(0xFF40464A)),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 19, horizontal: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Color(0xFFE4E2DE)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: orange, width: 1.6),
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
        color: const Color(0xFFFFF1E6),
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
            top: -110,
            right: -110,
            child: _leafCircle(340, const Color(0xFFE7F2D2)),
          ),
          Positioned(
            bottom: -180,
            left: -110,
            child: _leafCircle(420, const Color(0xFFE7F3D1)),
          ),
          Positioned(
            bottom: -100,
            right: -80,
            child: _leafCircle(260, const Color(0xFFF8E9D6)),
          ),
        ],
      ),
    );
  }

  Widget _leafCircle(double diameter, Color color) => Container(
    width: diameter,
    height: diameter,
    decoration: BoxDecoration(shape: BoxShape.circle, color: color),
  );
}
