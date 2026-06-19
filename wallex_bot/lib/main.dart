import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/data_provider.dart';
import 'screens/dashboard_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => AuthProvider()..checkAuthStatus(),
        ),
        ChangeNotifierProvider(
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
      theme: ThemeData.dark(),
      home: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          // اگر هنوز در حال بارگیری است
          if (authProvider.isLoading) {
            return Scaffold(
              backgroundColor: Color(0xFF0D1117),
              body: Center(
                child: CircularProgressIndicator(color: Colors.blueAccent),
              ),
            );
          }

          // اگر کاربر وارد شده‌است، داشبورد نشان بده
          if (authProvider.isAuthenticated) {
            return DashboardScreen();
          }

          // در غیر این صورت، صفحه ورود نشان بده
          return LoginScreen();
        },
      ),
      routes: {
        '/register': (context) => RegisterScreen(),
        '/dashboard': (context) => DashboardScreen(),
      },
    );
  }
}