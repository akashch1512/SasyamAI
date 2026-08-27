import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/admin_provider.dart';
import 'widgets/admin_chart_card.dart';
import 'widgets/admin_stat_card.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AdminProvider>(context, listen: false).fetchAllAdminData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final admin = Provider.of<AdminProvider>(context);
    final stats = admin.stats;
    final insights = admin.insights;

    return Scaffold(
      backgroundColor: AppTheme.surfaceWhite,
      appBar: AppBar(
        title: const Text(
          'Admin Analytics Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.primaryGreen),
            tooltip: 'Refresh Analytics',
            onPressed: () => admin.fetchAllAdminData(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryGreen,
          labelColor: AppTheme.primaryGreen,
          unselectedLabelColor: AppTheme.textMuted,
          tabs: const [
            Tab(icon: Icon(Icons.analytics_outlined, size: 18), text: 'Overview'),
            Tab(icon: Icon(Icons.psychology_outlined, size: 18), text: 'AI Insights'),
            Tab(icon: Icon(Icons.people_outline, size: 18), text: 'Farmers'),
          ],
        ),
      ),
      body: admin.isLoading && stats == null
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(admin),
                _buildInsightsTab(insights),
                _buildFarmersTab(admin),
              ],
            ),
    );
  }

  Widget _buildOverviewTab(AdminProvider admin) {
    final stats = admin.stats;
    if (stats == null) {
      return const Center(child: Text('No statistical data available'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 4 KPI Summary Cards Grid
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.35,
            children: [
              AdminStatCard(
                title: 'Total Farmers',
                value: '${stats.totalUsers}',
                icon: Icons.people_alt_rounded,
                color: AppTheme.primaryGreen,
                subtitle: 'Registered users',
              ),
              AdminStatCard(
                title: 'Total AI Inquiries',
                value: '${stats.totalQueries}',
                icon: Icons.forum_rounded,
                color: const Color(0xFF1E88E5),
                subtitle: 'Chat queries logged',
              ),
              AdminStatCard(
                title: 'Disease Scans',
                value: '${stats.totalDiseaseScans}',
                icon: Icons.document_scanner_outlined,
                color: const Color(0xFFE53935),
                subtitle: 'Leaf photo diagnoses',
              ),
              AdminStatCard(
                title: 'Crop Recomms',
                value: '${stats.totalCropRecommendations}',
                icon: Icons.spa_rounded,
                color: const Color(0xFFFB8C00),
                subtitle: 'ML suitability runs',
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Query Category Breakdown Chart
          AdminCategoryChartCard(categories: stats.categoryBreakdown),
          const SizedBox(height: 16),

          // Top Searched Crops
          Container(
            padding: const EdgeInsets.all(16),
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
                    Icon(Icons.trending_up_rounded, color: AppTheme.primaryGreen, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Top Inquired Crops',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (stats.topCrops.isEmpty)
                  const Text('No crop trends yet')
                else
                  ...stats.topCrops.map((crop) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              crop.cropName,
                              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppTheme.textDark),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.paleGreen,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${crop.inquiryCount} searches',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Recent Queries Feed
          Container(
            padding: const EdgeInsets.all(16),
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
                    Icon(Icons.history_rounded, color: AppTheme.primaryGreen, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Recent Farmer Searches',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (admin.recentQueries.isEmpty)
                  const Text('No queries logged yet')
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: admin.recentQueries.take(6).length,
                    separatorBuilder: (context, index) => const Divider(color: AppTheme.borderGrey, height: 16),
                    itemBuilder: (context, index) {
                      final q = admin.recentQueries[index];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                q.userName,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
                              ),
                              Text(
                                DateFormat('MMM d, h:mm a').format(q.createdAt),
                                style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            q.queryText,
                            style: const TextStyle(fontSize: 13.5, color: AppTheme.textDark),
                          ),
                          if (q.detectedCrop != null || q.detectedDisease != null) ...[
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 6,
                              children: [
                                if (q.detectedCrop != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppTheme.surfaceWhite,
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: AppTheme.borderGrey),
                                    ),
                                    child: Text('🌾 ${q.detectedCrop}', style: const TextStyle(fontSize: 11, color: AppTheme.textDark)),
                                  ),
                                if (q.detectedDisease != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFEBEE),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text('🔬 ${q.detectedDisease}', style: const TextStyle(fontSize: 11, color: Colors.red)),
                                  ),
                              ],
                            ),
                          ],
                        ],
                      );
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsTab(dynamic insights) {
    if (insights == null) {
      return const Center(child: Text('Loading AI Insights...'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Headline Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.paleGreen,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.accentGreen.withValues(alpha: 0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.auto_awesome, color: AppTheme.primaryGreen, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'AI Trend Intelligence',
                      style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryGreen, fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  insights.summaryHeadline,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark, height: 1.3),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Key Findings
          _buildInsightSection(
            'Key Farmer Inquiry Patterns',
            Icons.lightbulb_outline_rounded,
            insights.keyFindings,
            AppTheme.primaryGreen,
          ),
          const SizedBox(height: 16),

          // Emerging Crop Demands
          _buildInsightSection(
            'Emerging Crop Demands',
            Icons.grass_rounded,
            insights.emergingCropDemands,
            const Color(0xFFFB8C00),
          ),
          const SizedBox(height: 16),

          // Prevalent Crop Diseases
          _buildInsightSection(
            'Prevalent Crop Diseases Reported',
            Icons.coronavirus_outlined,
            insights.prevalentCropDiseases,
            const Color(0xFFE53935),
          ),
          const SizedBox(height: 16),

          // Advisory Suggestions
          _buildInsightSection(
            'Recommended Agronomy Campaign Actions',
            Icons.campaign_outlined,
            insights.farmerAdvisorySuggestions,
            const Color(0xFF1E88E5),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightSection(String title, IconData icon, List<String> items, Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderGrey),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accentColor, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textDark),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...items.map((item) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• ', style: TextStyle(color: accentColor, fontWeight: FontWeight.bold, fontSize: 16)),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(fontSize: 13.5, color: AppTheme.textDark, height: 1.4),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildFarmersTab(AdminProvider admin) {
    if (admin.users.isEmpty) {
      return const Center(child: Text('No registered farmers found'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: admin.users.length,
      itemBuilder: (context, index) {
        final u = admin.users[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.cardWhite,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.borderGrey),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppTheme.paleGreen,
                backgroundImage: u.profileImageUrl != null ? NetworkImage(u.profileImageUrl!) : null,
                child: u.profileImageUrl == null
                    ? const Icon(Icons.person, color: AppTheme.primaryGreen)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          u.fullName,
                          style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: u.isAdmin ? AppTheme.paleGreen : AppTheme.surfaceWhite,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppTheme.borderGrey),
                          ),
                          child: Text(
                            u.role.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: u.isAdmin ? AppTheme.primaryGreen : AppTheme.textMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(u.email, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                    if (u.phoneNumber != null)
                      Text('📞 ${u.phoneNumber}', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                    const SizedBox(height: 6),
                    Text(
                      '🌾 ${u.state ?? 'Region'}, ${u.soilType ?? 'Soil'} • ${u.landSizeAcres?.toStringAsFixed(1) ?? 'N/A'} Acres',
                      style: const TextStyle(fontSize: 12, color: AppTheme.textDark, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
