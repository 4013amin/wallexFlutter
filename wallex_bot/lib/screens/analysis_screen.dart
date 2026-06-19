import 'package:flutter/material.dart';
import 'dart:ui';
import '../services/api_service.dart';

class AnalysisScreen extends StatefulWidget {
  final String symbol;
  AnalysisScreen({required this.symbol});

  @override
  _AnalysisScreenState createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  final ApiService _api = ApiService();
  
  // پالت رنگی هماهنگ با فایل HTML و داشبورد
  final Color bgBody = const Color(0xFF0B0F19);
  final Color bgPanel = const Color(0xFF111827);
  final Color accentColor = const Color(0xFF3B82F6);
  final Color buyColor = const Color(0xFF10B981);
  final Color sellColor = const Color(0xFFF43F5E);
  final Color holdColor = const Color(0xFFF59E0B);
  final Color textMuted = const Color(0xFF9CA3AF);
  final Color borderColor = Colors.white.withOpacity(0.08);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgBody,
      appBar: AppBar(
        backgroundColor: bgPanel,
        elevation: 0,
        title: Text("آنالیز ایمنی ${widget.symbol}", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder(
        future: _api.getCoinAnalysis(widget.symbol),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: accentColor));
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return Center(child: Text("خطا در بارگذاری داده‌ها", style: TextStyle(color: textMuted)));
          }

          final data = snapshot.data as Map<String, dynamic>;
          final analysis = data['analysis'] ?? {};

