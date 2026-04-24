import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nourish_v/controllers/dashboard_controller.dart';
import 'package:nourish_v/controllers/localization_controller.dart';
import 'package:nourish_v/core/animations.dart';
import 'package:nourish_v/core/constants.dart';
import 'package:nourish_v/core/theme.dart';

class SupervisorDashboardView extends ConsumerStatefulWidget {
  final bool isEmbedded;
  const SupervisorDashboardView({super.key, this.isEmbedded = false});

  @override
  ConsumerState<SupervisorDashboardView> createState() =>
      _SupervisorDashboardViewState();
}

class _SupervisorDashboardViewState
    extends ConsumerState<SupervisorDashboardView> {
  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      ref.read(dashboardControllerProvider.notifier).loadDashboard();
    });
  }

  Widget _buildAppBar(LocalizationController l10n) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    child: Row(
      children: [
        if (!widget.isEmbedded) ...[
          TapScaleWrapper(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
            ),
          ),
          const SizedBox(width: 16),
        ],
        Text(
          l10n.tr('Dashboard'),
          style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w700),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            l10n.tr('Supervisor'),
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _buildStatCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required int delay,
  }) {
    return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.15)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 14),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
        )
        .animate(delay: Duration(milliseconds: delay))
        .fadeIn(duration: const Duration(milliseconds: 500))
        .slideY(begin: 0.15, end: 0, curve: Curves.easeOutCubic);
  }

  Widget _buildSummaryCards(
    DashboardState state,
    LocalizationController l10n,
  ) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                label: l10n.tr('Total Screened'),
                value: '${state.stats['totalScreened'] ?? 0}',
                icon: Icons.people_rounded,
                color: AppColors.primary,
                delay: 0,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                label: l10n.tr('Healthy'),
                value: '${state.stats['healthyPercent'] ?? 0}%',
                icon: Icons.check_circle_rounded,
                color: AppColors.healthy,
                delay: 100,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                label: l10n.tr('At Risk'),
                value: '${state.stats['atRiskPercent'] ?? 0}%',
                icon: Icons.warning_rounded,
                color: AppColors.atRisk,
                delay: 200,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                label: l10n.tr('Severe'),
                value: '${state.stats['severePercent'] ?? 0}%',
                icon: Icons.error_rounded,
                color: AppColors.severe,
                delay: 300,
              ),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _buildBarChart(List<Map<String, dynamic>> regionData) => BarChart(
    BarChartData(
      barTouchData: BarTouchData(enabled: true),
      titlesData: FlTitlesData(
        show: true,
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              if (value.toInt() >= regionData.length) {
                return const SizedBox();
              }

              final name = regionData[value.toInt()]['region'] as String? ?? 'Unknown';
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  name.length > 6 ? '${name.substring(0, 6)}..' : name,
                  style: GoogleFonts.poppins(
                    fontSize: 9,
                    color: AppColors.textSecondaryLight,
                  ),
                ),
              );
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            getTitlesWidget: (value, meta) => Text(
              '${value.toInt()}',
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: AppColors.textSecondaryLight,
              ),
            ),
          ),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
      ),
      borderData: FlBorderData(show: false),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: 2,
        getDrawingHorizontalLine: (value) {
          return FlLine(color: AppColors.divider, strokeWidth: 0.5);
        },
      ),
      barGroups: regionData.asMap().entries.map((entry) {
        final i = entry.key;
        final d = entry.value;
        return BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: (d['healthy'] as int).toDouble(),
              color: AppColors.healthy,
              width: 8,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
            BarChartRodData(
              toY: (d['atRisk'] as int).toDouble(),
              color: AppColors.atRisk,
              width: 8,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
            BarChartRodData(
              toY: (d['severe'] as int).toDouble(),
              color: AppColors.severe,
              width: 8,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
          ],
        );
      }).toList(),
    ),
    duration: const Duration(milliseconds: 800),
    curve: Curves.easeOutCubic,
  );

  Widget _buildLegendItem(String label, Color color) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(3),
        ),
      ),
      const SizedBox(width: 6),
      Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 11,
          color: AppColors.textSecondaryLight,
        ),
      ),
    ],
  );

  Widget _buildRegionChart(DashboardState state, LocalizationController l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.tr('Region Breakdown'),
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ).animate(delay: const Duration(milliseconds: 400)).fadeIn(),
          const SizedBox(height: 16),
          Container(
                height: 250,
                padding: const EdgeInsets.all(16),
                decoration: GlassDecoration.card(),
                child: state.regionData.isEmpty
                    ? Center(
                        child: Text(
                          l10n.tr('No data available'),
                          style: GoogleFonts.poppins(
                            color: AppColors.textSecondaryLight,
                          ),
                        ),
                      )
                    : _buildBarChart(state.regionData),
              )
              .animate(delay: const Duration(milliseconds: 500))
              .fadeIn(duration: const Duration(milliseconds: 600))
              .slideY(begin: 0.1, end: 0),
          // Legend
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem(l10n.tr('Healthy'), AppColors.healthy),
                const SizedBox(width: 20),
                _buildLegendItem(l10n.tr('At Risk'), AppColors.atRisk),
                const SizedBox(width: 20),
                _buildLegendItem(l10n.tr('Severe'), AppColors.severe),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLineChart(List<Map<String, dynamic>> monthlyTrends) => LineChart(
    LineChartData(
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipItems: (touchedSpots) {
            return touchedSpots.map((spot) {
              return LineTooltipItem(
                '${spot.y.toInt()}',
                GoogleFonts.poppins(
                  color: spot.bar.color,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              );
            }).toList();
          },
        ),
      ),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: 20,
        getDrawingHorizontalLine: (value) {
          return FlLine(color: AppColors.divider, strokeWidth: 0.5);
        },
      ),
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              if (value.toInt() < monthlyTrends.length) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    monthlyTrends[value.toInt()]['month'] as String,
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                );
              }
              return const SizedBox();
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            getTitlesWidget: (value, meta) {
              return Text(
                '${value.toInt()}',
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: AppColors.textSecondaryLight,
                ),
              );
            },
          ),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
      ),
      borderData: FlBorderData(show: false),
      lineBarsData: [
        LineChartBarData(
          spots: monthlyTrends.asMap().entries.map((e) {
            return FlSpot(
              e.key.toDouble(),
              (e.value['healthy'] as int).toDouble(),
            );
          }).toList(),
          isCurved: true,
          color: AppColors.healthy,
          barWidth: 3,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            color: AppColors.healthy.withValues(alpha: 0.1),
          ),
        ),
        LineChartBarData(
          spots: monthlyTrends.asMap().entries.map((e) {
            return FlSpot(
              e.key.toDouble(),
              (e.value['atRisk'] as int).toDouble(),
            );
          }).toList(),
          isCurved: true,
          color: AppColors.atRisk,
          barWidth: 3,
          dotData: const FlDotData(show: false),
        ),
        LineChartBarData(
          spots: monthlyTrends.asMap().entries.map((e) {
            return FlSpot(
              e.key.toDouble(),
              (e.value['severe'] as int).toDouble(),
            );
          }).toList(),
          isCurved: true,
          color: AppColors.severe,
          barWidth: 3,
          dotData: const FlDotData(show: false),
        ),
      ],
    ),
    duration: const Duration(milliseconds: 1000),
    curve: Curves.easeOutCubic,
  );

  Widget _buildTrendChart(DashboardState state, LocalizationController l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.tr('Monthly Trends'),
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ).animate(delay: const Duration(milliseconds: 600)).fadeIn(),
          const SizedBox(height: 16),
          Container(
                height: 220,
                padding: const EdgeInsets.all(16),
                decoration: GlassDecoration.card(),
                child: state.monthlyTrends.isEmpty
                    ? Center(
                        child: Text(
                          l10n.tr('No data available'),
                          style: GoogleFonts.poppins(
                            color: AppColors.textSecondaryLight,
                          ),
                        ),
                      )
                    : _buildLineChart(state.monthlyTrends),
              )
              .animate(delay: const Duration(milliseconds: 700))
              .fadeIn(duration: const Duration(milliseconds: 600))
              .slideY(begin: 0.1, end: 0),
        ],
      ),
    );
  }

  Widget _buildTypeRow(String label, int count, Color color) => Row(
    children: [
      Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: AppColors.textPrimaryLight,
          ),
        ),
      ),
      Text(
        '$count',
        style: GoogleFonts.poppins(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    ],
  );

  Widget _buildPieChart(
    int underweight,
    int stunting,
    int wasting,
    LocalizationController l10n,
  ) => Row(
    children: [
      SizedBox(
        width: 130,
        height: 130,
        child: PieChart(
          PieChartData(
            sectionsSpace: 3,
            centerSpaceRadius: 30,
            sections: [
              PieChartSectionData(
                value: underweight.toDouble(),
                color: const Color(0xFF3498DB),
                title: '',
                radius: 28,
              ),
              PieChartSectionData(
                value: stunting.toDouble(),
                color: const Color(0xFF9B59B6),
                title: '',
                radius: 28,
              ),
              PieChartSectionData(
                value: wasting.toDouble(),
                color: const Color(0xFFE67E22),
                title: '',
                radius: 28,
              ),
            ],
          ),
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeOutCubic,
        ),
      ),
      const SizedBox(width: 24),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTypeRow(
              l10n.tr('Underweight'),
              underweight,
              const Color(0xFF3498DB),
            ),
            const SizedBox(height: 14),
            _buildTypeRow(
              l10n.tr('Stunting'),
              stunting,
              const Color(0xFF9B59B6),
            ),
            const SizedBox(height: 14),
            _buildTypeRow(l10n.tr('Wasting'), wasting, const Color(0xFFE67E22)),
          ],
        ),
      ),
    ],
  );

  Widget _buildTypeDistribution(
    DashboardState state,
    LocalizationController l10n,
  ) {
    final stats = state.stats;
    final underweight = (stats['underweight'] ?? 0) as int;
    final stunting = (stats['stunting'] ?? 0) as int;
    final wasting = (stats['wasting'] ?? 0) as int;
    final total = underweight + stunting + wasting;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.tr('Malnutrition Types'),
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ).animate(delay: const Duration(milliseconds: 800)).fadeIn(),
          const SizedBox(height: 16),
          Container(
                padding: const EdgeInsets.all(20),
                decoration: GlassDecoration.card(),
                child: total == 0
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text(
                            l10n.tr('No data available'),
                            style: GoogleFonts.poppins(
                              color: AppColors.textSecondaryLight,
                            ),
                          ),
                        ),
                      )
                    : _buildPieChart(underweight, stunting, wasting, l10n),
              )
              .animate(delay: const Duration(milliseconds: 900))
              .fadeIn(duration: const Duration(milliseconds: 600))
              .slideY(begin: 0.1, end: 0),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dashboardControllerProvider);
    ref.watch(localizationProvider);
    final l10n = ref.read(localizationProvider.notifier);

    return Scaffold(
      body: SafeArea(
        child: state.viewState == ViewState.loading
            ? const Center(child: LoadingPulse())
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAppBar(l10n),
                    const SizedBox(height: 8),

                    _buildSummaryCards(state, l10n),
                    const SizedBox(height: 24),

                    _buildRegionChart(state, l10n),
                    const SizedBox(height: 24),

                    _buildTrendChart(state, l10n),
                    const SizedBox(height: 24),

                    _buildTypeDistribution(state, l10n),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
      ),
    );
  }
}
