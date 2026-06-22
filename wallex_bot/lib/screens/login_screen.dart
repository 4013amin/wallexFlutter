// lib/screens/login_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  bool _isLoading = false;

  Future<void> _handleLogin() async {
    // اعتبارسنجی اولیه فیلدها
    if (_userController.text.isEmpty || _passController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("لطفاً تمام فیلدها را پر کنید")),
      );
      return;
    }

    setState(() => _isLoading = true);

    // فراخوانی متد لاگین از AuthProvider
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    bool loginSuccess = await authProvider.login(
      _userController.text.trim(),
      _passController.text.trim(),
    );

    setState(() => _isLoading = false);

    if (loginSuccess) {
      // اگر ورود موفق بود، برو به داشبورد
      // (main.dart به صورت خودکار تغییرات وضعیت را شنیده و کاربر را به داشبورد هدایت می‌کند)
    } else {
      // نمایش پیام خطا در صورت ناموفق بودن لاگین روی سرور
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("نام کاربری یا رمز عبور اشتباه است یا سرور در دسترس نیست")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0D1117), // تم تاریک پلتفرم
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(25.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.auto_graph, size: 80, color: Colors.blueAccent),
              SizedBox(height: 20),
              Text(
                "ورود به ربات والکس",
                style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 40),
              
              // فیلد نام کاربری
              TextField(
                controller: _userController,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "نام کاربری",
                  labelStyle: TextStyle(color: Colors.grey),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.blueAccent)),
                ),
              ),
              SizedBox(height: 15),
              
              // فیلد رمز عبور
              TextField(
                controller: _passController,
                obscureText: true,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "رمز عبور",
                  labelStyle: TextStyle(color: Colors.grey),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.blueAccent)),
                ),
              ),
              SizedBox(height: 30),
              
              // دکمه ورود
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _isLoading 
                    ? CircularProgressIndicator(color: Colors.white) 
                    : Text("ورود به حساب", style: TextStyle(fontSize: 18, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}