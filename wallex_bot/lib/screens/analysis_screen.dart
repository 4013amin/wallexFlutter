import 'package:flutter/material.dart';
import 'dart:ui';
import '../services/api_service.dart';

class AnalysisScreen extends StatefulWidget {
  final String symbol;
  const AnalysisScreen({super.key, required this.symbol});

  @override
  _AnalysisScreenState createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  final ApiService _api = ApiService();
  
  // تم رنگی هماهنگ با داشبورد
  final Color bgBody = const Color(0xFF080D1A);
  final Color bgCard = const Color(0xFF111827);
  final Color accentColor = const Color(0xFF3B82F6);
  final Color buyColor = const Color(0xFF10B981);
  final Color sellColor = const Color(0xFFF43F5E);
  final Color holdColor = const Color(0xFFF59E0B);
  final Color textMuted = const Color(0xFF9CA3AF);

  late TextEditingController _slController, _tpController, _entryController;
  Map<String, dynamic>? _analysisData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _slController = TextEditingController();
    _tpController = TextEditingController();
    _entryController = TextEditingController();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final response = await _api.getCoinAnalysis(widget.symbol);
      final data = response['analysis'];
      if (mounted) {
        setState(() {
          _analysisData = data;
          _entryController.text = data?['current_price']?.toString() ?? '0';
          _slController.text = data?['sl_price']?.toString() ?? '';
          _tpController.text = data?['tp_price']?.toString() ?? '';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: bgBody,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          title: Text("آنالیز ${widget.symbol}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 18), onPressed: () => Navigator.pop(context)),
        ),
        body: _isLoading 
          ? Center(child: CircularProgressIndicator(color: accentColor, strokeWidth: 2))
          : Stack(
              children: [
                _buildBackgroundGlow(),
                SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildSafetyScoreCard(_analysisData!),
                      const SizedBox(height: 20),
                      _buildSectionCard("ساختار روند", Icons.analytics_outlined, [
                        _buildInfoRow("تایم‌فریم کوتاه", _analysisData!['trend_15m'] ?? '...', valueColor: buyColor),
                        _buildInfoRow("تایم‌فریم بلند", _analysisData!['trend_1h'] ?? '...'),
                        _buildInfoRow("قدرت خریداران", "${_analysisData!['imbalance']}%", valueColor: buyColor),
                      ]),
                      const SizedBox(height: 20),
                      _buildTradePanel(),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ],
            ),
      ),
    );
  }

  Widget _buildBackgroundGlow() {
    return Positioned(
      top: 50, left: -50,
      child: Container(width: 200, height: 200, decoration: BoxDecoration(shape: BoxShape.circle, color: accentColor.withOpacity(0.05)),
        child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80), child: Container(color: Colors.transparent))),
    );
  }

  Widget _buildSafetyScoreCard(Map analysis) {
    int score = int.tryParse(analysis['safety_score']?.toString() ?? '0') ?? 0;
    Color scoreColor = score >= 70 ? buyColor : (score >= 45 ? holdColor : sellColor);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: bgCard, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white.withOpacity(0.05))),
      child: Row(
        children: [
          _buildScoreCircle(score, scoreColor),
          const SizedBox(width: 20),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("ضریب اطمینان ورود", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                Text(score > 60 ? "فرصت معاملاتی مناسب" : "ریسک ورود بالا", style: TextStyle(color: textMuted, fontSize: 11)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildScoreCircle(int score, Color color) {
    return Stack(alignment: Alignment.center, children: [
      SizedBox(width: 65, height: 65, child: CircularProgressIndicator(value: score/100, strokeWidth: 6, backgroundColor: Colors.white10, valueColor: AlwaysStoppedAnimation(color))),
      Text("$score%", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
    ]);
  }

  Widget _buildTradePanel() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: accentColor.withOpacity(0.05), borderRadius: BorderRadius.circular(28), border: Border.all(color: accentColor.withOpacity(0.1))),
      child: Column(children: [
        _buildInputField("قیمت فعلی", _entryController, enabled: false),
        const SizedBox(height: 15),
        Row(children: [
          Expanded(child: _buildInputField("حد ضرر (SL)", _slController, color: sellColor)),
          const SizedBox(width: 15),
          Expanded(child: _buildInputField("حد سود (TP)", _tpController, color: buyColor)),
        ]),
        const SizedBox(height: 25),
        SizedBox(width: double.infinity, height: 55, child: ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: accentColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
          onPressed: () {}, 
          child: const Text("تایید پوزیشن هوشمند", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        )),
      ]),
    );
  }

  Widget _buildInputField(String label, TextEditingController controller, {bool enabled = true, Color? color}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(color: textMuted, fontSize: 10)),
      const SizedBox(height: 6),
      TextField(controller: controller, enabled: enabled, style: TextStyle(color: color ?? Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
        decoration: InputDecoration(filled: true, fillColor: bgBody, contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white10)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: accentColor)),
        ),
      ),
    ]);
  }

  Widget _buildSectionCard(String title, IconData icon, List<Widget> children) {
    return Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: bgCard, borderRadius: BorderRadius.circular(24)),
      child: Column(children: [
        Row(children: [Icon(icon, color: accentColor, size: 20), const SizedBox(width: 10), Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))]),
        const Divider(color: Colors.white10, height: 25),
        ...children
      ]),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(color: textMuted, fontSize: 12)),
        Text(value, style: TextStyle(color: valueColor ?? Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
      ]),
    );
  }
}