          return Directionality(
            textDirection: TextDirection.rtl,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderInfo(),
                  const SizedBox(height: 20),
                  _buildSafetyScoreCard(analysis),
                  const SizedBox(height: 20),
                  _buildTrendStructureCard(analysis),
                  const SizedBox(height: 20),
                  _buildTechnicalIndicatorsCard(analysis),
                  const SizedBox(height: 20),
                  _buildATRProtectionCard(analysis),
                  const SizedBox(height: 20),
                  _buildTradePanel(analysis),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          );
        },
      ),
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
        Text("گزارش جامع آماری برای صیانت از سرمایه", style: TextStyle(color: textMuted, fontSize: 12)),
      ],
    );
  }

  Widget _buildSafetyScoreCard(Map analysis) {
    int score = int.tryParse(analysis['safety_score']?.toString() ?? '0') ?? 0;
    Color scoreColor = score >= 70 ? buyColor : (score >= 45 ? holdColor : sellColor);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: bgPanel, borderRadius: BorderRadius.circular(18), border: Border.all(color: borderColor)),
      child: Column(
        children: [
          Row(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 80, height: 80,
                    child: CircularProgressIndicator(
                      value: score / 100,
                      strokeWidth: 8,
                      backgroundColor: Colors.white.withOpacity(0.05),
                      valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                    ),
                  ),
                  Text("$score%", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'JetBrainsMono')),
                ],
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("امتیاز امنیت ورود", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 5),
                    Text("هرچه این امتیاز بالاتر باشد، پتانسیل ثبات حرکت قیمت مطلوب‌تر است.", style: TextStyle(color: textMuted, fontSize: 11)),
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

  Widget _buildTrendStructureCard(Map analysis) {
    return _buildSectionCard(
      title: "پایش ساختار چندتایم‌فریمه",
      icon: Icons.history_toggle_off,
      children: [
        _buildInfoRow("روند کوتاه مدت (15m)", analysis['trend_15m'] ?? 'نامشخص'),
        _buildInfoRow("روند اصلی (1h)", analysis['trend_1h'] ?? 'نامشخص'),
        _buildInfoRow("روند کلان (4h)", analysis['trend_4h'] ?? 'نامشخص'),
        _buildInfoRow("روند مرجع (BTC)", analysis['btc_trend'] ?? 'نامشخص'),
        _buildInfoRow("جریان انباشت (Imbalance)", "${analysis['imbalance']}% خرید", valueColor: buyColor),
      ],
    );
  }

  Widget _buildTechnicalIndicatorsCard(Map analysis) {
    double rsi = double.tryParse(analysis['rsi']?.toString() ?? '50') ?? 50;
    return _buildSectionCard(
      title: "وضعیت ابزارها و قدرت شتاب",
      icon: Icons.analytics_outlined,
      children: [
        _buildInfoRow("شاخص ADX", analysis['adx']?.toString() ?? '0', valueColor: Colors.white),
        _buildInfoRow("شاخص RSI", rsi.toStringAsFixed(1), valueColor: rsi > 70 ? sellColor : (rsi < 30 ? buyColor : Colors.white)),
        _buildInfoRow("جریان پول (CMF)", analysis['cmf']?.toString() ?? '0'),
        _buildInfoRow("حمایت پیوت (S1)", "${analysis['support'] ?? 0} ت", valueColor: buyColor),
        _buildInfoRow("مقاومت پیوت (R1)", "${analysis['resistance'] ?? 0} ت", valueColor: sellColor),
      ],
    );
  }

  Widget _buildATRProtectionCard(Map analysis) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bgPanel,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accentColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.shield_outlined, color: buyColor, size: 20),
            const SizedBox(width: 10),
            Text("میز محافظت سرمایه (ATR Engine)", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 15),
          _buildInfoRow("کلاس نوسان قیمت", analysis['risk_class'] ?? 'معمولی'),
          _buildInfoRow("تخصیص حجم پیشنهادی", analysis['allocation_suggestion'] ?? '10%', valueColor: buyColor),
          const Divider(color: Colors.white10, height: 30),
          Text("توصیه اهرم معاملاتی:", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          Text(analysis['leverage_warning'] ?? 'مدیریت سرمایه را رعایت کنید.', style: TextStyle(color: textMuted, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildTradePanel(Map analysis) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: bgPanel, borderRadius: BorderRadius.circular(18), border: Border.all(color: borderColor)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.edit_note, color: accentColor, size: 22),
            const SizedBox(width: 10),
            Text("ثبت موقعیت هوشمند", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 20),
          _buildFieldLabel("قیمت لحظه‌ای بازار"),
          _buildFakeInput("${analysis['current_price'] ?? 0} تومان"),
          const SizedBox(height: 15),
          _buildFieldLabel("حد ضرر پیشنهادی (SL)"),
          _buildFakeInput("${analysis['sl_price'] ?? 0}", color: sellColor),
          const SizedBox(height: 15),
          _buildFieldLabel("حد سود پیشنهادی (TP)"),
          _buildFakeInput("${analysis['tp_price'] ?? 0}", color: buyColor),
          const SizedBox(height: 25),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 5,
              ),
              onPressed: () {}, // اکشن ثبت معامله
              child: Text("ارسال دستور معاملاتی به هسته", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          )
        ],
      ),
    );
  }

  // ویجت‌های کمکی کوچک
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

  Widget _buildAlertBox(String text, Color color) {
    return Container(
      margin: const EdgeInsets.only(top: 15),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: color.withOpacity(0.05), borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withOpacity(0.2), style: BorderStyle.solid)),
      child: Row(children: [
        Icon(Icons.info_outline, color: color, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold))),
      ]),
    );
  }

  Widget _buildScoreAdvice(int score) {
    String msg = score < 45 ? "ریسک معاملاتی سنگین: ورود پیشنهاد نمی‌شود." : (score < 70 ? "احتیاط معاملاتی: با مدیریت سرمایه حرکت کنید." : "تایید ساختار معاملاتی: پتانسیل موفقیت بالا.");
    Color col = score < 45 ? sellColor : (score < 70 ? holdColor : buyColor);
    return _buildAlertBox(msg, col);
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, right: 4),
      child: Text(label, style: TextStyle(color: textMuted, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildFakeInput(String text, {Color? color}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: bgBody, borderRadius: BorderRadius.circular(12), border: Border.all(color: borderColor)),
      child: Text(text, style: TextStyle(color: color ?? Colors.white, fontWeight: FontWeight.bold, fontFamily: 'JetBrainsMono')),
    );
  }
}