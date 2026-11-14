import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../logic/auth/auth_bloc.dart';
import '../logic/auth/auth_event.dart';
import '../logic/auth/auth_state.dart';
import '../services/api_client.dart';
import '../services/api_exception.dart';

/// Authenticated account-management flow. Open this page from the Profile
/// navigation item; leave the existing top-right account popup unchanged.
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key, this.onNameUpdated, this.embedded = false});

  final bool embedded;

  /// The parent can use the returned name to refresh its account display.
  final ValueChanged<String>? onNameUpdated;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  static const _darkGreen = Color(0xFF164B2C);
  static const _green = Color(0xFF278D24);
  static const _orange = Color(0xFFFF810F);
  static const _cream = Color(0xFFFFFAF3);
  static const _softGreen = Color(0xFFEAF7D8);

  String? _updatedName;

  bool get _desktop => MediaQuery.sizeOf(context).width >= 700;

  String get _name => _updatedName ??
      context.read<AuthBloc>().state.user?.name ?? 'Member';
  String get _email => context.read<AuthBloc>().state.user?.email ?? '';

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (previous, current) =>
          previous.isAuthenticated && !current.isAuthenticated,
      listener: (context, state) {
        if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
      },
      child: MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(_desktop ? 1.22 : 1.0),
        ),
        child: Scaffold(
        backgroundColor: _cream,
        appBar: widget.embedded ? null : AppBar(
          backgroundColor: _cream,
          surfaceTintColor: Colors.transparent,
          title: const Text('My Profile', style: TextStyle(fontWeight: FontWeight.w700)),
          centerTitle: false,
        ),
        body: _pageFrame(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _profileCard(),
              const SizedBox(height: 28),
              const Text('Account Settings', style: TextStyle(
                color: _darkGreen, fontWeight: FontWeight.w800, fontSize: 19,
              )),
              const SizedBox(height: 12),
              _settingTile(
                icon: Icons.manage_accounts_outlined,
                title: 'Edit Profile',
                subtitle: 'Update your display name',
                onTap: _openEditProfile,
              ),
              const SizedBox(height: 12),
              _settingTile(
                icon: Icons.lock_outline,
                title: 'Change Password',
                subtitle: 'Manage your password securely',
                onTap: _openChangePassword,
              ),
              const SizedBox(height: 12),
              _settingTile(
                icon: Icons.logout_rounded,
                title: 'Log Out',
                subtitle: null,
                destructive: true,
                onTap: _confirmLogout,
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }

  Widget _pageFrame({required Widget child}) =>
      SafeArea(
        child: Stack(
          children: [
            Positioned(
              bottom: -45, right: -35,
              child: IgnorePointer(child: Icon(Icons.spa_rounded,
                size: 210, color: const Color(0xFFB8E781).withValues(alpha: .28))),
            ),
            SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20, _desktop ? 28 : 18, 20, 45),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: _desktop ? 640 : 520),
                  child: child,
                ),
              ),
            ),
          ],
        ),
      );

  Widget _profileCard() => Container(
    padding: EdgeInsets.all(_desktop ? 28 : 20),
    decoration: BoxDecoration(
      gradient: const LinearGradient(colors: [Color(0xFFF0F9E6), Color(0xFFDDF3C4)]),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Row(children: [
      CircleAvatar(
        radius: _desktop ? 43 : 34, backgroundColor: _green,
        child: Icon(Icons.person, size: _desktop ? 53 : 43, color: Colors.white),
      ),
      SizedBox(width: _desktop ? 22 : 16),
      Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_name, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
          const SizedBox(height: 3),
          Text(_email, style: const TextStyle(fontSize: 13)),
          const SizedBox(height: 9),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
            decoration: BoxDecoration(color: const Color(0xFFC4F19E),
              borderRadius: BorderRadius.circular(20)),
            child: const Text('Registered Member', style: TextStyle(
              color: _darkGreen, fontWeight: FontWeight.w700, fontSize: 12)),
          ),
        ],
      )),
    ]),
  );

  Widget _settingTile({
    required IconData icon,
    required String title,
    required String? subtitle,
    required VoidCallback onTap,
    bool destructive = false,
  }) => Material(
    color: destructive ? const Color(0xFFFFEEEE) : Colors.white,
    borderRadius: BorderRadius.circular(15),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: _desktop ? 22 : 15, vertical: _desktop ? 21 : 14),
        decoration: BoxDecoration(
          border: Border.all(color: destructive
            ? const Color(0xFFF5CECE) : const Color(0xFFE8E8DF)),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(children: [
          Container(
            width: _desktop ? 54 : 43, height: _desktop ? 54 : 43,
            decoration: BoxDecoration(
              color: destructive ? const Color(0xFFFFE2E2) : _softGreen,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, size: _desktop ? 29 : 24, color: destructive ? const Color(0xFFB52121) : _green),
          ),
          SizedBox(width: _desktop ? 18 : 13),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontWeight: FontWeight.w700,
                color: destructive ? const Color(0xFFB52121) : Colors.black87)),
              if (subtitle != null) ...[
                const SizedBox(height: 3),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.black54)),
              ],
            ],
          )),
          Icon(Icons.chevron_right, color: destructive ? const Color(0xFFB52121) : Colors.black87),
        ]),
      ),
    ),
  );

  Future<void> _openEditProfile() async {
    final updated = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => _EditProfilePage(name: _name, email: _email)),
    );
    if (!mounted || updated == null) return;
    setState(() => _updatedName = updated);
    widget.onNameUpdated?.call(updated);
  }

  void _openChangePassword() {
    Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => const _ChangePasswordPage()),
    );
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        backgroundColor: Colors.white,
        title: const Column(children: [
          Icon(Icons.logout_rounded, size: 43, color: _orange),
          SizedBox(height: 12),
          Text('Log Out?', style: TextStyle(fontWeight: FontWeight.w800)),
        ]),
        content: const Text(
          'Are you sure you want to log out of MealMate?\n\n'
          'Your saved account data will remain available when you log in again.',
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _orange),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    context.read<AuthBloc>().add(const AuthLogoutRequested());
  }
}

