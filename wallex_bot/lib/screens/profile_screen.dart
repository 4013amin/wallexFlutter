import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';

class ProfileScreen extends StatefulWidget {
  final Map<String, dynamic> data;
  final VoidCallback onRefresh;

  const ProfileScreen({super.key, required this.data, required this.onRefresh});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiService _api = ApiService();

  late TextEditingController _apiKeyController;
  late TextEditingController _phoneController;
  late TextEditingController _maxInvController;
  late TextEditingController _slController;
  late TextEditingController _tpController;

  Timer? _debounce;
  bool _isDemoCharging = false;
  bool _isPaperTrading = true;
  String? _processingPackageId;
  List<dynamic> _transactions = [];

  final Color bgDark = const Color(0xFF020408);
  final Color neonBlue = const Color(0xFF00D1FF);
  final Color neonPurple = const Color(0xFF7000FF);
  final Color neonGreen = const Color(0xFF00FFA3);
  final Color neonRed = const Color(0xFFFF005C);

  @override
  void initState() {
    super.initState();
    // ایجاد کنترلرها با مقدار اولیه
    _apiKeyController = TextEditingController();
    _phoneController = TextEditingController();
    _maxInvController = TextEditingController();
    _slController = TextEditingController();
    _tpController = TextEditingController();
    
    _fillControllers(); // پر کردن مقادیر
    _loadTransactions();
  }

