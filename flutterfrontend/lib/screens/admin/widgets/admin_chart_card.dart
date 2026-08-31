import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../config/theme.dart';
import '../../../models/admin_model.dart';

class AdminCategoryChartCard extends StatelessWidget {
  final List<CategoryStatModel> categories;

  const AdminCategoryChartCard({super.key, required this.categories});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderGrey),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.pie_chart_outline_rounded,
                color: AppTheme.primaryGreen,
                size: 20,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Farmer Query Categories',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (categories.isEmpty)
            const Center(child: Text('No query data available yet'))
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final stacked = constraints.maxWidth < 330;
                final legend = ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: categories.length,
                  itemBuilder: (context, index) => _LegendItem(
                    category: categories[index],
                    color: _getColorForCategory(categories[index].category),
                    label: _formatCategoryName(categories[index].category),
                  ),
                );
                if (stacked) {
                  return SizedBox(
                    height: 300,
                    child: Column(
                      children: [
                        SizedBox(
                          height: 145,
                          child: PieChart(
                            PieChartData(
                              sectionsSpace: 2,
                              centerSpaceRadius: 30,
                              sections: _buildPieSections(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Expanded(child: legend),
                      ],
                    ),
                  );
                }
                return SizedBox(
                  height: 160,
                  child: Row(
                    children: [
                      Expanded(
                        child: PieChart(
                          PieChartData(
                            sectionsSpace: 2,
                            centerSpaceRadius: 30,
                            sections: _buildPieSections(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: legend),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildPieSections() {
    return categories.map((c) {
      return PieChartSectionData(
        value: c.count.toDouble(),
        title: '',
        color: _getColorForCategory(c.category),
        radius: 28,
      );
    }).toList();
  }

  Color _getColorForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'crop_recommendation':
        return AppTheme.primaryGreen;
      case 'disease_detection':
        return const Color(0xFFE53935);
      case 'farm_advisory':
        return const Color(0xFF43A047);
      case 'crop_price':
        return const Color(0xFFFB8C00);
      case 'government_schemes':
        return const Color(0xFF1E88E5);
      default:
        return const Color(0xFF8E24AA);
    }
  }

  String _formatCategoryName(String cat) {
    return cat.replaceAll('_', ' ').capitalizeWords();
  }
}

class _LegendItem extends StatelessWidget {
  final CategoryStatModel category;
  final Color color;
  final String label;
  const _LegendItem({
    required this.category,
    required this.color,
    required this.label,
  });
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11.5, color: AppTheme.textDark),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '${category.percentage}%',
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.bold,
            color: AppTheme.textMuted,
          ),
        ),
      ],
    ),
  );
}

extension StringExtension on String {
  String capitalizeWords() {
    if (isEmpty) return this;
    return split(' ')
        .map(
          (w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '',
        )
        .join(' ');
  }
}
