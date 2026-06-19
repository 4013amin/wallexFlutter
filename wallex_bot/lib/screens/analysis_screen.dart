import 'package:flutter/material.dart';
import 'dart:ui';
import '../services/api_service.dart';

class AnalysisScreen extends StatefulWidget {
  final String symbol;
  AnalysisScreen({required this.symbol});

  @override
  _AnalysisScreenState createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> with TickerProviderStateMixin {
  final ApiService _api = ApiService();
  
  // پالت رنگی
  final Color bgBody = const Color(0xFF0B0F19);
  final Color bgPanel = const Color(0xFF111827);
  final Color accentColor = const Color(0xFF3B82F6);
  final Color buyColor = const Color(0xFF10B981);
  final Color sellColor = const Color(0xFFF43F5E);
  final Color holdColor = const Color(0xFFF59E0B);
  final Color textMuted = const Color(0xFF9CA3AF);
  final Color borderColor = Colors.white.withOpacity(0.08);

  // کنترلرها برای فیلدها
  late TextEditingController _slController;
  late TextEditingController _tpController;
  late TextEditingController _entryController;
  
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

  @override
  void dispose() {
    _slController.dispose();
    _tpController.dispose();
    _entryController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    // اگر بار اول است لودینگ کامل نشان بده، در غیر این صورت فقط رفرش شود
    if (_analysisData == null) {
      setState(() => _isLoading = true);
    }
    
    try {
      final response = await _api.getCoinAnalysis(widget.symbol);
      final data = response['analysis'];
      
      setState(() {
        _analysisData = data;
        _entryController.text = data?['current_price']?.toString() ?? '0';
        _slController.text = data?['sl_price']?.toString() ?? '';
        _tpController.text = data?['tp_price']?.toString() ?? '';
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("خطا در ارتباط با سرور", style: TextStyle(fontFamily: 'Vazir'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgBody,
      appBar: AppBar(
        backgroundColor: bgPanel,
        elevation: 0,
        title: Text("آنالیز هوشمند ${widget.symbol}", 
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading 
        ? Center(child: CircularProgressIndicator(color: accentColor))
        : RefreshIndicator(
            color: accentColor,
            backgroundColor: bgPanel,
            onRefresh: _loadData,
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(), 
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _fadeInWrapper(_buildHeaderInfo(), 0),
                    const SizedBox(height: 20),
                    _fadeInWrapper(_buildSafetyScoreCard(_analysisData!), 1),
                    const SizedBox(height: 20),
                    _fadeInWrapper(_buildTrendStructureCard(_analysisData!), 2),
                    const SizedBox(height: 20),
                    _fadeInWrapper(_buildTechnicalIndicatorsCard(_analysisData!), 3),
                    const SizedBox(height: 20),
                    _fadeInWrapper(_buildATRProtectionCard(_analysisData!), 4),
                    const SizedBox(height: 20),
                    _fadeInWrapper(_buildTradePanel(_analysisData!), 5),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
    );
  }

  Widget _fadeInWrapper(Widget child, int index) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 400 + (index * 100)),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 15 * (1 - value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  Widget _buildHeaderInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text("پایش ارزیابی ریسک", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(width: 10),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: accentColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: Text(widget.symbol, style: TextStyle(color: accentColor, fontWeight: FontWeight.bold, fontFamily: 'JetBrainsMono')),
            )
          ],
        ),
        const SizedBox(height: 5),
        Text("گزارش جامع آماری و تحلیل ساختار بازار", style: TextStyle(color: textMuted, fontSize: 12)),
      ],
    );
  }

  Widget _buildSafetyScoreCard(Map analysis) {
    int score = int.tryParse(analysis['safety_score']?.toString() ?? '0') ?? 0;
    Color scoreColor = score >= 70 ? buyColor : (score >= 45 ? holdColor : sellColor);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bgPanel, 
        borderRadius: BorderRadius.circular(18), 
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _buildAnimatedScoreCircle(score, scoreColor),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("امتیاز امنیت ورود", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 5),
                    Text("بر اساس تلاقی پارامترهای تکنیکال و حجم", style: TextStyle(color: textMuted, fontSize: 11)),
                  ],
                ),
              )
            ],
          ),
          if (analysis['is_squeezed'] == true) _buildAlertBox("فشردگی نوسان (Squeeze) شناسایی شد.", holdColor),
          const SizedBox(height: 15),
          _buildScoreAdvice(score),
        ],
      ),
    );
  }

  Widget _buildAnimatedScoreCircle(int score, Color color) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 1200),
      curve: Curves.easeOutBack,
      tween: Tween(begin: 0, end: score / 100),
      builder: (context, value, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 75, height: 75,
              child: CircularProgressIndicator(
                value: value,
                strokeWidth: 8,
                backgroundColor: Colors.white.withOpacity(0.05),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            Text("${(value * 100).toInt()}%", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'JetBrainsMono')),
          ],
        );
      },
    );
  }

  Widget _buildTradePanel(Map analysis) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bgPanel, 
        borderRadius: BorderRadius.circular(22), 
        border: Border.all(color: accentColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.bolt, color: accentColor, size: 22),
            const SizedBox(width: 10),
            Text("پنل ثبت پوزیشن هوشمند", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 20),
          _buildRealInput("قیمت فعلی بازار", _entryController, Colors.white, enabled: false),
          const SizedBox(height: 15),
          _buildRealInput("حد ضرر پیشنهادی (SL)", _slController, sellColor),
          const SizedBox(height: 15),
          _buildRealInput("حد سود پیشنهادی (TP)", _tpController, buyColor),
          const SizedBox(height: 25),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("سفارش با قیمت ${_entryController.text} ثبت شد.")));
              },
              child: Text("تایید و ارسال به هسته", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildRealInput(String label, TextEditingController controller, Color color, {bool enabled = true}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6, right: 5),
          child: Text(label, style: TextStyle(color: textMuted, fontSize: 11)),
        ),
        TextField(
          controller: controller,
          enabled: enabled,
          style: TextStyle(color: color, fontWeight: FontWeight.bold, fontFamily: 'JetBrainsMono', fontSize: 14),
          decoration: InputDecoration(
            filled: true,
            fillColor: bgBody,
            contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 12),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: borderColor)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: accentColor)),
            disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: borderColor)),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionCard({required String title, required IconData icon, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: bgPanel, borderRadius: BorderRadius.circular(18), border: Border.all(color: borderColor)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: accentColor, size: 20),
            const SizedBox(width: 10),
            Text(title, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 10),
          ...children
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: textMuted, fontSize: 13)),
          Text(value, style: TextStyle(color: valueColor ?? Colors.white, fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'JetBrainsMono')),
        ],
      ),
    );
  }

  Widget _buildTrendStructureCard(Map analysis) => _buildSectionCard(
    title: "ساختار چند تایم‌فریمه", icon: Icons.account_tree_outlined,
    children: [
      _buildInfoRow("روند کوتاه مدت", analysis['trend_15m'] ?? '...', valueColor: buyColor),
      _buildInfoRow("روند میان مدت", analysis['trend_1h'] ?? '...'),
      _buildInfoRow("قدرت خریداران", "${analysis['imbalance']}%", valueColor: buyColor),
    ]
  );

  Widget _buildTechnicalIndicatorsCard(Map analysis) {
    double rsi = double.tryParse(analysis['rsi']?.toString() ?? '50') ?? 50;
    return _buildSectionCard(
      title: "اندیکاتورهای قدرت", 
      icon: Icons.tune, // اصلاح شده: tune با حروف کوچک
      children: [
        _buildInfoRow("RSI (14)", rsi.toStringAsFixed(1), valueColor: rsi > 70 ? sellColor : (rsi < 30 ? buyColor : Colors.white)),
        _buildInfoRow("شاخص ADX", analysis['adx']?.toString() ?? '0'),
        _buildInfoRow("حمایت معتبر", "${analysis['support'] ?? 0} ت", valueColor: buyColor),
      ]
    );
  }

  Widget _buildATRProtectionCard(Map analysis) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: bgPanel, borderRadius: BorderRadius.circular(18), border: Border.all(color: holdColor.withOpacity(0.3))),
      child: Column(
        children: [
          Row(children: [
            Icon(Icons.security, color: holdColor, size: 20),
            const SizedBox(width: 10),
            Text("مدیریت ریسک ATR", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 10),
          _buildInfoRow("کلاس نوسان", analysis['risk_class'] ?? '...'),
          _buildInfoRow("اهرم پیشنهادی", analysis['leverage_warning'] ?? '...', valueColor: holdColor),
        ],
      ),
    );
  }

  Widget _buildAlertBox(String text, Color color) {
    return Container(
      margin: const EdgeInsets.only(top: 15),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: color.withOpacity(0.05), borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withOpacity(0.2))),
      child: Row(children: [
        Icon(Icons.info_outline, color: color, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold))),
      ]),
    );
  }

  Widget _buildScoreAdvice(int score) {
    String msg = score < 45 ? "ریسک معاملاتی بالا است." : (score < 70 ? "با رعایت مدیریت سرمایه وارد شوید." : "تاییدیه ورود صادر شده است.");
    Color col = score < 45 ? sellColor : (score < 70 ? holdColor : buyColor);
    return _buildAlertBox(msg, col);
  }
}