// ============================================================
// patient_form_view.dart — Child Registration / Edit Wizard
// Updated: Phase 4 — TFLite Risk System
//
// PURPOSE: Collect ONE-TIME STATIC baseline data for a new child,
//   OR edit existing baseline data for an already-registered child.
//
// MODES:
//   - CREATE mode: no route argument → registers a new patient
//   - EDIT mode: Patient passed as route argument → pre-fills all
//     fields and submits via updatePatient()
//
// CHANGES FROM PREVIOUS VERSION:
//   - Replaced single motherBmi text field with two fields:
//       motherHeightCm + motherWeightKg (BMI auto-computed in model)
//   - Added EDIT mode with Patient? route argument
//   - Title, button label, and success message adapt to mode
//
// UX RULES:
//   - Zero keyboard entry where possible
//   - SwitchListTile for all booleans
//   - ToggleButtons for all enums
//   - Date pickers for dates
//
// 2-STEP WIZARD:
//   Step 1: Child & Mother Info
//   Step 2: Household & Environment + Confirm
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

class PatientFormView extends ConsumerStatefulWidget {
  const PatientFormView({super.key});

  @override
  ConsumerState<PatientFormView> createState() => _PatientFormViewState();
}

class _PatientFormViewState extends ConsumerState<PatientFormView> {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;

  // Edit-mode state
  Patient? _editingPatient; // null = create mode, non-null = edit mode
  bool _initialized = false;

  // ---- Step 1 Fields ----
  final _nameController = TextEditingController();
  final _guardianController = TextEditingController();
  final _locationController = TextEditingController();
  final _birthWeightController = TextEditingController();
  final _motherAgeController = TextEditingController();
  final _motherHeightController = TextEditingController(); // NEW: cm
  final _motherWeightController = TextEditingController(); // NEW: kg

  String _gender = 'M';
  DateTime _dob = DateTime.now().subtract(const Duration(days: 730));
  bool _isPreterm = false;
  bool _motherHadAnemia = false;
  bool _ironFolicIntake = false;
  MotherEducationLevel _motherEducation = MotherEducationLevel.none;

  final _breastfeedingDurationController = TextEditingController(text: '0');
  final _compFoodStartController = TextEditingController(text: '6');

  // ---- Step 2 Fields ----
  final _incomeController = TextEditingController();
  final _familySizeController = TextEditingController();
  final _numChildrenController = TextEditingController();

  WaterSourceType _waterSource = WaterSourceType.well;
  SanitationType _sanitationType = SanitationType.openDefecation;
  FoodSecurityStatus _foodSecurity = FoodSecurityStatus.insecure;
  bool _waterTreatment = false;
  bool _handwashing = false;

