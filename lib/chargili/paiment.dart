import 'dart:convert';
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
        title: const Text('Payment in Progress'),
        content: const Text(
          'Complete the payment in your browser.\n'
          'Your subscription will activate once confirmed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Subscribe – 1 Month Access')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Spacer(),
            const Text(
              'Fixed price: 3000 DZD',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _startSubscription,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 32,
                ),
                textStyle: const TextStyle(fontSize: 18),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Pay & Subscribe'),
            ),
            const SizedBox(height: 16),
            if (_errorMessage != null)
              Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
