import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/firebase_auth_service.dart';
import '../models/user_model.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 48),
            // ── Logo ──
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B35),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.fitness_center,
                color: Colors.white,
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'GYMFORM',
              style: GoogleFonts.barlow(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                letterSpacing: 6,
                color: Colors.white,
              ),
            ),
            Text(
              'Track. Lift. Grow.',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 13,
                color: const Color(0xFF888888),
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 40),
            // ── Tab bar ──
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: const Color(0xFF141414),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF2A2A2A)),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorSize: TabBarIndicatorSize.tab,
                labelPadding: EdgeInsets.zero,
                indicatorPadding: EdgeInsets.zero,
                indicator: BoxDecoration(
                  color: const Color(0xFFFF6B35),
                  borderRadius: BorderRadius.circular(10),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: const Color(0xFF666666),
                labelStyle: GoogleFonts.barlow(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
                tabs: const [
                  Tab(text: 'LOGIN'),
                  Tab(text: 'REGISTER'),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: const [_LoginForm(), _RegisterForm()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── LOGIN FORM ───────────────────────────────────────────────────────────────

class _LoginForm extends StatefulWidget {
  const _LoginForm();

  @override
  State<_LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<_LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final result = await FirebaseAuthService.instance.login(
      email: _emailCtrl.text,
      password: _passCtrl.text,
    );

    if (mounted) {
      setState(() => _loading = false);
      if (!result.success) {
        _showError(result.error ?? 'Login gagal');
      }
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: const Color(0xFFFF4444),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(
                  Icons.email_outlined,
                  color: Color(0xFF666666),
                ),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Email wajib diisi';
                if (!v.contains('@')) return 'Email tidak valid';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passCtrl,
              obscureText: _obscure,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(
                  Icons.lock_outlined,
                  color: Color(0xFF666666),
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: const Color(0xFF666666),
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Password wajib diisi';
                if (v.length < 6) return 'Password min 6 karakter';
                return null;
              },
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _login,
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('LOGIN'),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () async {
                final email = _emailCtrl.text.trim();
                if (email.isEmpty) {
                  _showError('Masukkan email dulu');
                  return;
                }
                final result = await FirebaseAuthService.instance.resetPassword(
                  email,
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        result.success
                            ? 'Email reset password dikirim!'
                            : result.error ?? 'Gagal',
                      ),
                      backgroundColor: result.success
                          ? const Color(0xFF00C896)
                          : const Color(0xFFFF4444),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              child: const Text(
                'Lupa password?',
                style: TextStyle(color: Color(0xFF888888)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── REGISTER FORM ────────────────────────────────────────────────────────────

class _RegisterForm extends StatefulWidget {
  const _RegisterForm();

  @override
  State<_RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<_RegisterForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  FitnessGoal _goal = FitnessGoal.maintain;
  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _weightCtrl.dispose();
    _heightCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final result = await FirebaseAuthService.instance.register(
      email: _emailCtrl.text,
      password: _passCtrl.text,
      name: _nameCtrl.text.trim(),
      weightKg: double.tryParse(_weightCtrl.text) ?? 70,
      heightCm: double.tryParse(_heightCtrl.text) ?? 170,
      goal: _goal,
    );

    if (mounted) {
      setState(() => _loading = false);
      if (!result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.error ?? 'Registrasi gagal'),
            backgroundColor: const Color(0xFFFF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _nameCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Nama',
                prefixIcon: Icon(
                  Icons.person_outlined,
                  color: Color(0xFF666666),
                ),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Nama wajib diisi' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(
                  Icons.email_outlined,
                  color: Color(0xFF666666),
                ),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Email wajib diisi';
                if (!v.contains('@')) return 'Email tidak valid';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _passCtrl,
              obscureText: _obscure,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(
                  Icons.lock_outlined,
                  color: Color(0xFF666666),
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: const Color(0xFF666666),
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Password wajib diisi';
                if (v.length < 6) return 'Password min 6 karakter';
                return null;
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _weightCtrl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Berat (kg)',
                      prefixIcon: Icon(
                        Icons.monitor_weight_outlined,
                        color: Color(0xFF666666),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Wajib';
                      if (double.tryParse(v) == null) return 'Angka';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _heightCtrl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Tinggi (cm)',
                      prefixIcon: Icon(Icons.height, color: Color(0xFF666666)),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Wajib';
                      if (double.tryParse(v) == null) return 'Angka';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'GOAL',
              style: GoogleFonts.barlow(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF888888),
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: FitnessGoal.values.map((g) {
                final labels = {
                  FitnessGoal.bulking: ('💪', 'Bulking'),
                  FitnessGoal.cutting: ('🔥', 'Cutting'),
                  FitnessGoal.maintain: ('⚖️', 'Maintain'),
                };
                final (emoji, label) = labels[g]!;
                final selected = _goal == g;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _goal = g),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: selected
                            ? const Color(0xFFFF6B35)
                            : const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: selected
                              ? const Color(0xFFFF6B35)
                              : const Color(0xFF2A2A2A),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(emoji, style: const TextStyle(fontSize: 18)),
                          const SizedBox(height: 4),
                          Text(
                            label,
                            style: GoogleFonts.barlow(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: selected
                                  ? Colors.white
                                  : const Color(0xFF888888),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _register,
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('DAFTAR SEKARANG'),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
