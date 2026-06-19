import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/api_service.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // کنترلرهای فیلدهای متنی مطابق با فرم جنگو شما
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;

  // تابع ارسال اطلاعات به جنگو
  Future<void> _register() async {
    // ۱. بررسی تطابق رمز عبور در سمت اپلیکیشن
    if (_passwordController.text != _confirmPasswordController.text) {
      _showSnackBar("رمزهای عبور با هم مطابقت ندارند.");
      return;
    }

    // ۲. بررسی فرمت شماره موبایل (مشابه منطق clean_phone_number در جنگو شما)
    if (_phoneController.text.length != 11 || !_phoneController.text.startsWith("09")) {
      _showSnackBar("شماره موبایل نامعتبر است (مثال: 09123456789)");
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
        _showSnackBar("ثبت‌نام با موفقیت انجام شد. وارد شوید.");
        Navigator.pop(context); // بازگشت به صفحه لاگین
      } else {
        // نمایش خطاهای احتمالی از سمت جنگو (مثلاً تکراری بودن یوزرنیم)
        final errorData = json.decode(response.body);
        _showSnackBar(errorData['message'] ?? "خطایی در ثبت‌نام رخ داد.");
      }
    } catch (e) {
      _showSnackBar("خطا در اتصال به سرور: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0D1117), // تم تاریک مطابق دیتای جنگو
      appBar: AppBar(title: Text("ایجاد حساب جدید"), backgroundColor: Colors.transparent),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(25.0),
        child: Column(
          children: [
            _buildTextField(_usernameController, "نام کاربری", Icons.person),
            SizedBox(height: 15),
            _buildTextField(_emailController, "ایمیل", Icons.email),
            SizedBox(height: 15),
            _buildTextField(_phoneController, "شماره موبایل (09...)", Icons.phone_android, keyboardType: TextInputType.phone),
            SizedBox(height: 15),
            _buildTextField(_passwordController, "رمز عبور", Icons.lock, isPassword: true),
            SizedBox(height: 15),
            _buildTextField(_confirmPasswordController, "تکرار رمز عبور", Icons.lock_outline, isPassword: true),
            SizedBox(height: 30),
            
            _isLoading 
              ? CircularProgressIndicator()
              : Container(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _register,
                    child: Text("ثبت نام و ایجاد حساب", style: TextStyle(fontSize: 16)),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                  ),
                ),
          ],
        ),
      ),
    );
  }

  // ویجت کمکی برای ساخت فیلدها
  Widget _buildTextField(TextEditingController controller, String label, IconData icon, 
      {bool isPassword = false, TextInputType keyboardType = TextInputType.text}) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: keyboardType,
      style: TextStyle(color: Colors.white),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.blueAccent),
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey),
        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.blueAccent)),
      ),
    );
  }
}