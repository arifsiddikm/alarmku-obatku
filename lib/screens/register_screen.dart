import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../utils/app_theme.dart';
import '../widgets/confirm_dialog.dart';
import 'login_screen.dart';
import 'home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscure = true;
  bool _obscureConfirm = true;
  bool _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final result = await AuthService.instance.register(
      name: _nameCtrl.text,
      email: _emailCtrl.text,
      password: _passCtrl.text,
      phone: _phoneCtrl.text.isEmpty ? null : _phoneCtrl.text,
    );

    setState(() => _loading = false);
    if (!mounted) return;

    if (result.success) {
      Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      showSnackBar(context, result.message, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.cream,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 48),

                Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(
                    color: AppTheme.terracotta, borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.medication_rounded, color: AppTheme.white, size: 30),
                ),
                const SizedBox(height: 24),
                Text('Buat akun baru', style: AppText.h1),
                const SizedBox(height: 6),
                Text('Mulai kelola jadwal minum obatmu', style: AppText.bodyMuted),
                const SizedBox(height: 36),

                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(labelText: 'Nama lengkap'),
                  textCapitalization: TextCapitalization.words,
                  validator: (v) => v!.trim().isEmpty ? 'Nama wajib diisi' : null,
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _emailCtrl,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v!.trim().isEmpty) return 'Email wajib diisi';
                    if (!v.contains('@')) return 'Format email tidak valid';
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _phoneCtrl,
                  decoration: const InputDecoration(
                    labelText: 'No. HP (opsional)',
                    hintText: '08xxxxxxxxxx',
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _passCtrl,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    hintText: 'Min. 6 karakter',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: AppTheme.warmGray, size: 20,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: (v) {
                    if (v!.isEmpty) return 'Password wajib diisi';
                    if (v.length < 6) return 'Password minimal 6 karakter';
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _confirmCtrl,
                  obscureText: _obscureConfirm,
                  decoration: InputDecoration(
                    labelText: 'Konfirmasi password',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: AppTheme.warmGray, size: 20,
                      ),
                      onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                  ),
                  validator: (v) {
                    if (v!.isEmpty) return 'Konfirmasi password wajib diisi';
                    if (v != _passCtrl.text) return 'Password tidak cocok';
                    return null;
                  },
                ),
                const SizedBox(height: 28),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _register,
                    child: _loading
                        ? const SizedBox(
                            height: 20, width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.white),
                          )
                        : const Text('Daftar'),
                  ),
                ),
                const SizedBox(height: 20),

                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text('Sudah punya akun? ', style: AppText.bodyMuted),
                    TextButton(
                      onPressed: () => Navigator.pushReplacement(
                        context, MaterialPageRoute(builder: (_) => const LoginScreen()),
                      ),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('Masuk'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
