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
              Icon(Icons.pie_chart_outline_rounded, color: AppTheme.primaryGreen, size: 20),
              SizedBox(width: 8),
              Text(
                'Farmer Query Categories',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textDark),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (categories.isEmpty)
            const Center(child: Text('No query data available yet'))
          else
            SizedBox(
              height: 160,
              child: Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 30,
                        sections: _buildPieSections(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 1,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: categories.map((c) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2.5),
                          child: Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: _getColorForCategory(c.category),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  _formatCategoryName(c.category),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 11.5, color: AppTheme.textDark),
                                ),
                              ),
                              Text(
                                '${c.percentage}%',
                                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppTheme.textMuted),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
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

extension StringExtension on String {
  String capitalizeWords() {
    if (isEmpty) return this;
    return split(' ').map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '').join(' ');
  }
}