  bool _isSubmitting = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      final arg = ModalRoute.of(context)?.settings.arguments;
      if (arg is Patient) {
        _editingPatient = arg;
        _prefillFromPatient(arg);
      }
    }
  }

  /// Pre-fill all form fields from an existing Patient.
  void _prefillFromPatient(Patient p) {
    _nameController.text = p.name;
    _guardianController.text = p.guardianName ?? '';
    _locationController.text = p.location;
    _birthWeightController.text = p.birthWeightKg?.toString() ?? '';
    _motherAgeController.text = p.motherAge?.toString() ?? '';
    _motherHeightController.text = p.motherHeightCm?.toString() ?? '';
    _motherWeightController.text = p.motherWeightKg?.toString() ?? '';
    _incomeController.text = p.householdIncome?.toString() ?? '';
    _familySizeController.text = p.familySize?.toString() ?? '';
    _numChildrenController.text = p.numberOfChildren?.toString() ?? '';
    _breastfeedingDurationController.text = p.breastfeedingDuration.toString();
    _compFoodStartController.text = p.complementaryFoodStartAge.toString();
    setState(() {
      _dob = p.dateOfBirth;
      _gender = p.gender;
      _isPreterm = p.isPreterm;
      _motherHadAnemia = p.motherHadAnemia;
      _motherEducation = p.motherEducation;
      _ironFolicIntake = p.ironFolicIntake;
      _waterSource = p.waterSource;
      _sanitationType = p.sanitationType;
      _foodSecurity = p.foodSecurityStatus;
      _waterTreatment = p.waterTreatment;
      _handwashing = p.handwashing;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _guardianController.dispose();
    _locationController.dispose();
    _birthWeightController.dispose();
    _motherAgeController.dispose();
    _motherHeightController.dispose();
    _motherWeightController.dispose();
    _incomeController.dispose();
    _familySizeController.dispose();
    _numChildrenController.dispose();
    _breastfeedingDurationController.dispose();
    _compFoodStartController.dispose();
    super.dispose();
  }

  bool get _isEditMode => _editingPatient != null;

  // ---- Step indicator ----
  Widget _buildStepIndicator(LocalizationController l10n) {
    final steps = [
      l10n.tr('Child & Mother'),
      l10n.tr('Household'),
    ];
    return Row(
      children: List.generate(steps.length, (i) {
        final active = i <= _currentStep;
        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: 4,
                  decoration: BoxDecoration(
                    color: active ? AppColors.primary : AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              if (i < steps.length - 1) const SizedBox(width: 4),
            ],
          ),
        );
      }),
    );
  }

  void _handleNext() {
    if (_currentStep == 0) {
      if (_formKey.currentState!.validate()) {
        setState(() => _currentStep = 1);
      }
    } else {
      _submitForm();
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    final authState = ref.read(authControllerProvider);
    final l10n = ref.read(localizationProvider.notifier);

    final patient = Patient(
      // Preserve the original ID in edit mode
      id: _editingPatient?.id,
      name: _nameController.text.trim(),
      guardianName: _guardianController.text.trim().isEmpty
          ? null
          : _guardianController.text.trim(),
      dateOfBirth: _dob,
      gender: _gender,
      location: _locationController.text.trim().isEmpty
          ? (authState.user?.location ?? 'Unknown')
          : _locationController.text.trim(),
      workerUid: _editingPatient?.workerUid ?? authState.user?.uid,
      createdAt: _editingPatient?.createdAt, // Preserve original registration date
      // Birth
      birthWeightKg: double.tryParse(_birthWeightController.text),
      isPreterm: _isPreterm,
      // Mother
      motherAge: int.tryParse(_motherAgeController.text),
      motherHeightCm: double.tryParse(_motherHeightController.text),
      motherWeightKg: double.tryParse(_motherWeightController.text),
      motherHadAnemia: _motherHadAnemia,
      motherEducation: _motherEducation,
      ironFolicIntake: _ironFolicIntake,
      breastfeedingDuration: int.tryParse(_breastfeedingDurationController.text) ?? 0,
      complementaryFoodStartAge: int.tryParse(_compFoodStartController.text) ?? 6,
      // Socio-economic
      householdIncome: int.tryParse(_incomeController.text),
      familySize: int.tryParse(_familySizeController.text),
      numberOfChildren: int.tryParse(_numChildrenController.text),
      // WASH
      waterSource: _waterSource,
      sanitationType: _sanitationType,
      waterTreatment: _waterTreatment,
      handwashing: _handwashing,
      // Food
      foodSecurityStatus: _foodSecurity,
    );

    if (_isEditMode) {
      await ref
          .read(assessmentControllerProvider.notifier)
          .updatePatient(patient);
    } else {
      await ref
          .read(assessmentControllerProvider.notifier)
          .registerPatient(patient);
    }

    setState(() => _isSubmitting = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditMode
                ? l10n.tr('Patient details updated successfully!')
                : l10n.tr('Patient registered successfully!'),
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: AppColors.healthy,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(localizationProvider);
    final l10n = ref.read(localizationProvider.notifier);

    final title = _isEditMode
        ? l10n.tr('Edit Child Details')
        : l10n.tr('Register New Child');

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
                  TapScaleWrapper(
                    onTap: () => _currentStep > 0
                        ? setState(() => _currentStep--)
                        : Navigator.pop(context),
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
                  Expanded(
                    child: Text(
                      title,
                      style: GoogleFonts.poppins(
                          fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                  ),
                  // Edit mode badge
                  if (_isEditMode)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        l10n.tr('Editing'),
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    )
                  else
                    Text(
                      '${_currentStep + 1}/2',
                      style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: AppColors.textSecondaryLight),
                    ),
                ],
              ),
            ),

            // ---- Progress bar ----
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildStepIndicator(l10n),
            ),

            const SizedBox(height: 20),

            // ---- Form body ----
            Expanded(
              child: Form(
                key: _formKey,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                              begin: const Offset(0.08, 0), end: Offset.zero)
                          .animate(animation),
                      child: child,
                    ),
                  ),
                  child: _currentStep == 0
                      ? _buildStep1(l10n)
                      : _buildStep2(l10n),
                ),
              ),
            ),

            // ---- Action buttons ----
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  if (_currentStep > 0) ...[
                    Expanded(
                      child: TapScaleWrapper(
                        onTap: () => setState(() => _currentStep--),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.divider),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: Text(
                              l10n.tr('Back'),
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondaryLight,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    flex: 2,
                    child: TapScaleWrapper(
                      onTap: _isSubmitting ? null : _handleNext,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [
                            AppColors.primary,
                            AppColors.primaryDark
                          ]),
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
                          child: _isSubmitting
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5),
                                )
                              : Text(
                                  _currentStep < 1
                                      ? l10n.tr('Next')
                                      : (_isEditMode
                                          ? l10n.tr('Save Changes')
                                          : l10n.tr('Register Child')),
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
          ],
        ),
      ),
    );
  }

  // ============================================================
  // STEP 1: Child & Mother Info
  // ============================================================

  Widget _buildStep1(LocalizationController l10n) {
    return SingleChildScrollView(
      key: const ValueKey('step1'),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
              l10n.tr("Child's Information"), Icons.child_care_rounded),
          const SizedBox(height: 16),

          // Child name
          _textField(
            controller: _nameController,
            label: l10n.tr("Child's Full Name"),
            icon: Icons.person_rounded,
            validator: (v) =>
                v!.trim().isEmpty ? l10n.tr('Name is required') : null,
            delay: 100,
          ),
          const SizedBox(height: 14),

          // Guardian
          _textField(
            controller: _guardianController,
            label: l10n.tr("Guardian / Mother's Name"),
            icon: Icons.people_rounded,
            delay: 150,
          ),
          const SizedBox(height: 14),

          // Location
          _textField(
            controller: _locationController,
            label: l10n.tr('Village / Location'),
            icon: Icons.location_on_rounded,
            delay: 200,
          ),
          const SizedBox(height: 14),

          // Date of birth
          _buildDatePicker(l10n, delay: 250),
          const SizedBox(height: 14),

          // Gender selector
          _buildGenderSelector(l10n, delay: 300),
          const SizedBox(height: 24),

          _sectionHeader(
              l10n.tr("Child's Birth History"), Icons.baby_changing_station_rounded),
          const SizedBox(height: 16),

          // Birth weight
          _textField(
            controller: _birthWeightController,
            label: l10n.tr('Birth Weight (kg)'),
            icon: Icons.monitor_weight_outlined,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            hint: 'e.g. 2.8',
            delay: 350,
          ),
          const SizedBox(height: 8),

          // Preterm switch
          _buildSwitch(
            title: l10n.tr('Premature Birth (Preterm)'),
            subtitle: l10n.tr('Was the child born before 37 weeks?'),
            value: _isPreterm,
            onChanged: (v) => setState(() => _isPreterm = v),
            delay: 400,
          ),
          const SizedBox(height: 16),

          // Breastfeeding Duration
          _textField(
            controller: _breastfeedingDurationController,
            label: l10n.tr('Breastfeeding Duration (months)'),
            icon: Icons.child_care_rounded,
            keyboardType: TextInputType.number,
            hint: 'e.g. 12 (0 if none)',
            delay: 420,
          ),
          const SizedBox(height: 14),

          // Comp food start
          _textField(
            controller: _compFoodStartController,
            label: l10n.tr('Complementary Food Start (months)'),
            icon: Icons.restaurant_rounded,
            keyboardType: TextInputType.number,
            hint: 'e.g. 6',
            delay: 440,
          ),

          const SizedBox(height: 24),
          _sectionHeader(
              l10n.tr("Mother's Health"), Icons.favorite_border_rounded),
          const SizedBox(height: 16),

          // Mother age
          _textField(
            controller: _motherAgeController,
            label: l10n.tr("Mother's Age (years)"),
            icon: Icons.cake_rounded,
            keyboardType: TextInputType.number,
            hint: 'e.g. 24',
            delay: 450,
          ),
          const SizedBox(height: 14),

          // --- Mother Height + Weight (replaces old single BMI field) ---
          // Shown side-by-side in a Row with a computed BMI preview chip
          _buildMotherMeasurements(l10n),
          const SizedBox(height: 8),

          // Anaemia switch
          _buildSwitch(
            title: l10n.tr('History of Anaemia'),
            subtitle: l10n
                .tr('Did the mother have diagnosed anaemia during pregnancy?'),
            value: _motherHadAnemia,
            onChanged: (v) => setState(() => _motherHadAnemia = v),
            delay: 600,
          ),
          const SizedBox(height: 16),

          // Iron/Folic switch
          _buildSwitch(
            title: l10n.tr('Iron/Folic Acid Taken'),
            subtitle: l10n
                .tr('Did the mother take iron/folic acid during pregnancy?'),
            value: _ironFolicIntake,
            onChanged: (v) => setState(() => _ironFolicIntake = v),
            delay: 620,
          ),
          const SizedBox(height: 16),

          // Mother education
          _buildEnumSelector(
            label: l10n.tr("Mother's Education"),
            options: MotherEducationLevel.values
                .map((e) => e.displayName)
                .toList(),
            selectedIndex: _motherEducation.index,
            onSelect: (i) => setState(
                () => _motherEducation = MotherEducationLevel.values[i]),
            delay: 650,
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ---- Mother height + weight side-by-side with live BMI preview ----
  Widget _buildMotherMeasurements(LocalizationController l10n) {
    // Compute BMI on the fly for the preview chip
    final h = double.tryParse(_motherHeightController.text);
    final w = double.tryParse(_motherWeightController.text);
    double? bmi;
    if (h != null && w != null && h > 0) {
      final hm = h / 100.0;
      bmi = w / (hm * hm);
    }

    String bmiLabel = '—';
    Color bmiColor = AppColors.textSecondaryLight;
    if (bmi != null) {
      bmiLabel = bmi.toStringAsFixed(1);
      if (bmi < 18.5) {
        bmiColor = AppColors.severe;
      } else if (bmi < 25) {
        bmiColor = AppColors.healthy;
      } else if (bmi < 30) {
        bmiColor = AppColors.atRisk;
      } else {
        bmiColor = AppColors.severe;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _textField(
                controller: _motherHeightController,
                label: l10n.tr("Mother's Height (cm)"),
                icon: Icons.height_rounded,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                hint: 'e.g. 155',
                delay: 500,
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _textField(
                controller: _motherWeightController,
                label: l10n.tr("Mother's Weight (kg)"),
                icon: Icons.monitor_weight_outlined,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                hint: 'e.g. 52',
                delay: 540,
                onChanged: (_) => setState(() {}),
              ),
            ),
          ],
        ),
        if (bmi != null) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: bmiColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border:
                    Border.all(color: bmiColor.withValues(alpha: 0.3)),
              ),
              child: Text(
                '${l10n.tr('Computed BMI')}: $bmiLabel kg/m²',
                style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: bmiColor),
              ),
            ),
          ),
        ],
      ],
    )
        .animate(delay: const Duration(milliseconds: 490))
        .fadeIn()
        .slideY(begin: 0.08, end: 0);
  }

  // ============================================================
  // STEP 2: Household & Environment
  // ============================================================

  Widget _buildStep2(LocalizationController l10n) {
    return SingleChildScrollView(
      key: const ValueKey('step2'),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
              l10n.tr('Socio-Economic Profile'), Icons.home_work_rounded),
          const SizedBox(height: 16),

          // Income
          _textField(
            controller: _incomeController,
            label: l10n.tr('Monthly Household Income (INR)'),
            icon: Icons.currency_rupee_rounded,
            keyboardType: TextInputType.number,
            hint: 'e.g. 8000',
            delay: 100,
          ),
          const SizedBox(height: 14),

          // Family size
          _textField(
            controller: _familySizeController,
            label: l10n.tr('Total Family Size (persons)'),
            icon: Icons.group_rounded,
            keyboardType: TextInputType.number,
            hint: 'e.g. 5',
            delay: 150,
          ),
          const SizedBox(height: 14),

          // Number of children
          _textField(
            controller: _numChildrenController,
            label: l10n.tr('Number of Children Under 5'),
            icon: Icons.child_friendly_rounded,
            keyboardType: TextInputType.number,
            hint: 'e.g. 2',
            delay: 200,
          ),
          const SizedBox(height: 16),

          // Food Security
          _buildEnumSelector(
            label: l10n.tr('Food Security Status'),
            options: FoodSecurityStatus.values
                .map((e) => e.displayName)
                .toList(),
            selectedIndex: _foodSecurity.index,
            onSelect: (i) =>
                setState(() => _foodSecurity = FoodSecurityStatus.values[i]),
            delay: 250,
          ),

          const SizedBox(height: 24),
          _sectionHeader(
              l10n.tr('Water & Sanitation (WASH)'), Icons.water_drop_rounded),
          const SizedBox(height: 16),

          // Water source
          _buildEnumSelector(
            label: l10n.tr('Primary Water Source'),
            options: WaterSourceType.values
                .map((e) => e.displayName)
                .toList(),
            selectedIndex: _waterSource.index,
            onSelect: (i) =>
                setState(() => _waterSource = WaterSourceType.values[i]),
            delay: 300,
          ),
          const SizedBox(height: 16),

          // Sanitation with icons
          _buildSanitationSelector(l10n, delay: 350),

          const SizedBox(height: 16),

          // Water Treatment switch
          _buildSwitch(
            title: l10n.tr('Water Treatment'),
            subtitle: l10n.tr('Is the primary water source treated (boiled/filtered)?'),
            value: _waterTreatment,
            onChanged: (v) => setState(() => _waterTreatment = v),
            delay: 370,
          ),
          const SizedBox(height: 16),

          // Handwashing switch
          _buildSwitch(
            title: l10n.tr('Handwashing'),
            subtitle: l10n.tr('Does the caregiver regularly wash hands with soap before feeding?'),
            value: _handwashing,
            onChanged: (v) => setState(() => _handwashing = v),
            delay: 390,
          ),

          const SizedBox(height: 24),

          // Summary review card
          _buildReviewCard(l10n),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildReviewCard(LocalizationController l10n) {
    final h = double.tryParse(_motherHeightController.text);
    final w = double.tryParse(_motherWeightController.text);
    String bmiDisplay = l10n.tr('Not entered');
    if (h != null && w != null && h > 0) {
      final hm = h / 100.0;
      bmiDisplay = '${(w / (hm * hm)).toStringAsFixed(1)} kg/m²';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: GlassDecoration.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.tr('Summary'),
            style: GoogleFonts.poppins(
                fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          _summaryRow(Icons.person_rounded, l10n.tr('Child'),
              _nameController.text.isEmpty ? '—' : _nameController.text),
          _summaryRow(Icons.cake_rounded, l10n.tr('Date of Birth'),
              '${_dob.day}/${_dob.month}/${_dob.year}'),
          _summaryRow(
              _gender == 'M' ? Icons.male_rounded : Icons.female_rounded,
              l10n.tr('Gender'),
              _gender == 'M' ? l10n.tr('Male') : l10n.tr('Female')),
          _summaryRow(Icons.location_on_rounded, l10n.tr('Location'),
              _locationController.text.isEmpty
                  ? l10n.tr('Worker location')
                  : _locationController.text),
          _summaryRow(Icons.monitor_weight_outlined, l10n.tr('Birth Weight'),
              _birthWeightController.text.isEmpty
                  ? l10n.tr('Not entered')
                  : '${_birthWeightController.text} kg'),
          _summaryRow(
              Icons.calculate_rounded, l10n.tr("Mother's BMI"), bmiDisplay),
          _summaryRow(Icons.wc_rounded, l10n.tr('Sanitation'),
              _sanitationType.displayName),
        ],
      ),
    )
        .animate(delay: const Duration(milliseconds: 400))
        .fadeIn()
        .slideY(begin: 0.05, end: 0);
  }

  Widget _summaryRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 10),
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
                fontSize: 13, fontWeight: FontWeight.w600),
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
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style:
              GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ],
    );
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

  Widget _buildDatePicker(LocalizationController l10n, {int delay = 0}) {
    return TapScaleWrapper(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _dob,
          firstDate: DateTime(2019),
          lastDate: DateTime.now(),
          builder: (context, child) => Theme(
            data: Theme.of(context).copyWith(
              colorScheme:
                  const ColorScheme.light(primary: AppColors.primary),
            ),
            child: child!,
          ),
        );
        if (picked != null) setState(() => _dob = picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.divider),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_rounded,
                color: AppColors.primary, size: 20),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Date of Birth',
                  style: GoogleFonts.poppins(
                      fontSize: 12, color: AppColors.textSecondaryLight),
                ),
                Text(
                  '${_dob.day} / ${_dob.month} / ${_dob.year}',
                  style: GoogleFonts.poppins(
                      fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const Spacer(),
            Icon(Icons.edit_calendar_rounded,
                color: AppColors.primary.withValues(alpha: 0.6), size: 18),
          ],
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: delay))
        .fadeIn()
        .slideY(begin: 0.08, end: 0);
  }

  Widget _buildGenderSelector(LocalizationController l10n, {int delay = 0}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.wc_rounded, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Text(
            l10n.tr('Gender'),
            style: GoogleFonts.poppins(fontSize: 14),
          ),
          const Spacer(),
          ToggleButtons(
            isSelected: [_gender == 'M', _gender == 'F'],
            onPressed: (i) => setState(() => _gender = i == 0 ? 'M' : 'F'),
            borderRadius: BorderRadius.circular(12),
            selectedColor: Colors.white,
            fillColor: AppColors.primary,
            color: AppColors.textSecondaryLight,
            constraints:
                const BoxConstraints(minWidth: 64, minHeight: 36),
            children: [
              Text(l10n.tr('Boy'),
                  style: GoogleFonts.poppins(
                      fontSize: 13, fontWeight: FontWeight.w600)),
              Text(l10n.tr('Girl'),
                  style: GoogleFonts.poppins(
                      fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    )
        .animate(delay: Duration(milliseconds: delay))
        .fadeIn()
        .slideY(begin: 0.08, end: 0);
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
              fontSize: 14, fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.poppins(
              fontSize: 12, color: AppColors.textSecondaryLight),
        ),
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.primary,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    )
        .animate(delay: Duration(milliseconds: delay))
        .fadeIn()
        .slideX(begin: 0.05, end: 0);
  }

  Widget _buildEnumSelector({
    required String label,
    required List<String> options,
    required int selectedIndex,
    required ValueChanged<int> onSelect,
    int delay = 0,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondaryLight),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: List.generate(options.length, (i) {
            final selected = i == selectedIndex;
            return ChoiceChip(
              label: Text(
                options[i],
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color:
                      selected ? Colors.white : AppColors.textPrimaryLight,
                ),
              ),
              selected: selected,
              onSelected: (_) => onSelect(i),
              selectedColor: AppColors.primary,
              backgroundColor: AppColors.divider.withValues(alpha: 0.3),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            );
          }),
        ),
      ],
    )
        .animate(delay: Duration(milliseconds: delay))
        .fadeIn()
        .slideY(begin: 0.05, end: 0);
  }

  Widget _buildSanitationSelector(LocalizationController l10n,
      {int delay = 0}) {
    final icons = [
      Icons.dangerous_rounded,
      Icons.people_outlined,
      Icons.home_rounded,
    ];
    final labels = [
      l10n.tr('Open Defecation'),
      l10n.tr('Shared Toilet'),
      l10n.tr('Private Toilet'),
    ];
    final colors = [AppColors.severe, AppColors.atRisk, AppColors.healthy];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.tr('Sanitation / Toilet Access'),
          style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondaryLight),
        ),
        const SizedBox(height: 10),
        Row(
          children: List.generate(3, (i) {
            final selected = _sanitationType.index == i;
            return Expanded(
              child: GestureDetector(
                onTap: () =>
                    setState(() => _sanitationType = SanitationType.values[i]),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: EdgeInsets.only(right: i < 2 ? 8 : 0),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: selected
                        ? colors[i].withValues(alpha: 0.12)
                        : Colors.transparent,
                    border: Border.all(
                      color: selected ? colors[i] : AppColors.divider,
                      width: selected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Icon(icons[i],
                          color: selected
                              ? colors[i]
                              : AppColors.textSecondaryLight,
                          size: 28),
                      const SizedBox(height: 6),
                      Text(
                        labels[i],
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: selected
                              ? colors[i]
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    )
        .animate(delay: Duration(milliseconds: delay))
        .fadeIn()
        .slideY(begin: 0.05, end: 0);
  }
}
