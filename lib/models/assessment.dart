// ============================================================
// assessment.dart — Nourish V Monthly Assessment Model
// Updated: Phase 4 — TFLite Predictive Risk System
//
// DATA SPLIT STRATEGY:
// ---------------------
// This model stores ROUTINE DYNAMIC data collected during each
// monthly checkup visit. All values here can change monthly.
//
// ONE-TIME STATIC data (socio-economic, maternal history, WASH)
// lives in the Patient model and is not re-entered each assessment.
//
// The TFLite model receives a combined payload of both Patient
// baseline fields + this assessment's routine fields.
// ============================================================

import 'package:uuid/uuid.dart';
import '../core/constants.dart';

class Assessment {
  // ---- Identity ----
  final String id;
  final String patientId; // Reference to patients/{id}
  final String patientName; // Denormalized for list display
  final String workerUid;
  final DateTime assessmentDate;
  final String location; // Denormalized for aggregation

  // ---- Infant Feeding ----

  /// Whether the child is exclusively breastfed.
  /// Smart UI: if child < 6 months AND this is true, solid food
  /// questions are auto-hidden in AssessmentFormView.
  final bool exclusiveBreastfeeding;

  /// Whether the child is bottle-fed (risk factor for infections).
  final bool bottleFeeding;

  /// Number of times the child is fed per day (main meals + snacks).
  final int feedingFrequency;

  // ---- 24-Hour Dietary Recall ----

  /// A list of 7 booleans representing the WHO food groups consumed
  /// by the child in the past 24 hours. Indices match [kDietaryFoodGroups].
  /// [0] Grains, [1] Legumes, [2] Dairy, [3] Meat/Eggs,
  /// [4] Fruits, [5] Vegetables, [6] Fats/Oils
  final List<bool> dietaryDiversity;

  /// Maternal Dietary Diversity Score (0-7).
  final int maternalDietScore;

  /// Estimated maternal daily calorie intake.
  final int maternalCalorieIntake;

  /// Estimated protein intake level (0 = low, 1 = medium, 2 = high).
  final int proteinIntakeLevel;

  /// Estimated calories per meal for the child.
  final int caloriePerMeal;

  // ---- Nutrition Supplements & Junk Food ----

  /// Whether the child is currently receiving micronutrient supplements
  /// (Iron, Zinc, Vitamin A, etc.) from an Anganwadi or clinic.
  final bool micronutrientSupplements;

  /// Average number of times per week the child consumes junk/processed food.
  final int junkFoodFrequency;

  // ---- Illness History (recent 2 weeks) ----

  /// Number of days the child was sick in the past 14 days.
  /// Captured via a Slider (0–14) in the form.
  final int recentIllnessDays;

  /// Any recent noticeable weight loss in the child.
  final bool recentWeightLoss;

  /// Has the child had diarrhea in the last 14 days?
  final bool recentDiarrhea;

  /// Has the child had a fever in the last 14 days?
  final bool recentFever;

  // ---- Health & Preventive Care ----

  /// Index representing vaccination status (0=None, 1=Partial, 2=Fully)
  final int vaccinationStatus;

  /// Whether the child has received deworming (Albendazole) within
  /// the recommended interval (every 6 months for children > 1 year).
  final bool dewormingHistory;

  // ---- ML Model Output ----

  /// The probability (0.0 to 1.0) returned by the TFLite service
  /// predicting the risk of developing malnutrition within 6 months.
  /// This is calculated and stored after the form submission.
  final double futureRiskProbability;

  /// Classification derived from [futureRiskProbability] using [RiskThresholds].
  final RiskCategory riskCategory;

