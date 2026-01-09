import 'dart:convert';
import 'package:easy_localization/easy_localization.dart';
import 'package:eyadati/chargili/secrets.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

class SubscribeScreen extends StatefulWidget {
  const SubscribeScreen({super.key});

  @override
  State<SubscribeScreen> createState() => _SubscribeScreenState();
}

class _SubscribeScreenState extends State<SubscribeScreen> {
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _startSubscription() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      final resp = await http.post(
        Uri.parse(
          "https://erkldarqweehvwgpncrg.supabase.co/functions/v1/create-chargily-checkout",
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $AnonKey',
        },
      );

      if (resp.statusCode != 200) {
        throw Exception(
          'Checkout API failed: ${resp.statusCode} – ${resp.body}',
        );
      }

      final Map<String, dynamic> data = jsonDecode(resp.body);
      final String? checkoutUrl = data['checkoutUrl'] ?? data['checkout_url'];

      if (checkoutUrl == null || checkoutUrl.isEmpty) {
        throw Exception('Invalid checkout URL returned from backend');
      }

      final uri = Uri.parse(checkoutUrl);
      if (!await launchUrl(uri, mode: LaunchMode.platformDefault)) {
        throw Exception('Failed to open payment URL');
      }

      _showPendingDialog();
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showPendingDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('payment_in_progress'.tr()),
        content: Text(
          '${'complete_payment_browser'.tr()}\n${'subscription_will_activate'.tr()}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('ok'.tr()),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('subscribe'.tr())),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'choose_your_plan'.tr(),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'unlock_all_features'.tr(),
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            _PricingCard(
              planName: 'basic'.tr(),
              price: '1000 DZD',
              features: [
                'feature_1'.tr(),
                'feature_2'.tr(),
                'feature_3'.tr(),
              ],
              onPressed: _startSubscription,
              isLoading: _isLoading,
              isRecommended: false,
            ),
            const SizedBox(height: 16),
            _PricingCard(
              planName: 'premium'.tr(),
              price: '3000 DZD',
              features: [
                'feature_1'.tr(),
                'feature_2'.tr(),
                'feature_3'.tr(),
                'feature_4'.tr(),
              ],
              onPressed: _startSubscription,
              isLoading: _isLoading,
              isRecommended: true,
            ),
            const SizedBox(height: 16),
            _PricingCard(
              planName: 'vip'.tr(),
              price: '5000 DZD',
              features: [
                'feature_1'.tr(),
                'feature_2'.tr(),
                'feature_3'.tr(),
                'feature_4'.tr(),
                'feature_5'.tr(),
              ],
              onPressed: _startSubscription,
              isLoading: _isLoading,
              isRecommended: false,
            ),
            const SizedBox(height: 16),
            if (_errorMessage != null)
              Text(
                _errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
    );
  }
}

class _PricingCard extends StatelessWidget {
  final String planName;
  final String price;
  final List<String> features;
  final VoidCallback onPressed;
  final bool isLoading;
  final bool isRecommended;

  const _PricingCard({
    required this.planName,
    required this.price,
    required this.features,
    required this.onPressed,
    required this.isLoading,
    this.isRecommended = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: isRecommended ? 8 : 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isRecommended
            ? BorderSide(
                color: Theme.of(context).colorScheme.primary, width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              planName,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Text(
              price,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            Text(
              'per_month'.tr(),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            ...features.map((feature) => _buildFeatureRow(context, feature)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: isLoading ? null : onPressed,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: isLoading
                  ? CircularProgressIndicator(
                      color: Theme.of(context).colorScheme.onPrimary)
                  : Text('subscribe'.tr()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureRow(BuildContext context, String feature) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_outline,
            color: Theme.of(context).colorScheme.primary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(feature)),
        ],
      ),
    );
  }
}
