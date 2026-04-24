import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../core/animations.dart';
import '../../controllers/assessment_controller.dart';
import '../../controllers/localization_controller.dart';
import '../../services/poshan_tracker_service.dart';

class GovernmentReportView extends ConsumerStatefulWidget {
  final bool isEmbedded;
  const GovernmentReportView({super.key, this.isEmbedded = false});

  @override
  ConsumerState<GovernmentReportView> createState() =>
      _GovernmentReportViewState();
}

class _GovernmentReportViewState extends ConsumerState<GovernmentReportView> {
  bool _isSubmitting = false;
  Map<String, dynamic>? _submissionResult;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(assessmentControllerProvider.notifier).loadAllHistory();
    });
  }

  Future<void> _submitToPoshan() async {
    setState(() => _isSubmitting = true);

    final state = ref.read(assessmentControllerProvider);
    final assessments = state.history;

    final samCount =
        assessments.where((a) => a.riskCategory == RiskCategory.high).length;
    final mamCount =
        assessments.where((a) => a.riskCategory == RiskCategory.moderate).length;
    final healthyCount =
        assessments.where((a) => a.riskCategory == RiskCategory.low).length;

    // Group by location
    final Map<String, List<dynamic>> byLocation = {};
    for (final a in assessments) {
      byLocation.putIfAbsent(a.location, () => []).add(a);
    }

    final locationBreakdown = byLocation.entries.map((e) {
      return {
        'location': e.key,
        'total': e.value.length,
        'sam': e.value.where((a) => a.riskCategory == RiskCategory.high).length,
        'mam': e.value.where((a) => a.riskCategory == RiskCategory.moderate).length,
      };
    }).toList();

    final report = PoshanTrackerService.formatReport(
      totalScreened: assessments.length,
      samCount: samCount,
      mamCount: mamCount,
      healthyCount: healthyCount,
      location: assessments.isNotEmpty ? assessments.first.location : 'N/A',
      locationBreakdown: locationBreakdown,
    );

    final result = await PoshanTrackerService.submitReport(report);

    setState(() {
      _isSubmitting = false;
      _submissionResult = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(localizationProvider);
    final l10n = ref.read(localizationProvider.notifier);
    final state = ref.watch(assessmentControllerProvider);
    final assessments = state.history;

    final samCount =
        assessments.where((a) => a.riskCategory == RiskCategory.high).length;
    final mamCount =
        assessments.where((a) => a.riskCategory == RiskCategory.moderate).length;
    final healthyCount =
        assessments.where((a) => a.riskCategory == RiskCategory.low).length;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top bar
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                          child: const Icon(Icons.arrow_back_ios_new_rounded,
                              size: 18),
                        ),
                      ),
                      const SizedBox(width: 16),
                    ],
                    Text(
                      l10n.tr('Government Reports'),
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),



              // Poshan Tracker header card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1565C0).withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.account_balance_rounded,
                                color: Colors.white, size: 24),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.tr('Poshan Tracker (ICDS)'),
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  l10n.tr('Integrated Child Development Services'),
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    color: Colors.white.withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.tr('Automatically format and submit nutrition screening data to the Government\'s Poshan Tracker portal.'),
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.8),
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              )
                  .animate(delay: const Duration(milliseconds: 200))
                  .fadeIn()
                  .slideY(begin: 0.15, end: 0),

              const SizedBox(height: 24),

              // Summary stats
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  l10n.tr('Current Period Summary'),
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    _buildStatCard(l10n.tr('Total'), '${assessments.length}',
                        AppColors.primary, 0),
                    const SizedBox(width: 10),
                    _buildStatCard(
                        l10n.tr('SAM'), '$samCount', AppColors.severe, 1),
                    const SizedBox(width: 10),
                    _buildStatCard(
                        l10n.tr('MAM'), '$mamCount', AppColors.atRisk, 2),
                    const SizedBox(width: 10),
                    _buildStatCard(
                        l10n.tr('Normal'), '$healthyCount', AppColors.healthy, 3),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Location breakdown table
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  l10n.tr('Location-wise Breakdown'),
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              _buildLocationTable(assessments, l10n),

              const SizedBox(height: 24),

              // Action buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    // Submit to Poshan Tracker
                    TapScaleWrapper(
                      onTap: _isSubmitting ? null : _submitToPoshan,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF1565C0)
                                  .withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: _isSubmitting
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                        Icons.cloud_upload_rounded,
                                        color: Colors.white,
                                        size: 20),
                                    const SizedBox(width: 10),
                                      Text(
                                        l10n.tr('Submit to Poshan Tracker'),
                                        style: GoogleFonts.poppins(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                  ],
                                ),
                        ),
                      ),
                    )
                        .animate(delay: const Duration(milliseconds: 600))
                        .fadeIn()
                        .slideY(begin: 0.1, end: 0),
                  ],
                ),
              ),

              // Submission result
              if (_submissionResult != null) _buildSubmissionResult(l10n),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
      String label, String value, Color color, int index) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      )
          .animate(delay: Duration(milliseconds: 300 + index * 80))
          .fadeIn()
          .scaleXY(begin: 0.85, end: 1, curve: Curves.easeOutBack),
    );
  }

  Widget _buildLocationTable(List assessments, LocalizationController l10n) {
    final Map<String, Map<String, int>> grouped = {};
    for (final a in assessments) {
      final v = a.location as String;
      grouped.putIfAbsent(v, () => {'total': 0, 'sam': 0, 'mam': 0, 'normal': 0});
      grouped[v]!['total'] = grouped[v]!['total']! + 1;
      if (a.riskCategory == RiskCategory.high) {
        grouped[v]!['sam'] = grouped[v]!['sam']! + 1;
      } else if (a.riskCategory == RiskCategory.moderate) {
        grouped[v]!['mam'] = grouped[v]!['mam']! + 1;
      } else {
        grouped[v]!['normal'] = grouped[v]!['normal']! + 1;
      }
    }

    if (grouped.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Text(
          l10n.tr('No screening data available'),
          style: GoogleFonts.poppins(color: AppColors.textSecondaryLight),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: GlassDecoration.card(),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Table(
            columnWidths: const {
              0: FlexColumnWidth(2),
              1: FlexColumnWidth(1),
              2: FlexColumnWidth(1),
              3: FlexColumnWidth(1),
              4: FlexColumnWidth(1),
            },
            children: [
              TableRow(
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                ),
                children: [
                  _headerCell(l10n.tr('Location')),
                  _headerCell(l10n.tr('Total')),
                  _headerCell(l10n.tr('SAM')),
                  _headerCell(l10n.tr('MAM')),
                  _headerCell(l10n.tr('OK')),
                ],
              ),
              ...grouped.entries.map((e) {
                return TableRow(
                  children: [
                    _dataCell(e.key),
                    _dataCell('${e.value['total']}'),
                    _dataCell('${e.value['sam']}',
                        color: AppColors.severe),
                    _dataCell('${e.value['mam']}',
                        color: AppColors.atRisk),
                    _dataCell('${e.value['normal']}',
                        color: AppColors.healthy),
                  ],
                );
              }),
            ],
          ),
        ),
      ),
    )
        .animate(delay: const Duration(milliseconds: 500))
        .fadeIn()
        .slideY(begin: 0.1, end: 0);
  }

  Widget _headerCell(String text) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _dataCell(String text, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: color ?? AppColors.textPrimaryLight,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildSubmissionResult(LocalizationController l10n) {
    final result = _submissionResult!;
    final success = result['success'] == true;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: success
              ? AppColors.healthy.withValues(alpha: 0.08)
              : AppColors.error.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: success
                ? AppColors.healthy.withValues(alpha: 0.3)
                : AppColors.error.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  success
                      ? Icons.check_circle_rounded
                      : Icons.error_rounded,
                  color: success ? AppColors.healthy : AppColors.error,
                  size: 24,
                ),
                const SizedBox(width: 10),
                Text(
                  success ? l10n.tr('Submission Successful') : l10n.tr('Submission Failed'),
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color:
                        success ? AppColors.healthy : AppColors.error,
                  ),
                ),
              ],
            ),
            if (success) ...[
              const SizedBox(height: 12),
              _resultRow(l10n.tr('Reference ID'), result['referenceId'] ?? ''),
              _resultRow(l10n.tr('Status'), result['status'] ?? ''),
              const SizedBox(height: 8),
              Text(
                result['message'] ?? '',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppColors.textSecondaryLight,
                ),
              ),
            ],
          ],
        ),
      ),
    )
        .animate()
        .fadeIn()
        .scaleXY(begin: 0.95, end: 1, curve: Curves.easeOutBack);
  }

  Widget _resultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppColors.textSecondaryLight,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
