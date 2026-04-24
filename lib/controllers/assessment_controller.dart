// ============================================================
// assessment_controller.dart — Nourish V ML Pipeline Controller
// Updated: Phase 4 — TFLite Predictive Risk System
//
// This controller is the BRAIN of the assessment pipeline:
//   1. Manages the patient roster for the Home View
//   2. Pre-fills static patient data for the Assessment form
//   3. Auto-calculates derived ML features from raw inputs
//   4. Implicitly injects worker context (isRural, hasHealthcareAccess)
//   5. Builds the normalized ML payload
//   6. Calls TFLiteService and stores the returned probability
// ============================================================

import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants.dart';
import '../models/patient.dart';
import '../models/assessment.dart';
import '../models/app_user.dart';
import '../repositories/assessment_repository.dart';
import '../repositories/firebase_assessment_repository.dart';
import '../services/ml_service.dart';

// ---- Repository & Service Providers ----

final assessmentRepositoryProvider = Provider<AssessmentRepository>((ref) {
  return FirebaseAssessmentRepository();
});


// ============================================================
// ASSESSMENT STATE
// ============================================================

class AssessmentState {
  final ViewState viewState;

  /// The last completed assessment result (shown in result view).
  final Assessment? currentAssessment;

  /// The patient currently being assessed (used by AssessmentForm pre-fill).
  final Patient? selectedPatient;

  /// Assessment history for the current worker or all workers (admin).
  final List<Assessment> history;

  /// Full patient roster for the logged-in worker (Home View).
  final List<Patient> patientRoster;

  /// The current search query applied to [patientRoster].
  final String searchQuery;

  final String? errorMessage;

  const AssessmentState({
    this.viewState = ViewState.initial,
    this.currentAssessment,
    this.selectedPatient,
    this.history = const [],
    this.patientRoster = const [],
    this.searchQuery = '',
    this.errorMessage,
  });

  /// Returns [patientRoster] filtered by [searchQuery] (case-insensitive).
  List<Patient> get filteredRoster {
    if (searchQuery.isEmpty) return patientRoster;
    final query = searchQuery.toLowerCase();
    return patientRoster
        .where((p) =>
            p.name.toLowerCase().contains(query) ||
            p.location.toLowerCase().contains(query))
        .toList();
  }

