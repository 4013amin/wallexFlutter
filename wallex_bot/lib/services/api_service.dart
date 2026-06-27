  // lib/services/api_service.dart
  import 'package:http/http.dart' as http;
  import 'dart:convert';
  import 'package:shared_preferences/shared_preferences.dart';

  class ApiService {
    static const String baseUrl = "https://wallexbotas.runflare.run/api";
    static const Duration _timeout = Duration(seconds: 30);
    
    // HTTP client با connection pooling برای سرعت بیشتر
    static final _client = http.Client();
      
    // Cache SharedPreferences برای جلوگیری از getInstance مکرر
    static SharedPreferences? _prefs;
    
    Future<SharedPreferences> _getPrefs() async {
      _prefs ??= await SharedPreferences.getInstance();
      return _prefs!;
    }

    Future<String?> _getToken() async {
      final prefs = await _getPrefs();
      return prefs.getString('token');
    }

    Future<void> _saveToken(String token) async {
      final prefs = await _getPrefs();
      await prefs.setString('token', token);
    }

    // متد لاگین بهینه‌سازی شده با ارسال داده به صورت JSON استاندارد
    Future<String?> login(String username, String password) async {
      try {
        final response = await _client.post(
          Uri.parse("$baseUrl/login/"),
          headers: {
            "Content-Type": "application/json",
          },
          body: json.encode({
            "username": username,
            "password": password,
          }),
        ).timeout(_timeout);

        if (response.statusCode == 200) {
          final data = json.decode(utf8.decode(response.bodyBytes));
          final token = data['token'] as String?;
          if (token != null) {
            await _saveToken(token);
            return token;
          }
        } else {
          print('[ApiService] Login rejected. Status code: ${response.statusCode}');
        }
        return null;
      } catch (e) {
        print('[ApiService] login error: $e');
        return null;
      }
    }

    // دریافت اطلاعات اصلی داشبورد
   Future<Map<String, dynamic>> getDashboardData() async {
      try {
        String? token = await _getToken();
        var res = await _client.get(
          Uri.parse("$baseUrl/dashboard/"), 
          headers: {
            "Authorization": "Token $token", 
            "Content-Type": "application/json"
          },
        ).timeout(_timeout);

        if (res.statusCode == 200) {
          final decoded = json.decode(utf8.decode(res.bodyBytes));
          if (decoded is Map<String, dynamic>) {
            return decoded;
          } else {
            return {"error": "فرمت داده اشتباه است"};
          }
        } else {
          return {"error": "خطای سرور: ${res.statusCode}"};
        }
      } catch (e) {
        return {"error": "خطا در برقراری ارتباط"};
      }
    }

    // ارسال عملیات (اسکن، فعال‌سازی، خرید و غیره) به صورت ایمن
    Future<Map<String, dynamic>> sendDashboardAction(String action, {Map? extraData}) async {
    try {
      String? token = await _getToken();
      Map<String, dynamic> body = {"action": action};
      
      if (extraData != null) {
        // ✅ به جای cast مستقیم، map رو convert کن
        extraData.forEach((key, value) {
          body[key.toString()] = value;
        });
      }

      var res = await _client.post(
        Uri.parse("$baseUrl/dashboard/"),
        headers: {
          "Authorization": "Token $token", 
          "Content-Type": "application/json"
        },
        body: json.encode(body),
      ).timeout(_timeout);
      
      final decodedData = json.decode(utf8.decode(res.bodyBytes));

      if (res.statusCode == 200 || res.statusCode == 201) {
        if (decodedData is Map<String, dynamic>) {
          return decodedData;
        }
        return {"success": true};
      } else {
        String errorMessage = "خطایی در سرور رخ داد";
        if (decodedData is Map && decodedData.containsKey('error')) {
          errorMessage = decodedData['error'];
        }
        return {"error": errorMessage};
      }
    } catch (e) {
      print("[ApiService] Action Error TYPE: ${e.runtimeType}");
      print("[ApiService] Action Error: $e");
      return {"error": "عدم برقراری ارتباط با سرور"};
    }
  }

    // متد آنالیز
    Future<Map<String, dynamic>> getCoinAnalysis(String symbol) async {
      String? token = await _getToken();
      var res = await _client.get(
        Uri.parse("$baseUrl/analysis/$symbol/"),
        headers: {
          "Authorization": "Token $token",
          "Content-Type": "application/json"
        },
      ).timeout(_timeout);
      return json.decode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    }

    // دریافت لیست تراکنش‌ها
    Future<Map<String, dynamic>> getTransactions() async {
      try {
        String? token = await _getToken();
        var res = await _client.get(
          Uri.parse("$baseUrl/transactions/"),
          headers: {
            "Authorization": "Token $token",
            "Content-Type": "application/json"
          },
        ).timeout(_timeout);

        if (res.statusCode == 200) {
          final decoded = json.decode(utf8.decode(res.bodyBytes));
          if (decoded is Map<String, dynamic>) {
            return decoded;
          } else {
            return {"error": "فرمت داده اشتباه است"};
          }
        } else {
          return {"error": "خطای سرور: ${res.statusCode}"};
        }
      } catch (e) {
        return {"error": "خطا در برقراری ارتباط"};
      }
    }

   // در فایل api_service.dart متدهای زیر را جایگزین کنید:

// ارسال درخواست فراموشی رمز عبور با شماره موبایل
  Future<Map<String, dynamic>> sendForgotPassword(String phoneNumber) async {
    try {
      var res = await _client.post(
        Uri.parse("$baseUrl/forgot-password/"),
        headers: {
          "Content-Type": "application/json"
        },
        // تغییر کلید از email به phone_number
        body: json.encode({"phone_number": phoneNumber}),
      ).timeout(_timeout);

      final decodedData = json.decode(utf8.decode(res.bodyBytes));

      if (res.statusCode == 200) {
        return decodedData is Map<String, dynamic> ? decodedData : {"success": true};
      } else {
        String errorMessage = "خطایی در سرور رخ داد";
        if (decodedData is Map && decodedData.containsKey('error')) {
          errorMessage = decodedData['error'];
        }
        return {"error": errorMessage};
      }
    } catch (e) {
      return {"error": "عدم برقراری ارتباط با سرور"};
    }
  }

  // تغییر رمز عبور با OTP و شماره موبایل
  Future<Map<String, dynamic>> resetPassword(String phoneNumber, String otp, String newPassword) async {
    try {
      var res = await _client.post(
        Uri.parse("$baseUrl/reset-password/"),
        headers: {
          "Content-Type": "application/json"
        },
        body: json.encode({
          "phone_number": phoneNumber, // تغییر کلید
          "otp": otp,
          "new_password": newPassword,
        }),
      ).timeout(_timeout);

      final decodedData = json.decode(utf8.decode(res.bodyBytes));

      if (res.statusCode == 200) {
        return decodedData is Map<String, dynamic> ? decodedData : {"success": true};
      } else {
        String errorMessage = "خطایی در سرور رخ داد";
        if (decodedData is Map && decodedData.containsKey('error')) {
          errorMessage = decodedData['error'];
        }
        return {"error": errorMessage};
      }
    } catch (e) {
      return {"error": "عدم برقراری ارتباط با سرور"};
    }
  }

    Future<void> logout() async {
      final prefs = await _getPrefs();
      await prefs.clear();
    }
  }