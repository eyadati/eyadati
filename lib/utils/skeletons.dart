import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ClinicCardSkeleton extends StatelessWidget {
  const ClinicCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: Column(
          children: [
            ListTile(
              contentPadding: const EdgeInsets.all(12),
              leading: const CircleAvatar(
                radius: 45,
                backgroundColor: Colors.white,
              ),
              title: Container(
                width: double.infinity,
                height: 16,
                color: Colors.white,
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(width: 100, height: 14, color: Colors.white),
                    const SizedBox(height: 4),
                    Container(width: 150, height: 14, color: Colors.white),
                  ],
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.all(12),
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
