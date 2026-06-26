import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  // تغییر کنترلر ایمیل به شماره موبایل
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _resetMode = false; // فاز اول (وارد کردن شماره) یا فاز دوم (وارد کردن کد و رمز جدید)

  // پالت رنگی هماهنگ با قالب تیره
  final Color _bgDark = const Color(0xFF080B11);
  final Color _cardBg = const Color(0xFF111928);
  final Color _borderColor = const Color(0x1FFFFFFF);
  final Color _primary = const Color(0xFF2962FF);
  final Color _textSecondary = const Color(0xFF94A3B8);
  final Color _success = const Color(0xFF0ECB81);
  final Color _danger = const Color(0xFFF6465D);

  final ApiService _api = ApiService();

  // مرحله اول: ارسال شماره موبایل برای دریافت کد
  Future<void> _sendOTP() async {
    String phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      _showSnackBar("لطفاً شماره موبایل خود را وارد کنید", isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final res = await _api.sendForgotPassword(phone);
      if (!mounted) return;

      if (res.containsKey('success')) {
        setState(() {
          _resetMode = true;
        });
        _showSnackBar("کد تایید به شماره شما پیامک شد", isSuccess: true);
      } else {
        _showSnackBar(res['error'] ?? "خطا در ارسال کد تایید", isError: true);
      }
    } catch (e) {
      if (mounted) _showSnackBar("خطا در ارتباط با سرور", isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // مرحله دوم: تایید کد و تغییر رمز عبور
  Future<void> _resetPassword() async {
    String otp = _otpController.text.trim();
    String newPass = _newPasswordController.text;
    String confirmPass = _confirmPasswordController.text;

    if (otp.isEmpty || newPass.isEmpty || confirmPass.isEmpty) {
      _showSnackBar("لطفاً تمام فیلدها را پر کنید", isError: true);
      return;
    }

    if (newPass != confirmPass) {
      _showSnackBar("رمزهای عبور با هم مطابقت ندارند", isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final res = await _api.resetPassword(
        _phoneController.text.trim(),
        otp,
        newPass,
      );
      if (!mounted) return;

      if (res.containsKey('success')) {
        _showSnackBar("رمز عبور با موفقیت تغییر کرد", isSuccess: true);
        // بازگشت به صفحه ورود بعد از 1.5 ثانیه
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) Navigator.pop(context);
        });
      } else {
        _showSnackBar(res['error'] ?? "خطا در تغییر رمز عبور", isError: true);
      }
    } catch (e) {
      if (mounted) _showSnackBar("خطا در ارتباط با سرور", isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
          textAlign: TextAlign.right,
          textDirection: TextDirection.rtl,
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
      backgroundColor: _bgDark,
      body: Stack(
        children: [
          // دایره‌های تزئینی پس‌زمینه
          Positioned(
            top: -100,
            right: -50,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _primary.withOpacity(0.1),
              ),
            ),
          ),

          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxWidth: 420),
                decoration: BoxDecoration(
                  color: _cardBg.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: _borderColor, width: 1),
                ),
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // آیکون بالای صفحه
                    Icon(
                      _resetMode ? Icons.security_outlined : Icons.vibration_outlined,
                      size: 60,
                      color: _primary,
                    ),
                    const SizedBox(height: 20),
                    
                    // تیتر
                    Text(
                      _resetMode ? "تایید هویت" : "فراموشی رمز عبور",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Vazir',
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // متن راهنما
                    Text(
                      _resetMode
                          ? "کد پیامک شده به ${_phoneController.text} را وارد کنید"
                          : "شماره موبایل خود را وارد کنید تا کد بازیابی ارسال شود",
                      style: TextStyle(
                        color: _textSecondary,
                        fontSize: 13,
                        fontFamily: 'Vazir',
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),

                    // فیلد شماره موبایل (در هر دو وضعیت نمایش داده می‌شود اما در وضعیت دوم غیرفعال است)
                    _buildTextField(
                      controller: _phoneController,
                      label: "شماره موبایل",
                      icon: Icons.phone_android_rounded,
                      keyboardType: TextInputType.phone,
                      hintText: "مثلاً 09123456789",
                      enabled: !_resetMode,
                    ),
                    
                    if (_resetMode) ...[
                      const SizedBox(height: 18),
                      // فیلد کد تایید
                      _buildTextField(
                        controller: _otpController,
                        label: "کد تایید پیامکی",
                        icon: Icons.message_outlined,
                        keyboardType: TextInputType.number,
                        hintText: "- - - - - -",
                      ),
                      const SizedBox(height: 18),
                      // رمز عبور جدید
                      _buildTextField(
                        controller: _newPasswordController,
                        label: "رمز عبور جدید",
                        icon: Icons.lock_open_rounded,
                        isPassword: true,
                        hintText: "حداقل ۸ کاراکتر",
                      ),
                      const SizedBox(height: 18),
                      // تکرار رمز
                      _buildTextField(
                        controller: _confirmPasswordController,
                        label: "تکرار رمز عبور جدید",
                        icon: Icons.lock_outline_rounded,
                        isPassword: true,
                      ),
                    ],

                    const SizedBox(height: 32),

                    // دکمه اصلی عملیات
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading
                            ? null
                            : (_resetMode ? _resetPassword : _sendOTP),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
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
                            : Text(
                                _resetMode ? "تغییر رمز عبور" : "ارسال کد تایید",
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Vazir',
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // دکمه بازگشت
                    TextButton(
                      onPressed: () {
                        if (_resetMode) {
                          setState(() => _resetMode = false);
                        } else {
                          Navigator.pop(context);
                        }
                      },
                      child: Text(
                        _resetMode ? "ویرایش شماره موبایل" : "بازگشت به صفحه ورود",
                        style: TextStyle(
                          color: _textSecondary,
                          fontSize: 14,
                          fontFamily: 'Vazir',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ویجت اختصاصی برای فیلدهای ورودی
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
    String? hintText,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          label,
          style: TextStyle(
            color: _textSecondary,
            fontSize: 13,
            fontFamily: 'Vazir',
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isPassword,
          keyboardType: keyboardType,
          enabled: enabled,
          textAlign: TextAlign.left,
          textDirection: TextDirection.ltr, // شماره و کدها چپ به راست
          style: const TextStyle(color: Colors.white, fontSize: 16),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(color: _textSecondary.withOpacity(0.3), fontSize: 14),
            prefixIcon: Icon(icon, color: _primary.withOpacity(0.7), size: 22),
            filled: true,
            fillColor: _bgDark.withOpacity(0.5),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: _borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: _borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: _primary, width: 1.5),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: _borderColor.withOpacity(0.2)),
            ),
          ),
        ),
      ],
    );
  }
}