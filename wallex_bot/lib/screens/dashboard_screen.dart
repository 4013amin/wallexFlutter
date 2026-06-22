import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import '../services/api_service.dart';
import '../providers/data_provider.dart';
import '../providers/auth_provider.dart';
import 'analysis_screen.dart';
import 'profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with TickerProviderStateMixin {
  final ApiService _api = ApiService();
  int _selectedIndex = 0;
  
  bool _isLoading = false;
  bool _isScanning = false;
  Map<String, dynamic>? _data;
  List _currentSignals = [];

  // پالت رنگی کوانتوم
  final Color bgBody = const Color(0xFF080D1A);
  final Color bgCard = const Color(0xFF111827);
  final Color accentColor = const Color(0xFF3B82F6);
  final Color buyColor = const Color(0xFF10B981);
  final Color sellColor = const Color(0xFFF43F5E);
  final Color holdColor = const Color(0xFFF59E0B);
  final Color textMain = const Color(0xFFF3F4F6);
  final Color textMuted = const Color(0xFF9CA3AF);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPersistedData();
    });
  }

  void _loadPersistedData() {
    final dataProvider = Provider.of<DataProvider>(context, listen: false);
    setState(() {
      _data = dataProvider.dashboardData;
      _currentSignals = dataProvider.signals;
      if (_data == null) {
        _refreshData();
      }
    });
  }

  Future<void> _refreshData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      var res = await _api.getDashboardData();
      if (mounted) {
        final dataProvider = Provider.of<DataProvider>(context, listen: false);
        await dataProvider.saveDashboardData(res);
        setState(() {
          _data = res;
          _isLoading = false;
        });
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
        final dataProvider = Provider.of<DataProvider>(context, listen: false);
        List newSignals = List.from(res['signals'] ?? []);
        await dataProvider.saveSignals(newSignals);
        
        setState(() {
          _currentSignals = newSignals;
          if (_data != null && res['remaining_tokens'] != null) {
            _data!['profile']['tokens_balance'] = res['remaining_tokens'];
          }
        });
      }
    } finally {
      if (mounted) setState(() => _isScanning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: bgBody,
        extendBody: true,
        bottomNavigationBar: _buildBottomNav(),
        body: _isLoading 
            ? Center(child: CircularProgressIndicator(color: accentColor, strokeWidth: 2)) 
            : Stack(
                children: [
                  _buildBackgroundGlow(),
                  SafeArea(
                    child: RefreshIndicator(
                      onRefresh: _refreshData,
                      color: accentColor,
                      child: CustomScrollView(
                        physics: const BouncingScrollPhysics(),
                        slivers: [
                          _buildAppBar(),
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: _buildBodyContent(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_isScanning) _buildLoadingOverlay(),
                ],
              ),
      ),
    );
  }

  Widget _buildBodyContent() {
    if (_selectedIndex == 1) return _buildSignalsRadar();
    if (_selectedIndex == 2) {
    if (_data == null) return const Center(child: CircularProgressIndicator());
    return ProfileScreen(
      data: _data!, 
      onRefresh: _refreshData // این باعث می‌شود بعد از هر تغییر، دیتای کل داشبورد آپدیت شود
    ); 
  }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        _buildTokenCard(),
        const SizedBox(height: 25),
        _buildQuickActions(),
        const SizedBox(height: 30),
        _buildRiskBanner(),
        const SizedBox(height: 35),
        _buildSectionHeader("موقعیت‌های باز تعهدی", Icons.layers_outlined),
        _buildActivePositions(),
        const SizedBox(height: 120),
      ],
    );
  }

  Widget _buildBottomNav() {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 30),
      height: 70,
      decoration: BoxDecoration(
        color: bgCard.withOpacity(0.8),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(0, Icons.grid_view_rounded, "خانه"),
              _navItem(1, Icons.radar_rounded, "رادار"),
              _navItem(2, Icons.person_2_rounded, "پروفایل"),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label) {
    bool isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? accentColor.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isSelected ? accentColor : textMuted, size: 26),
            if (isSelected)
              Container(
                margin: const EdgeInsets.only(top: 4), // اصلاح شده
                height: 4, width: 4,
                decoration: BoxDecoration(color: accentColor, shape: BoxShape.circle),
              )
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      floating: true,
      centerTitle: true,
      automaticallyImplyLeading: false,
      title: Text("QUANT TERMINAL", style: TextStyle(color: textMain, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1)),
      actions: [
        _buildStatusDot(),
        const SizedBox(width: 20),
      ],
    );
  }

  Widget _buildSignalsRadar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        _buildSectionHeader("رادار فرصت‌های معاملاتی", Icons.radar_outlined),
        if (_currentSignals.isEmpty) 
          _emptyState("دیتای ذخیره شده‌ای یافت نشد. اسکن کنید.")
        else 
          Column(
            children: _currentSignals.map((s) => _FadeInSlide(delay: 50, child: _signalCard(s))).toList().cast<Widget>()
          ),
        const SizedBox(height: 120),
      ],
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
          border: Border.all(color: (isBuy ? buyColor : sellColor).withOpacity(0.1))
        ),
        child: Row(children: [
            _coinCircle(s['symbol'], isBuy ? buyColor : sellColor),
            const SizedBox(width: 15),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(s['symbol'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  Text("قیمت: ${s['price']}", style: TextStyle(color: textMuted, fontSize: 11)),
            ])),
            Icon(Icons.arrow_forward_ios_rounded, color: textMuted, size: 14),
        ]),
      ),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("موجودی توکن پردازشی", style: TextStyle(color: textMuted, fontSize: 12)),
              Icon(Icons.toll_rounded, color: holdColor, size: 20),
            ],
          ),
          const SizedBox(height: 10),
          Text("$tokens", style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900, fontFamily: 'monospace')),
          const SizedBox(height: 15),
          _statusChip(_data?['config']?['is_paper_trading'] == true ? "PAPER MODE" : "LIVE MODE", accentColor),
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
          isActive ? Icons.power_settings_new_rounded : Icons.play_arrow_rounded, 
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
      decoration: BoxDecoration(color: accentColor.withOpacity(0.05), borderRadius: BorderRadius.circular(18), border: Border.all(color: accentColor.withOpacity(0.1))),
      child: Row(children: [
          Icon(Icons.gpp_good_rounded, color: buyColor, size: 28),
          const SizedBox(width: 15),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text("مانیتورینگ ریسک فعال است", style: TextStyle(color: textMain, fontSize: 13, fontWeight: FontWeight.bold)),
                Text(phone != null ? "هشدار به $phone" : "شماره همراه ثبت نشده", style: TextStyle(color: textMuted, fontSize: 11)),
          ]))
      ]),
    );
  }

  Widget _buildActivePositions() {
    List positions = _data?['active_positions'] ?? [];
    if (positions.isEmpty) return _emptyState("موقعیت باز فعالی یافت نشد");
    return Column(
      children: positions.map((p) => _FadeInSlide(delay: 100, child: _positionCard(p))).toList().cast<Widget>()
    );
  }

  Widget _positionCard(Map p) {
    bool isLong = p['side'] == "long";
    double pnl = double.tryParse(p['pnl_percent']?.toString() ?? '0') ?? 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: bgCard, borderRadius: BorderRadius.circular(20)),
      child: Row(children: [
          _coinCircle(p['symbol'], isLong ? buyColor : sellColor),
          const SizedBox(width: 15),
          Expanded(child: Text(p['symbol'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text("${pnl >= 0 ? '+' : ''}$pnl%", style: TextStyle(color: pnl >= 0 ? buyColor : sellColor, fontWeight: FontWeight.w900, fontSize: 16)),
              Text("سود/ضرر", style: TextStyle(color: textMuted, fontSize: 10)),
          ]),
      ]),
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

  Widget _statusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _coinCircle(String sym, Color c) => Container(width: 40, height: 40, decoration: BoxDecoration(color: c.withOpacity(0.1), shape: BoxShape.circle), child: Center(child: Text(sym[0], style: TextStyle(color: c, fontWeight: FontWeight.bold))));
  Widget _emptyState(String m) => Center(child: Padding(padding: const EdgeInsets.all(30), child: Text(m, style: TextStyle(color: textMuted, fontSize: 12))));
  Widget _buildSectionHeader(String t, IconData i) => Padding(padding: const EdgeInsets.only(bottom: 15), child: Row(children: [Icon(i, color: accentColor, size: 20), const SizedBox(width: 10), Text(t, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))]));
  Widget _buildLoadingOverlay() => BackdropFilter(filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5), child: Container(color: Colors.black54, child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [CircularProgressIndicator(color: accentColor), const SizedBox(height: 20), Text("در حال اسکن بازار...", style: TextStyle(color: textMain))]))));

  Widget _buildStatusDot() {
    bool isActive = _data?['config']?['is_active'] ?? false;
    return Row(
      children: [
        Text(isActive ? "LIVE" : "IDLE", style: TextStyle(color: isActive ? buyColor : sellColor, fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(width: 8),
        _PulseDot(color: isActive ? buyColor : sellColor),
      ],
    );
  }

  Widget _buildBackgroundGlow() {
    return Positioned(
      top: -100,
      right: -100,
      child: Container(
        width: 300,
        height: 300,
        decoration: BoxDecoration(shape: BoxShape.circle, color: accentColor.withOpacity(0.05)),
        child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100), child: Container(color: Colors.transparent)),
      ),
    );
  }
}

// --- کلاس‌های کمکی انیمیشن (اضافه شد برای رفع خطا) ---

class _PulseDot extends StatefulWidget {
  final Color color;
  const _PulseDot({required this.color});
  @override
  __PulseDotState createState() => __PulseDotState();
}

class __PulseDotState extends State<_PulseDot> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  @override
  void initState() {
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat(reverse: true);
    super.initState();
  }
  @override
  Widget build(BuildContext context) => FadeTransition(opacity: _c, child: Container(width: 8, height: 8, decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle, boxShadow: [BoxShadow(color: widget.color, blurRadius: 6)])));
  @override
  void dispose() { _c.dispose(); super.dispose(); }
}

class _FadeInSlide extends StatelessWidget {
  final Widget child;
  final int delay;
  const _FadeInSlide({required this.child, required this.delay});
  @override
  Widget build(BuildContext context) => TweenAnimationBuilder(
    tween: Tween<double>(begin: 0, end: 1), 
    duration: const Duration(milliseconds: 500), 
    builder: (context, double v, child) => Opacity(opacity: v, child: Transform.translate(offset: Offset(0, 20 * (1 - v)), child: child)), 
    child: child
  );
}