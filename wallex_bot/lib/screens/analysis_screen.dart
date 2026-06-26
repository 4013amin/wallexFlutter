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
  
  // پالت رنگی حرفه‌ای (مطابق HTML)
  final Color bgBody = const Color(0xFF0B0F19);
  final Color bgPanel = const Color(0xFF111827);
  final Color bgCard = const Color(0xFF1F2937);
  final Color accentColor = const Color(0xFF3B82F6);
  final Color buyColor = const Color(0xFF10B981);
  final Color sellColor = const Color(0xFFF43F5E);
  final Color holdColor = const Color(0xFFF59E0B);
  final Color textMuted = const Color(0xFF9CA3AF);
  final Color borderColor = Colors.white.withOpacity(0.08);

  late TextEditingController _slController, _tpController, _entryController, _collateralController, _totalCapitalController;
  String _selectedSide = "BUY";
  Map<String, dynamic>? _analysisData;
  bool _isLoading = true;
  double _allowedInvestment = 0;

  @override
  void initState() {
    super.initState();
    _slController = TextEditingController();
    _tpController = TextEditingController();
    _entryController = TextEditingController();
    _collateralController = TextEditingController();
    _totalCapitalController = TextEditingController();
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
          _selectedSide = (data?['direction']?.toString().contains("SELL") ?? false) ? "SELL" : "BUY";
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _calculateAllowedRisk(String value) {
    double total = double.tryParse(value.replaceAll(',', '')) ?? 0;
    double percent = double.tryParse(_analysisData?['allocation_num']?.toString() ?? '0') ?? 0;
    setState(() {
      _allowedInvestment = (total * percent) / 100;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: bgBody,
        appBar: _buildAppBar(),
        body: _isLoading 
          ? Center(child: CircularProgressIndicator(color: accentColor))
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Column(
                children: [
                  _buildSafetyScoreHeader(),
                  const SizedBox(height: 20),
                  _buildAlertBox(),
                  const SizedBox(height: 25),
                  _buildRiskRewardSection(), // بخش ریسک به ریوارد جدید
                  const SizedBox(height: 25),
                  _buildDcaSection(), // بخش DCA جدید
                  const SizedBox(height: 25),
                  _buildSectionCard("پایش ساختار و جریان بازار", Icons.grid_view_rounded, [
                    _buildInfoRow("موقعیت کوتاه مدت (15m)", _analysisData!['trend_15m']),
                    _buildInfoRow("روند اصلی (1h)", _analysisData!['trend_1h']),
                    _buildInfoRow("روند کلان (4h)", _analysisData!['trend_4h']),
                    _buildInfoRow("جریان نقدینگی (BTC)", _analysisData!['btc_trend']),
                    _buildInfoRow("تراکم سفارشات", "خرید ${_analysisData!['imbalance']}% | فروش ${_analysisData!['ask_imbalance']}%", valueColor: accentColor),
                  ]),
                  const SizedBox(height: 25),
                  _buildSmartCalculator(), // ماشین حساب هوشمند جدید
                  const SizedBox(height: 25),
                  _buildSectionCard("اندیکاتورهای شتاب حرکتی", Icons.analytics_outlined, [
                    _buildIndicatorRow("شاخص قدرت (ADX)", _analysisData!['adx'].toString(), 
                      _analysisData!['adx'] > 25 ? "روند قوی" : "روند ضعیف", _analysisData!['adx'] > 25 ? buyColor : sellColor),
                    _buildIndicatorRow("شاخص RSI", _analysisData!['rsi'].toString(), 
                      _analysisData!['rsi'] > 70 ? "اشباع خرید" : (_analysisData!['rsi'] < 30 ? "اشباع فروش" : "خنثی"), 
                      _analysisData!['rsi'] > 70 ? sellColor : (_analysisData!['rsi'] < 30 ? buyColor : textMuted)),
                    _buildIndicatorRow("جریان پول هوشمند (CMF)", _analysisData!['cmf'].toString(), 
                      _analysisData!['cmf'] > 0.05 ? "انباشت" : "توزیع", _analysisData!['cmf'] > 0.05 ? buyColor : sellColor),
                  ]),
                  const SizedBox(height: 25),
                  _buildTradePanel(),
                  const SizedBox(height: 50),
                ],
              ),
            ),
      ),
    );
  }

  // --- المان‌های جدید الهام گرفته از نسخه وب ---

  // ۱. هدر امتیاز امنیت
  Widget _buildSafetyScoreHeader() {
    int score = int.tryParse(_analysisData!['safety_score']?.toString() ?? '0') ?? 0;
    Color scoreColor = score >= 70 ? buyColor : (score >= 45 ? holdColor : sellColor);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: bgPanel, 
        borderRadius: BorderRadius.circular(24), 
        border: Border.all(color: borderColor),
        boxShadow: [BoxShadow(color: scoreColor.withOpacity(0.05), blurRadius: 20)]
      ),
      child: Row(
        children: [
          Stack(alignment: Alignment.center, children: [
            SizedBox(width: 90, height: 90, child: CircularProgressIndicator(value: score/100, strokeWidth: 10, backgroundColor: borderColor, valueColor: AlwaysStoppedAnimation(scoreColor))),
            Text("$score%", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white, fontFamily: 'monospace')),
          ]),
          const SizedBox(width: 20),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("امتیاز امنیت ورود", style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 6),
                Text("هرچه این امتیاز بالاتر باشد، پتانسیل ثبات قیمت مطلوب‌تر است.", style: TextStyle(fontSize: 12, color: textMuted, height: 1.5)),
              ],
            ),
          )
        ],
      ),
    );
  }

  // ۲. بخش ریسک به ریوارد (Risk/Reward Grid)
  Widget _buildRiskRewardSection() {
    return Row(
      children: [
        _riskBox("حد ضرر (SL)", _analysisData!['sl_price'].toString(), "${_analysisData!['sl_percent']}%", sellColor),
        const SizedBox(width: 10),
        _riskBox("ریسک به ریوارد", "1 : ${_analysisData!['rrr']}", "وضعیت مطلوب", accentColor, isCenter: true),
        const SizedBox(width: 10),
        _riskBox("حد سود (TP)", _analysisData!['tp_price'].toString(), "${_analysisData!['tp_percent']}%", buyColor),
      ],
    );
  }

  Widget _riskBox(String label, String value, String sub, Color color, {bool isCenter = false}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isCenter ? color.withOpacity(0.1) : bgPanel,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: isCenter ? color.withOpacity(0.5) : borderColor),
        ),
        child: Column(
          children: [
            Text(label, style: TextStyle(color: textMuted, fontSize: 10)),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(color: isCenter ? Colors.white : color, fontWeight: FontWeight.w900, fontSize: 15, fontFamily: 'monospace')),
            const SizedBox(height: 4),
            Text(sub, style: TextStyle(color: color.withOpacity(0.7), fontSize: 10, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  // ۳. پله‌های ورود (DCA)
  Widget _buildDcaSection() {
    return _buildSectionCard("استراتژی ورود پله‌ای (DCA)", Icons.layers_outlined, [
      _buildInfoRow("پله اول (قیمت فعلی)", "${_analysisData!['dca_1']} تومان", valueColor: Colors.white),
      _buildInfoRow("پله دوم (حمایت لیمیت)", "${_analysisData!['dca_2']} تومان", valueColor: buyColor),
    ]);
  }

  // ۴. ماشین حساب هوشمند ریسک
  Widget _buildSmartCalculator() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bgPanel, 
        borderRadius: BorderRadius.circular(24), 
        border: Border.all(color: holdColor.withOpacity(0.3))
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Icon(Icons.calculate_outlined, color: holdColor, size: 20), const SizedBox(width: 10), const Text("ماشین حساب هوشمند ریسک", style: TextStyle(fontWeight: FontWeight.bold))]),
          const SizedBox(height: 15),
          Text("بر اساس تحلیل، پیشنهاد می‌شود حداکثر ${_analysisData!['allocation_num']}% از سرمایه را وارد کنید.", style: TextStyle(color: textMuted, fontSize: 12)),
          const SizedBox(height: 15),
          _buildInputField("کل سرمایه آزاد شما (تومان)", _totalCapitalController, onChanged: _calculateAllowedRisk),
          const SizedBox(height: 15),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: bgBody, borderRadius: BorderRadius.circular(15), border: Border.all(color: borderColor, style: BorderStyle.none)),
            child: Column(
              children: [
                Text("مبلغ مجاز ورود به این معامله:", style: TextStyle(color: textMuted, fontSize: 11)),
                const SizedBox(height: 5),
                Text("${_allowedInvestment.toInt()} تومان", style: TextStyle(color: holdColor, fontSize: 18, fontWeight: FontWeight.w900, fontFamily: 'monospace')),
              ],
            ),
          )
        ],
      ),
    );
  }

  // ۵. پنل ثبت معامله
  Widget _buildTradePanel() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [bgCard, bgPanel], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(28), 
        border: Border.all(color: borderColor)
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text("میز کار ورود امن", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        Row(children: [
          Expanded(child: _buildSideButton("خرید (LONG)", "BUY", buyColor)),
          const SizedBox(width: 12),
          Expanded(child: _buildSideButton("فروش (SHORT)", "SELL", sellColor)),
        ]),
        const SizedBox(height: 20),
        _buildInputField("قیمت لحظه‌ای", _entryController, isReadOnly: true),
        const SizedBox(height: 15),
        Row(children: [
          Expanded(child: _buildInputField("حد ضرر (SL)", _slController, textColor: sellColor)),
          const SizedBox(width: 12),
          Expanded(child: _buildInputField("حد سود (TP)", _tpController, textColor: buyColor)),
        ]),
        const SizedBox(height: 25),
        SizedBox(width: double.infinity, height: 58, child: ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: accentColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)), elevation: 10, shadowColor: accentColor.withOpacity(0.3)),
          onPressed: () {}, 
          child: const Text("تایید و ارسال دستور به هسته", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
        )),
      ]),
    );
  }

  // --- متدهای کمکی UI ---

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: bgBody,
      elevation: 0,
      title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text("آنالیز هوشمند ${widget.symbol}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Text("صیانت از سرمایه (Risk Management)", style: TextStyle(fontSize: 10, color: textMuted)),
      ]),
    );
  }

  Widget _buildInputField(String label, TextEditingController controller, {bool isReadOnly = false, Color? textColor, Function(String)? onChanged}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(color: textMuted, fontSize: 11)),
      const SizedBox(height: 8),
      TextField(
        controller: controller,
        readOnly: isReadOnly,
        onChanged: onChanged,
        keyboardType: TextInputType.number,
        style: TextStyle(color: textColor ?? Colors.white, fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
        decoration: InputDecoration(
          filled: true, fillColor: bgBody.withOpacity(0.5),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: borderColor)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: accentColor)),
        ),
      ),
    ]);
  }

  Widget _buildSectionCard(String title, IconData icon, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: bgPanel, borderRadius: BorderRadius.circular(24), border: Border.all(color: borderColor)),
      child: Column(children: [
        Row(children: [Icon(icon, color: accentColor, size: 20), const SizedBox(width: 10), Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))]),
        const Divider(color: Colors.white10, height: 30),
        ...children
      ]),
    );
  }

  Widget _buildInfoRow(String label, dynamic value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(color: textMuted, fontSize: 12)),
        Text(value?.toString() ?? '-', style: TextStyle(color: valueColor ?? Colors.white, fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'Vazir')),
      ]),
    );
  }

  Widget _buildIndicatorRow(String label, String value, String status, Color statusColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(color: textMuted, fontSize: 12)),
        Row(children: [
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'monospace')),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
            child: Text(status, style: TextStyle(color: statusColor, fontSize: 9, fontWeight: FontWeight.bold)),
          ),
        ]),
      ]),
    );
  }

  Widget _buildSideButton(String label, String side, Color color) {
    bool isSelected = _selectedSide == side;
    return InkWell(
      onTap: () => setState(() => _selectedSide = side),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isSelected ? color : borderColor)
        ),
        alignment: Alignment.center,
        child: Text(label, style: TextStyle(color: isSelected ? Colors.white : textMuted, fontWeight: FontWeight.bold, fontSize: 13)),
      ),
    );
  }

  Widget _buildAlertBox() {
    int score = int.tryParse(_analysisData!['safety_score']?.toString() ?? '0') ?? 0;
    bool isSqueezed = _analysisData!['is_squeezed'] ?? false;
    
    if (isSqueezed) return _alertItem("فشردگی نوسان (Squeeze)", "احتمال خواب سرمایه یا شکست فیک بالا است.", holdColor, Icons.pause_circle_outline);
    if (score < 45) return _alertItem("ریسک سنگین", "سیستم ورود به این نماد را پیشنهاد نمی‌کند.", sellColor, Icons.gpp_maybe);
    return _alertItem("تایید ساختار", "پتانسیل موفقیت استراتژی بالا ارزیابی می‌شود.", buyColor, Icons.gpp_good);
  }

  Widget _alertItem(String title, String desc, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: color.withOpacity(0.05), borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withOpacity(0.2))),
      child: Row(children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 15),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
          Text(desc, style: TextStyle(color: color.withOpacity(0.8), fontSize: 11)),
        ])),
      ]),
    );
  }
}