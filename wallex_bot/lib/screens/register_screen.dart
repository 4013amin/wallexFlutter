import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/api_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;

  // Color palette matching HTML template
  final Color _bgDark = const Color(0xFF080B11);
  final Color _cardBg = const Color(0xFF111928);
  final Color _borderColor = const Color(0x1FFFFFFF);
  final Color _primary = const Color(0xFF2962FF);
  final Color _textSecondary = const Color(0xFF94A3B8);
  final Color _success = const Color(0xFF0ECB81);
  final Color _danger = const Color(0xFFF6465D);

  Future<void> _register() async {
    if (_passwordController.text != _confirmPasswordController.text) {
      _showSnackBar("رمزهای عبور با هم مطابقت ندارند.", isError: true);
      return;
    }

    if (_phoneController.text.length != 11 || !_phoneController.text.startsWith("09")) {
      _showSnackBar("شماره موبایل نامعتبر است (مثال: 09123456789)", isError: true);
      return;
    }

    if (_usernameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      _showSnackBar("لطفاً تمام فیلدها را پر کنید", isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final url = Uri.parse("${ApiService.baseUrl}/register/");
      final response = await http.post(
        url,
        body: {
          'username': _usernameController.text,
          'email': _emailController.text,
          'phone_number': _phoneController.text,
          'password': _passwordController.text,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showSnackBar("ثبت‌نام با موفقیت انجام شد. وارد شوید.", isSuccess: true);
        Navigator.pop(context);
      } else {
        final errorData = json.decode(response.body);
        _showSnackBar(errorData['message'] ?? "خطایی در ثبت‌نام رخ داد.", isError: true);
      }
    } catch (e) {
      _showSnackBar("خطا در اتصال به سرور", isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false, bool isSuccess = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontFamily: 'Vazir', fontSize: 14),
        ),
        backgroundColor: isError ? _danger : (isSuccess ? _success : _primary),
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
              top: -100,
              left: -50,
              child: Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _primary.withValues(alpha: 0.15),
                ),
              ),
            ),
            Positioned(
              bottom: -100,
              right: -50,
              child: Container(
                width: 350,
                height: 350,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _success.withValues(alpha: 0.1),
                ),
              ),
            ),
            
            // Main content
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxWidth: 480),
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
                  padding: const EdgeInsets.all(35),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header
                      const Text(
                        "ایجاد حساب کاربری",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Vazir',
                        ),
                      ),
                      const SizedBox(height: 25),
                      
                      // Promo badge
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _success.withValues(alpha: 0.1),
                          border: Border.all(
                            color: _success,
                            width: 1,
                            style: BorderStyle.solid,
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "🎁",
                              style: TextStyle(fontSize: 16),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "با عضویت، ۱۰ توکن اسکن هدیه بگیرید!",
                              style: TextStyle(
                                color: _success,
                                fontSize: 13,
                                fontFamily: 'Vazir',
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 25),
                      
                      // Username field
                      _buildTextField(
                        controller: _usernameController,
                        label: "نام کاربری",
                        icon: Icons.person_outline,
                      ),
                      const SizedBox(height: 18),
                      
                      // Email field
                      _buildTextField(
                        controller: _emailController,
                        label: "ایمیل",
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 18),
                      
                      // Phone field
                      _buildTextField(
                        controller: _phoneController,
                        label: "شماره موبایل",
                        icon: Icons.phone_android_outlined,
                        keyboardType: TextInputType.phone,
                        hintText: "09123456789",
                      ),
                      const SizedBox(height: 18),
                      
                      // Password field
                      _buildTextField(
                        controller: _passwordController,
                        label: "رمز عبور",
                        icon: Icons.lock_outline,
                        isPassword: true,
                      ),
                      const SizedBox(height: 18),
                      
                      // Confirm password field
                      _buildTextField(
                        controller: _confirmPasswordController,
                        label: "تکرار رمز عبور",
                        icon: Icons.lock_outline,
                        isPassword: true,
                      ),
                      const SizedBox(height: 25),
                      
                      // Register button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _register,
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
                                  "تایید و ساخت حساب",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'Vazir',
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 25),
                      
                      // Footer
                      Container(
                        padding: const EdgeInsets.only(top: 20),
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(
                              color: _borderColor,
                              width: 1,
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "قبلاً ثبت‌نام کرده‌اید؟",
                              style: TextStyle(
                                color: _textSecondary,
                                fontSize: 14,
                                fontFamily: 'Vazir',
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: Text(
                                "وارد شوید",
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
    TextInputType keyboardType = TextInputType.text,
    String? hintText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            color: _textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
            fontFamily: 'Vazir',
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isPassword,
          keyboardType: keyboardType,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontFamily: 'Vazir',
          ),
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.left,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(
              color: _textSecondary.withValues(alpha: 0.5),
              fontSize: 14,
            ),
            prefixIcon: Icon(
              icon,
              color: _textSecondary,
              size: 20,
            ),
            filled: true,
            fillColor: const Color(0xFF0F172A).withValues(alpha: 0.6),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _borderColor, width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _borderColor, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _primary, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }
}