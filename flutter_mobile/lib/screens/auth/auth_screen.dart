import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';

// ═══════════════════════════════════════════════════════════
//  AUTH SCREEN — Sign In / Register (floating modal style)
// ═══════════════════════════════════════════════════════════

class AuthScreen extends StatefulWidget {
  final String tab;
  const AuthScreen({super.key, this.tab = 'sign'});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  late TabController _tabs;
  final _emailC = TextEditingController();
  final _passC  = TextEditingController();
  final _nameC  = TextEditingController();
  final _regEmailC = TextEditingController();
  final _phoneC    = TextEditingController();
  final _regPassC  = TextEditingController();
  final _confPassC = TextEditingController();

  String? _loginErr;
  String? _regErr;
  bool _loginLoading = false;
  bool _regLoading   = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this, initialIndex: widget.tab == 'reg' ? 1 : 0);
  }

  @override
  void dispose() {
    _tabs.dispose();
    for (final c in [_emailC,_passC,_nameC,_regEmailC,_phoneC,_regPassC,_confPassC]) c.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() { _loginErr = null; _loginLoading = true; });
    final provider = context.read<AppProvider>();
    provider.showLoader('Signing in…');
    final err = await provider.doLogin(_emailC.text.trim(), _passC.text);
    provider.hideLoader();
    if (!mounted) return;
    if (err != null) {
      setState(() { _loginErr = err; _loginLoading = false; });
    } else {
      setState(() { _loginLoading = false; });
      // Router redirects automatically
    }
  }

  Future<void> _register() async {
    setState(() { _regErr = null; _regLoading = true; });
    final provider = context.read<AppProvider>();
    provider.showLoader('Creating account…');
    final err = await provider.doRegister(
      name:  _nameC.text.trim(),
      email: _regEmailC.text.trim(),
      phone: _phoneC.text.trim(),
      pass:  _regPassC.text,
      pass2: _confPassC.text,
    );
    provider.hideLoader();
    if (!mounted) return;
    if (err != null) {
      setState(() { _regErr = err; _regLoading = false; });
    } else {
      setState(() { _regLoading = false; });
    }
  }

  Future<void> _googleSignIn({required bool fromRegister}) async {
    setState(() {
      if (fromRegister) {
        _regErr = null;
        _regLoading = true;
      } else {
        _loginErr = null;
        _loginLoading = true;
      }
    });
    final error = await context.read<AppProvider>().doGoogleSignIn();
    if (!mounted) return;
    setState(() {
      if (fromRegister) {
        _regErr = error;
        _regLoading = false;
      } else {
        _loginErr = error;
        _loginLoading = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: const Color(0xE0061020),
      body: Stack(children: [
        // Backdrop — tappable to go back
        GestureDetector(
          onTap: () => context.canPop() ? context.pop() : context.go('/'),
          child: Container(color: Colors.transparent, width: double.infinity, height: double.infinity),
        ),
        Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Container(
              width: size.width > 600 ? 440 : double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [BoxShadow(color: Color(0x55000000), blurRadius: 80, offset: Offset(0, 24))],
              ),
              padding: const EdgeInsets.all(40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Close
                  Align(
                    alignment: Alignment.topRight,
                    child: GestureDetector(
                      onTap: () => context.canPop() ? context.pop() : context.go('/'),
                      child: const Icon(Icons.close, color: Color(0xFF6B7280), size: 22),
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Logo
                  RichText(text: const TextSpan(
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF111827)),
                    children: [
                      TextSpan(text: 'Laba'),
                      TextSpan(text: 'Flow', style: TextStyle(color: AppColors.lpAccent)),
                    ],
                  )),
                  const SizedBox(height: 4),
                  const Text('Lab-a-Day Laundry Management System',
                    style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)), textAlign: TextAlign.center),
                  const SizedBox(height: 20),
                  // Tabs
                  Container(
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB), width: 2)),
                    ),
                    child: TabBar(
                      controller: _tabs,
                      labelColor: AppColors.lpAccent,
                      unselectedLabelColor: const Color(0xFF6B7280),
                      indicatorColor: AppColors.lpAccent,
                      indicatorSize: TabBarIndicatorSize.tab,
                      tabs: const [Tab(text: 'Sign In'), Tab(text: 'Register')],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Tab content
                  SizedBox(
                    height: _tabs.index == 0 ? 360 : 400,
                    child: TabBarView(
                      controller: _tabs,
                      children: [_buildSignIn(), _buildRegister()],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildSignIn() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        _LightField(controller: _emailC, label: 'Email', hint: 'email@address.com', type: TextInputType.emailAddress),
        const SizedBox(height: 14),
        _LightField(controller: _passC, label: 'Password', hint: '••••••••', obscure: true),
        if (_loginErr != null) ...[
          const SizedBox(height: 8),
          _ErrBox(_loginErr!),
        ],
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _loginLoading ? null : _login,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.lpAccent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: _loginLoading
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Sign In →', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          ),
        ),
        const SizedBox(height: 12),
        Row(children: const [
          Expanded(child: Divider()),
          Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('OR', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF6B7280)))),
          Expanded(child: Divider()),
        ]),
        const SizedBox(height: 12),
        _googleButton(
          loading: _loginLoading,
          onPressed: () => _googleSignIn(fromRegister: false),
        ),
        ],
      ),
    );
  }

  Widget _googleButton({required bool loading, required VoidCallback onPressed}) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: loading ? null : onPressed,
        icon: const Text('G', style: TextStyle(color: Color(0xFF4285F4), fontWeight: FontWeight.w800, fontSize: 17)),
        label: const Text('Continue with Google'),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF1F2937),
          padding: const EdgeInsets.symmetric(vertical: 12),
          side: const BorderSide(color: Color(0xFFD1D5DB)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  Widget _buildRegister() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              border: Border.all(color: const Color(0xFFBFDBFE)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Customer self-registration. Staff accounts are created by Admin.',
              style: TextStyle(fontSize: 12, color: Color(0xFF1D4ED8)),
            ),
          ),
          const SizedBox(height: 14),
          _LightField(controller: _nameC,    label: 'Full Name', hint: 'Juan dela Cruz'),
          const SizedBox(height: 14),
          _LightField(controller: _regEmailC,label: 'Email',     hint: 'juan@gmail.com', type: TextInputType.emailAddress),
          const SizedBox(height: 14),
          _LightField(controller: _phoneC,   label: 'Phone',     hint: '09171234567', type: TextInputType.phone),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: _LightField(controller: _regPassC,  label: 'Password', hint: 'Min 6 chars', obscure: true)),
            const SizedBox(width: 12),
            Expanded(child: _LightField(controller: _confPassC, label: 'Confirm',  hint: 'Repeat',      obscure: true)),
          ]),
          if (_regErr != null) ...[
            const SizedBox(height: 8),
            _ErrBox(_regErr!),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _regLoading ? null : _register,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.lpAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: _regLoading
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Create Account →', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 12),
          Row(children: const [
            Expanded(child: Divider()),
            Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('OR', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF6B7280)))),
            Expanded(child: Divider()),
          ]),
          const SizedBox(height: 12),
          _googleButton(
            loading: _regLoading,
            onPressed: () => _googleSignIn(fromRegister: true),
          ),
        ],
      ),
    );
  }
}

class _LightField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final bool obscure;
  final TextInputType type;
  const _LightField({
    required this.controller, required this.label, required this.hint,
    this.obscure = false, this.type = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF6B7280), letterSpacing: 0.4)),
        const SizedBox(height: 5),
        Builder(builder: (context) {
          final decoration = InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
            border:        OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1.5)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1.5)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.lpAccent, width: 1.5)),
          );
          final style = const TextStyle(fontSize: 13, color: Color(0xFF111827));
          return obscure
              ? PasswordInputField(controller: controller, keyboardType: type, style: style, decoration: decoration)
              : TextField(controller: controller, keyboardType: type, style: style, decoration: decoration);
        }),
      ],
    );
  }
}

class _ErrBox extends StatelessWidget {
  final String msg;
  const _ErrBox(this.msg);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        border: Border.all(color: const Color(0xFFFECACA)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(msg, style: const TextStyle(fontSize: 12, color: Color(0xFFDC2626))),
    );
  }
}
