import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfileScreen extends StatefulWidget {
  final Map<String, dynamic> data;
  final VoidCallback onRefresh;

  const ProfileScreen({super.key, required this.data, required this.onRefresh});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiService _api = ApiService();
  final TextEditingController _apiKeyController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  
  bool _isSaving = false;
  String? _processingPackageId;

  @override
  void initState() {
    super.initState();
    _apiKeyController.text = widget.data['config']?['api_key'] ?? "";
    _phoneController.text = widget.data['profile']?['phone_number'] ?? "";
  }

 Future<void> _initiatePayment(String packageId) async {
    setState(() => _processingPackageId = packageId);
    try {
      final res = await _api.sendDashboardAction(
        "get_payment_link", 
        extraData: {"package_id": packageId}
      );
      
      // ۱. ابتدا چک کن که آیا پاسخ شامل ارور دست‌ساز جنگو هست یا نه
      if (res.containsKey('error')) {
        _showSnackBar(res['error'], isError: true);
        return;
      }

      // ۲. بررسی وجود لینک پرداخت
      if (res.containsKey('payment_url') && res['payment_url'] != null) {
        final Uri url = Uri.parse(res['payment_url']);
        
        // استفاده از بلاک try-catch مستقیم برای لانچ کردن به جای شرط canLaunchUrl
        try {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        } catch (launchError) {
          _showSnackBar("مرورگری برای باز کردن درگاه پرداخت یافت نشد", isError: true);
        }
        
      } else {
        _showSnackBar("لینک پرداخت از سمت سرور دریافت نشد", isError: true);
      }
    } catch (e) {
      _showSnackBar("خطای غیرمنتظره در پردازش عملیات", isError: true);
      print("Flutter API Error: $e");
    } finally {
      setState(() => _processingPackageId = null);
    }
  }

  void _saveSettings() async {
    setState(() => _isSaving = true);
    try {
      await _api.sendDashboardAction("update_config", extraData: {
        "api_key": _apiKeyController.text,
        "phone_number": _phoneController.text
      });
      widget.onRefresh();
      _showSnackBar("تنظیمات با موفقیت ذخیره شد");
    } catch (e) {
      _showSnackBar("خطا در ذخیره تنظیمات", isError: true);
    }
    setState(() => _isSaving = false);
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontFamily: 'Vazir')),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // جلوگیری از کرش کردن در صورت خالی بودن دیتا
    final profile = widget.data['profile'] ?? {};
    final tokens = (profile['tokens_balance'] ?? 0).toString();

    // استفاده از Material به جای Container برای رفع خطای RenderBox
    return Material(
      color: const Color(0xFF0D1117), // رنگ پس‌زمینه دارک و مدرن
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              
              // کارت موجودی توکن
              _buildTokenBalanceCard(tokens),
              
              const SizedBox(height: 30),
              
              // بخش تنظیمات کاربری
              const Text("تنظیمات کاربری", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              _buildModernInput("API Key صرافی", _apiKeyController, Icons.vpn_key_rounded),
              _buildModernInput("شماره همراه", _phoneController, Icons.phone_android_rounded),
              
              const SizedBox(height: 10),
              _buildSaveButton(),

              const SizedBox(height: 40),

              // بخش فروشگاه توکن
              const Text("تهیه اشتراک توکن", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              
              _buildPackageCard("بسته نقره‌ای", "10", "50,000", "pack_10", [Colors.grey.shade400, Colors.grey.shade600]),
              _buildPackageCard("بسته طلایی", "50", "200,000", "pack_50", [Colors.orange.shade300, Colors.orange.shade600]),
              _buildPackageCard("بسته پلاتینیوم", "100", "350,000", "pack_100", [Colors.blue.shade300, Colors.purple.shade500]),
              
              const SizedBox(height: 80), // جلوگیری از گیر کردن محتوا زیر نویگیشن بار
            ],
          ),
        ),
      ),
    );
  }

  // --- ویجت‌های زیباسازی شده ---

  Widget _buildTokenBalanceCard(String balance) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade800, Colors.blue.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.monetization_on_rounded, color: Colors.white70, size: 40),
          const SizedBox(height: 10),
          const Text("موجودی توکن‌های شما", style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 5),
          Text(balance, style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildModernInput(String hint, TextEditingController controller, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.blueAccent),
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white38),
          filled: true,
          fillColor: const Color(0xFF161B22),
          contentPadding: const EdgeInsets.symmetric(vertical: 18),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Colors.blueAccent, width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveSettings,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blueAccent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          elevation: 0,
        ),
        child: _isSaving 
          ? const SizedBox(width: 25, height: 25, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
          : const Text("ذخیره تغییرات", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
      ),
    );
  }

  Widget _buildPackageCard(String title, String tokens, String price, String packId, List<Color> gradientColors) {
    bool isProcessing = _processingPackageId == packId;

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // آیکون پکیج
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: gradientColors),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.diamond_rounded, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 15),
            
            // متون
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text("$tokens توکن پردازشی", style: const TextStyle(color: Colors.white54, fontSize: 13)),
                ],
              ),
            ),

            // دکمه و قیمت
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text("$price تومان", style: const TextStyle(color: Colors.greenAccent, fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                InkWell(
                  onTap: isProcessing ? null : () => _initiatePayment(packId),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: isProcessing ? Colors.grey.withOpacity(0.2) : Colors.blueAccent.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: isProcessing
                        ? const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blueAccent))
                        : const Text("خرید", style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
                  ),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}