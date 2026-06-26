import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/data_provider.dart';
import 'screens/dashboard_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';

void main() async {
  // ۱. اطمینان از مقداردهی اولیه برای استفاده از SharedPreferences
  WidgetsFlutterBinding.ensureInitialized();
  
  // ۲. ایجاد نمونه از پروایدرها قبل از runApp (اختیاری اما برای سرعت لود بهتر است)
  final dataProvider = DataProvider();
  final authProvider = AuthProvider();

  // شروع عملیات بارگذاری دیتای کش شده همزمان با لود شدن اپلیکیشن
  // این کار باعث می‌شود سیگنال‌های قبلی بلافاصله در دسترس باشند
  dataProvider.loadCachedData();
  authProvider.checkAuthStatus();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider.value(value: dataProvider),
      ],
      child: const WallexBotApp(),
    ),
  );
}

class WallexBotApp extends StatelessWidget {
  const WallexBotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Wallex Bot',
      // تم تاریک هماهنگ با طراحی کوانتوم
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF080D1A), // رنگ تیره پس‌زمینه شما
        primaryColor: const Color(0xFF3B82F6),
        fontFamily: 'Vazir', 
      ),
      
      home: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          // ۱. نمایش لودینگ در ابتدای باز شدن اپلیکیشن
          if (auth.isLoading) {
            return const Scaffold(
              backgroundColor: Color(0xFF080D1A),
              body: Center(
                child: CircularProgressIndicator(color: Color(0xFF3B82F6)),
              ),
            );
          }

          // ۲. اگر کاربر قبلاً لاگین کرده و توکنش معتبر است
          if (auth.isAuthenticated) {
            return const DashboardScreen();
          }

          // ۳. اگر کاربر باید دوباره وارد شود
          return LoginScreen();
        },
      ),

      // مسیرهای تعریف شده برای دسترسی سریع
      routes: {
        '/login': (context) => LoginScreen(),
        '/register': (context) => RegisterScreen(),
        '/dashboard': (context) => const DashboardScreen(),
      },
    );
  }
}