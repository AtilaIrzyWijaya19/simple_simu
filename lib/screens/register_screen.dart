// lib/screens/register_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firebase_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _namaCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _konfPassCtrl = TextEditingController();
  bool _showPass = false;
  bool _showKonfPass = false;
  bool _isLoading = false;
  String? _errorMsg;

  @override
  void dispose() {
    _namaCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _konfPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final nama = _namaCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text.trim();
    final konfPass = _konfPassCtrl.text.trim();

    if (nama.isEmpty || email.isEmpty || pass.isEmpty || konfPass.isEmpty) {
      setState(() => _errorMsg = 'Semua field wajib diisi.');
      return;
    }
    if (!email.contains('@')) {
      setState(() => _errorMsg = 'Format email tidak valid.');
      return;
    }
    if (pass.length < 6) {
      setState(() => _errorMsg = 'Password minimal 6 karakter.');
      return;
    }
    if (pass != konfPass) {
      setState(() => _errorMsg = 'Konfirmasi password tidak cocok.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });

    try {
      await FirebaseService.register(nama, email, pass);
      // AuthGate akan otomatis mendeteksi dan arahkan ke Dashboard
    } on FirebaseAuthException catch (e) {
      setState(() {
        switch (e.code) {
          case 'email-already-in-use':
            _errorMsg = 'Email sudah terdaftar. Silakan masuk.';
            break;
          case 'invalid-email':
            _errorMsg = 'Format email tidak valid.';
            break;
          case 'weak-password':
            _errorMsg = 'Password terlalu lemah.';
            break;
          default:
            _errorMsg = 'Pendaftaran gagal. Periksa koneksi internet.';
        }
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF1A6BFF)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Buat Akun Baru',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              const Text(
                'Isi data diri dengan benar',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 28),
              if (_errorMsg != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          color: Colors.red, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(_errorMsg!,
                            style: const TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                ),
              _buildLabel('Nama Lengkap'),
              _buildTextField(
                controller: _namaCtrl,
                hint: 'Nama lengkap',
                icon: Icons.person_outline,
                onChanged: (_) => setState(() => _errorMsg = null),
              ),
              const SizedBox(height: 16),
              _buildLabel('Email'),
              _buildTextField(
                controller: _emailCtrl,
                hint: 'contoh@email.com',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                onChanged: (_) => setState(() => _errorMsg = null),
              ),
              const SizedBox(height: 16),
              _buildLabel('Password'),
              _buildPassField(
                controller: _passCtrl,
                hint: 'Minimal 6 karakter',
                showPass: _showPass,
                onToggle: () => setState(() => _showPass = !_showPass),
                onChanged: (_) => setState(() => _errorMsg = null),
              ),
              const SizedBox(height: 16),
              _buildLabel('Konfirmasi Password'),
              _buildPassField(
                controller: _konfPassCtrl,
                hint: 'Ulangi password',
                showPass: _showKonfPass,
                onToggle: () => setState(() => _showKonfPass = !_showKonfPass),
                onChanged: (_) => setState(() => _errorMsg = null),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A6BFF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 2,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Daftar',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Sudah punya akun? ',
                        style: TextStyle(color: Colors.grey)),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Text(
                        'Masuk',
                        style: TextStyle(
                          color: Color(0xFF1A6BFF),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      );

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    Function(String)? onChanged,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: const Color(0xFF1A6BFF)),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1A6BFF), width: 2),
        ),
      ),
    );
  }

  Widget _buildPassField({
    required TextEditingController controller,
    required String hint,
    required bool showPass,
    required VoidCallback onToggle,
    Function(String)? onChanged,
  }) {
    return TextField(
      controller: controller,
      obscureText: !showPass,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF1A6BFF)),
        suffixIcon: IconButton(
          icon: Icon(showPass ? Icons.visibility_off : Icons.visibility,
              color: Colors.grey),
          onPressed: onToggle,
        ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1A6BFF), width: 2),
        ),
      ),
    );
  }
}
