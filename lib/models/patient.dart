// ============================================================
// patient.dart — Nourish V Patient (Child) Baseline Model
// Updated: Phase 4 — TFLite Predictive Risk System
//
// DATA SPLIT STRATEGY:
// ---------------------
// This model stores ONE-TIME STATIC data collected during
// initial child registration. Fields here do not change monthly.
//
// ROUTINE MONTHLY data (weight, height, diet recall, illness)
// is stored in Assessment instead, since it varies each visit.
//
// The model_parameters.xlsx + additional user-specified fields
// are all captured here at registration time.
// ============================================================

import 'package:uuid/uuid.dart';
import '../core/constants.dart';

class Patient {
  // --- Identity ---
  final String id;
  final String name;
  final DateTime dateOfBirth;
  final String gender; // 'M' or 'F'
  final String? guardianName;
  final String location;
  final String? workerUid; // UID of the ASHA/Anganwadi worker who registered
  final DateTime createdAt;

  // ---- Pregnancy / Birth History ----

  /// Birth weight in kilograms.
  /// Used by AssessmentController to derive [lowBirthWeight] (< 2.5 kg).
  final double? birthWeightKg;

  /// Whether the child was born prematurely (< 37 weeks gestation).
  /// true = preterm, false = full-term.
  final bool isPreterm;

  // ---- Mother's Health ----

  /// Mother's age at time of child's birth.
  /// Used to derive [teenageMother] (< 20 years) for the ML payload.
  final int? motherAge;

  /// Mother's pre-pregnancy or first-trimester height in centimetres.
  final double? motherHeightCm;

  /// Mother's pre-pregnancy or first-trimester weight in kilograms.
  final double? motherWeightKg;

  /// Whether the mother had a diagnosed history of anaemia.
  /// Per WHO, maternal anaemia is a significant risk factor for LBW.
  final bool motherHadAnemia;

  /// Mother's highest completed education level.
  final MotherEducationLevel motherEducation;

  /// Whether the mother received regular iron-folic acid supplementation during pregnancy.
  final bool ironFolicIntake;

  /// Expected or historical breastfeeding duration in months.
  final int breastfeedingDuration;

  /// Age in months when complementary solid foods were started.
  final int complementaryFoodStartAge;

  // ---- Socio-Economic Profile ----

  /// Estimated monthly household income in INR.
  final int? householdIncome;

  /// Total number of people living in the household.
  final int? familySize;

  /// Total number of children under 5 in the household.
  final int? numberOfChildren;

  // ---- WASH (Water, Sanitation & Hygiene) ----

  /// Primary drinking water source for the household.
  final WaterSourceType waterSource;

  /// Level of access to sanitation facilities.
  /// Index maps directly to ML model: 0=OD, 1=Shared, 2=Private.
  final SanitationType sanitationType;

  /// Whether primary drinking water is treated (boiled, filtered) before use.
  final bool waterTreatment;

  /// Whether caregiver regularly uses soap for handwashing before feeding.
  final bool handwashing;

  // ---- Food Security ----

  /// Household food security status per simplified HFIAS scale.
  final FoodSecurityStatus foodSecurityStatus;