  AssessmentState copyWith({
    ViewState? viewState,
    Assessment? currentAssessment,
    Patient? selectedPatient,
    List<Assessment>? history,
    List<Patient>? patientRoster,
    String? searchQuery,
    String? errorMessage,
    bool clearCurrentAssessment = false,
    bool clearSelectedPatient = false,
    bool clearError = false,
  }) {
    return AssessmentState(
      viewState: viewState ?? this.viewState,
      currentAssessment: clearCurrentAssessment
          ? null
          : (currentAssessment ?? this.currentAssessment),
      selectedPatient: clearSelectedPatient
          ? null
          : (selectedPatient ?? this.selectedPatient),
      history: history ?? this.history,
      patientRoster: patientRoster ?? this.patientRoster,
      searchQuery: searchQuery ?? this.searchQuery,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

// ============================================================
// ASSESSMENT CONTROLLER
// ============================================================

class AssessmentController extends StateNotifier<AssessmentState> {
  final AssessmentRepository _repository;
  final MalnutritionModelService _mlService;

  AssessmentController(this._repository, this._mlService)
      : super(const AssessmentState());

  // ----------------------------------------------------------
  // SECTION 1: Patient Roster (Home View)
  // ----------------------------------------------------------

  /// Loads all patients assigned to [workerUid] for the Home roster.
  Future<void> loadPatientRoster(String workerUid) async {
    state = state.copyWith(viewState: ViewState.loading);
    try {
      final patients = await _repository.getPatientsForWorker(workerUid);
      state = state.copyWith(
        viewState: ViewState.success,
        patientRoster: patients,
      );
    } catch (e) {
      state = state.copyWith(
        viewState: ViewState.error,
        errorMessage: 'Failed to load patients: $e',
      );
    }
  }

  /// Updates the search query; [filteredRoster] is recomputed automatically.
  void filterRoster(String query) {
    state = state.copyWith(searchQuery: query);
  }

  /// Registers a new patient and refreshes the roster.
  Future<void> registerPatient(Patient patient) async {
    state = state.copyWith(viewState: ViewState.loading);
    try {
      await _repository.savePatient(patient);
      // Refresh roster (re-fetches all patients for this worker)
      if (patient.workerUid != null) {
        final patients =
            await _repository.getPatientsForWorker(patient.workerUid!);
        state = state.copyWith(
          viewState: ViewState.success,
          patientRoster: patients,
        );
      } else {
        state = state.copyWith(viewState: ViewState.success);
      }
    } catch (e) {
      state = state.copyWith(
        viewState: ViewState.error,
        errorMessage: 'Failed to register patient: $e',
      );
    }
  }

  /// Updates an existing patient's baseline data and refreshes the roster.
  Future<void> updatePatient(Patient patient) async {
    state = state.copyWith(viewState: ViewState.loading);
    try {
      await _repository.updatePatient(patient);
      if (patient.workerUid != null) {
        final patients =
            await _repository.getPatientsForWorker(patient.workerUid!);
        state = state.copyWith(
          viewState: ViewState.success,
          patientRoster: patients,
          // Keep selectedPatient fresh in case the user returns to assess
          selectedPatient: patient,
        );
      } else {
        state = state.copyWith(viewState: ViewState.success);
      }
    } catch (e) {
      state = state.copyWith(
        viewState: ViewState.error,
        errorMessage: 'Failed to update patient: $e',
      );
    }
  }

  // ----------------------------------------------------------
  // SECTION 2: Assessment Form — Pre-fill Pattern
  // ----------------------------------------------------------

  /// Loads [patient] into state so AssessmentFormView can
  /// display a read-only summary before the routine questions.
  void selectPatientForAssessment(Patient patient) {
    state = state.copyWith(
      selectedPatient: patient,
      clearCurrentAssessment: true,
    );
  }

  // ----------------------------------------------------------
  // SECTION 3: Submit Assessment — ML Pipeline
  // ----------------------------------------------------------

  /// Main pipeline: computes derived features, builds the ML payload,
  /// calls TFLiteService, assigns risk output, and saves to Firestore.
  ///
  /// [rawAssessment] — the assessment built from user form inputs
  ///   (futureRiskProbability is 0.0 at this point — not yet scored).
  /// [patient] — the patient's baseline static data (also sent to model).
  /// [worker] — the logged-in worker profile (provides isRural + hasHealthcareAccess).
  Future<void> submitAssessment({
    required Assessment rawAssessment,
    required Patient patient,
    required AppUser worker,
  }) async {
    state = state.copyWith(viewState: ViewState.loading, clearError: true);

    try {
      // --- Step 1: Auto-calculate derived binary features ---
      final bool lowBirthWeight = _isLowBirthWeight(patient.birthWeightKg);
      final bool teenageMother = _isTeenageMother(patient.motherAge);
      final bool openDefecation = _isOpenDefecation(patient.sanitationType);
      final int dds = _computeDds(rawAssessment.dietaryDiversity);

      // --- Step 2: Build EXACT 51-feature ML array payload ---
      final double parasiteInfection = rawAssessment.dewormingHistory ? 0.0 : 1.0;
      final double illnessBurdenScore = rawAssessment.recentIllnessDays.toDouble() + (3.0 * parasiteInfection) + (2.0 * (rawAssessment.recentDiarrhea ? 1.0 : 0.0));
      
      final double motherBmi = patient.motherBmi ?? ((patient.motherHeightCm != null && patient.motherWeightKg != null && patient.motherHeightCm! > 0) ? (patient.motherWeightKg! / math.pow(patient.motherHeightCm! / 100.0, 2)) : 22.0);

      final double maternalRiskScore = (motherBmi < 18.5 ? 2.0 : 0.0) + (patient.motherHadAnemia ? 1.0 : 0.0) + math.max(0.0, 3.0 - rawAssessment.maternalDietScore.toDouble()) + (patient.ironFolicIntake ? 0.0 : 1.0);
      
      final double feedingRiskScore = ((!rawAssessment.exclusiveBreastfeeding && patient.ageInMonths <= 6) ? 1.0 : 0.0) + ((patient.complementaryFoodStartAge < 4 || patient.complementaryFoodStartAge > 8) ? 1.0 : 0.0) + math.max(0.0, 3.0 - rawAssessment.feedingFrequency.toDouble()) + (rawAssessment.bottleFeeding ? 1.0 : 0.0);
      
      final double socioRiskScore = (patient.foodSecurityStatus == FoodSecurityStatus.insecure ? 3.0 : 0.0) + (2.0 * (openDefecation ? 1.0 : 0.0)) + (worker.hasHealthcareAccess ? 0.0 : 1.0) + ((patient.householdIncome ?? 5000.0) < 8000.0 ? 1.0 : 0.0);

      final Map<String, double> mlPayload = {
        'child_age_months': patient.ageInMonths.toDouble(),
        'gender': patient.gender == 'M' ? 1.0 : 0.0,
        'birth_weight': patient.birthWeightKg ?? 2.5,
        'low_birth_weight': lowBirthWeight ? 1.0 : 0.0,
        'gestation_term': patient.isPreterm ? 1.0 : 0.0,
        'recent_weight_loss': rawAssessment.recentWeightLoss ? 1.0 : 0.0,
        'mother_age': patient.motherAge?.toDouble() ?? 25.0,
        'teenage_mother': teenageMother ? 1.0 : 0.0,
        'mother_bmi': motherBmi,
        'mother_anemia': patient.motherHadAnemia ? 1.0 : 0.0,
        'mother_education': patient.motherEducation.index.toDouble(),
        'maternal_diet_score': rawAssessment.maternalDietScore.toDouble(),
        'iron_folic_intake': patient.ironFolicIntake ? 1.0 : 0.0,
        'maternal_calorie_intake': rawAssessment.maternalCalorieIntake.toDouble(),
        'exclusive_bf': rawAssessment.exclusiveBreastfeeding ? 1.0 : 0.0,
        'breastfeeding_duration': patient.breastfeedingDuration.toDouble(),
        'complementary_food_start_age': patient.complementaryFoodStartAge.toDouble(),
        'feeding_frequency': rawAssessment.feedingFrequency.toDouble(),
        'bottle_feeding': rawAssessment.bottleFeeding ? 1.0 : 0.0,
        'diet_grains_roots': rawAssessment.dietaryDiversity[0] ? 1.0 : 0.0,
        'diet_pulses_nuts': rawAssessment.dietaryDiversity[1] ? 1.0 : 0.0,
        'diet_dairy': rawAssessment.dietaryDiversity[2] ? 1.0 : 0.0,
        'diet_flesh_foods': rawAssessment.dietaryDiversity[3] ? 1.0 : 0.0,
        'diet_eggs': rawAssessment.dietaryDiversity[4] ? 1.0 : 0.0,
        'diet_vitA_rich': rawAssessment.dietaryDiversity[5] ? 1.0 : 0.0,
        'diet_other_fruits_veg': rawAssessment.dietaryDiversity[6] ? 1.0 : 0.0,
        'dietary_diversity_score': dds.toDouble(),
        'protein_intake_level': rawAssessment.proteinIntakeLevel.toDouble(),
        'junk_food_frequency': rawAssessment.junkFoodFrequency.toDouble(),
        'micronutrient_supplements': rawAssessment.micronutrientSupplements ? 1.0 : 0.0,
        'water_source': patient.waterSource.index.toDouble(),
        'water_treatment': patient.waterTreatment ? 1.0 : 0.0,
        'sanitation_type': patient.sanitationType.index.toDouble(),
        'handwashing': patient.handwashing ? 1.0 : 0.0,
        'open_defecation': openDefecation ? 1.0 : 0.0,
        'household_income': patient.householdIncome?.toDouble() ?? 5000.0,
        'family_size': patient.familySize?.toDouble() ?? 4.0,
        'number_of_children': patient.numberOfChildren?.toDouble() ?? 2.0,
        'food_security': patient.foodSecurityStatus.index.toDouble(),
        'rural_urban': worker.isRural ? 1.0 : 0.0,
        'healthcare_access': worker.hasHealthcareAccess ? 1.0 : 0.0,
        'recent_diarrhea': rawAssessment.recentDiarrhea ? 1.0 : 0.0,
        'recent_fever': rawAssessment.recentFever ? 1.0 : 0.0,
        'illness_days': rawAssessment.recentIllnessDays.toDouble(),
        'vaccination_status': rawAssessment.vaccinationStatus.toDouble(),
        'parasite_infection': parasiteInfection,
        'illness_burden_score': illnessBurdenScore,
        'maternal_risk_score': maternalRiskScore,
        'feeding_risk_score': feedingRiskScore,
        'socio_risk_score': socioRiskScore,
        'calorie_per_meal': rawAssessment.caloriePerMeal.toDouble(),
      };

      // Mother BMI is already computed above.

      // --- Step 3: Call ML service ---
      final double probability = _mlService.predict(mlPayload);

      // --- Step 4: Assign risk output and save ---
      final scoredAssessment = rawAssessment.copyWith(
        futureRiskProbability: probability,
        riskCategory: RiskThresholds.fromProbability(probability),
      );
      await _repository.saveAssessment(scoredAssessment);

      state = state.copyWith(
        viewState: ViewState.success,
        currentAssessment: scoredAssessment,
      );
    } catch (e) {
      state = state.copyWith(
        viewState: ViewState.error,
        errorMessage: 'Assessment failed: $e',
      );
    }
  }

  // ----------------------------------------------------------
  // SECTION 4: History Loading
  // ----------------------------------------------------------

  /// Load assessment history for a specific worker (Worker home view).
  Future<void> loadWorkerHistory(String workerUid) async {
    state = state.copyWith(viewState: ViewState.loading);
    try {
      final assessments =
          await _repository.getAssessmentsForWorker(workerUid);
      state = state.copyWith(
        viewState: ViewState.success,
        history: assessments,
      );
    } catch (e) {
      state = state.copyWith(
        viewState: ViewState.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// Load all assessments across all workers (admin view).
  Future<void> loadAllHistory() async {
    state = state.copyWith(viewState: ViewState.loading);
    try {
      final assessments = await _repository.getAllAssessments();
      final patients = await _repository.getAllPatients();
      state = state.copyWith(
        viewState: ViewState.success,
        history: assessments,
        patientRoster: patients,
      );
    } catch (e) {
      state = state.copyWith(
        viewState: ViewState.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// Reset to initial state (called after result view is dismissed).
  void reset() {
    state = const AssessmentState();
  }

  // ----------------------------------------------------------
  // SECTION 5: Private ML Feature Helpers
  // ----------------------------------------------------------

  /// Returns true if [birthWeightKg] < 2.5 kg (WHO LBW threshold).
  bool _isLowBirthWeight(double? birthWeightKg) {
    return birthWeightKg != null && birthWeightKg < 2.5;
  }

  /// Returns true if [motherAge] < 20 (teenage mother risk factor).
  bool _isTeenageMother(int? motherAge) {
    return motherAge != null && motherAge < 20;
  }

  /// Returns true if sanitation == openDefecation (strongest categorical risk).
  bool _isOpenDefecation(SanitationType sanitation) {
    return sanitation == SanitationType.openDefecation;
  }

  /// Counts the number of food groups consumed — the Dietary Diversity Score.
  /// A score < 4 indicates inadequate diversity per WHO MDD guidelines.
  int _computeDds(List<bool> diversity) {
    return diversity.where((consumed) => consumed).length;
  }
}

// ============================================================
// RIVERPOD PROVIDER
// ============================================================

final assessmentControllerProvider =
    StateNotifierProvider<AssessmentController, AssessmentState>((ref) {
  final repository = ref.watch(assessmentRepositoryProvider);
  final mlService = ref.watch(malnutritionModelServiceProvider);
  return AssessmentController(repository, mlService);
});