  Assessment({
    String? id,
    required this.patientId,
    required this.patientName,
    required this.workerUid,
    DateTime? assessmentDate,
    required this.location,
    // Feeding
    this.exclusiveBreastfeeding = false,
    this.bottleFeeding = false,
    this.feedingFrequency = 3,
    // Dietary diversity — default all false (nothing consumed)
    List<bool>? dietaryDiversity,
    this.maternalDietScore = 0,
    this.maternalCalorieIntake = 1800,
    this.proteinIntakeLevel = 0,
    this.caloriePerMeal = 250,
    // Supplements & junk
    this.micronutrientSupplements = false,
    this.junkFoodFrequency = 0,
    // Illness
    this.recentIllnessDays = 0,
    this.recentWeightLoss = false,
    this.recentDiarrhea = false,
    this.recentFever = false,
    // Preventive care
    this.vaccinationStatus = 0,
    this.dewormingHistory = false,
    // ML output
    this.futureRiskProbability = 0.0,
    this.riskCategory = RiskCategory.low,
  })  : id = id ?? const Uuid().v4(),
        assessmentDate = assessmentDate ?? DateTime.now(),
        // Ensure dietaryDiversity always has exactly 7 entries
        dietaryDiversity = (dietaryDiversity != null && dietaryDiversity.length == 7)
            ? dietaryDiversity
            : List.filled(7, false);

  // ---- Computed Properties ----

  /// The count of food groups consumed — the Dietary Diversity Score (DDS).
  /// Score of ≥ 5 is considered minimum dietary diversity for children.
  int get dietaryDiversityScore => dietaryDiversity.where((v) => v).length;

  /// Risk percentage string for display (e.g. "72%").
  String get riskPercentage =>
      '${(futureRiskProbability * 100).round()}%';

  /// Human-readable risk level label.
  String get riskLabel {
    switch (riskCategory) {
      case RiskCategory.low:
        return 'Low Risk';
      case RiskCategory.moderate:
        return 'Moderate Risk';
      case RiskCategory.high:
        return 'High Risk';
    }
  }

  /// Context string shown in result view (e.g. "72% Risk of MAM within 6 months").
  String get riskContextString {
    final pct = (futureRiskProbability * 100).round();
    switch (riskCategory) {
      case RiskCategory.low:
        return '$pct% — Unlikely to develop malnutrition';
      case RiskCategory.moderate:
        return '$pct% Risk of MAM within 6 months';
      case RiskCategory.high:
        return '$pct% Risk of Severe Malnutrition within 6 months';
    }
  }

  // ---- Firestore Serialization ----

  factory Assessment.fromFirestore(Map<String, dynamic> data) {
    return Assessment(
      id: data['id'] as String,
      patientId: data['patientId'] as String,
      patientName: data['patientName'] as String,
      workerUid: data['workerUid'] as String,
      assessmentDate: (data['assessmentDate'] as dynamic).toDate(),
      location: data['location'] as String? ?? 'Unknown Location',
      // Feeding
      exclusiveBreastfeeding: data['exclusiveBreastfeeding'] as bool? ?? false,
      bottleFeeding: data['bottleFeeding'] as bool? ?? false,
      feedingFrequency: data['feedingFrequency'] as int? ?? 3,
      // Dietary diversity (stored as List<bool> in Firestore)
      dietaryDiversity: (data['dietaryDiversity'] as List<dynamic>?)
              ?.map((e) => e as bool)
              .toList() ??
          List.filled(7, false),
      maternalDietScore: data['maternalDietScore'] as int? ?? 0,
      maternalCalorieIntake: data['maternalCalorieIntake'] as int? ?? 1800,
      proteinIntakeLevel: data['proteinIntakeLevel'] as int? ?? 0,
      caloriePerMeal: data['caloriePerMeal'] as int? ?? 250,
      // Supplements & junk
      micronutrientSupplements:
          data['micronutrientSupplements'] as bool? ?? false,
      junkFoodFrequency: data['junkFoodFrequency'] as int? ?? 0,
      // Illness
      recentIllnessDays: data['recentIllnessDays'] as int? ?? 0,
      recentWeightLoss: data['recentWeightLoss'] as bool? ?? false,
      recentDiarrhea: data['recentDiarrhea'] as bool? ?? false,
      recentFever: data['recentFever'] as bool? ?? false,
      // Preventive care
      vaccinationStatus: data['vaccinationStatus'] as int? ?? 0,
      dewormingHistory: data['dewormingHistory'] as bool? ?? false,
      // ML output
      futureRiskProbability:
          (data['futureRiskProbability'] as num?)?.toDouble() ?? 0.0,
      riskCategory: RiskCategory.values[data['riskCategory'] as int? ?? 0],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'patientId': patientId,
      'patientName': patientName,
      'workerUid': workerUid,
      'assessmentDate': assessmentDate,
      'location': location,
      // Feeding
      'exclusiveBreastfeeding': exclusiveBreastfeeding,
      'bottleFeeding': bottleFeeding,
      'feedingFrequency': feedingFrequency,
      // Dietary diversity stored as plain bool list
      'dietaryDiversity': dietaryDiversity,
      'maternalDietScore': maternalDietScore,
      'maternalCalorieIntake': maternalCalorieIntake,
      'proteinIntakeLevel': proteinIntakeLevel,
      'caloriePerMeal': caloriePerMeal,
      // Supplements & junk
      'micronutrientSupplements': micronutrientSupplements,
      'junkFoodFrequency': junkFoodFrequency,
      // Illness
      'recentIllnessDays': recentIllnessDays,
      'recentWeightLoss': recentWeightLoss,
      'recentDiarrhea': recentDiarrhea,
      'recentFever': recentFever,
      // Preventive care
      'vaccinationStatus': vaccinationStatus,
      'dewormingHistory': dewormingHistory,
      // ML output
      'futureRiskProbability': futureRiskProbability,
      'riskCategory': riskCategory.index,
    };
  }