  Patient({
    String? id,
    required this.name,
    required this.dateOfBirth,
    required this.gender,
    this.guardianName,
    required this.location,
    this.workerUid,
    DateTime? createdAt,
    // Pregnancy / Birth
    this.birthWeightKg,
    this.isPreterm = false,
    // Mother's health
    this.motherAge,
    this.motherHeightCm,
    this.motherWeightKg,
    this.motherHadAnemia = false,
    this.motherEducation = MotherEducationLevel.none,
    this.ironFolicIntake = false,
    this.breastfeedingDuration = 0,
    this.complementaryFoodStartAge = 6,
    // Socio-Economic
    this.householdIncome,
    this.familySize,
    this.numberOfChildren,
    // WASH
    this.waterSource = WaterSourceType.well,
    this.sanitationType = SanitationType.openDefecation,
    this.waterTreatment = false,
    this.handwashing = false,
    // Food
    this.foodSecurityStatus = FoodSecurityStatus.insecure,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  // ---- Computed Properties ----

  /// Mother's BMI derived from stored height and weight.
  /// Returns null if either measurement is missing or height is zero.
  double? get motherBmi {
    if (motherHeightCm == null ||
        motherWeightKg == null ||
        motherHeightCm! <= 0) return null;
    final heightM = motherHeightCm! / 100.0;
    return motherWeightKg! / (heightM * heightM);
  }

  /// Age in months (needed for age-specific ML features).
  int get ageInMonths {
    final now = DateTime.now();
    return (now.year - dateOfBirth.year) * 12 + now.month - dateOfBirth.month;
  }

  /// Human-readable age display string.
  String get ageDisplay {
    final months = ageInMonths;
    if (months < 12) return '$months months';
    final years = months ~/ 12;
    final rem = months % 12;
    if (rem == 0) return '$years yr';
    return '$years yr $rem mo';
  }

  // ---- Firestore Serialization ----

  factory Patient.fromFirestore(Map<String, dynamic> data) {
    return Patient(
      id: data['id'] as String,
      name: data['name'] as String,
      dateOfBirth: (data['dateOfBirth'] as dynamic).toDate(),
      gender: data['gender'] as String,
      guardianName: data['guardianName'] as String?,
      location: data['location'] as String? ?? 'Unknown Location',
      workerUid: data['workerUid'] as String?,
      createdAt: (data['createdAt'] as dynamic).toDate(),
      // Pregnancy / Birth
      birthWeightKg: (data['birthWeightKg'] as num?)?.toDouble(),
      isPreterm: data['isPreterm'] as bool? ?? false,
      // Mother
      motherAge: data['motherAge'] as int?,
      motherHeightCm: (data['motherHeightCm'] as num?)?.toDouble(),
      motherWeightKg: (data['motherWeightKg'] as num?)?.toDouble(),
      motherHadAnemia: data['motherHadAnemia'] as bool? ?? false,
      motherEducation: MotherEducationLevel
          .values[data['motherEducation'] as int? ?? 0],
      ironFolicIntake: data['ironFolicIntake'] as bool? ?? false,
      breastfeedingDuration: data['breastfeedingDuration'] as int? ?? 0,
      complementaryFoodStartAge: data['complementaryFoodStartAge'] as int? ?? 6,
      // Socio-Economic
      householdIncome: data['householdIncome'] as int?,
      familySize: data['familySize'] as int?,
      numberOfChildren: data['numberOfChildren'] as int?,
      // WASH
      waterSource:
          WaterSourceType.values[data['waterSource'] as int? ?? 1],
      sanitationType: SanitationType
          .values[data['sanitationType'] as int? ?? 0],
      waterTreatment: data['waterTreatment'] as bool? ?? false,
      handwashing: data['handwashing'] as bool? ?? false,
      // Food
      foodSecurityStatus: FoodSecurityStatus
          .values[data['foodSecurityStatus'] as int? ?? 0],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'name': name,
      'dateOfBirth': dateOfBirth,
      'gender': gender,
      'guardianName': guardianName,
      'location': location,
      'workerUid': workerUid,
      'createdAt': createdAt,
      // Pregnancy / Birth
      'birthWeightKg': birthWeightKg,
      'isPreterm': isPreterm,
      // Mother
      'motherAge': motherAge,
      'motherHeightCm': motherHeightCm,
      'motherWeightKg': motherWeightKg,
      'motherHadAnemia': motherHadAnemia,
      'motherEducation': motherEducation.index,
      'ironFolicIntake': ironFolicIntake,
      'breastfeedingDuration': breastfeedingDuration,
      'complementaryFoodStartAge': complementaryFoodStartAge,
      // Socio-Economic
      'householdIncome': householdIncome,
      'familySize': familySize,
      'numberOfChildren': numberOfChildren,
      // WASH
      'waterSource': waterSource.index,
      'sanitationType': sanitationType.index,
      'waterTreatment': waterTreatment,
      'handwashing': handwashing,
      // Food
      'foodSecurityStatus': foodSecurityStatus.index,
    };
  }

  Patient copyWith({
    String? name,
    DateTime? dateOfBirth,
    String? gender,
    String? guardianName,
    String? location,
    double? birthWeightKg,
    bool? isPreterm,
    int? motherAge,
    double? motherHeightCm,
    double? motherWeightKg,
    bool? motherHadAnemia,
    MotherEducationLevel? motherEducation,
    bool? ironFolicIntake,
    int? breastfeedingDuration,
    int? complementaryFoodStartAge,
    int? householdIncome,
    int? familySize,
    int? numberOfChildren,
    WaterSourceType? waterSource,
    SanitationType? sanitationType,
    bool? waterTreatment,
    bool? handwashing,
    FoodSecurityStatus? foodSecurityStatus,
  }) {
    return Patient(
      id: id,
      name: name ?? this.name,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      guardianName: guardianName ?? this.guardianName,
      location: location ?? this.location,
      workerUid: workerUid,
      createdAt: createdAt,
      birthWeightKg: birthWeightKg ?? this.birthWeightKg,
      isPreterm: isPreterm ?? this.isPreterm,
      motherAge: motherAge ?? this.motherAge,
      motherHeightCm: motherHeightCm ?? this.motherHeightCm,
      motherWeightKg: motherWeightKg ?? this.motherWeightKg,
      motherHadAnemia: motherHadAnemia ?? this.motherHadAnemia,
      motherEducation: motherEducation ?? this.motherEducation,
      ironFolicIntake: ironFolicIntake ?? this.ironFolicIntake,
      breastfeedingDuration: breastfeedingDuration ?? this.breastfeedingDuration,
      complementaryFoodStartAge: complementaryFoodStartAge ?? this.complementaryFoodStartAge,
      householdIncome: householdIncome ?? this.householdIncome,
      familySize: familySize ?? this.familySize,
      numberOfChildren: numberOfChildren ?? this.numberOfChildren,
      waterSource: waterSource ?? this.waterSource,
      sanitationType: sanitationType ?? this.sanitationType,
      waterTreatment: waterTreatment ?? this.waterTreatment,
      handwashing: handwashing ?? this.handwashing,
      foodSecurityStatus: foodSecurityStatus ?? this.foodSecurityStatus,
    );
  }
}
