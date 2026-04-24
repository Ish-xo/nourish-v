// ============================================================
// assessment_detail_view.dart — Assessment History Detail
// Updated: Phase 4 — TFLite Risk System
//
// Shows a full read-only view of a past assessment.
// Uses the new Assessment schema (riskCategory, DDS, illness, etc.)
// No imageUrl, no Z-scores, no nutritionPlan fields.
// ============================================================

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../core/animations.dart';
import '../../models/assessment.dart';
import '../../controllers/localization_controller.dart';

class AssessmentDetailView extends ConsumerWidget {
  final Assessment assessment;

  const AssessmentDetailView({super.key, required this.assessment});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(localizationProvider);
    final l10n = ref.read(localizationProvider.notifier);

    final a = assessment;
    Color riskColor;
    IconData riskIcon;

    switch (a.riskCategory) {
      case RiskCategory.low:
        riskColor = AppColors.healthy;
        riskIcon = Icons.check_circle_rounded;
        break;
      case RiskCategory.moderate:
        riskColor = AppColors.atRisk;
        riskIcon = Icons.warning_rounded;
        break;
      case RiskCategory.high:
        riskColor = AppColors.severe;
        riskIcon = Icons.error_rounded;
        break;
    }

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              riskColor.withValues(alpha: 0.12),
              AppColors.scaffoldLight,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ---- Top Bar ----
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      TapScaleWrapper(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                              Icons.arrow_back_ios_new_rounded, size: 18),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        l10n.tr('Assessment Details'),
                        style: GoogleFonts.poppins(
                            fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                      const Spacer(),
                      const SizedBox(width: 40),
                    ],
                  ),
                ).animate().fadeIn(),

                // ---- Risk Hero Card ----
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          riskColor.withValues(alpha: 0.15),
                          riskColor.withValues(alpha: 0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                          color: riskColor.withValues(alpha: 0.3), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: riskColor.withValues(alpha: 0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Small ring
                        SizedBox(
                          width: 120,
                          height: 120,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: 120,
                                height: 120,
                                child: CircularProgressIndicator(
                                  value: 1.0,
                                  strokeWidth: 12,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      riskColor.withValues(alpha: 0.12)),
                                ),
                              ),
                              SizedBox(
                                width: 120,
                                height: 120,
                                child: CustomPaint(
                                  painter: _MiniArcPainter(
                                    value: a.futureRiskProbability,
                                    color: riskColor,
                                  ),
                                ),
                              ),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    a.riskPercentage,
                                    style: GoogleFonts.poppins(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w800,
                                      color: riskColor,
                                      height: 1.1,
                                    ),
                                  ),
                                  Text(
                                    l10n.tr('Risk'),
                                    style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      color: AppColors.textSecondaryLight,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        )
                            .animate()
                            .scale(
                                begin: const Offset(0.6, 0.6),
                                duration: const Duration(milliseconds: 600),
                                curve: Curves.easeOutBack)
                            .fadeIn(),
                        const SizedBox(height: 16),
                        Text(
                          l10n.tr(a.riskLabel),
                          style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: riskColor,
                          ),
                        )
                            .animate(delay: const Duration(milliseconds: 200))
                            .fadeIn()
                            .slideY(begin: 0.2, end: 0),
                        const SizedBox(height: 4),
                        Text(
                          a.patientName,
                          style: GoogleFonts.poppins(
                              fontSize: 15,
                              color: AppColors.textPrimaryLight,
                              fontWeight: FontWeight.w500),
                        )
                            .animate(delay: const Duration(milliseconds: 300))
                            .fadeIn(),
                        Text(
                          a.location,
                          style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: AppColors.textSecondaryLight),
                        )
                            .animate(delay: const Duration(milliseconds: 350))
                            .fadeIn(),
                        const SizedBox(height: 6),
                        Text(
                          DateFormat('dd MMM yyyy, HH:mm')
                              .format(a.assessmentDate),
                          style: GoogleFonts.poppins(
                              fontSize: 12,
                              color:
                                  AppColors.textSecondaryLight.withValues(alpha: 0.7)),
                        )
                            .animate(delay: const Duration(milliseconds: 380))
                            .fadeIn(),
                      ],
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(duration: const Duration(milliseconds: 600))
                    .slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic),

                const SizedBox(height: 24),

                // ---- Diet & Feeding ----
                _section(
                  context,
                  l10n,
                  title: l10n.tr('Feeding & Diet'),
                  delay: 500,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _infoRow(l10n.tr('Feeding Frequency'),
                          '${a.feedingFrequency}× per day'),
                      _infoRow(l10n.tr('Dietary Diversity Score'),
                          '${a.dietaryDiversityScore}/7 food groups'),
                      _infoRow(l10n.tr('Junk Food'),
                          '${a.junkFoodFrequency} days/week'),
                      _infoRow(l10n.tr('Exclusive Breastfeeding'),
                          a.exclusiveBreastfeeding
                              ? l10n.tr('Yes')
                              : l10n.tr('No')),
                      _infoRow(l10n.tr('Bottle Feeding'),
                          a.bottleFeeding ? l10n.tr('Yes') : l10n.tr('No')),
                      const SizedBox(height: 8),
                      Text(l10n.tr('Food groups consumed:'),
                          style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: AppColors.textSecondaryLight)),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: List.generate(
                          kDietaryFoodGroups.length,
                          (i) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: a.dietaryDiversity[i]
                                  ? AppColors.healthy.withValues(alpha: 0.12)
                                  : AppColors.divider.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: a.dietaryDiversity[i]
                                    ? AppColors.healthy.withValues(alpha: 0.3)
                                    : AppColors.divider.withValues(alpha: 0.5),
                              ),
                            ),
                            child: Text(
                              kDietaryFoodGroups[i],
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: a.dietaryDiversity[i]
                                    ? AppColors.healthy
                                    : AppColors.textSecondaryLight,
                                fontWeight: a.dietaryDiversity[i]
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ---- Illness & Care ----
                _section(
                  context,
                  l10n,
                  title: l10n.tr('Illness & Preventive Care'),
                  delay: 600,
                  child: Column(
                    children: [
                      _infoRow(
                        l10n.tr('Illness (last 2 weeks)'),
                        '${a.recentIllnessDays} days',
                        valueColor: a.recentIllnessDays > 7
                            ? AppColors.severe
                            : a.recentIllnessDays > 3
                                ? AppColors.atRisk
                                : null,
                      ),
                      _infoRow(
                        l10n.tr('Micronutrient Supplements'),
                        a.micronutrientSupplements
                            ? l10n.tr('Yes ✓')
                            : l10n.tr('No'),
                        valueColor: a.micronutrientSupplements
                            ? AppColors.healthy
                            : null,
                      ),
                      _infoRow(
                        l10n.tr('Vaccination Status'),
                        a.vaccinationStatus == 2
                            ? l10n.tr('Fully Vaccinated ✓')
                            : a.vaccinationStatus == 1
                                ? l10n.tr('Partially Vaccinated')
                                : l10n.tr('Not Vaccinated'),
                        valueColor:
                            a.vaccinationStatus == 2 ? AppColors.healthy
                            : a.vaccinationStatus == 1 ? AppColors.atRisk
                            : AppColors.severe,
                      ),
                      _infoRow(
                        l10n.tr('Deworming'),
                        a.dewormingHistory ? l10n.tr('Yes ✓') : l10n.tr('No'),
                        valueColor:
                            a.dewormingHistory ? AppColors.healthy : null,
                      ),
                    ],
                  ),
                ),

                // ---- Recommendations ----
                const SizedBox(height: 12),
                _buildRecommendations(context, a, l10n),

                // ---- Referral (high risk) ----
                if (a.riskCategory == RiskCategory.high)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 8),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.severe.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: AppColors.severe.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.local_hospital_rounded,
                              color: AppColors.severe, size: 22),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              l10n.tr(
                                  'Urgent: Medical referral required for this child. Contact the nearest PHC.'),
                              style: GoogleFonts.poppins(
                                  fontSize: 13, color: AppColors.severe),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                      .animate(delay: const Duration(milliseconds: 700))
                      .fadeIn()
                      .shake(hz: 3, offset: const Offset(2, 0)),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _section(
    BuildContext context,
    LocalizationController l10n, {
    required String title,
    required Widget child,
    int delay = 0,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
                fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: GlassDecoration.card(),
            child: child,
          ),
        ],
      ),
    )
        .animate(delay: Duration(milliseconds: delay))
        .fadeIn(duration: const Duration(milliseconds: 400))
        .slideY(begin: 0.06, end: 0);
  }

  Widget _infoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                  fontSize: 12, color: AppColors.textSecondaryLight),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: valueColor ?? AppColors.textPrimaryLight,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // NUTRITIONAL RECOMMENDATIONS
  // ============================================================

  Widget _buildRecommendations(
      BuildContext context, Assessment assessment, LocalizationController l10n) {
      
    List<String> recs = [];
    switch (assessment.riskCategory) {
      case RiskCategory.low:
        recs = [
          'Continue current feeding practices',
          'Maintain regular weight monitoring',
          'Ensure up-to-date vaccinations',
        ];
        break;
      case RiskCategory.moderate:
        recs = [
          'Increase feeding frequency to 4-5 times a day',
          'Add calorie-dense foods (ghee, extra oil, nuts)',
          'Follow up in 14 days',
          'Check for hidden infections or diarrhea',
        ];
        break;
      case RiskCategory.high:
        recs = [
          'Immediate referral to nearest PHC/NRC',
          'Provide ORS if diarrhea is present',
          'Counsel mother on urgent danger signs',
          'Active daily follow-up by ASHA',
        ];
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.tr('Recommended Actions'),
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ).animate(delay: const Duration(milliseconds: 700)).fadeIn(),
          const SizedBox(height: 12),
          ...List.generate(
            recs.length,
            (index) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color ?? AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.divider),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.tr(recs[index]),
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        height: 1.5,
                        color: AppColors.textPrimaryLight,
                      ),
                    ),
                  ),
                ],
              ),
            )
                .animate(
                    delay: Duration(milliseconds: 800 + (index * 80)))
                .fadeIn(duration: const Duration(milliseconds: 400))
                .slideX(begin: 0.1, end: 0),
          ),
        ],
      ),
    );
  }
}

// ---- Mini Arc Painter (static — no animation controller needed for history view) ----

class _MiniArcPainter extends CustomPainter {
  final double value;
  final Color color;

  _MiniArcPainter({required this.value, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(6, 6, size.width - 12, size.height - 12);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, -math.pi / 2, math.pi * 2 * value, false, paint);
  }

  @override
  bool shouldRepaint(_MiniArcPainter old) => old.value != value;
}