class _EditProfilePage extends StatefulWidget {
  const _EditProfilePage({required this.name, required this.email});
  final String name;
  final String email;

  @override
  State<_EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<_EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.name);
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _saving) return;
    final name = _name.text.trim();
    if (name == widget.name) {
      Navigator.of(context).pop(name);
      return;
    }
    setState(() => _saving = true);
    try {
      final response = await context.read<ApiClient>().patch(
        '/users/me', data: {'name': name},
      );
      if (response['success'] != true) throw StateError('Could not save your profile.');
      if (!mounted) return;
      Navigator.of(context).pop(name);
    } catch (error) {
      if (!mounted) return;
      _showError(context, error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => _formScaffold(
    context: context,
    title: 'Edit Profile',
    child: Form(
      key: _formKey,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const _FieldLabel('Full Name'),
        TextFormField(
          controller: _name,
          maxLength: 80,
          decoration: _inputDecoration('Enter your full name', Icons.person_outline),
          textCapitalization: TextCapitalization.words,
          validator: (value) {
            final name = value?.trim() ?? '';
            if (name.length < 2) return 'Name must be at least 2 characters.';
            if (name.length > 80) return 'Name cannot exceed 80 characters.';
            return null;
          },
        ),
        const SizedBox(height: 18),
        const _FieldLabel('Email Address'),
        TextFormField(
          initialValue: widget.email,
          readOnly: true,
          decoration: _inputDecoration('Email address', Icons.mail_outline)
              .copyWith(fillColor: const Color(0xFFF0F0F0)),
        ),
        const SizedBox(height: 8),
        const Row(children: [
          Icon(Icons.info_outline, size: 17, color: Colors.black54),
          SizedBox(width: 7),
          Text('Email cannot be changed.', style: TextStyle(color: Colors.black54)),
        ]),
        const SizedBox(height: 42),
        _primaryButton('Save Changes', Icons.check, _saving ? null : _save,
            loading: _saving),
      ]),
    ),
  );
}

class _ChangePasswordPage extends StatefulWidget {
  const _ChangePasswordPage();
  @override
  State<_ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<_ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _new = TextEditingController();
  final _confirm = TextEditingController();
  bool _saving = false;
  final _visible = <int, bool>{};

