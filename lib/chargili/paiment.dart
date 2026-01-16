import 'package:chargily_pay/chargily_pay.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lucide_icons/lucide_icons.dart';

class SubscriptionPlan {
  final String title;
  final String description;
  final String price;
  final int doctorLimit; // e.g., 5 for Basic, 15 for Standard, 0 for Unlimited
  final List<String> features;
  final String chargilyProductId; // To map to Chargily products if applicable

  SubscriptionPlan({
    required this.title,
    required this.description,
    required this.price,
    required this.doctorLimit,
    required this.features,
    required this.chargilyProductId,
  });
}

class SubscribeScreen extends StatefulWidget {
  const SubscribeScreen({super.key});

  @override
  State<SubscribeScreen> createState() => _SubscribeScreenState();
}

class _SubscribeScreenState extends State<SubscribeScreen> {
  bool _isLoading = false;
  String? _errorMessage;

  // Define the 3 plans
  final List<SubscriptionPlan> _plans = [
    SubscriptionPlan(
      title: 'basic_plan_title'.tr(),
      description: 'basic_plan_description'.tr(),
      price: '4000 DZD',
      doctorLimit: 5,
      features: [
        'up_to_5_doctors'.tr(),
        'basic_features'.tr(),
        'email_support'.tr(),
      ],
      chargilyProductId: 'prod_basic_plan', // Placeholder
    ),
    SubscriptionPlan(
      title: 'standard_plan_title'.tr(),
      description: 'standard_plan_description'.tr(),
      price: '7000 DZD',
      doctorLimit: 15,
      features: [
        'up_to_15_doctors'.tr(),
        'all_basic_features'.tr(),
        'priority_support'.tr(),
        'advanced_analytics'.tr(),
      ],
      chargilyProductId: 'prod_standard_plan', // Placeholder
    ),
    SubscriptionPlan(
      title: 'premium_plan_title'.tr(),
      description: 'premium_plan_description'.tr(),
      price: '10000 DZD',
      doctorLimit: 0, // 0 indicates unlimited
      features: [
        'unlimited_doctors'.tr(),
        'all_features'.tr(),
        '24_7_support'.tr(),
        'custom_integrations'.tr(),
      ],
      chargilyProductId: 'prod_premium_plan', // Placeholder
    ),
  ];

  //TODO: Replace with your actual Chargily API keys
  final client = ChargilyClient(
    ChargilyConfig.test(
      apiKey: 'test_sk_kMrjDHPewHDyW4CMkPEPl1viQN0ieJp5IKY9vrPB',
    ),
  );

  Future<void> _startSubscription(SubscriptionPlan plan) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      // In a real app, you would dynamically fetch the amount from Chargily
      // or ensure your product IDs map to correct amounts.
      // For this example, we'll parse from the plan's price string.
      final amountString = plan.price.replaceAll(' DZD', '');
      final double price = double.parse(amountString);

      final request = CreateCheckoutRequest(
        amount: price,
        currency: 'dzd',
        successUrl: 'https://eyadati.page.link/payment_status',
        failureUrl: 'https://eyadati.page.link/payment_status',
        description:
            '${plan.title} Subscription (${plan.doctorLimit == 0 ? "Unlimited" : "${plan.doctorLimit} doctors"})',
      );

      final checkout = await client.createCheckout(request);

      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ChargilyCheckoutView(
              checkout: checkout,
              onPaymentSuccess: () {
                // Handle success (e.g., show success dialog)
                Navigator.pop(context);
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Payment Successful!')));
              },
              onPaymentFailure: () {
                // Handle failure
                Navigator.pop(context);
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Payment Failed.')));
              },
              onPaymentCancel: () {
                // User closed the modal
                Navigator.pop(context);
              },
            ),
          ),
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
              ..._plans.map(
                (plan) => Padding(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: _PlanCard(
                    plan: plan,
                    onPressed: () => _startSubscription(plan),
                    isLoading: _isLoading,
                  ),
                ),
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
}

class _PlanCard extends StatelessWidget {
  final SubscriptionPlan plan;
  final VoidCallback onPressed;
  final bool isLoading;

  const _PlanCard({
    required this.plan,
    required this.onPressed,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.center,
              child: Text(
                plan.title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.center,
              child: Text(
                plan.description,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.center,
              child: Text(
                plan.price,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            ...plan.features.map(
              (feature) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.checkCircle,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        feature,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : onPressed,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: isLoading
                    ? CircularProgressIndicator(
                        color: Theme.of(context).colorScheme.onPrimary,
                      )
                    : Text('select_plan'.tr()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
