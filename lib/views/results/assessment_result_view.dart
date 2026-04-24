// ============================================================
// assessment_result_view.dart — Risk Probability Result Screen
// Updated: Phase 4 — TFLite Predictive Risk System
//
// REPLACES: Z-score classification ring
// NEW:     Animated Risk Probability Ring (0–100%)
//
// COLOR CODING:
//   < 30%  — Green    — Low risk
//   30–60% — Yellow   — Moderate risk (MAM likely)
//   > 60%  — Red      — High risk (SAM likely)
//
// SECTIONS:
//   1. Risk probability ring (large, animated)
//   2. Risk context string + label
//   3. Top contributing risk factors
//   4. Nutrition recommendations (risk-adapted)
//   5. Referral alert (for high-risk cases)
//   6. Action buttons (New Assessment / Home)
// ============================================================

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../core/animations.dart';
import '../../controllers/localization_controller.dart';
import '../../models/assessment.dart';

class AssessmentResultView extends ConsumerStatefulWidget {
  final Assessment assessment;

  const AssessmentResultView({super.key, required this.assessment});

  @override
  ConsumerState<AssessmentResultView> createState() =>
      _AssessmentResultViewState();
}

class _AssessmentResultViewState extends ConsumerState<AssessmentResultView>
    with SingleTickerProviderStateMixin {
  late AnimationController _ringController;
  late Animation<double> _ringAnimation;

  @override
  void initState() {
    super.initState();
    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _ringAnimation = Tween<double>(
      begin: 0.0,
      end: widget.assessment.futureRiskProbability,
    ).animate(CurvedAnimation(
      parent: _ringController,
      curve: Curves.easeOutCubic,
    ));
    // Start animation after a short delay for entrance UX
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _ringController.forward();
    });
  }

  @override
  void dispose() {
    _ringController.dispose();
    super.dispose();
  }

  Color get _riskColor {
    switch (widget.assessment.riskCategory) {
      case RiskCategory.low:
        return AppColors.healthy;
      case RiskCategory.moderate:
        return AppColors.atRisk;
      case RiskCategory.high:
        return AppColors.severe;
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(localizationProvider);
    final l10n = ref.read(localizationProvider.notifier);
    final a = widget.assessment;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ---- Header ----
              Row(
                children: [
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
                  Text(
                    l10n.tr('Risk Assessment Result'),
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ).animate().fadeIn(duration: const Duration(milliseconds: 400)),

              const SizedBox(height: 8),
              Center(
                child: Text(
                  a.patientName,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: AppColors.textSecondaryLight,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ).animate().fadeIn(delay: const Duration(milliseconds: 200)),

              const SizedBox(height: 32),

              // ---- Risk Probability Ring ----
              Center(
                child: AnimatedBuilder(
                  animation: _ringAnimation,
                  builder: (context, _) {
                    return _buildRiskRing(
                        context, _ringAnimation.value, l10n);
                  },
                ),
              ).animate().scale(
                  begin: const Offset(0.7, 0.7),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOutBack).fadeIn(),

              const SizedBox(height: 24),

              // ---- Risk context string ----
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: _riskColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: _riskColor.withValues(alpha: 0.2)),
                  ),
                  child: Text(
                    l10n.tr(a.riskContextString),
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _riskColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
                  .animate(delay: const Duration(milliseconds: 500))
                  .fadeIn()
                  .slideY(begin: 0.1, end: 0),

              const SizedBox(height: 28),

              // ---- Contributing Factors ----
              Text(
                l10n.tr('Key Risk Factors'),
                style: GoogleFonts.poppins(
                    fontSize: 17, fontWeight: FontWeight.w700),
              ).animate(delay: const Duration(milliseconds: 600)).fadeIn(),
              const SizedBox(height: 12),
              _buildRiskFactors(context, a, l10n),

              const SizedBox(height: 28),

              // ---- Recommendations ----
              _buildRecommendations(context, a, l10n),

              // ---- High-risk referral alert ----
              if (a.riskCategory == RiskCategory.high) ...[
                const SizedBox(height: 20),
                _buildReferralAlert(context, l10n),
              ],

              const SizedBox(height: 32),

              // ---- Action buttons ----
              _buildActionButtons(context, l10n),
              const SizedBox(height: 24),
            ],
          ),
        ),
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

  // ============================================================
  // RISK RING
  // ============================================================

  Widget _buildRiskRing(BuildContext context, double animatedValue,
      LocalizationController l10n) {
    final pct = (animatedValue * 100).round();
    final ringColor = animatedValue < RiskThresholds.lowMax
        ? AppColors.healthy
        : animatedValue < RiskThresholds.moderateMax
            ? AppColors.atRisk
            : AppColors.severe;

    return SizedBox(
      width: 220,
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer glow ring
          Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: ringColor.withValues(alpha: 0.15),
                  blurRadius: 40,
                  spreadRadius: 10,
                ),
              ],
            ),
          ),
          // Background track
          SizedBox(
            width: 200,
            height: 200,
            child: CircularProgressIndicator(
              value: 1.0,
              strokeWidth: 16,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(
                  ringColor.withValues(alpha: 0.12)),
            ),
          ),
          // Animated risk arc
          SizedBox(
            width: 200,
            height: 200,
            child: CustomPaint(
              painter: _RiskArcPainter(
                value: animatedValue,
                color: ringColor,
                strokeWidth: 16,
              ),
            ),
          ),
          // Center content
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$pct%',
                style: GoogleFonts.poppins(
                  fontSize: 40,
                  fontWeight: FontWeight.w800,
                  color: ringColor,
                  height: 1.0,
                ),
              ),
              Text(
                l10n.tr('Risk'),
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: AppColors.textSecondaryLight,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: ringColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  l10n.tr(widget.assessment.riskLabel),
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: ringColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // RISK FACTORS CARDS
  // ============================================================

  Widget _buildRiskFactors(BuildContext context, Assessment a,
      LocalizationController l10n) {
    final factors = <_RiskFactor>[];

    // Dietary diversity
    final dds = a.dietaryDiversityScore;
    if (dds < 5) {
      factors.add(_RiskFactor(
        label: l10n.tr('Low Dietary Diversity'),
        detail: '$dds/7 ${l10n.tr('food groups')}',
        color: dds <= 2 ? AppColors.severe : AppColors.atRisk,
        icon: Icons.food_bank_outlined,
        severity: dds <= 2 ? 'Critical' : 'Moderate',
      ));
    }

    // Illness
    if (a.recentIllnessDays > 3) {
      factors.add(_RiskFactor(
        label: l10n.tr('Recent Illness'),
        detail:
            '${a.recentIllnessDays} ${l10n.tr('days sick in past 2 weeks')}',
        color: a.recentIllnessDays > 7 ? AppColors.severe : AppColors.atRisk,
        icon: Icons.sick_outlined,
        severity: a.recentIllnessDays > 7 ? 'Critical' : 'Moderate',
      ));
    }

    // Not vaccinated
    if (a.vaccinationStatus == 0) {
      factors.add(_RiskFactor(
        label: l10n.tr('Vaccination Gap'),
        detail: l10n.tr('Immunisation schedule incomplete'),
        color: AppColors.atRisk,
        icon: Icons.vaccines_outlined,
        severity: 'Moderate',
      ));
    }

    if (factors.isEmpty) {
      factors.add(_RiskFactor(
        label: l10n.tr('No Major Risk Factors Detected'),
        detail: l10n.tr('Continue current feeding and care practices'),
        color: AppColors.healthy,
        icon: Icons.check_circle_outline_rounded,
        severity: 'Low',
      ));
    }

    return Column(
      children: factors
          .asMap()
          .entries
          .map((e) => _buildFactorCard(e.value, e.key, l10n))
          .toList(),
    );
  }

  Widget _buildFactorCard(
      _RiskFactor factor, int index, LocalizationController l10n) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: factor.color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: factor.color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: factor.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(factor.icon, color: factor.color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  factor.label,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  factor.detail,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: factor.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              l10n.tr(factor.severity),
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: factor.color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    )
        .animate(
          delay: CascadeAnimationHelper.cascadeDelay(index, baseMs: 100) +
              const Duration(milliseconds: 600),
        )
        .fadeIn()
        .slideX(begin: 0.05, end: 0);
  }

  // ============================================================
  // REFERRAL ALERT (High risk only)
  // ============================================================

  Widget _buildReferralAlert(
      BuildContext context, LocalizationController l10n) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.severe.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: AppColors.severe.withValues(alpha: 0.4), width: 2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_rounded,
              color: AppColors.severe, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.tr('Medical Referral Required'),
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.severe,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.tr(
                      'This child is at high risk of severe malnutrition. Begin the referral process to the nearest PHC immediately. Do not wait for the next scheduled visit.'),
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.severe,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    )
        .animate(delay: const Duration(milliseconds: 900))
        .fadeIn()
        .scale(begin: const Offset(0.97, 0.97), end: const Offset(1, 1));
  }

  // ============================================================
  // ACTION BUTTONS
  // ============================================================

  Widget _buildActionButtons(
      BuildContext context, LocalizationController l10n) {
    return Row(
      children: [
        Expanded(
          child: TapScaleWrapper(
            onTap: () =>
                Navigator.pushNamedAndRemoveUntil(
                    context, '/home', (route) => false),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.divider),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  l10n.tr('Go to Roster'),
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondaryLight,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: TapScaleWrapper(
            onTap: () => Navigator.pushNamedAndRemoveUntil(
                context, '/home', (route) => false),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDark]),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  l10n.tr('Done'),
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    )
        .animate(delay: const Duration(milliseconds: 800))
        .fadeIn()
        .slideY(begin: 0.1, end: 0);
  }
}

// ============================================================
// DATA CLASSES
// ============================================================

class _RiskFactor {
  final String label;
  final String detail;
  final Color color;
  final IconData icon;
  final String severity;

  _RiskFactor({
    required this.label,
    required this.detail,
    required this.color,
    required this.icon,
    required this.severity,
  });
}


// ============================================================
// CUSTOM PAINTER: Risk Arc
// ============================================================

class _RiskArcPainter extends CustomPainter {
  final double value;
  final Color color;
  final double strokeWidth;

  _RiskArcPainter({
    required this.value,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(
        strokeWidth / 2,
        strokeWidth / 2,
        size.width - strokeWidth,
        size.height - strokeWidth);

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Draw the colored arc from -90° (top) to value * 360°
    canvas.drawArc(
      rect,
      -math.pi / 2, // Start at top
      math.pi * 2 * value, // Sweep angle proportional to risk
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_RiskArcPainter old) =>
      old.value != value || old.color != color;
}
