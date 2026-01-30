import 'package:chargily_pay/chargily_pay.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:eyadati/chargili/secrets.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:url_launcher/url_launcher.dart';

class SubscribeScreen extends StatefulWidget {
  const SubscribeScreen({super.key});

  @override
  State<SubscribeScreen> createState() => _SubscribeScreenState();
}

class _SubscribeScreenState extends State<SubscribeScreen> {
  bool _isLoading = false;
  String? _errorMessage;
  int _doctorCount = 1;
  double _price = 4000;
  final client = ChargilyClient(
    ChargilyConfig.test(apiKey: AppSecrets.chargilyApiKey),
  );

  @override
  void initState() {
    super.initState();
    _calculatePrice();
  }

  void _calculatePrice() {
    setState(() {
      if (_doctorCount == 1) {
        _price = 4000;
      } else if (_doctorCount == 2) {
        _price = 7000;
      } else {
        _price = _doctorCount * 3000.0;
      }
    });
  }

  void _incrementDoctors() {
    setState(() {
      _doctorCount++;
      _calculatePrice();
    });
  }

  void _decrementDoctors() {
    setState(() {
      if (_doctorCount > 1) {
        _doctorCount--;
        _calculatePrice();
      }
    });
  }

  Future<void> _startSubscription(double amount, int doctorCount) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      final request = CreateCheckoutRequest(
        amount: amount,
        currency: 'dzd',
        successUrl: 'https://eyadati.page.link/payment_status',
        failureUrl: 'https://eyadati.page.link/payment_status',
        description: 'Subscription for $doctorCount doctors',
        metadata: {
          'clinic_id': user.uid,
          'doctor_count': doctorCount.toString(),
        },
      );

      final checkout = await client.createCheckout(request);

      if (mounted) {
        await launchUrl(
          Uri.parse(checkout.checkoutUrl),
          mode: LaunchMode.externalApplication,
        );
      }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('subscribe'.tr())),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildNote(context),
              const SizedBox(height: 24),
              Text(
                'available_plans'.tr(),
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildPlansRow(context),
              const SizedBox(height: 32),
              Divider(),
              const SizedBox(height: 16),
              Text(
                'customize_your_plan'.tr(),
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              _SubscriptionCalculator(
                doctorCount: _doctorCount,
                price: _price,
                onDecrement: _decrementDoctors,
                onIncrement: _incrementDoctors,
                onSubscribe: () => _startSubscription(_price, _doctorCount),
                isLoading: _isLoading,
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
      ),
    );
  }

  Widget _buildNote(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withAlpha(50),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withAlpha(100),
        ),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.info, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'number_of_doctors_note'.tr(),
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlansRow(BuildContext context) {
    // Using a Column for small screens, or a layout builder could be used.
    // Given mobile focus, a vertical list of cards is often safer,
    // but requested "3 cards" usually implies horizontal if they fit, or vertical.
    // I'll stack them vertically for better readability of details.
    return Column(
      children: [
        _PlanCard(
          title: 'Starter',
          price: '4000 DZD',
          subtitle: '1 Doctor',
          description: 'Perfect for individual practitioners.',
          isPopular: false,
          color: Colors.blue,
        ),
        const SizedBox(height: 12),
        _PlanCard(
          title: 'Growth',
          price: '7000 DZD',
          subtitle: '2 Doctors',
          description: '3500 DZD / Doctor. Great for small clinics.',
          isPopular: false,
          color: Colors.purple,
        ),
        const SizedBox(height: 12),
        _PlanCard(
          title: 'Enterprise',
          price: '3000 DZD',
          subtitle: 'Per Doctor (3+)',
          description: 'Best value for larger medical centers.',
          isPopular: true,
          color: Colors.orange,
        ),
      ],
    );
  }
}

class _PlanCard extends StatelessWidget {
  final String title;
  final String price;
  final String subtitle;
  final String description;
  final bool isPopular;
  final Color color;

  const _PlanCard({
    required this.title,
    required this.price,
    required this.subtitle,
    required this.description,
    required this.isPopular,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isPopular ? BorderSide(color: color, width: 2) : BorderSide.none,
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color.withAlpha(20), color.withAlpha(5)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: color,
                    ),
                  ),
                  if (isPopular)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Best Value',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    price,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(description, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

class _SubscriptionCalculator extends StatelessWidget {
  final int doctorCount;
  final double price;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onSubscribe;
  final bool isLoading;

  const _SubscriptionCalculator({
    required this.doctorCount,
    required this.price,
    required this.onIncrement,
    required this.onDecrement,
    required this.onSubscribe,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8,
      shadowColor: Theme.of(context).colorScheme.primary.withAlpha(50),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Text(
              'configure_doctors'.tr(),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(50),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _RoundIconButton(
                    icon: Icons.remove,
                    onPressed: onDecrement,
                    enabled: doctorCount > 1,
                  ),
                  const SizedBox(width: 24),
                  Column(
                    children: [
                      Text(
                        '$doctorCount',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Doctors',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                  ),
                  const SizedBox(width: 24),
                  _RoundIconButton(
                    icon: Icons.add,
                    onPressed: onIncrement,
                    enabled: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Total',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  '${price.toStringAsFixed(0)} DZD',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: isLoading ? null : onSubscribe,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: isLoading
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Theme.of(context).colorScheme.onPrimary,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'subscribe_now'.tr(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final bool enabled;

  const _RoundIconButton({
    required this.icon,
    required this.onPressed,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: enabled
          ? Theme.of(context).colorScheme.surface
          : Colors.grey.shade300,
      shape: const CircleBorder(),
      elevation: enabled ? 2 : 0,
      child: InkWell(
        onTap: enabled ? onPressed : null,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Icon(
            icon,
            color: enabled
                ? Theme.of(context).colorScheme.primary
                : Colors.grey,
          ),
        ),
      ),
    );
  }
}
