import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import '../services/api_service.dart';
import '../providers/data_provider.dart';
import '../providers/auth_provider.dart';
import 'analysis_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with TickerProviderStateMixin {
  final ApiService _api = ApiService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  bool _isLoading = true;
  bool _isScanning = false;
  Map<String, dynamic>? _data;
  List _currentSignals = []; // برای جلوگیری از پاک شدن لیست پس از رفرش

  // پالت رنگی حرفه‌ای هماهنگ با فایل HTML شما
  final Color bgBody = const Color(0xFF080D1A);
  final Color bgCard = const Color(0xFF111827);
  final Color accentColor = const Color(0xFF3B82F6);
  final Color buyColor = const Color(0xFF10B981);
  final Color sellColor = const Color(0xFFF43F5E);
  final Color textMain = const Color(0xFFF3F4F6);
  final Color textMuted = const Color(0xFF9CA3AF);

  @override
  void initState() {
    super.initState();
    // بارگذاری داده‌های ذخیره‌شده از حافظه
    final dataProvider = Provider.of<DataProvider>(context, listen: false);
    _data = dataProvider.dashboardData;
    _currentSignals = dataProvider.signals;
    
    _refreshData();
  }

  Future<void> _refreshData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      var res = await _api.getDashboardData();
      if (mounted) {
        setState(() {
          _data = res;
          // مشابه فایل HTML: اگر سیگنال‌های جدیدی آمد جایگزین کن، در غیر این صورت لیست قبلی را حفظ کن
          if (res['signals'] != null && (res['signals'] as List).isNotEmpty) {
            _currentSignals = res['signals'];
          }
          _isLoading = false;
        });
        
        // ذخیره داده‌ها برای بازیابی بعدی
        final dataProvider = Provider.of<DataProvider>(context, listen: false);
        await dataProvider.saveDashboardData(res);
        await dataProvider.saveSignals(_currentSignals);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleScan() async {
    setState(() => _isScanning = true);
    try {
      var res = await _api.sendDashboardAction("scan_signals");
      if (res != null && mounted) {
        setState(() {
          _currentSignals = List.from(res['signals'] ?? []);
          if (_data != null) {
            _data!['profile']['tokens_balance'] = res['remaining_tokens'];
          }
        });
        
        // ذخیره سیگنال‌های جدید
        final dataProvider = Provider.of<DataProvider>(context, listen: false);
        await dataProvider.saveSignals(_currentSignals);
        await dataProvider.saveDashboardData(_data!);
      }
    } finally {
      if (mounted) setState(() => _isScanning = false);
    }
  }

  void _handleLogout() async {
    // پاک کردن تمام داده‌های ذخیره‌شده
    final dataProvider = Provider.of<DataProvider>(context, listen: false);
    await dataProvider.clearCachedData();
    
    // خروج
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.logout();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: bgBody,
      drawer: _buildDrawer(), // منوی کناری (Sidebar)
      body: _isLoading 
          ? Center(child: CircularProgressIndicator(color: accentColor, strokeWidth: 2)) 
          : Stack(
              children: [
                _buildBackgroundGlow(), // رفع خطای فیلتر در اینجا
                SafeArea(
                  child: Directionality(
                    textDirection: TextDirection.rtl,
                    child: RefreshIndicator(
                      onRefresh: _refreshData,
                      color: accentColor,
                      child: CustomScrollView(
                        physics: const BouncingScrollPhysics(),
                        slivers: [
                          _buildAppBar(),
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildTokenCard(),
                                  const SizedBox(height: 25),
                                  _buildQuickActions(),
                                  const SizedBox(height: 30),
                                  _buildRiskBanner(), // بنر مدیریت ریسک مشابه HTML
                                  const SizedBox(height: 35),
                                  _buildSectionHeader("موقعیت‌های باز تعهدی", Icons.layers_outlined),
                                  _buildActivePositions(),
                                  const SizedBox(height: 35),
                                  _buildSectionHeader("رادار فرصت‌های معاملاتی", Icons.radar_outlined),
                                  _buildSignalsRadar(),
                                  const SizedBox(height: 100),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (_isScanning) _buildLoadingOverlay(),
              ],
            ),
    );
  }

  // --- ویجت‌های بخش پس‌زمینه (رفع خطا) ---

  Widget _buildBackgroundGlow() {
    return Positioned(
      top: -100,
      left: -100,
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
        child: Container(
          width: 300,
          height: 300,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: accentColor.withOpacity(0.1),
          ),
        ),
      ),
    );
  }

  // --- منوی کناری (Sidebar) ---

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: bgBody,
      child: Column(
        children: [
          DrawerHeader(child: Center(child: Text("QUANT TERMINAL", style: TextStyle(color: accentColor, fontSize: 20, fontWeight: FontWeight.w900)))),
          _drawerItem(Icons.dashboard_rounded, "داشبورد معاملات", () => Navigator.pop(context), isActive: true),
          _drawerItem(Icons.settings_outlined, "تنظیمات استراتژی", () {}),
          const Spacer(),
          _drawerItem(Icons.logout_rounded, "خروج از حساب", _handleLogout, color: sellColor),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _drawerItem(IconData icon, String title, VoidCallback tap, {bool isActive = false, Color? color}) {
    return ListTile(
      leading: Icon(icon, color: color ?? (isActive ? accentColor : textMuted)),
      title: Text(title, style: TextStyle(color: color ?? (isActive ? Colors.white : textMuted), fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
      onTap: tap,
    );
  }

  // --- اجزای اصلی صفحه ---

  Widget _buildAppBar() {
    return SliverAppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      floating: true,
      centerTitle: true,
      leading: IconButton(
        icon: Icon(Icons.menu_rounded, color: textMain),
        onPressed: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      title: Text("کوانت تریدر", style: TextStyle(color: textMain, fontSize: 16, fontWeight: FontWeight.bold)),
      actions: [
        _buildStatusDot(),
        const SizedBox(width: 15),
      ],
    );
  }

  Widget _buildStatusDot() {
    bool isActive = _data?['config']?['is_active'] ?? false;
    return Row(
      children: [
        Text(isActive ? "LIVE" : "OFFLINE", style: TextStyle(color: isActive ? buyColor : sellColor, fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(width: 8),
        _PulseDot(color: isActive ? buyColor : sellColor),
      ],
    );
  }

  Widget _buildTokenCard() {
    int tokens = _data?['profile']?['tokens_balance'] ?? 0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: bgCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("موجودی توکن پردازشی", style: TextStyle(color: textMuted, fontSize: 12)),
          const SizedBox(height: 10),
          Text(
            "$tokens",
            style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900, fontFamily: 'monospace'),
          ),
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: accentColor.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
            child: Text(
              _data?['config']?['is_paper_trading'] == true ? "PAPER MODE" : "REAL MODE",
              style: TextStyle(color: accentColor, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    bool isActive = _data?['config']?['is_active'] ?? false;
    return Row(
      children: [
        Expanded(child: _actionBtn("اسکن زنده", Icons.bolt_rounded, accentColor, _handleScan)),
        const SizedBox(width: 15),
        Expanded(child: _actionBtn(
          isActive ? "توقف ربات" : "شروع ربات", 
          isActive ? Icons.stop_rounded : Icons.play_arrow_rounded, 
          isActive ? sellColor : buyColor, 
          () async {
            await _api.sendDashboardAction("toggle_bot");
            _refreshData();
          }
        )),
      ],
    );
  }

  Widget _buildRiskBanner() {
    String? phone = _data?['profile']?['phone_number'];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accentColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accentColor.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Icon(Icons.gpp_good_rounded, color: buyColor, size: 30),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("سیستم مانیتورینگ ریسک فعال", style: TextStyle(color: textMain, fontSize: 13, fontWeight: FontWeight.bold)),
                Text(phone != null ? "پیامک هشدار به $phone" : "شماره همراه ثبت نشده است", style: TextStyle(color: textMuted, fontSize: 11)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildActivePositions() {
    List positions = _data?['active_positions'] ?? [];
    if (positions.isEmpty) return _emptyState("هیچ موقعیت باز فعالی یافت نشد");
    return Column(children: positions.map((p) => _FadeInSlide(delay: 100, child: _positionCard(p))).toList());
  }

  Widget _buildSignalsRadar() {
    if (_currentSignals.isEmpty) return _emptyState("رادار خالی است. جهت دریافت فرصت اسکن کنید.");
    return Column(children: _currentSignals.map((s) => _FadeInSlide(delay: 100, child: _signalCard(s))).toList());
  }

  // --- کامپوننت‌های کوچک کارت‌ها ---

  Widget _positionCard(Map p) {
    bool isLong = p['side'] == "long";
    double pnl = double.tryParse(p['pnl_percent']?.toString() ?? '0') ?? 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: bgCard, borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          _coinCircle(p['symbol'], isLong ? buyColor : sellColor),
          const SizedBox(width: 15),
          Expanded(child: Text(p['symbol'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text("${pnl >= 0 ? '+' : ''}$pnl%", style: TextStyle(color: pnl >= 0 ? buyColor : sellColor, fontWeight: FontWeight.w900, fontSize: 16)),
              Text("سود/ضرر", style: TextStyle(color: textMuted, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _signalCard(Map s) {
    bool isBuy = s['side'] == "BUY";
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AnalysisScreen(symbol: s['symbol']))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgCard, 
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: (isBuy ? buyColor : sellColor).withOpacity(0.1)),
        ),
        child: Row(
          children: [
            _coinCircle(s['symbol'], isBuy ? buyColor : sellColor),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s['symbol'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  Text("قیمت: ${s['price']}", style: TextStyle(color: textMuted, fontSize: 11)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: textMuted, size: 14),
          ],
        ),
      ),
    );
  }

  Widget _actionBtn(String t, IconData i, Color c, VoidCallback tap) {
    return InkWell(
      onTap: tap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(18), border: Border.all(color: c.withOpacity(0.2))),
        child: Column(children: [Icon(i, color: c), const SizedBox(height: 5), Text(t, style: TextStyle(color: c, fontSize: 12, fontWeight: FontWeight.bold))]),
      ),
    );
  }

  Widget _coinCircle(String sym, Color c) {
    return Container(width: 40, height: 40, decoration: BoxDecoration(color: c.withOpacity(0.1), shape: BoxShape.circle), child: Center(child: Text(sym[0], style: TextStyle(color: c, fontWeight: FontWeight.bold))));
  }

  Widget _emptyState(String m) {
    return Center(child: Padding(padding: const EdgeInsets.all(30), child: Text(m, style: TextStyle(color: textMuted, fontSize: 12))));
  }

  Widget _buildSectionHeader(String t, IconData i) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(children: [Icon(i, color: accentColor, size: 20), const SizedBox(width: 10), Text(t, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))]),
    );
  }

  Widget _buildLoadingOverlay() {
    return BackdropFilter(filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5), child: Container(color: Colors.black54, child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [CircularProgressIndicator(color: accentColor, strokeWidth: 2), const SizedBox(height: 20), Text("در حال اسکن بازار...", style: TextStyle(color: textMain))]))));
  }
}

// --- انیمیشن‌ها ---

class _PulseDot extends StatefulWidget {
  final Color color;
  const _PulseDot({required this.color});
  @override
  __PulseDotState createState() => __PulseDotState();
}

class __PulseDotState extends State<_PulseDot> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  @override
  void initState() { _c = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat(reverse: true); super.initState(); }
  @override
  Widget build(BuildContext context) { return FadeTransition(opacity: _c, child: Container(width: 8, height: 8, decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle, boxShadow: [BoxShadow(color: widget.color, blurRadius: 6)]))); }
  @override
  void dispose() { _c.dispose(); super.dispose(); }
}

class _FadeInSlide extends StatelessWidget {
  final Widget child;
  final int delay;
  const _FadeInSlide({required this.child, required this.delay});
  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder(tween: Tween<double>(begin: 0, end: 1), duration: const Duration(milliseconds: 500), builder: (context, double v, child) => Opacity(opacity: v, child: Transform.translate(offset: Offset(0, 20 * (1 - v)), child: child)), child: child);
  }
}