import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../infrastructure/auth_repository.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true;

  // PoleBarn Theme Colors
  static const Color primaryForest = Color(0xFF173124);
  static const Color secondaryEarth = Color(0xFF7C580F);
  static const Color backgroundLight = Color(0xFFFDFBF7);

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await ref.read(authRepositoryProvider).signInWithEmailAndPassword(
            _emailController.text,
            _passwordController.text,
          );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundLight,
      body: Row(
        children: [
          // Left side: Brand Visual (Hidden on mobile)
          if (MediaQuery.of(context).size.width > 900)
            Expanded(
              flex: 1,
              child: Container(
                color: primaryForest,
                child: Stack(
                  children: [

                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(48.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildLogo(height: 120),
                            const SizedBox(height: 32),
                            const Text(
                              'POLEBARNS',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Quality Construction Since Day One',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 16,
                                fontWeight: FontWeight.w300,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          
          // Right side: Login Form
          Expanded(
            flex: 1,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32.0),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Mobile Logo
                      if (MediaQuery.of(context).size.width <= 900) ...[
                        Center(child: _buildLogo(height: 60, padding: 16)),
                        const SizedBox(height: 48),
                      ],
                      
                      const Text(
                        '¡Hola de nuevo!',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: primaryForest,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Ingresa a tu cuenta para gestionar tus proyectos.',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black.withValues(alpha: 0.5),
                        ),
                      ),
                      const SizedBox(height: 48),
                      
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _emailController,
                              decoration: _inputDecoration(
                                label: 'Email o Usuario',
                                icon: Icons.person_outline,
                              ),
                              validator: (value) => value == null || value.isEmpty ? 'Requerido' : null,
                            ),
                            const SizedBox(height: 24),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              decoration: _inputDecoration(
                                label: 'Contraseña',
                                icon: Icons.lock_outline,
                                suffix: IconButton(
                                  icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                  color: primaryForest.withValues(alpha: 0.5),
                                ),
                              ),
                              onFieldSubmitted: (_) => _signIn(),
                              validator: (value) => value == null || value.isEmpty ? 'Requerido' : null,
                            ),
                            const SizedBox(height: 40),
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: FilledButton(
                                onPressed: _isLoading ? null : _signIn,
                                style: FilledButton.styleFrom(
                                  backgroundColor: primaryForest,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: _isLoading
                                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                    : const Text(
                                        'INICIAR SESIÓN',
                                        style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "¿No tienes cuenta?",
                                  style: TextStyle(color: Colors.black.withValues(alpha: 0.6)),
                                ),
                                TextButton(
                                  onPressed: () => context.go('/register'),
                                  child: const Text(
                                    'Regístrate gratis',
                                    style: TextStyle(color: secondaryEarth, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo({double height = 100, double padding = 24}) {
    return Hero(
      tag: 'logo',
      child: Container(
        padding: EdgeInsets.all(padding),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.black.withValues(alpha: 0.05),
            width: 1,
          ),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              Colors.white.withValues(alpha: 0.95),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 30,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        child: Image.asset(
          'assets/branding/logo.png',
          height: height,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({required String label, required IconData icon, Widget? suffix}) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: primaryForest.withValues(alpha: 0.6)),
      prefixIcon: Icon(icon, color: primaryForest, size: 20),
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: secondaryEarth, width: 2),
      ),
    );
  }
}
