import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import '../services/api_service.dart';
import '../providers/data_provider.dart';
import 'analysis_screen.dart';
import 'profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ApiService _api = ApiService();
  int _selectedIndex = 0;
  bool _isScanning = false;
  Map<String, dynamic>? _data;
  List _currentSignals = [];

  // پالت رنگی بهینه شده (بدون نیاز به Blur سنگین)
  final Color bgDark = const Color(0xFF020408);
  final Color cardBase = const Color(0xFF0B121F);
  final Color neonBlue = const Color(0xFF00D1FF);
  final Color neonPurple = const Color(0xFF7000FF);
  final Color neonGreen = const Color(0xFF00FFA3);
  final Color neonRed = const Color(0xFFFF005C);

  @override
  void initState() {
    super.initState();
    _loadPersistedData();
  }

  void _loadPersistedData() {
    final dataProvider = Provider.of<DataProvider>(context, listen: false);
    setState(() {
      _data = dataProvider.dashboardData;
      _currentSignals = dataProvider.signals;
      if (_data == null) _refreshData();
    });
  }

  Future<void> _refreshData() async {
    try {
      var res = await _api.getDashboardData();
      if (mounted) {
        final dataProvider = Provider.of<DataProvider>(context, listen: false);
        await dataProvider.saveDashboardData(res);
        setState(() => _data = res);
      }
    } catch (e) {
      debugPrint("Refresh Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: bgDark,
        extendBody: true, // اجازه نمایش محتوا پشت نویگیشن بار
        bottomNavigationBar: _buildBottomNav(),
        body: Stack(
          children: [
            _buildStaticBackgroundGlow(), // پس‌زمینه ثابت برای سرعت بیشتر
            SafeArea(
              bottom: false,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  _buildGlassAppBar(),
                  if (_selectedIndex == 0) ..._buildHomeTab(),
                  if (_selectedIndex == 1) ..._buildRadarTab(),
                  if (_selectedIndex == 2) 
                    SliverToBoxAdapter(
                      child: ProfileScreen(data: _data ?? {}, onRefresh: _refreshData)
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 120)),
                ],
              ),
            ),
            if (_isScanning) _buildScanningOverlay(),
          ],
        ),
      ),
    );
  }

  // --- پس‌زمینه ثابت (بهینه برای CPU) ---
  Widget _buildStaticBackgroundGlow() {
    return Positioned.fill(
      child: Opacity(
        opacity: 0.4,
        child: Stack(
          children: [
            Positioned(top: -100, right: -50, child: _GlowCircle(color: neonBlue.withOpacity(0.2), size: 300)),
            Positioned(bottom: 100, left: -50, child: _GlowCircle(color: neonPurple.withOpacity(0.2), size: 250)),
          ],
        ),
      ),
    );
  }

  // --- آپ‌بار (تنها جایی که Blur مجاز است) ---
  Widget _buildGlassAppBar() {
    bool isActive = _data?['config']?['is_active'] ?? false;
    return SliverAppBar(
      backgroundColor: bgDark.withOpacity(0.8),
      floating: true,
      pinned: true,
      elevation: 0,
      flexibleSpace: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            color: Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("QUANTUM AI", style: TextStyle(color: neonBlue, fontWeight: FontWeight.w900, fontSize: 20, letterSpacing: 1.2)),
                      Text(isActive ? "هسته هوشمند فعال" : "سیستم متوقف", style: const TextStyle(color: Colors.white54, fontSize: 10)),
                    ],
                  ),
                  IconButton(icon: Icon(Icons.refresh_rounded, color: neonBlue), onPressed: _refreshData)
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- تب میز کار ---
  List<Widget> _buildHomeTab() {
    return [
      SliverPadding(
        padding: const EdgeInsets.all(20),
        sliver: SliverToBoxAdapter(
          child: Column(
            children: [
              _buildAIStatsCard(),
              const SizedBox(height: 25),
              _buildQuickActions(),
              const SizedBox(height: 30),
              _buildSectionHeader("معاملات زنده استراتژی", Icons.psychology_outlined),
            ],
          ),
        ),
      ),
      _buildActivePositionsSliver(),
    ];
  }

  // --- تب رادار (بدون محدودیت و بسیار سریع) ---
  List<Widget> _buildRadarTab() {
    return [
      SliverPadding(
        padding: const EdgeInsets.all(20),
        sliver: SliverToBoxAdapter(child: _buildSectionHeader("لیست پایش تمام کوین‌ها", Icons.radar_rounded)),
      ),
      if (_currentSignals.isEmpty)
        SliverToBoxAdapter(child: _buildEmptyState())
      else
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => _buildNeuralSignalCard(_currentSignals[index]),
            childCount: _currentSignals.length,
          ),
        ),
    ];
  }

  // --- کارت سیگنال بهینه شده (بدون Blur برای اسکرول روان) ---
  Widget _buildNeuralSignalCard(Map s) {
    bool isBuy = s['side'] == "BUY";
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      decoration: BoxDecoration(
        color: cardBase.withOpacity(0.9), // رنگ ثابت به جای Blur
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: (isBuy ? neonGreen : neonRed).withOpacity(0.15)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10)],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AnalysisScreen(symbol: s['symbol']))),
        leading: _buildCoinCircle(s['symbol'], isBuy ? neonGreen : neonRed),
        title: Text(s['symbol'] ?? "---", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Text("قیمت: ${s['price']}", style: const TextStyle(color: Colors.white38, fontSize: 12)),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(color: (isBuy ? neonGreen : neonRed).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
          child: Text(isBuy ? "BUY" : "SELL", style: TextStyle(color: isBuy ? neonGreen : neonRed, fontWeight: FontWeight.bold, fontSize: 12)),
        ),
      ),
    );
  }

  Widget _buildActivePositionsSliver() {
    List positions = _data?['active_positions'] ?? [];
    if (positions.isEmpty) return SliverToBoxAdapter(child: _buildEmptyState());
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          var p = positions[index];
          double pnl = double.tryParse(p['pnl_percent']?.toString() ?? '0') ?? 0;
          return _buildPositionItem(p, pnl);
        },
        childCount: positions.length,
      ),
    );
  }

  Widget _buildPositionItem(Map p, double pnl) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.04), borderRadius: BorderRadius.circular(15)),
      child: Row(
        children: [
          _buildCoinCircle(p['symbol'], pnl >= 0 ? neonGreen : neonRed),
          const SizedBox(width: 15),
          Expanded(child: Text(p['symbol'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
          Text("${pnl >= 0 ? '+' : ''}$pnl%", style: TextStyle(color: pnl >= 0 ? neonGreen : neonRed, fontWeight: FontWeight.w900, fontSize: 18)),
        ],
      ),
    );
  }

  Widget _buildAIStatsCard() {
    int tokens = _data?['profile']?['tokens_balance'] ?? 0;
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        gradient: LinearGradient(colors: [neonBlue.withOpacity(0.15), neonPurple.withOpacity(0.1)]),
        border: Border.all(color: neonBlue.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          const Text("قدرت پردازش در دسترس", style: TextStyle(color: Colors.white54, fontSize: 11)),
          Text(tokens.toString(), style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w900)),
          Text("QUANTUM UNITS", style: TextStyle(color: neonBlue, fontSize: 9, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    bool isActive = _data?['config']?['is_active'] ?? false;
    return Row(
      children: [
        Expanded(child: _buildActionBtn("اسکن هوشمند", Icons.bolt_rounded, neonBlue, _handleScan)),
        const SizedBox(width: 15),
        Expanded(child: _buildActionBtn(isActive ? "توقف سیستم" : "فعال‌سازی AI", isActive ? Icons.stop_rounded : Icons.play_arrow_rounded, isActive ? neonRed : neonGreen, () async {
          await _api.sendDashboardAction("toggle_bot");
          _refreshData();
        })),
      ],
    );
  }

  Widget _buildActionBtn(String t, IconData i, Color c, VoidCallback tap) {
    return InkWell(
      onTap: tap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(color: c.withOpacity(0.08), borderRadius: BorderRadius.circular(18), border: Border.all(color: c.withOpacity(0.2))),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(i, color: c, size: 20), const SizedBox(width: 8), Text(t, style: TextStyle(color: c, fontWeight: FontWeight.bold, fontSize: 13))]),
      ),
    );
  }

  // --- نویگیشن بار ثابت و پاسخگو ---
  Widget _buildBottomNav() {
    return Container(
      height: 85,
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 25),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.06), borderRadius: BorderRadius.circular(25), border: Border.all(color: Colors.white.withOpacity(0.1))),
            child: Row(
              children: [
                _navItem(0, Icons.grid_view_rounded, "میزکار"),
                _navItem(1, Icons.radar_rounded, "رادار"),
                _navItem(2, Icons.person_rounded, "پروفایل"),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(int idx, IconData icon, String label) {
    bool isSel = _selectedIndex == idx;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedIndex = idx),
        highlightColor: Colors.transparent,
        splashColor: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSel ? neonBlue : Colors.white30, size: 26),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: isSel ? neonBlue : Colors.white30, fontSize: 10, fontWeight: isSel ? FontWeight.bold : FontWeight.normal)),
          ],
        ),
      ),
    );
  }

  // --- لودینگ اسکن ---
  Widget _buildScanningOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.9),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: neonBlue, strokeWidth: 2),
            const SizedBox(height: 20),
            const Text("در حال تحلیل شبکه‌های عصبی بازار...", style: TextStyle(color: Colors.white70, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Future<void> _handleScan() async {
    setState(() => _isScanning = true);
    try {
      var res = await _api.sendDashboardAction("scan_signals");
      if (mounted) {
        final dataProvider = Provider.of<DataProvider>(context, listen: false);
        List signals = List.from(res['signals'] ?? []);
        await dataProvider.saveSignals(signals);
        setState(() {
          _currentSignals = signals;
          _isScanning = false;
          _selectedIndex = 1;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isScanning = false);
    }
  }

  Widget _buildCoinCircle(String sym, Color c) => Container(
    width: 40, height: 40,
    decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: c.withOpacity(0.3)), gradient: LinearGradient(colors: [c.withOpacity(0.2), Colors.transparent])),
    child: Center(child: Text(sym.isNotEmpty ? sym[0] : "?", style: TextStyle(color: c, fontWeight: FontWeight.bold))),
  );

  Widget _buildSectionHeader(String t, IconData i) => Row(children: [Icon(i, color: neonBlue, size: 18), const SizedBox(width: 8), Text(t, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold))]);

  Widget _buildEmptyState() => const Center(child: Padding(padding: EdgeInsets.all(40), child: Text("داده‌ای یافت نشد", style: TextStyle(color: Colors.white24))));
}

class _GlowCircle extends StatelessWidget {
  final Color color;
  final double size;
  const _GlowCircle({required this.color, required this.size});
  @override
  Widget build(BuildContext context) => Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: color, blurRadius: 80, spreadRadius: 40)]));
}