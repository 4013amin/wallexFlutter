import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class AnalysisScreen extends StatefulWidget {
  final String symbol;
  const AnalysisScreen({super.key, required this.symbol});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> with SingleTickerProviderStateMixin {
  final ApiService _api = ApiService();

  // ── پالت رنگی اختصاصی ──────────────────────────────────────────
  static const Color bgBody = Color(0xFF0B0F19);
  static const Color bgPanel = Color(0xFF111827);
  static const Color accent = Color(0xFF3B82F6);
  static const Color buyClr = Color(0xFF10B981);
  static const Color sellClr = Color(0xFFF43F5E);
  static const Color holdClr = Color(0xFFF59E0B);
  static const Color mutedClr = Color(0xFF9CA3AF);
  static const Color borderClr = Color(0x14FFFFFF);

  late final TextEditingController _slCtrl, _tpCtrl, _entryCtrl, _capitalCtrl;
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  String _side = 'BUY';
  Map<String, dynamic>? _data;
  bool _loading = true;
  double _allowedInvest = 0;

  @override
  void initState() {
    super.initState();
    _slCtrl = TextEditingController();
    _tpCtrl = TextEditingController();
    _entryCtrl = TextEditingController();
    _capitalCtrl = TextEditingController();

    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);

    _loadData();
  }

  @override
  void dispose() {
    _slCtrl.dispose();
    _tpCtrl.dispose();
    _entryCtrl.dispose();
    _capitalCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  String _fmt(dynamic v) {
    if (v == null || v == 0) return '۰';
    final n = double.tryParse(v.toString())?.toInt() ?? 0;
    return NumberFormat('#,###').format(n);
  }

  Future _loadData() async {
    try {
      final res = await _api.getCoinAnalysis(widget.symbol);
      final data = res['analysis'] as Map<String, dynamic>?;
      if (!mounted) return;
      setState(() {
        _data = data;
        _entryCtrl.text = data?['current_price']?.toString() ?? '0';
        _slCtrl.text = data?['sl_price']?.toString() ?? '';
        _tpCtrl.text = data?['tp_price']?.toString() ?? '';
        _side = (data?['direction']?.toString().toUpperCase().contains('SELL') ?? false) ? 'SELL' : 'BUY';
        _loading = false;
      });
      _fadeCtrl.forward();
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _calcRisk(String raw) {
    final clean = raw.replaceAll(RegExp(r'[^0-9]'), '');
    final capital = double.tryParse(clean) ?? 0;
    final pct = double.tryParse(_data?['allocation_num']?.toString() ?? '5') ?? 5;
    setState(() => _allowedInvest = capital * pct / 100);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgBody,
      appBar: _appBar(),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: accent))
          : FadeTransition(
              opacity: _fadeAnim,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: Column(
                  children: [
                    _scoreHeader(),
                    const SizedBox(height: 16),
                    _alertBox(),
                    const SizedBox(height: 20),
                    _rrSection(),
                    const SizedBox(height: 20),
                    _dcaCard(),
                    const SizedBox(height: 20),
                    _smartCalc(),
                    const SizedBox(height: 20),
                    _marketCard(),
                    const SizedBox(height: 20),
                    _tradePanel(),
                    const SizedBox(height: 50),
                  ],
                ),
              ),
            ),
    );
  }

  PreferredSizeWidget _appBar() => AppBar(
        backgroundColor: bgBody,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'تحلیل هوشمند ${widget.symbol}',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white54, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      );

  Widget _scoreHeader() {
    final score = int.tryParse(_data?['safety_score']?.toString() ?? '0') ?? 0;
    final scoreClr = score >= 70 ? buyClr : (score >= 45 ? holdClr : sellClr);
    final label = score >= 70 ? 'امن' : (score >= 45 ? 'متوسط' : 'پر ریسک');

    return _panel(
      child: Row(children: [
        Stack(alignment: Alignment.center, children: [
          SizedBox(
            width: 72, height: 72,
            child: CircularProgressIndicator(
              value: score / 100, strokeWidth: 7,
              backgroundColor: borderClr,
              valueColor: AlwaysStoppedAnimation(scoreClr),
            ),
          ),
          Text('$score٪', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: scoreClr)),
        ]),
        const SizedBox(width: 18),
        Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('نمره امنیت معامله', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 4),
          _chip(label, scoreClr),
          const SizedBox(height: 6),
          const Text('پتانسیل موفقیت بر اساس ساختار فعلی بازار', style: TextStyle(fontSize: 11, color: mutedClr)),
        ])),
      ]),
    );
  }

  Widget _chip(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
        child: Text(text, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
      );

  Widget _alertBox() {
    final score = int.tryParse(_data?['safety_score']?.toString() ?? '0') ?? 0;
    if (score < 45) return _alertItem('ریسک بالا شناسایی شد', 'ورود به این موقعیت توصیه نمی‌شود.', sellClr, Icons.warning_amber_rounded);
    return _alertItem('ساختار قیمتی تایید شد', 'سیگنال دارای پتانسیل رشد مناسبی است.', buyClr, Icons.check_circle_outline_rounded);
  }

  Widget _alertItem(String title, String desc, Color clr, IconData icon) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: clr.withOpacity(0.07),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: clr.withOpacity(0.25)),
        ),
        child: Row(children: [
          Icon(icon, color: clr, size: 22),
          const SizedBox(width: 12),
          Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: TextStyle(color: clr, fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 2),
            Text(desc, style: TextStyle(color: clr.withOpacity(0.8), fontSize: 11)),
          ])),
        ]),
      );

  Widget _rrSection() => Row(children: [
        _rrBox('حد ضرر (SL)', _fmt(_data?['sl_price']), '${_data?['sl_percent'] ?? 0}٪', sellClr),
        const SizedBox(width: 8),
        _rrBox('R / R', '1 : ${_data?['rrr'] ?? 0}', 'نسبت سود', accent, center: true),
        const SizedBox(width: 8),
        _rrBox('حد سود (TP)', _fmt(_data?['tp_price']), '${_data?['tp_percent'] ?? 0}٪', buyClr),
      ]);

  Widget _rrBox(String lbl, String val, String sub, Color clr, {bool center = false}) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: center ? clr.withOpacity(0.1) : bgPanel,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: center ? clr.withOpacity(0.5) : borderClr),
          ),
          child: Column(children: [
            Text(lbl, style: const TextStyle(color: mutedClr, fontSize: 10)),
            const SizedBox(height: 6),
            FittedBox(child: Text(val, style: TextStyle(color: center ? Colors.white : clr, fontWeight: FontWeight.bold, fontSize: 13))),
            const SizedBox(height: 4),
            Text(sub, style: TextStyle(color: clr.withOpacity(0.8), fontSize: 10)),
          ]),
        ),
      );

  Widget _dcaCard() => _sectionCard('پله‌های ورود (DCA)', Icons.layers_outlined, [
        _infoRow('پله اول (قیمت فعلی)', '${_fmt(_data?['dca_1'])} تومان'),
        _infoRow('پله دوم (حمایت اصلی)', '${_fmt(_data?['dca_2'])} تومان', valClr: buyClr),
      ]);

  Widget _smartCalc() => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: bgPanel,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: holdClr.withOpacity(0.3)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.calculate_outlined, color: holdClr, size: 20),
            const SizedBox(width: 10),
            const Text('مدیریت ریسک هوشمند', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          ]),
          const SizedBox(height: 6),
          Text('درصد پیشنهادی تخصیص سرمایه: ${_data?['allocation_num'] ?? 5}٪', style: const TextStyle(color: mutedClr, fontSize: 12)),
          const SizedBox(height: 14),
          _field('سرمایه کل شما (تومان)', _capitalCtrl, onChanged: _calcRisk, focusBorder: holdClr),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(color: bgBody, borderRadius: BorderRadius.circular(14)),
            child: Column(children: [
              const Text('مبلغ مجاز جهت خرید در این پله:', style: TextStyle(color: mutedClr, fontSize: 11)),
              const SizedBox(height: 6),
              Text(
                '${_fmt(_allowedInvest.toInt())} تومان',
                style: const TextStyle(color: holdClr, fontSize: 22, fontWeight: FontWeight.w900),
              ),
            ]),
          ),
        ]),
      );

  Widget _marketCard() => _sectionCard('وضعیت ساختار بازار', Icons.grid_view_rounded, [
        _infoRow('روند کوتاه مدت (15m)', _data?['trend_15m'] ?? 'خنثی'),
        _infoRow('روند میان مدت (1h)', _data?['trend_1h'] ?? 'خنثی'),
        _infoRow('وضعیت نقدینگی', _data?['btc_trend'] ?? 'خنثی'),
        _infoRow(
          'توازن سفارشات',
          'خرید ${_data?['imbalance'] ?? 50}٪ | فروش ${_data?['ask_imbalance'] ?? 50}٪',
          valClr: accent,
        ),
      ]);

  Widget _tradePanel() => _panel(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('تنظیمات معامله', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 18),
          Row(children: [
            Expanded(child: _sideBtn('خرید (LONG)', 'BUY', buyClr)),
            const SizedBox(width: 10),
            Expanded(child: _sideBtn('فروش (SHORT)', 'SELL', sellClr)),
          ]),
          const SizedBox(height: 18),
          _field('قیمت ورود به پله', _entryCtrl, readOnly: true),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: _field('حد ضرر (SL)', _slCtrl, txtColor: sellClr)),
            const SizedBox(width: 12),
            Expanded(child: _field('حد سود (TP)', _tpCtrl, txtColor: buyClr)),
          ]),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              onPressed: () {
                // اجرای معامله
              },
              child: const Text('ثبت و اجرای معامله', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
            ),
          ),
        ]),
      );

  Widget _panel({required Widget child}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: bgPanel, borderRadius: BorderRadius.circular(24), border: Border.all(color: borderClr)),
        child: child,
      );

  Widget _sectionCard(String title, IconData icon, List<Widget> rows) => _panel(
        child: Column(children: [
          Row(children: [Icon(icon, color: accent, size: 18), const SizedBox(width: 10), Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white))]),
          const Divider(color: Colors.white10, height: 28),
          ...rows,
        ]),
      );

  Widget _infoRow(String lbl, dynamic val, {Color? valClr}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(lbl, style: const TextStyle(color: mutedClr, fontSize: 12)),
          Text(val?.toString() ?? '-', style: TextStyle(color: valClr ?? Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
        ]),
      );

  Widget _field(
    String label,
    TextEditingController ctrl, {
    bool readOnly = false,
    Color? txtColor,
    Color focusBorder = accent,
    void Function(String)? onChanged,
  }) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(color: mutedClr, fontSize: 11)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          readOnly: readOnly,
          onChanged: onChanged,
          keyboardType: TextInputType.number,
          style: TextStyle(color: txtColor ?? Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            filled: true,
            fillColor: bgBody,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: borderClr)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: focusBorder)),
          ),
        ),
      ]);

  Widget _sideBtn(String label, String side, Color clr) {
    final selected = _side == side;
    return GestureDetector(
      onTap: () => setState(() => _side = side),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? clr : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? clr : borderClr),
        ),
        alignment: Alignment.center,
        child: Text(label, style: TextStyle(color: selected ? Colors.white : mutedClr, fontWeight: FontWeight.bold)),
      ),
    );
  }
}