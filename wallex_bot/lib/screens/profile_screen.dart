import 'dart:ui';
import 'dart:async'; // اضافه شدن برای تایمر ذخیره خودکار
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

  late TextEditingController _apiKeyController;
  late TextEditingController _phoneController;
  late TextEditingController _maxInvestmentController;
  late TextEditingController _stopLossController;
  late TextEditingController _takeProfitController;

  Timer? _debounce; // تایمر برای جلوگیری از ارسال رگباری درخواست به سرور
  bool _isDemoCharging = false;
  bool _isPaperTrading = true;
  String? _processingPackageId;
  bool _isUserTyping = false; // برای جلوگیری از آپدیت controllers هنگام تایپ کاربر

  // پالت رنگی
  final Color _bgColor = const Color(0xFF0B1120);
  final Color _panelColor = const Color(0xFF161E31);
  final Color _borderColor = const Color(0xFF2A364E);
  final Color _accentColor = const Color(0xFF3B82F6);
  final Color _buyColor = const Color(0xFF10B981);
  final Color _sellColor = const Color(0xFFEF4444);
  final Color _holdColor = const Color(0xFFF59E0B);
  final Color _premiumColor = const Color(0xFF8B5CF6);

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    final config = widget.data['config'] ?? {};
    final profile = widget.data['profile'] ?? {};

    _apiKeyController = TextEditingController(text: config['api_key'] ?? "");
    _phoneController = TextEditingController(text: profile['phone_number'] ?? "");

    double maxInv = 0;
    if (config['max_investment_per_trade'] != null) {
      maxInv = double.tryParse(config['max_investment_per_trade'].toString()) ?? 0;
    }
    _maxInvestmentController = TextEditingController(text: maxInv.toStringAsFixed(0));
    _stopLossController = TextEditingController(text: (config['stop_loss_percent'] ?? "1.5").toString());
    _takeProfitController = TextEditingController(text: (config['take_profit_percent'] ?? "3.0").toString());

    _isPaperTrading = config['is_paper_trading'] ?? true;
  }

  @override
  void didUpdateWidget(covariant ProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.data != oldWidget.data) {
      _updateControllers();
    }
  }

  void _updateControllers() {
    // اگر کاربر در حال تایپ است، controllers را آپدیت نکن تا دیتا قاطی نشود
    if (_isUserTyping) return;
    
    final config = widget.data['config'] ?? {};
    final profile = widget.data['profile'] ?? {};

    if (config['api_key'] != null && _apiKeyController.text != config['api_key']) {
      _apiKeyController.text = config['api_key'] ?? "";
    }
    if (profile['phone_number'] != null && _phoneController.text != profile['phone_number']) {
      _phoneController.text = profile['phone_number'] ?? "";
    }

    double maxInv = 0;
    if (config['max_investment_per_trade'] != null) {
      maxInv = double.tryParse(config['max_investment_per_trade'].toString()) ?? 0;
    }
    if (_maxInvestmentController.text != maxInv.toStringAsFixed(0)) {
      _maxInvestmentController.text = maxInv.toStringAsFixed(0);
    }

    String stopLoss = (config['stop_loss_percent'] ?? "1.5").toString();
    if (_stopLossController.text != stopLoss) _stopLossController.text = stopLoss;

    String takeProfit = (config['take_profit_percent'] ?? "3.0").toString();
    if (_takeProfitController.text != takeProfit) _takeProfitController.text = takeProfit;

    if (_isPaperTrading != (config['is_paper_trading'] ?? true)) {
      setState(() => _isPaperTrading = config['is_paper_trading'] ?? true);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _apiKeyController.dispose();
    _phoneController.dispose();
    _maxInvestmentController.dispose();
    _stopLossController.dispose();
    _takeProfitController.dispose();
    super.dispose();
  }

  // ==================== توابع API ====================

  // ذخیره خودکار تنظیمات با وقفه ۱.۲ ثانیه‌ای (Debounce)
  void _autoSaveSettings() {
    _isUserTyping = true;
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 1200), () async {
      try {
        double maxInv = double.tryParse(_maxInvestmentController.text) ?? 0;
        double stopLoss = double.tryParse(_stopLossController.text) ?? 1.5;
        double takeProfit = double.tryParse(_takeProfitController.text) ?? 3.0;

        final res = await _api.sendDashboardAction("update_config", extraData: {
          "api_key": _apiKeyController.text,
          "phone_number": _phoneController.text,
          "is_paper": _isPaperTrading,
          "max_investment": maxInv,
          "stop_loss": stopLoss,
          "take_profit": takeProfit,
        }).timeout(const Duration(seconds: 10));

        if (!mounted) return;
        _isUserTyping = false;

        if (res.containsKey('error')) {
          _showSnackBar(res['error'], isError: true);
        } else {
          // در ذخیره خودکار معمولا پیغام موفقیت نشان نمی‌دهند تا کاربر اذیت نشود، 
          // اما رفرش را صدا میزنیم که در استیت اصلی ثبت شود
          widget.onRefresh();
        }
      } catch (e) {
        if (mounted) {
          _isUserTyping = false;
          _showSnackBar("خطا در ارتباط با سرور هنگام ذخیره خودکار", isError: true);
        }
      }
    });
  }

  Future<void> _initiatePayment(String packageId) async {
    setState(() => _processingPackageId = packageId);
    try {
      final res = await _api.sendDashboardAction("get_payment_link", extraData: {"package_id": packageId}).timeout(const Duration(seconds: 10));
      if (!mounted) return;

      if (res.containsKey('error')) {
        _showSnackBar(res['error'], isError: true);
      } else if (res.containsKey('payment_url') && res['payment_url'] != null) {
        final Uri url = Uri.parse(res['payment_url']);
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        _showSnackBar("لینک پرداخت دریافت نشد", isError: true);
      }
    } catch (e) {
      if (mounted) _showSnackBar("خطا در ارتباط با سرور", isError: true);
    } finally {
      if (mounted) setState(() => _processingPackageId = null);
    }
  }

  void _chargeDemo() async {
    setState(() => _isDemoCharging = true);
    try {
      final res = await _api.sendDashboardAction("charge_demo").timeout(const Duration(seconds: 10));
      if (!mounted) return;
      if (res.containsKey('error')) {
        _showSnackBar(res['error'], isError: true);
      } else {
        _showSnackBar("۱۰ توکن دمو اضافه شد", isSuccess: true);
        widget.onRefresh();
      }
    } catch (e) {
      if (mounted) _showSnackBar("خطا در سرور", isError: true);
    } finally {
      if (mounted) setState(() => _isDemoCharging = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false, bool isSuccess = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(isError ? Icons.error_outline : Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontFamily: 'Vazir', fontSize: 13, fontWeight: FontWeight.bold),
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
        backgroundColor: isError ? _sellColor : (isSuccess ? _buyColor : _accentColor),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(left: 16, right: 16, bottom: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 10,
      ),
    );
  }

  // ==================== BUILD ====================

  @override
  Widget build(BuildContext context) {
    final profile = widget.data['profile'] ?? {};
    final tokens = (profile['tokens_balance'] ?? 0).toString();
    final transactions = widget.data['transactions'] as List<dynamic>? ?? [];

    return LayoutBuilder(
      builder: (context, constraints) {
        double availableHeight = constraints.maxHeight;
        if (availableHeight == double.infinity) {
          availableHeight = MediaQuery.of(context).size.height;
        }

        return SizedBox(
          height: availableHeight,
          child: Scaffold(
            backgroundColor: _bgColor,
            body: Directionality(
              textDirection: TextDirection.rtl,
              child: SafeArea(
                bottom: false,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 40), // پدینگ پایین کم شد چون دکمه حذف شد
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeaderTitle(),
                      const SizedBox(height: 24),
                      _buildTokenBalanceCard(tokens),
                      const SizedBox(height: 32),
                      _buildSectionTitle("تنظیمات اتصال و استراتژی", Icons.settings_input_component_rounded),
                      const SizedBox(height: 12),
                      _buildExchangeCard(),
                      const SizedBox(height: 20),
                      _buildRiskManagementCard(),
                      const SizedBox(height: 20),
                      _buildSmsAlertCard(),
                      const SizedBox(height: 36),
                      _buildSectionTitle("فروشگاه توکن", Icons.store_rounded),
                      const SizedBox(height: 12),
                      _buildShopSection(),
                      const SizedBox(height: 36),
                      _buildSectionTitle("امور مالی", Icons.account_balance_wallet_rounded),
                      const SizedBox(height: 12),
                      _buildTransactionHistory(transactions),
                      const SizedBox(height: 24),
                      _buildDemoChargeCard(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ==================== ویجت‌های صفحه ====================

  Widget _buildHeaderTitle() {
    return const Align(
      alignment: Alignment.center,
      child: Text(
        "پروفایل و تنظیمات",
        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Vazir'),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: _accentColor, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Vazir'),
        ),
      ],
    );
  }

  Widget _buildTokenBalanceCard(String balance) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF1E3A8A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: _accentColor.withOpacity(0.25), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: -30,
            bottom: -30,
            child: Icon(Icons.bolt_rounded, size: 140, color: Colors.white.withOpacity(0.08)),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      "موجودی فعلی",
                      style: TextStyle(color: Colors.white, fontSize: 11, fontFamily: 'Vazir', fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        balance,
                        style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                      ),
                      const SizedBox(width: 8),
                      const Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: Text("توکن", style: TextStyle(color: Colors.white70, fontSize: 14, fontFamily: 'Vazir')),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.bolt_rounded, color: Colors.yellowAccent, size: 36),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExchangeCard() => _buildGlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildInputLabel("کلید دسترسی والکس (API Key)"),
            const SizedBox(height: 8),
            _buildTextField(_apiKeyController, "e.g. WLX-...", icon: Icons.key_rounded, isLtr: true),
            const SizedBox(height: 20),
            _buildInputLabel("محیط معاملاتی ربات"),
            const SizedBox(height: 8),
            _buildDropdownEnvironment(),
          ],
        ),
      );

  Widget _buildRiskManagementCard() => _buildGlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildInputLabel("حداکثر سرمایه درگیری در هر پوزیشن (تومان)"),
            const SizedBox(height: 8),
            _buildTextField(_maxInvestmentController, "مثال: 500000", icon: Icons.monetization_on_rounded, isLtr: true, isNumber: true),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildInputLabel("حد ضرر (Stop Loss)"),
                      const SizedBox(height: 8),
                      _buildTextField(_stopLossController, "%", icon: Icons.trending_down_rounded, isLtr: true, isNumber: true, iconColor: _sellColor),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildInputLabel("حد سود (Take Profit)"),
                      const SizedBox(height: 8),
                      _buildTextField(_takeProfitController, "%", icon: Icons.trending_up_rounded, isLtr: true, isNumber: true, iconColor: _buyColor),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      );

  Widget _buildSmsAlertCard() => _buildGlassCard(
        borderColor: _accentColor.withOpacity(0.3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.sms_failed_rounded, color: _holdColor, size: 20),
                const SizedBox(width: 8),
                const Text("هشدار اضطراری پیامکی", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'Vazir')),
              ],
            ),
            const SizedBox(height: 16),
            _buildInputLabel("شماره موبایل گیرنده پیامک"),
            const SizedBox(height: 8),
            _buildTextField(_phoneController, "09123456789", icon: Icons.phone_android_rounded, isLtr: true, isNumber: true),
            const SizedBox(height: 12),
            Text(
              "در صورت ریزش شدید بازار، سیستم پیامک خروج فوری ارسال می‌کند.",
              style: TextStyle(color: Colors.grey.shade400, fontSize: 11, fontFamily: 'Vazir'),
            ),
          ],
        ),
      );

  Widget _buildShopSection() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildShopCard("بسته استارتر", "۱۰", "۵۰,۰۰۰", "pack_10", _accentColor),
        _buildShopCard("بسته طلایی", "۵۰", "۲۰۰,۰۰۰", "pack_50", _holdColor, isPremium: true),
        _buildShopCard("بسته پلاتینیوم", "۱۰۰", "۳۵۰,۰۰۰", "pack_100", _premiumColor),
      ],
    );
  }

  Widget _buildShopCard(String title, String tokens, String price, String packId, Color mainColor, {bool isPremium = false}) {
    bool isProcessing = _processingPackageId == packId;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      width: double.infinity,
      decoration: BoxDecoration(
        color: isPremium ? mainColor.withOpacity(0.05) : _panelColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isPremium ? mainColor.withOpacity(0.5) : _borderColor, width: isPremium ? 1.5 : 1),
        boxShadow: isPremium ? [BoxShadow(color: mainColor.withOpacity(0.1), blurRadius: 15)] : [],
      ),
      child: Stack(
        children: [
          if (isPremium)
            Positioned(
              left: 12,
              top: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: mainColor,
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
                ),
                child: const Text("پیشنهاد ویژه", style: TextStyle(color: Colors.black87, fontSize: 10, fontWeight: FontWeight.bold, fontFamily: 'Vazir')),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: mainColor.withOpacity(0.15), shape: BoxShape.circle),
                  child: Icon(isPremium ? Icons.workspace_premium_rounded : Icons.star_rounded, color: mainColor, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(title, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold, fontFamily: 'Vazir')),
                      const SizedBox(height: 6),
                      Text("$tokens توکن پردازشی", style: TextStyle(color: Colors.grey.shade400, fontSize: 13, fontFamily: 'Vazir')),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("$price تومان", style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold, fontFamily: 'Vazir')),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 38,
                      child: ElevatedButton(
                        onPressed: isProcessing ? null : () => _initiatePayment(packId),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: mainColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: isPremium ? 4 : 0,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                        ),
                        child: isProcessing
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text("خرید", style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold, fontFamily: 'Vazir')),
                      ),
                    )
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionHistory(List<dynamic> transactions) {
    if (transactions.isEmpty) {
      return _buildGlassCard(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.receipt_long_rounded, size: 48, color: _borderColor),
                const SizedBox(height: 12),
                Text("تراکنشی یافت نشد.", style: TextStyle(color: Colors.grey.shade500, fontSize: 14, fontFamily: 'Vazir')),
              ],
            ),
          ),
        ),
      );
    }

    return _buildGlassCard(
      padding: const EdgeInsets.all(0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(transactions.length, (index) {
          final tx = transactions[index];
          final status = tx['status'] ?? 'PENDING';

          Color statusColor = _holdColor;
          IconData statusIcon = Icons.hourglass_empty_rounded;
          String statusText = "در انتظار";

          if (status == 'SUCCESS') {
            statusColor = _buyColor;
            statusIcon = Icons.check_circle_rounded;
            statusText = "موفق";
          } else if (status == 'FAILED') {
            statusColor = _sellColor;
            statusIcon = Icons.cancel_rounded;
            statusText = "ناموفق";
          }

          return Container(
            decoration: BoxDecoration(
              border: index != transactions.length - 1 ? Border(bottom: BorderSide(color: _borderColor.withOpacity(0.5))) : null,
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: statusColor.withOpacity(0.1), shape: BoxShape.circle),
                  child: Icon(statusIcon, color: statusColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text("خرید ${tx['tokens_to_add'] ?? 0} توکن", style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold, fontFamily: 'Vazir')),
                      const SizedBox(height: 4),
                      Text("کد پیگیری: ${tx['ref_id'] ?? '-'}", style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontFamily: 'monospace')),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("${tx['amount_toman'] ?? 0} تومان", style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold, fontFamily: 'Vazir')),
                    const SizedBox(height: 4),
                    Text(statusText, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'Vazir')),
                  ],
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildDemoChargeCard() {
    return InkWell(
      onTap: _isDemoCharging ? null : _chargeDemo,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _borderColor, width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isDemoCharging)
              const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            else ...[
              Icon(Icons.card_giftcard_rounded, color: Colors.grey.shade300, size: 22),
              const SizedBox(width: 12),
              Text(
                "دریافت ۱۰ توکن هدیه (شبیه‌ساز)",
                style: TextStyle(color: Colors.grey.shade300, fontSize: 13, fontWeight: FontWeight.bold, fontFamily: 'Vazir'),
              ),
            ]
          ],
        ),
      ),
    );
  }

  // ==================== کامپوننت‌های پایه ====================

  Widget _buildGlassCard({required Widget child, EdgeInsetsGeometry? padding, Color? borderColor}) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _panelColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor ?? _borderColor),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: child,
    );
  }

  Widget _buildInputLabel(String label) {
    return Text(
      label,
      style: TextStyle(color: Colors.grey.shade400, fontSize: 12, fontWeight: FontWeight.w600, fontFamily: 'Vazir'),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint, {
    required IconData icon,
    bool isLtr = false,
    bool isNumber = false,
    Color? iconColor,
  }) {
    return TextField(
      controller: controller,
      onChanged: (value) => _autoSaveSettings(), // اضافه شدن فراخوانی اتوسیو با هر تغییر کاربر
      style: TextStyle(
        color: Colors.white,
        fontFamily: isLtr ? 'monospace' : 'Vazir',
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
      textDirection: isLtr ? TextDirection.ltr : TextDirection.rtl,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.normal),
        filled: true,
        fillColor: _bgColor,
        prefixIcon: Icon(icon, color: iconColor ?? Colors.grey.shade500, size: 20),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: _borderColor)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: _borderColor)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: _accentColor, width: 1.5)),
      ),
    );
  }

  Widget _buildDropdownEnvironment() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _borderColor),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<bool>(
          value: _isPaperTrading,
          dropdownColor: _panelColor,
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey.shade400),
          isExpanded: true,
          style: const TextStyle(color: Colors.white, fontFamily: 'Vazir', fontSize: 13, fontWeight: FontWeight.w600),
          onChanged: (bool? newValue) {
            if (newValue != null) {
              setState(() => _isPaperTrading = newValue);
              _autoSaveSettings(); // با انتخاب از لیست، درجا ذخیره می‌شود
            }
          },
          items: [
            DropdownMenuItem(
              value: true,
              child: Row(
                children: [
                  Icon(Icons.science_rounded, color: _holdColor, size: 18),
                  const SizedBox(width: 10),
                  const Text("شبیه‌ساز (بدون ریسک واقعی)", style: TextStyle(fontFamily: 'Vazir')),
                ],
              ),
            ),
            DropdownMenuItem(
              value: false,
              child: Row(
                children: [
                  Icon(Icons.real_estate_agent_rounded, color: _buyColor, size: 18),
                  const SizedBox(width: 10),
                  const Text("حساب واقعی (Live Margin)", style: TextStyle(fontFamily: 'Vazir')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}