import 'package:url_launcher/url_launcher.dart';

// در داخل متد خرید بسته:
void _startPayment(String packageId) async {
  final String paymentUrl = "https://your-domain.com/payment/request/$packageId/";
  if (await canLaunchUrl(Uri.parse(paymentUrl))) {
    await launchUrl(Uri.parse(paymentUrl), mode: LaunchMode.externalApplication);
  }
}