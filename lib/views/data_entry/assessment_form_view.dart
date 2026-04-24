// ============================================================
// assessment_form_view.dart — Monthly Checkup Form
// Phase 4: TFLite Risk System — NEW VIEW
//
// PURPOSE: Collect ROUTINE DYNAMIC data for a monthly checkup.
// This form is shown when a worker taps a patient card on the
// Home Roster.
//
// 3-STEP FLOW:
//   Step 1: Patient Review (Pre-fill Pattern — read-only baseline)
//   Step 2: Current Measurements & Feeding & Dietary Recall
//   Step 3: Analysis — loading spinner → transitions to ResultView
//
// KEY SMART UI RULES:
//   - If child < 6 months AND exclusiveBreastfeeding=true:
//     auto-hide all solid food + diversity questions
//   - MUAC field only shown for children 6–59 months
//   - All booleans: SwitchListTile
//   - Diet recall: 7 FilterChip food groups
//   - Illness: Slider 0–14
//   - Junk food: Slider 0–7
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../core/animations.dart';
import '../../controllers/assessment_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/localization_controller.dart';
import '../../models/patient.dart';
import '../../models/assessment.dart';

class AssessmentFormView extends ConsumerStatefulWidget {
  final Patient patient;

  const AssessmentFormView({super.key, required this.patient});

  @override
  ConsumerState<AssessmentFormView> createState() =>
      _AssessmentFormViewState();
}

class _AssessmentFormViewState extends ConsumerState<AssessmentFormView> {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;

  // ---- Feeding ----
  bool _exclusiveBreastfeeding = false;
  bool _bottleFeeding = false;
  int _feedingFrequency = 3;

  // ---- Dietary recall: 7 food groups ----
  final List<bool> _dietaryDiversity = List.filled(7, false);

  double _maternalDietScore = 0;
  final _maternalCalorieController = TextEditingController(text: '1800');
  int _proteinIntakeLevel = 0;
  final _mealCalorieController = TextEditingController(text: '250');

  // ---- Supplements & Junk ----
  bool _micronutrientSupplements = false;
  double _junkFoodFrequency = 0;

  // ---- Illness ----
  double _recentIllnessDays = 0;
  bool _recentWeightLoss = false;
  bool _recentDiarrhea = false;
  bool _recentFever = false;

  // ---- Preventive Care ----
  int _vaccinationStatus = 0;
  bool _dewormingHistory = false;

  bool _isSubmitting = false;

  // Smart UI: infant ≤ 6 months EBF → hide solid food questions
  bool get _isInfantEBF =>
      widget.patient.ageInMonths <= 6 && _exclusiveBreastfeeding;

  @override
  void dispose() {
    _maternalCalorieController.dispose();
    _mealCalorieController.dispose();
    super.dispose();
  }

  void _handleNext() {
    if (_currentStep == 0) {
      setState(() => _currentStep = 1);
    } else if (_currentStep == 1) {
      if (_formKey.currentState!.validate()) {
        _submitAssessment();
      }
    }
  }

