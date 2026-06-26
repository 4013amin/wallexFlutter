import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
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

class _DashboardScreenState extends State<DashboardScreen> with TickerProviderStateMixin {
  final ApiService _api = ApiService();
  int _selectedIndex = 0;
  bool _isScanning = false;
  Map<String, dynamic>? _data;
  List _currentSignals = [];

  // پالت رنگی Cyberpunk/AI
  final Color bgDark = const Color(0xFF020408);
  final Color cardColor = const Color(0xFF0B121F).withOpacity(0.7);
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
        body: Stack(
          children: [
            _buildAnimatedBackground(),
            SafeArea(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  _buildGlassAppBar(),
                  if (_selectedIndex == 0) ..._buildHomeTab(),
                  if (_selectedIndex == 1) ..._buildRadarTab(),
                  if (_selectedIndex == 2) SliverToBoxAdapter(child: ProfileScreen(data: _data ?? {}, onRefresh: _refreshData)),
                  const SliverToBoxAdapter(child: SizedBox(height: 120)),
                ],
              ),
            ),
            _buildBottomNav(),
            if (_isScanning) _buildScanningOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return Positioned.fill(
      child: Stack(
        children: [
          Positioned(
            top: -100,
            right: -50,
            child: _GlowCircle(color: neonBlue.withOpacity(0.1), size: 300),
          ),
          Positioned(
            bottom: 100,
            left: -50,
            child: _GlowCircle(color: neonPurple.withOpacity(0.1), size: 250),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassAppBar() {
    bool isActive = _data?['config']?['is_active'] ?? false;
    return SliverAppBar(
      backgroundColor: Colors.transparent,
      floating: true,
      pinned: true,
      expandedHeight: 80,
      flexibleSpace: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            color: bgDark.withOpacity(0.5),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("QUANTUM AI", style: TextStyle(color: neonBlue, fontWeight: FontWeight.w900, fontSize: 20, letterSpacing: 1.2)),
                    Row(
                      children: [
                        _PulseDot(color: isActive ? neonGreen : neonRed),
                        const SizedBox(width: 6),
                        Text(isActive ? "هسته هوشمند فعال" : "سیستم در انتظار", style: TextStyle(color: Colors.white70, fontSize: 10)),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  icon: Icon(Icons.refresh_rounded, color: neonBlue),
                  onPressed: _refreshData,
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

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

  List<Widget> _buildRadarTab() {
    return [
      SliverPadding(
        padding: const EdgeInsets.all(20),
        sliver: SliverToBoxAdapter(
          child: _buildSectionHeader("پایش لحظه‌ای بازار (Scanner)", Icons.radar_rounded),
        ),
      ),
      if (_currentSignals.isEmpty)
        SliverToBoxAdapter(child: _buildEmptyState())
      else
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => _buildNeuralSignalCard(_currentSignals[index], index),
            childCount: _currentSignals.length,
          ),
        ),
    ];
  }

  Widget _buildAIStatsCard() {
    int tokens = _data?['profile']?['tokens_balance'] ?? 0;
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: LinearGradient(colors: [neonBlue.withOpacity(0.2), neonPurple.withOpacity(0.1)]),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          const Text("قدرت پردازش فعلی", style: TextStyle(color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 8),
          Text(tokens.toString(), style: const TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.w900, letterSpacing: 2)),
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(10)),
            child: Text("Real-time Analysis Engine", style: TextStyle(color: neonBlue, fontSize: 10, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  Widget _buildNeuralSignalCard(Map s, int index) {
    bool isBuy = s['side'] == "BUY";
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: (isBuy ? neonGreen : neonRed).withOpacity(0.2)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AnalysisScreen(symbol: s['symbol']))),
            leading: _buildCoinIcon(s['symbol'], isBuy ? neonGreen : neonRed),
            title: Text(s['symbol'] ?? "---", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
            subtitle: Text("Price: ${s['price']}", style: const TextStyle(color: Colors.white38, fontSize: 12)),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(isBuy ? "SIGNAL: LONG" : "SIGNAL: SHORT", 
                    style: TextStyle(color: isBuy ? neonGreen : neonRed, fontWeight: FontWeight.w900, fontSize: 12)),
                const SizedBox(height: 5),
                const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.white24),
              ],
            ),
          ),
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
          return _buildPositionCard(p, pnl);
        },
        childCount: positions.length,
      ),
    );
  }