  // این متد بسیار مهم است: وقتی والد (Dashboard) Refresh می‌شود و داده جدید می‌فرستد، 
  // این متد فیلدها را با مقادیر جدید آپدیت می‌کند.
  @override
  void didUpdateWidget(covariant ProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.data != oldWidget.data) {
      _fillControllers();
    }
  }

  void _fillControllers() {
    final config = widget.data['config'] ?? {};
    final profile = widget.data['profile'] ?? {};

    // فقط اگر مقدار تغییر کرده باشد، متن کنترلر را عوض می‌کنیم (برای جلوگیری از پرش مکان‌نما)
    if (_apiKeyController.text != (config['api_key'] ?? "")) {
      _apiKeyController.text = config['api_key'] ?? "";
    }
    if (_phoneController.text != (profile['phone_number'] ?? "")) {
      _phoneController.text = profile['phone_number'] ?? "";
    }
    
    String maxInv = (config['max_investment_per_trade'] ?? "0").toString();
    if (_maxInvController.text != maxInv) _maxInvController.text = maxInv;

    String sl = (config['stop_loss_percent'] ?? "1.5").toString();
    if (_slController.text != sl) _slController.text = sl;

    String tp = (config['take_profit_percent'] ?? "3.0").toString();
    if (_tpController.text != tp) _tpController.text = tp;

    _isPaperTrading = config['is_paper_trading'] ?? true;
  }

  void _autoSave() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 1500), () async {
      await _api.sendDashboardAction("update_config", extraData: {
        "api_key": _apiKeyController.text,
        "phone_number": _phoneController.text,
        "is_paper": _isPaperTrading,
        "max_investment": _maxInvController.text,
        "stop_loss": _slController.text,
        "take_profit": _tpController.text,
      });
      widget.onRefresh(); 
    });
  }

  Future<void> _loadTransactions() async {
    final res = await _api.getTransactions();
    if (res.containsKey('transactions')) {
      setState(() => _transactions = res['transactions']);
    }
  }

  Future<void> _logout() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.logout();
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    }
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _phoneController.dispose();
    _maxInvController.dispose();
    _slController.dispose();
    _tpController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = (widget.data['profile']?['tokens_balance'] ?? 0).toString();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          _buildBalanceGlowingCard(tokens),
          const SizedBox(height: 30),
          _buildSectionTitle("هسته پردازشی و اتصال", Icons.developer_board_rounded),
          _buildGlassField("Wallex API Key", _apiKeyController, Icons.vpn_key_rounded, true),
          const SizedBox(height: 15),
          _buildEnvironmentToggle(),
          const SizedBox(height: 30),
          _buildSectionTitle("مدیریت ریسک هوشمند", Icons.security_rounded),
          _buildGlassField("سرمایه در هر معامله (TMN)", _maxInvController, Icons.account_balance_wallet_rounded, false),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(child: _buildGlassField("حد سود %", _tpController, Icons.trending_up, false, color: neonGreen)),
              const SizedBox(width: 15),
              Expanded(child: _buildGlassField("حد ضرر %", _slController, Icons.trending_down, false, color: neonRed)),
            ],
          ),
          const SizedBox(height: 30),
          _buildSectionTitle("فروشگاه توکن AI", Icons.shopping_cart_outlined),
          _buildPackageCard("بسته پایه", "۱۰", "۵۰,۰۰۰", "pack_10", neonBlue),
          _buildPackageCard("بسته حرفه‌ای", "۵۰", "۲۰۰,۰۰۰", "pack_50", neonPurple),
          _buildPackageCard("بسته نامحدود", "۱۰۰", "۳۵۰,۰۰۰", "pack_100", neonGreen),
          const SizedBox(height: 30),
          _buildSectionTitle("تاریخچه تراکنش‌ها", Icons.history),
          _buildTransactionList(),
          const SizedBox(height: 40),
          _buildDemoChargeBtn(),
          const SizedBox(height: 30),
          _buildLogoutButton(),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildBalanceGlowingCard(String tokens) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: LinearGradient(colors: [neonBlue.withOpacity(0.2), neonPurple.withOpacity(0.2)]),
        border: Border.all(color: neonBlue.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          const Text("موجودی توکن‌های آنالیز", style: TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 10),
          Text(tokens, style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.w900, letterSpacing: 2)),
          const SizedBox(height: 5),
          Text("QUANTUM UNITS", style: TextStyle(color: neonBlue, fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildGlassField(String label, TextEditingController controller, IconData icon, bool ltr, {Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 10, bottom: 8),
          child: Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
        ),
        ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: TextField(
              controller: controller,
              onChanged: (_) => _autoSave(),
              textAlign: ltr ? TextAlign.left : TextAlign.right,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                prefixIcon: Icon(icon, color: color ?? neonBlue, size: 20),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Colors.white10)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: color ?? neonBlue)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEnvironmentToggle() {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(15)),
      child: Row(
        children: [
          Expanded(child: _toggleBtn("شبیه‌ساز", _isPaperTrading, () => _setPaper(true))),
          Expanded(child: _toggleBtn("بازار واقعی", !_isPaperTrading, () => _setPaper(false))),
        ],
      ),
    );
  }

  void _setPaper(bool val) {
    setState(() => _isPaperTrading = val);
    _autoSave();
  }

  Widget _toggleBtn(String text, bool active, VoidCallback tap) {
    return GestureDetector(
      onTap: tap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: active ? neonBlue.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: active ? Border.all(color: neonBlue.withOpacity(0.5)) : null,
        ),
        child: Center(child: Text(text, style: TextStyle(color: active ? Colors.white : Colors.white38, fontSize: 12, fontWeight: FontWeight.bold))),
      ),
    );
  }

  Widget _buildPackageCard(String title, String tokens, String price, String packId, Color color) {
    bool isProcessing = _processingPackageId == packId;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(Icons.bolt, color: color),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              Text("$tokens توکن پردازش", style: const TextStyle(color: Colors.white38, fontSize: 11)),
            ]),
          ),
          ElevatedButton(
            onPressed: isProcessing ? null : () => _buyPackage(packId),
            style: ElevatedButton.styleFrom(backgroundColor: color.withOpacity(0.2), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: isProcessing ? const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2)) : Text("$price ت", style: const TextStyle(fontSize: 12, color: Colors.white)),
          )
        ],
      ),
    );
  }

  Future<void> _buyPackage(String packId) async {
    setState(() => _processingPackageId = packId);
    final res = await _api.sendDashboardAction("get_payment_link", extraData: {"package_id": packId});
    if (res.containsKey('payment_url')) {
      await launchUrl(Uri.parse(res['payment_url']), mode: LaunchMode.externalApplication);
    }
    setState(() => _processingPackageId = null);
  }

  Widget _buildTransactionList() {
    if (_transactions.isEmpty) return const Center(child: Text("تراکنشی ثبت نشده", style: TextStyle(color: Colors.white24, fontSize: 12)));
    return Column(
      children: _transactions.map((tx) => ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(tx['status'] == 'SUCCESS' ? Icons.check_circle_outline : Icons.pending_outlined, color: tx['status'] == 'SUCCESS' ? neonGreen : Colors.orange),
        title: Text("خرید ${tx['tokens_to_add']} توکن", style: const TextStyle(color: Colors.white, fontSize: 13)),
        subtitle: Text(tx['created_at'], style: const TextStyle(color: Colors.white24, fontSize: 10)),
        trailing: Text("${tx['amount_toman']} ت", style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
      )).toList(),
    );
  }

  Widget _buildDemoChargeBtn() {
    return Center(
      child: TextButton.icon(
        onPressed: _isDemoCharging ? null : () async {
          setState(() => _isDemoCharging = true);
          await _api.sendDashboardAction("charge_demo");
          widget.onRefresh();
          setState(() => _isDemoCharging = false);
        },
        icon: Icon(Icons.card_giftcard, color: neonPurple),
        label: Text(_isDemoCharging ? "در حال دریافت..." : "دریافت ۱۰ توکن هدیه (دمو)", style: TextStyle(color: neonPurple, fontSize: 12)),
      ),
    );
  }

  Widget _buildSectionTitle(String t, IconData i) => Padding(
    padding: const EdgeInsets.only(bottom: 15),
    child: Row(children: [Icon(i, color: neonBlue, size: 18), const SizedBox(width: 8), Text(t, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold))]),
  );

  Widget _buildLogoutButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [neonRed.withOpacity(0.1), Colors.transparent]),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: neonRed.withOpacity(0.3)),
      ),
      child: TextButton.icon(
        onPressed: _logout,
        icon: Icon(Icons.logout_rounded, color: neonRed),
        label: Text("خروج از حساب کاربری", style: TextStyle(color: neonRed, fontSize: 14, fontWeight: FontWeight.bold)),
        style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
      ),
    );
  }
}