  Future<void> _submitAssessment() async {
    setState(() {
      _currentStep = 2; // Show loading step
      _isSubmitting = true;
    });

    final authState = ref.read(authControllerProvider);
    if (authState.user == null) {
      setState(() {
        _currentStep = 1;
        _isSubmitting = false;
      });
      return;
    }

    // Build raw assessment (risk = 0 until TFLite runs)
    final rawAssessment = Assessment(
      patientId: widget.patient.id,
      patientName: widget.patient.name,
      workerUid: authState.user!.uid,
      location: widget.patient.location,
      exclusiveBreastfeeding: _exclusiveBreastfeeding,
      bottleFeeding: _bottleFeeding,
      feedingFrequency: _feedingFrequency,
      dietaryDiversity: _isInfantEBF
          ? List.filled(7, true) // Assume full diversity if EBF (max DDS)
          : List<bool>.from(_dietaryDiversity),
      maternalDietScore: _maternalDietScore.round(),
      maternalCalorieIntake: int.tryParse(_maternalCalorieController.text) ?? 1800,
      proteinIntakeLevel: _proteinIntakeLevel,
      caloriePerMeal: int.tryParse(_mealCalorieController.text) ?? 250,
      micronutrientSupplements: _micronutrientSupplements,
      junkFoodFrequency: _junkFoodFrequency.round(),
      recentIllnessDays: _recentIllnessDays.round(),
      recentWeightLoss: _recentWeightLoss,
      recentDiarrhea: _recentDiarrhea,
      recentFever: _recentFever,
      vaccinationStatus: _vaccinationStatus,
      dewormingHistory: _dewormingHistory,
    );

    await ref.read(assessmentControllerProvider.notifier).submitAssessment(
          rawAssessment: rawAssessment,
          patient: widget.patient,
          worker: authState.user!,
        );

    if (!mounted) return;

    final state = ref.read(assessmentControllerProvider);
    if (state.viewState == ViewState.success &&
        state.currentAssessment != null) {
      // Navigate to result view, pushing it so Back goes to roster
      Navigator.pushReplacementNamed(
        context,
        '/assessment-result',
        arguments: state.currentAssessment,
      );
    } else {
      // Error: go back to step 2
      setState(() {
        _currentStep = 1;
        _isSubmitting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.errorMessage ?? 'Assessment failed'),
          backgroundColor: AppColors.severe,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(localizationProvider);
    final l10n = ref.read(localizationProvider.notifier);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // ---- App bar ----
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  if (_currentStep < 2)
                    TapScaleWrapper(
                      onTap: () {
                        if (_currentStep > 0) {
                          setState(() => _currentStep--);
                        } else {
                          Navigator.pop(context);
                        }
                      },
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
                    )
                  else
                    const SizedBox(width: 40),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      _currentStep == 0
                          ? l10n.tr('Monthly Checkup')
                          : _currentStep == 1
                              ? l10n.tr('Health Assessment')
                              : l10n.tr('Analysing...'),
                      style: GoogleFonts.poppins(
                          fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                  ),
                  if (_currentStep < 2)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_currentStep + 1}/2',
                        style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                ],
              ),
            ),

            // ---- Patient chip ----
            if (_currentStep < 2) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.15)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.child_care_rounded,
                          color: AppColors.primary, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        '${widget.patient.name} • ${widget.patient.ageDisplay}',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ---- Step content ----
            Expanded(
              child: Form(
                key: _formKey,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  transitionBuilder: (child, anim) => FadeTransition(
                    opacity: anim,
                    child: SlideTransition(
                      position: Tween<Offset>(
                              begin: const Offset(0.06, 0), end: Offset.zero)
                          .animate(anim),
                      child: child,
                    ),
                  ),
                  child: _currentStep == 0
                      ? _buildStep1Review(l10n)
                      : _currentStep == 1
                          ? _buildStep2Form(l10n)
                          : _buildStep3Loading(l10n),
                ),
              ),
            ),

            // ---- Bottom button (Steps 0 & 1 only) ----
            if (_currentStep < 2)
              Padding(
                padding: const EdgeInsets.all(20),
                child: TapScaleWrapper(
                  onTap: _handleNext,
                  child: Container(
                    width: double.infinity,
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
                        _currentStep == 0
                            ? l10n.tr('Confirm & Start Checkup')
                            : l10n.tr('Submit & Analyse Risk'),
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // STEP 1: Pre-fill Review (Read-only patient baseline)
  // ============================================================

  Widget _buildStep1Review(LocalizationController l10n) {
    final p = widget.patient;
    return SingleChildScrollView(
      key: const ValueKey('review'),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.tr('Please confirm the child\'s registered information before proceeding.'),
            style: GoogleFonts.poppins(
                fontSize: 13, color: AppColors.textSecondaryLight),
          ),
          const SizedBox(height: 16),

          _reviewSection(l10n.tr('Birth & Background'), [
            _reviewRow(l10n.tr('Age'), p.ageDisplay),
            _reviewRow(l10n.tr('Gender'),
                p.gender == 'M' ? l10n.tr('Male') : l10n.tr('Female')),
            _reviewRow(l10n.tr('Birth Weight'),
                p.birthWeightKg != null
                    ? '${p.birthWeightKg!.toStringAsFixed(2)} kg'
                    : l10n.tr('Not recorded')),
            _reviewRow(l10n.tr('Preterm'), p.isPreterm ? l10n.tr('Yes') : l10n.tr('No')),
          ]),
          const SizedBox(height: 12),

          _reviewSection(l10n.tr("Mother's Profile"), [
            _reviewRow(l10n.tr('Age'), p.motherAge != null
                ? '${p.motherAge} years' : l10n.tr('Not recorded')),
            _reviewRow(l10n.tr('Education'), p.motherEducation.displayName),
            _reviewRow(l10n.tr('Anaemia'),
                p.motherHadAnemia ? l10n.tr('History of anaemia') : l10n.tr('None')),
          ]),
          const SizedBox(height: 12),

          _reviewSection(l10n.tr('Household & WASH'), [
            _reviewRow(l10n.tr('Sanitation'), p.sanitationType.displayName),
            _reviewRow(l10n.tr('Water Source'), p.waterSource.displayName),
            _reviewRow(l10n.tr('Food Security'), p.foodSecurityStatus.displayName),
            _reviewRow(l10n.tr('Family Size'),
                p.familySize != null ? '${p.familySize} persons' : l10n.tr('Not recorded')),
          ]),

          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.atRisk.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: AppColors.atRisk.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded,
                    color: AppColors.atRisk, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.tr('If any information above is incorrect, please update the child\'s profile before continuing.'),
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: AppColors.atRisk),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TapScaleWrapper(
            onTap: () {
              Navigator.pushNamed(context, '/data-entry', arguments: widget.patient);
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.primary),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.edit_rounded, color: AppColors.primary, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      l10n.tr('Edit Child Profile'),
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _reviewSection(String title, List<Widget> rows) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: GlassDecoration.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
                fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          ...rows,
        ],
      ),
    )
        .animate(delay: const Duration(milliseconds: 100))
        .fadeIn()
        .slideY(begin: 0.05, end: 0);
  }

  Widget _reviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
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
                fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STEP 2: Measurements & Feeding & Diet Recall
  // ============================================================

  Widget _buildStep2Form(LocalizationController l10n) {
    return SingleChildScrollView(
      key: const ValueKey('form'),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),

          // ---- Feeding ----
          _sectionHeader(l10n.tr("Child's Feeding"), Icons.baby_changing_station_rounded),
          const SizedBox(height: 8),

          // EBF switch (only for ≤ 6 months)
          if (widget.patient.ageInMonths <= 6) ...[
            _buildSwitch(
              title: l10n.tr('Exclusively Breastfed'),
              subtitle: l10n.tr('No water, formula, or solids — breast milk only'),
              value: _exclusiveBreastfeeding,
              onChanged: (v) => setState(() => _exclusiveBreastfeeding = v),
              delay: 200,
            ),
          ],

          // Smart UI: if EBF + ≤6 months → hide solid food questions
          if (!_isInfantEBF) ...[
            _buildSwitch(
              title: l10n.tr('Bottle Feeding'),
              subtitle: l10n.tr('Does the child use a bottle for feeding?'),
              value: _bottleFeeding,
              onChanged: (v) => setState(() => _bottleFeeding = v),
              delay: 250,
            ),
            const SizedBox(height: 16),

            // Feeding frequency
            // Feeding frequency
            _sectionHeader(l10n.tr("Child's Feeding Frequency"),
                Icons.restaurant_rounded),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: List.generate(
                  6,
                  (i) => ChoiceChip(
                        label: Text(
                          i < 5 ? '${i + 1}x' : '5+',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _feedingFrequency == i + 1
                                ? Colors.white
                                : AppColors.textPrimaryLight,
                          ),
                        ),
                        selected: _feedingFrequency == i + 1,
                        onSelected: (_) =>
                            setState(() => _feedingFrequency = i + 1),
                        selectedColor: AppColors.primary,
                        backgroundColor:
                            AppColors.divider.withValues(alpha: 0.3),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      )),
            )
                .animate(delay: const Duration(milliseconds: 300))
                .fadeIn(),

            const SizedBox(height: 24),

            // ---- Dietary 24hr recall ----
            // ---- Dietary 24hr recall ----
            _sectionHeader(
                l10n.tr("Mother's 24-Hour Dietary Recall"), Icons.food_bank_rounded),
            const SizedBox(height: 6),
            Text(
              l10n.tr('Which food groups did the mother eat in the past 24 hours?'),
              style: GoogleFonts.poppins(
                  fontSize: 12, color: AppColors.textSecondaryLight),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(kDietaryFoodGroups.length, (i) {
                return FilterChip(
                  label: Text(
                    kDietaryFoodGroups[i],
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: _dietaryDiversity[i]
                          ? Colors.white
                          : AppColors.textPrimaryLight,
                    ),
                  ),
                  selected: _dietaryDiversity[i],
                  onSelected: (v) =>
                      setState(() => _dietaryDiversity[i] = v),
                  selectedColor: AppColors.primary,
                  backgroundColor: AppColors.divider.withValues(alpha: 0.3),
                  checkmarkColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                );
              }),
            )
                .animate(delay: const Duration(milliseconds: 350))
                .fadeIn(),
            const SizedBox(height: 6),
            Text(
              '${l10n.tr('Food groups selected')}: ${_dietaryDiversity.where((v) => v).length}/7',
              style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600),
            ),

            const SizedBox(height: 16),
            Text(l10n.tr('Maternal Dietary Diversity Score'),
                style: GoogleFonts.poppins(
                    fontSize: 12, color: AppColors.textSecondaryLight)),
            Row(
              children: [
                Text('0', style: GoogleFonts.poppins(fontSize: 12)),
                Expanded(
                  child: Slider(
                    value: _maternalDietScore,
                    min: 0,
                    max: 7,
                    divisions: 7,
                    activeColor: AppColors.primary,
                    inactiveColor: AppColors.divider,
                    label: '${_maternalDietScore.round()}',
                    onChanged: (v) => setState(() => _maternalDietScore = v),
                  ),
                ),
                Text('7', style: GoogleFonts.poppins(fontSize: 12)),
              ],
            ),
            const SizedBox(height: 10),
            _textField(
              controller: _maternalCalorieController,
              label: l10n.tr('Est. Maternal Daily Calories'),
              icon: Icons.restaurant_menu_rounded,
              keyboardType: TextInputType.number,
              hint: 'e.g. 1800',
              delay: 370,
            ),
            const SizedBox(height: 10),
            _textField(
              controller: _mealCalorieController,
              label: l10n.tr('Est. Mother\'s Calories per Meal'),
              icon: Icons.local_dining_rounded,
              keyboardType: TextInputType.number,
              hint: 'e.g. 600',
              delay: 380,
            ),
            const SizedBox(height: 16),
            Text(l10n.tr('Estimated Protein Intake Level'),
                style: GoogleFonts.poppins(
                    fontSize: 12, color: AppColors.textSecondaryLight)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [l10n.tr('Low'), l10n.tr('Medium'), l10n.tr('High')].asMap().entries.map((e) {
                return ChoiceChip(
                  label: Text(e.value),
                  selected: _proteinIntakeLevel == e.key,
                  onSelected: (v) {
                    if (v) setState(() => _proteinIntakeLevel = e.key);
                  },
                  selectedColor: AppColors.primary,
                  labelStyle: TextStyle(
                      color: _proteinIntakeLevel == e.key
                          ? Colors.white
                          : AppColors.textPrimaryLight),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            // ---- Junk food frequency ----
            _sectionHeader(l10n.tr("Mother's Junk Food Frequency"),
                Icons.fastfood_rounded),
            const SizedBox(height: 6),
            Text(
              l10n.tr('How many days per week does the mother eat processed/junk food?'),
              style: GoogleFonts.poppins(
                  fontSize: 12, color: AppColors.textSecondaryLight),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text('0',
                    style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppColors.textSecondaryLight)),
                Expanded(
                  child: Slider(
                    value: _junkFoodFrequency,
                    min: 0,
                    max: 7,
                    divisions: 7,
                    activeColor: AppColors.atRisk,
                    inactiveColor: AppColors.divider,
                    label: '${_junkFoodFrequency.round()} days/week',
                    onChanged: (v) => setState(() => _junkFoodFrequency = v),
                  ),
                ),
                Text('7',
                    style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppColors.textSecondaryLight)),
              ],
            )
                .animate(delay: const Duration(milliseconds: 400))
                .fadeIn(),
          ],

          const SizedBox(height: 24),

          // ---- Illness ----
          _sectionHeader(l10n.tr("Child's Recent Illness"), Icons.sick_rounded),
          const SizedBox(height: 6),
          Text(
            l10n.tr('How many days was the child sick in the past 2 weeks?'),
            style: GoogleFonts.poppins(
                fontSize: 12, color: AppColors.textSecondaryLight),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text('0',
                  style: GoogleFonts.poppins(
                      fontSize: 12, color: AppColors.textSecondaryLight)),
              Expanded(
                child: Slider(
                  value: _recentIllnessDays,
                  min: 0,
                  max: 14,
                  divisions: 14,
                  activeColor: _recentIllnessDays > 7
                      ? AppColors.severe
                      : _recentIllnessDays > 3
                          ? AppColors.atRisk
                          : AppColors.healthy,
                  inactiveColor: AppColors.divider,
                  label: '${_recentIllnessDays.round()} days',
                  onChanged: (v) => setState(() => _recentIllnessDays = v),
                ),
              ),
              Text('14',
                  style: GoogleFonts.poppins(
                      fontSize: 12, color: AppColors.textSecondaryLight)),
            ],
          )
              .animate(delay: const Duration(milliseconds: 450))
              .fadeIn(),

          const SizedBox(height: 16),
          _buildSwitch(
            title: l10n.tr('Recent Weight Loss'),
            subtitle: l10n.tr('Has the child noticeably lost weight recently?'),
            value: _recentWeightLoss,
            onChanged: (v) => setState(() => _recentWeightLoss = v),
            delay: 460,
          ),
          _buildSwitch(
            title: l10n.tr('Recent Diarrhea'),
            subtitle: l10n.tr('Has the child had diarrhea in the last 14 days?'),
            value: _recentDiarrhea,
            onChanged: (v) => setState(() => _recentDiarrhea = v),
            delay: 470,
          ),
          _buildSwitch(
            title: l10n.tr('Recent Fever'),
            subtitle: l10n.tr('Has the child had a fever in the last 14 days?'),
            value: _recentFever,
            onChanged: (v) => setState(() => _recentFever = v),
            delay: 480,
          ),

          const SizedBox(height: 24),

          // ---- Preventive care ----
          _sectionHeader(
              l10n.tr("Child's Preventive Care"), Icons.health_and_safety_rounded),
          const SizedBox(height: 8),

          _buildSwitch(
            title: l10n.tr('Micronutrient Supplements'),
            subtitle: l10n.tr(
                'Receiving Iron, Zinc, or Vitamin A supplements from Anganwadi/clinic?'),
            value: _micronutrientSupplements,
            onChanged: (v) => setState(() => _micronutrientSupplements = v),
            delay: 500,
          ),

          const SizedBox(height: 16),
          Text(l10n.tr('Vaccination Status'),
              style: GoogleFonts.poppins(
                  fontSize: 12, color: AppColors.textSecondaryLight)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [l10n.tr('None'), l10n.tr('Partial'), l10n.tr('Fully Vaccinated')].asMap().entries.map((e) {
              return ChoiceChip(
                label: Text(e.value),
                selected: _vaccinationStatus == e.key,
                onSelected: (v) {
                  if (v) setState(() => _vaccinationStatus = e.key);
                },
                selectedColor: AppColors.primary,
                labelStyle: TextStyle(
                    color: _vaccinationStatus == e.key
                        ? Colors.white
                        : AppColors.textPrimaryLight),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          if (widget.patient.ageInMonths >= 12)
            _buildSwitch(
              title: l10n.tr('Deworming (Albendazole)'),
              subtitle:
                  l10n.tr('Has the child received deworming in the last 6 months?'),
              value: _dewormingHistory,
              onChanged: (v) => setState(() => _dewormingHistory = v),
              delay: 600,
            ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ============================================================
  // STEP 3: Analysing (Loading)
  // ============================================================

  Widget _buildStep3Loading(LocalizationController l10n) {
    return Center(
      key: const ValueKey('loading'),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.15),
                  AppColors.primary.withValues(alpha: 0.0),
                ],
              ),
            ),
            child: Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                    strokeWidth: 3,
                  ),
                ),
              ),
            ),
          )
              .animate(onPlay: (c) => c.repeat())
              .scaleXY(
                  begin: 0.95,
                  end: 1.05,
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeInOut)
              .then()
              .scaleXY(begin: 1.05, end: 0.95),
          const SizedBox(height: 32),
          Text(
            l10n.tr('Running Risk Analysis'),
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          )
              .animate()
              .fadeIn(delay: const Duration(milliseconds: 200)),
          const SizedBox(height: 8),
          Text(
            l10n.tr('The TFLite model is computing malnutrition risk\nbased on ${widget.patient.name}\'s profile...'),
            style: GoogleFonts.poppins(
                fontSize: 13, color: AppColors.textSecondaryLight),
            textAlign: TextAlign.center,
          )
              .animate()
              .fadeIn(delay: const Duration(milliseconds: 400)),
          const SizedBox(height: 24),
          // Animated dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
                3,
                (i) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    )
                        .animate(
                          onPlay: (c) => c.repeat(),
                          delay: Duration(milliseconds: i * 200),
                        )
                        .scaleXY(
                            begin: 0.5,
                            end: 1.2,
                            duration: const Duration(milliseconds: 600),
                            curve: Curves.easeInOut)
                        .then()
                        .scaleXY(begin: 1.2, end: 0.5)),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SHARED WIDGETS
  // ============================================================

  Widget _sectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, color: AppColors.primary, size: 18),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: GoogleFonts.poppins(
              fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildSwitch({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    int delay = 0,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: value
            ? AppColors.primary.withValues(alpha: 0.04)
            : Colors.transparent,
        border: Border.all(
            color: value
                ? AppColors.primary.withValues(alpha: 0.2)
                : AppColors.divider),
        borderRadius: BorderRadius.circular(16),
      ),
      child: SwitchListTile(
        title: Text(
          title,
          style: GoogleFonts.poppins(
              fontSize: 13, fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.poppins(
              fontSize: 11, color: AppColors.textSecondaryLight),
        ),
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        dense: true,
      ),
    )
        .animate(delay: Duration(milliseconds: delay))
        .fadeIn(duration: const Duration(milliseconds: 350))
        .slideX(begin: 0.05, end: 0);
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    String? hint,
    int delay = 0,
    ValueChanged<String>? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      onChanged: onChanged,
      style: GoogleFonts.poppins(fontSize: 14),
      inputFormatters: keyboardType == TextInputType.number ||
              keyboardType ==
                  const TextInputType.numberWithOptions(decimal: true)
          ? [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))]
          : null,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
      ),
    )
        .animate(delay: Duration(milliseconds: delay))
        .fadeIn(duration: const Duration(milliseconds: 400))
        .slideY(begin: 0.08, end: 0);
  }
}
