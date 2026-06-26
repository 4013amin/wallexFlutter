// lib/screens/login_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  bool _isLoading = false;

  // Color palette matching HTML template
  final Color _bgDark = const Color(0xFF080B11);
  final Color _cardBg = const Color(0xFF111928);
  final Color _borderColor = const Color(0x1FFFFFFF);
  final Color _primary = const Color(0xFF2962FF);
  final Color _textSecondary = const Color(0xFF94A3B8);
  final Color _success = const Color(0xFF0ECB81);
  final Color _danger = const Color(0xFFF6465D);

  Future<void> _handleLogin() async {
    if (_userController.text.isEmpty || _passController.text.isEmpty) {
      _showSnackBar("لطفاً تمام فیلدها را پر کنید", isError: true);
      return;
    }

    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    bool loginSuccess = await authProvider.login(
      _userController.text.trim(),
      _passController.text.trim(),
    );

    setState(() => _isLoading = false);

    if (loginSuccess) {
      // Navigation handled by main.dart
    } else {
      _showSnackBar("نام کاربری یا رمز عبور اشتباه است", isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontFamily: 'Vazir', fontSize: 14),
        ),
        backgroundColor: isError ? _danger : _success,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _bgDark,
              _bgDark,
            ],
          ),
        ),
        child: Stack(
          children: [
            // Decorative circles
            Positioned(
              top: MediaQuery.of(context).size.height * 0.1,
              right: MediaQuery.of(context).size.width * 0.15,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _primary.withValues(alpha: 0.1),
                ),
              ),
            ),
            Positioned(
              bottom: MediaQuery.of(context).size.height * 0.1,
              left: MediaQuery.of(context).size.width * 0.15,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _success.withValues(alpha: 0.08),
                ),
              ),
            ),
            
            // Main content
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxWidth: 420),
                  decoration: BoxDecoration(
                    color: _cardBg.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: _borderColor, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        blurRadius: 50,
                        offset: const Offset(0, 25),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header
                      Column(
                        children: [
                          const Text(
                            "خوش آمدید",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'Vazir',
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "برای ادامه وارد حساب کاربری خود شوید",
                            style: TextStyle(
                              color: _textSecondary,
                              fontSize: 14,
                              fontFamily: 'Vazir',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 35),
                      
                      // Username field
                      _buildTextField(
                        controller: _userController,
                        label: "نام کاربری",
                        icon: Icons.person_outline,
                      ),
                      const SizedBox(height: 20),
                      
                      // Password field
                      _buildTextField(
                        controller: _passController,
                        label: "رمز عبور",
                        icon: Icons.lock_outline,
                        isPassword: true,
                      ),
                      const SizedBox(height: 10),
                      
                      // Forgot password link
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ForgotPasswordScreen(),
                              ),
                            );
                          },
                          child: Text(
                            "فراموشی رمز عبور؟",
                            style: TextStyle(
                              color: _textSecondary,
                              fontSize: 12,
                              fontFamily: 'Vazir',
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 25),
                      
                      // Login button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            shadowColor: _primary.withValues(alpha: 0.3),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  "ورود به پنل کاربری",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'Vazir',
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      
                      // Footer
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "حساب کاربری ندارید؟",
                            style: TextStyle(
                              color: _textSecondary,
                              fontSize: 14,
                              fontFamily: 'Vazir',
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/register');
                            },
                            child: Text(
                              "ثبت‌نام سریع",
                              style: TextStyle(
                                color: _primary,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'Vazir',
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
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontFamily: 'Vazir',
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.left,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: _textSecondary,
          fontSize: 13,
          fontWeight: FontWeight.w500,
          fontFamily: 'Vazir',
        ),
        prefixIcon: Icon(
          icon,
          color: _textSecondary,
          size: 20,
        ),
        filled: true,
        fillColor: const Color(0xFF0F172A).withValues(alpha: 0.6),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: _borderColor, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: _borderColor, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: _primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      ),
    );
  }
}