  @override
  void dispose() {
    _current.dispose();
    _new.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Widget _passwordField(String label, String hint,
      TextEditingController controller, int index, String? Function(String?) validator) {
    final visible = _visible[index] ?? false;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _FieldLabel(label),
      TextFormField(
        controller: controller,
        obscureText: !visible,
        enableSuggestions: false,
        autocorrect: false,
        decoration: _inputDecoration(hint, Icons.lock_outline).copyWith(
          suffixIcon: IconButton(
            tooltip: visible ? 'Hide password' : 'Show password',
            icon: Icon(visible ? Icons.visibility_off_outlined : Icons.visibility_outlined),
            onPressed: () => setState(() => _visible[index] = !visible),
          ),
        ),
        validator: validator,
      ),
    ]);
  }

  Future<void> _updatePassword() async {
    if (!_formKey.currentState!.validate() || _saving) return;
    setState(() => _saving = true);
    try {
      final response = await context.read<ApiClient>().patch(
        '/users/me/password',
        data: {'currentPassword': _current.text, 'newPassword': _new.text},
      );
      if (response['success'] != true) throw StateError('Password update failed.');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated successfully.')),
      );
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      _showError(context, error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => _formScaffold(
    context: context,
    title: 'Change Password',
    child: Form(
      key: _formKey,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _passwordField('Current Password', 'Enter current password', _current, 0,
          (v) => (v == null || v.isEmpty) ? 'Enter your current password.' : null),
        const SizedBox(height: 22),
        _passwordField('New Password', 'Enter new password', _new, 1, (v) {
          if (v == null || v.length < 8) return 'At least 8 characters required.';
          if (v == _current.text) return 'Choose a different password.';
          return null;
        }),
        const SizedBox(height: 8),
        const Row(children: [
          Icon(Icons.info_outline, size: 17, color: Colors.black54),
          SizedBox(width: 7),
          Text('At least 8 characters.', style: TextStyle(color: Colors.black54)),
        ]),
        const SizedBox(height: 22),
        _passwordField('Confirm New Password', 'Confirm new password', _confirm, 2,
          (v) => v != _new.text ? 'Passwords do not match.' : null),
        const SizedBox(height: 42),
        _primaryButton('Update Password', Icons.shield_outlined,
          _saving ? null : _updatePassword, loading: _saving),
      ]),
    ),
  );
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);
  final String label;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 9),
    child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
  );
}

InputDecoration _inputDecoration(String hint, IconData icon) => InputDecoration(
  hintText: hint,
  prefixIcon: Icon(icon, color: const Color(0xFF245D35)),
  filled: true,
  fillColor: Colors.white,
  contentPadding: const EdgeInsets.symmetric(vertical: 17, horizontal: 14),
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: Color(0xFFBEC5C0)),
  ),
);

Widget _primaryButton(String label, IconData icon, VoidCallback? onPressed,
    {bool loading = false}) => SizedBox(
  height: 51,
  child: FilledButton.icon(
    onPressed: onPressed,
    style: FilledButton.styleFrom(
      backgroundColor: const Color(0xFF258E20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
    ),
    icon: loading
      ? const SizedBox(width: 18, height: 18,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
      : Icon(icon),
    label: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
  ),
);

Widget _formScaffold({required BuildContext context, required String title,
    required Widget child}) => MediaQuery(
  data: MediaQuery.of(context).copyWith(
    textScaler: TextScaler.linear(MediaQuery.sizeOf(context).width >= 700 ? 1.22 : 1.0),
  ),
  child: Scaffold(
  backgroundColor: const Color(0xFFFFFAF3),
  appBar: AppBar(
    backgroundColor: const Color(0xFFFFFAF3),
    surfaceTintColor: Colors.transparent,
    title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
  ),
  body: SafeArea(child: Stack(children: [
    Positioned(bottom: -45, right: -30,
      child: IgnorePointer(child: Icon(Icons.spa_rounded, size: 210,
        color: const Color(0xFFB8E781).withValues(alpha: .28)))),
    SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 45),
      child: Center(child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width >= 700 ? 640 : 520),
        child: child,
      )),
    ),
  ])),
  ),
);

void _showError(BuildContext context, Object error) {
  final message = error is ApiException ? error.message : error.toString();
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
