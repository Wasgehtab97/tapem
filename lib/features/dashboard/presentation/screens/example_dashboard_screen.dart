import 'package:flutter/material.dart';

import '../../../core/widgets/circular_xp_indicator.dart';
import '../../../core/widgets/line_chart_widget.dart';
import '../../../core/widgets/horizontal_bar_chart_widget.dart';
import '../../../core/widgets/heatmap_widget.dart';
import '../../../core/theme/design_tokens.dart';

/// An example dashboard screen demonstrating the refreshed UI components.
///
/// This screen is not wired to real data sources; instead it showcases how
/// the `CircularXpIndicator`, `TimeSeriesLineChart`, `HorizontalBarChart`
/// and `HeatmapWidget` can be composed. Use it as a starting point when
/// integrating the new design into existing features.
class ExampleDashboardScreen extends StatelessWidget {
  const ExampleDashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Sample data for charts.
    final lineData = [3.0, 4.5, 2.5, 5.2, 6.0, 4.8, 5.5];
    final barData = {
      'Browser': 80.0,
      'Mail': 50.0,
      'Terminal': 65.0,
    };
    final heatmapData = [
      [0.1, 0.2, 0.3, 0.4, 0.2],
      [0.3, 0.6, 0.5, 0.4, 0.3],
      [0.2, 0.4, 0.8, 0.7, 0.5],
      [0.1, 0.3, 0.4, 0.2, 0.1],
    ];

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {},
          ),
        ],
        title: const Text('Dashboard'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(child: CircularXpIndicator(progress: 0.82, label: 'XP')),
            const SizedBox(height: AppSpacing.md),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.card),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Activity', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: AppSpacing.sm),
                    TimeSeriesLineChart(points: lineData),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.card),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Applications', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: AppSpacing.sm),
                    HorizontalBarChart(data: barData),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.card),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Heatmap', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: AppSpacing.sm),
                    HeatmapWidget(values: heatmapData),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.leaderboard), label: 'Rank'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        currentIndex: 0,
        onTap: (index) {},
      ),
    );
  }
}
