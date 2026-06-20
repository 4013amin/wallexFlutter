import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiService _api = ApiService();
  
  // کنترلرهای فرم برای ذخیره اطلاعات
  final TextEditingController _apiKeyController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _api.getDashboardData(), // فراخوانی دیتای داشبورد
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) return Center(child: Text("خطا: ${snapshot.error}", style: const TextStyle(color: Colors.white)));

          // دیتاهای دریافت شده از API
          final data = snapshot.data!;
          final profile = data['profile'];
          final config = data['config'];

          // پر کردن کنترلرها فقط یکبار
          if (_apiKeyController.text.isEmpty) {
            _apiKeyController.text = config['api_key'] ?? "";
            _phoneController.text = profile['phone_number'] ?? "";
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // کارت نمایش توکن
                _buildInfoCard("موجودی توکن", "${profile['tokens_balance']}", Icons.wallet),
                
                const SizedBox(height: 20),
                const Text("تنظیمات اتصال", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                
                _buildTextField("کلید API", _apiKeyController),
                _buildTextField("شماره همراه", _phoneController),
                
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    var res = await _api.sendDashboardAction("update_config", extraData: {
                      "api_key": _apiKeyController.text,
                      "phone_number": _phoneController.text
                    });
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("با موفقیت ذخیره شد")));
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, minimumSize: const Size(double.infinity, 50)),
                  child: const Text("ذخیره تنظیمات", style: TextStyle(color: Colors.white)),
                ),

                const SizedBox(height: 30),
                const Text("خرید توکن", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                
                // لیست دکمه‌های خرید
                _buildPurchaseButton("بسته نقره‌ای (۱۰ توکن)", "pack_10"),
                _buildPurchaseButton("بسته طلایی (۵۰ توکن)", "pack_50"),
              ],
            ),
          );
        },
      ),
    );
  }

  // ویجت‌های کمکی برای زیبایی صفحه
  Widget _buildInfoCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(16)),
      child: Row(children: [
        Icon(icon, color: Colors.blue, size: 30),
        const SizedBox(width: 15),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
        ]),
      ]),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(labelText: label, labelStyle: const TextStyle(color: Colors.grey), border: const OutlineInputBorder()),
      ),
    );
  }

  Widget _buildPurchaseButton(String label, String packId) {
    return Card(
      color: const Color(0xFF1E293B),
      child: ListTile(
        title: Text(label, style: const TextStyle(color: Colors.white)),
        trailing: const Icon(Icons.payment, color: Colors.green),
        onTap: () async {
          // اینجا اکشن خرید به API ارسال می‌شود
          await _api.sendDashboardAction("buy_token", extraData: {"package": packId});
          setState(() {}); // رفرش صفحه برای دیدن موجودی جدید
        },
      ),
    );
  }
}