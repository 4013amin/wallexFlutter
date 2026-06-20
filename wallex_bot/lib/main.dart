import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/data_provider.dart';
import 'screens/dashboard_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';

void main() async {
  // اطمینان از مقداردهی اولیه فلاتر قبل از اجرای برنامه
  WidgetsFlutterBinding.ensureInitialized();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          // بلافاصله بعد از ساخته شدن، وضعیت لاگین را چک می‌کند
          create: (context) => AuthProvider()..checkAuthStatus(),
        ),
        ChangeNotifierProvider(
          // بارگذاری داده‌های کش شده داشبورد
          create: (context) => DataProvider()..loadCachedData(),
        ),
      ],
      child: WallexBotApp(),
    ),
  );
}

class WallexBotApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Wallex Bot',
      // تم تاریک هماهنگ با طراحی والکس
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0D1117),
        primaryColor: Colors.blueAccent,
        fontFamily: 'Vazir', // اگر فونت فارسی دارید نام آن را اینجا بگذارید
      ),
      
      // منطق اصلی نمایش صفحات
      home: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          // ۱. حالت بارگذاری (وقتی اپ تازه باز شده و دارد توکن را چک می‌کند)
          if (auth.isLoading) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(color: Colors.blueAccent),
              ),
            );
          }

          // ۲. اگر کاربر وارد شده است (توکن معتبر دارد)
          if (auth.isAuthenticated) {
            return const DashboardScreen();
          }

          // ۳. اگر کاربر وارد نشده است
          return LoginScreen();
        },
      ),

      // مسیرهای فرعی
      routes: {
        '/login': (context) => LoginScreen(),
        '/register': (context) => RegisterScreen(),
        '/dashboard': (context) => const DashboardScreen(),
      },
    );
  }
}