  Assessment copyWith({
    bool? exclusiveBreastfeeding,
    bool? bottleFeeding,
    int? feedingFrequency,
    List<bool>? dietaryDiversity,
    int? maternalDietScore,
    int? maternalCalorieIntake,
    int? proteinIntakeLevel,
    int? caloriePerMeal,
    bool? micronutrientSupplements,
    int? junkFoodFrequency,
    int? recentIllnessDays,
    bool? recentWeightLoss,
    bool? recentDiarrhea,
    bool? recentFever,
    int? vaccinationStatus,
    bool? dewormingHistory,
    double? futureRiskProbability,
    RiskCategory? riskCategory,
  }) {
    return Assessment(
      id: id,
      patientId: patientId,
      patientName: patientName,
      workerUid: workerUid,
      assessmentDate: assessmentDate,
      location: location,
      exclusiveBreastfeeding:
          exclusiveBreastfeeding ?? this.exclusiveBreastfeeding,
      bottleFeeding: bottleFeeding ?? this.bottleFeeding,
      feedingFrequency: feedingFrequency ?? this.feedingFrequency,
      dietaryDiversity: dietaryDiversity ?? this.dietaryDiversity,
      maternalDietScore: maternalDietScore ?? this.maternalDietScore,
      maternalCalorieIntake: maternalCalorieIntake ?? this.maternalCalorieIntake,
      proteinIntakeLevel: proteinIntakeLevel ?? this.proteinIntakeLevel,
      caloriePerMeal: caloriePerMeal ?? this.caloriePerMeal,
      micronutrientSupplements:
          micronutrientSupplements ?? this.micronutrientSupplements,
      junkFoodFrequency: junkFoodFrequency ?? this.junkFoodFrequency,
      recentIllnessDays: recentIllnessDays ?? this.recentIllnessDays,
      recentWeightLoss: recentWeightLoss ?? this.recentWeightLoss,
      recentDiarrhea: recentDiarrhea ?? this.recentDiarrhea,
      recentFever: recentFever ?? this.recentFever,
      vaccinationStatus: vaccinationStatus ?? this.vaccinationStatus,
      dewormingHistory: dewormingHistory ?? this.dewormingHistory,
      futureRiskProbability:
          futureRiskProbability ?? this.futureRiskProbability,
      riskCategory: riskCategory ?? this.riskCategory,
    );
  }
}