  Widget _buildPositionCard(Map p, double pnl) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          _buildCoinIcon(p['symbol'], pnl >= 0 ? neonGreen : neonRed),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p['symbol'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                Text(p['side'] == 'long' ? "BUY ORDER" : "SELL ORDER", style: const TextStyle(color: Colors.white38, fontSize: 10)),
              ],
            ),
          ),
          Text("${pnl >= 0 ? '+' : ''}$pnl%", 
              style: TextStyle(color: pnl >= 0 ? neonGreen : neonRed, fontWeight: FontWeight.w900, fontSize: 20)),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    bool isActive = _data?['config']?['is_active'] ?? false;
    return Row(
      children: [
        Expanded(child: _buildGlassBtn("اسکن هوشمند", Icons.bolt_rounded, neonBlue, _handleScan)),
        const SizedBox(width: 15),
        Expanded(child: _buildGlassBtn(
          isActive ? "توقف سیستم" : "فعال‌سازی AI", 
          isActive ? Icons.stop_circle_outlined : Icons.play_arrow_rounded, 
          isActive ? neonRed : neonGreen, 
          () async {
            await _api.sendDashboardAction("toggle_bot");
            _refreshData();
          }
        )),
      ],
    );
  }

  Widget _buildGlassBtn(String t, IconData i, Color c, VoidCallback tap) {
    return GestureDetector(
      onTap: tap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: c.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: c.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(i, color: c),
            const SizedBox(width: 10),
            Text(t, style: TextStyle(color: c, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Positioned(
      bottom: 20, left: 20, right: 20,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            height: 80,
            color: Colors.white.withOpacity(0.05),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _navItem(0, Icons.grid_view_rounded, "ترمینال"),
                _navItem(1, Icons.radar_rounded, "رادار"),
                _navItem(2, Icons.person_2_outlined, "پروفایل"),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(int idx, IconData icon, String label) {
    bool isSel = _selectedIndex == idx;
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = idx),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: isSel ? neonBlue : Colors.white38),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: isSel ? neonBlue : Colors.white38, fontSize: 10)),
          if (isSel) Container(margin: const EdgeInsets.only(top: 4), width: 4, height: 4, decoration: BoxDecoration(color: neonBlue, shape: BoxShape.circle))
        ],
      ),
    );
  }

  Widget _buildScanningOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.95), // FIXED black95 Error
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(width: 200, height: 200, child: CircularProgressIndicator(color: neonBlue, strokeWidth: 2)),
            const SizedBox(height: 30),
            const _ShimmerText(text: "در حال پردازش شبکه‌های عصبی..."),
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

  Widget _buildCoinIcon(String sym, Color color) => Container(
    width: 45, height: 45,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: LinearGradient(colors: [color.withOpacity(0.4), color.withOpacity(0)]),
      border: Border.all(color: color.withOpacity(0.3))
    ),
    child: Center(child: Text(sym.isNotEmpty ? sym[0] : "?", style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 20))),
  );

  Widget _buildSectionHeader(String t, IconData i) => Row(children: [Icon(i, color: neonBlue, size: 20), const SizedBox(width: 10), Text(t, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))]);

  Widget _buildEmptyState() => Container(padding: const EdgeInsets.all(50), child: const Column(children: [Icon(Icons.layers_clear_outlined, color: Colors.white10, size: 60), SizedBox(height: 15), Text("داده‌ای یافت نشد", style: TextStyle(color: Colors.white24))]));
}

class _GlowCircle extends StatelessWidget {
  final Color color;
  final double size;
  const _GlowCircle({required this.color, required this.size});
  @override
  Widget build(BuildContext context) => Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: color, blurRadius: 100, spreadRadius: 50)]));
}

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
  Widget build(BuildContext context) => ScaleTransition(scale: Tween(begin: 0.8, end: 1.2).animate(_c), child: Container(width: 8, height: 8, decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle, boxShadow: [BoxShadow(color: widget.color, blurRadius: 5)])));
  @override
  void dispose() { _c.dispose(); super.dispose(); }
}

class _ShimmerText extends StatelessWidget {
  final String text;
  const _ShimmerText({required this.text});
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.white,
      highlightColor: const Color(0xFF00D1FF),
      child: Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
    );
  }
}