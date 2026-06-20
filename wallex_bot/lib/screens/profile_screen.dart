import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final Color bgCard = const Color(0xFF111827);
  final Color accentColor = const Color(0xFF3B82F6);
  final Color textMuted = const Color(0xFF9CA3AF);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        _buildUserHeader(),
        const SizedBox(height: 25),
        _buildSectionTitle("تنظیمات امنیتی"),
        _buildOptionCard(Icons.api_rounded, "کلیدهای API والکس", "متصل شده"),
        _buildOptionCard(Icons.security_rounded, "مدیریت ریسک هوشمند", "فعال"),
        const SizedBox(height: 25),
        _buildSectionTitle("اشتراک و توکن"),
        _buildTokenStatus(),
        const SizedBox(height: 25),
        _buildLogoutBtn(),
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildUserHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: accentColor.withOpacity(0.1), borderRadius: BorderRadius.circular(24)),
      child: Row(
        children: [
          CircleAvatar(radius: 30, backgroundColor: accentColor, child: const Icon(Icons.person, color: Colors.white, size: 30)),
          const SizedBox(width: 15),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text("کاربر کوانتوم", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            Text("09123456789", style: TextStyle(color: textMuted, fontSize: 12)),
          ]),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(padding: const EdgeInsets.only(bottom: 15, right: 5),
      child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildOptionCard(IconData icon, String title, String status) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: bgCard, borderRadius: BorderRadius.circular(20)),
      child: Row(children: [
        Icon(icon, color: accentColor, size: 22),
        const SizedBox(width: 15),
        Expanded(child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 14))),
        Text(status, style: TextStyle(color: textMuted, fontSize: 12)),
        const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white12, size: 14),
      ]),
    );
  }

  Widget _buildTokenStatus() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(gradient: LinearGradient(colors: [accentColor, const Color(0xFF1E40AF)]), borderRadius: BorderRadius.circular(24)),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text("موجودی فعلی", style: TextStyle(color: Colors.white70, fontSize: 12)),
          Text("124 توکن", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
        ]),
        ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: accentColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          child: const Text("افزایش اعتبار"),
        )
      ]),
    );
  }

  Widget _buildLogoutBtn() {
    return InkWell(
      onTap: () {
        Provider.of<AuthProvider>(context, listen: false).logout();
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(border: Border.all(color: Colors.redAccent.withOpacity(0.3)), borderRadius: BorderRadius.circular(20)),
        child: const Center(child: Text("خروج از حساب کاربری", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold))),
      ),
    );
  }
}