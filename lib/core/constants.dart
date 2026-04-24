// ============================================================
// SECTION 1: Legacy Malnutrition Classification (kept for
// Dashboard, Government Reports, and PDF generation)
// ============================================================

/// Used by the admin dashboard and existing report modules.
enum MalnutritionStatus {
  healthy,
  atRisk,
  severe,
}

/// Used by charts to classify the primary malnutrition presentation.
enum MalnutritionType {
  underweight, // Low Weight-for-Age
  stunting, // Low Height-for-Age
  wasting, // Low BMI-for-Age / Weight-for-Height
}

// ----- WHO Z-Score Thresholds (used by dashboard/reporting) -----

class WHOThresholds {
  /// Weight-for-Age Z-score thresholds
  static const double underweightModerate = -2.0;
  static const double underweightSevere = -3.0;

  /// Height-for-Age Z-score thresholds
  static const double stuntingModerate = -2.0;
  static const double stuntingSevere = -3.0;

  /// BMI-for-Age / Weight-for-Height Z-score thresholds
  static const double wastingModerate = -2.0;
  static const double wastingSevere = -3.0;

  /// MUAC thresholds (cm) for children 6-59 months
  static const double muacNormal = 13.5;
  static const double muacModerate = 12.5;
  static const double muacSevere = 11.5;
}

// ============================================================
// SECTION 2: TFLite Risk Prediction Enums & Thresholds
// ============================================================

/// The output classification from the TFLite predictive model.
/// Based on the returned [futureRiskProbability] float (0.0–1.0).
enum RiskCategory {
  low, // Green  — probability < 30%
  moderate, // Yellow — 30% ≤ probability < 60%
  high, // Red    — probability ≥ 60%
}

/// Risk probability thresholds for the TFLite output.
class RiskThresholds {
  static const double lowMax = 0.30;
  static const double moderateMax = 0.60;

  /// Derive [RiskCategory] from a raw probability float.
  static RiskCategory fromProbability(double probability) {
    if (probability < lowMax) return RiskCategory.low;
    if (probability < moderateMax) return RiskCategory.moderate;
    return RiskCategory.high;
  }
}

// ============================================================
// SECTION 3: Patient Baseline Enums
// (Collected once during registration)
// ============================================================

/// Mother's highest level of completed education.
enum MotherEducationLevel {
  none, // No formal schooling
  primary, // Grades 1–5
  secondary, // Grades 6–10
  higher, // College / University
}

extension MotherEducationLevelX on MotherEducationLevel {
  String get displayName {
    switch (this) {
      case MotherEducationLevel.none:
        return 'None';
      case MotherEducationLevel.primary:
        return 'Primary';
      case MotherEducationLevel.secondary:
        return 'Secondary';
      case MotherEducationLevel.higher:
        return 'Higher';
    }
  }
}

/// Primary drinking water source for the household.
enum WaterSourceType {
  river, // River / pond / surface water
  well, // Borewell / Hand-pump
  piped, // Treated piped municipal water
  other, // Tanker / bottled / other
}

extension WaterSourceTypeX on WaterSourceType {
  String get displayName {
    switch (this) {
      case WaterSourceType.piped:
        return 'Piped';
      case WaterSourceType.well:
        return 'Well';
      case WaterSourceType.river:
        return 'River';
      case WaterSourceType.other:
        return 'Other';
    }
  }
}

/// Household sanitation access level.
/// The integer index (0, 1, 2) maps directly to the ML model input.
enum SanitationType {
  openDefecation, // 0 — Open defecation / no toilet
  shared, // 1 — Shared community toilet
  private, // 2 — Private household toilet
}

extension SanitationTypeX on SanitationType {
  String get displayName {
    switch (this) {
      case SanitationType.openDefecation:
        return 'Open Defecation';
      case SanitationType.shared:
        return 'Shared Toilet';
      case SanitationType.private:
        return 'Private Toilet';
    }
  }
}

/// Household food security rating per the HFIAS scale (simplified).
enum FoodSecurityStatus {
  insecure, // 0 — Severely food insecure
  moderate, // 1 — Moderately food insecure
  secure, // 2 — Food secure
}

extension FoodSecurityStatusX on FoodSecurityStatus {
  String get displayName {
    switch (this) {
      case FoodSecurityStatus.insecure:
        return 'Insecure';
      case FoodSecurityStatus.moderate:
        return 'Moderate';
      case FoodSecurityStatus.secure:
        return 'Secure';
    }
  }
}

// ============================================================
// SECTION 4: Dietary Diversity (24-Hour Recall)
// ============================================================

/// The 7 standard food groups used for the WHO Minimum Dietary
/// Diversity Score (MDD-W / MDD) indicator.
/// Each [bool] in Assessment.dietaryDiversity corresponds to one group.
const List<String> kDietaryFoodGroups = [
  'Grains / Roots', // 0
  'Legumes / Pulses', // 1
  'Dairy', // 2
  'Meat / Eggs', // 3
  'Fruits', // 4
  'Vegetables', // 5
  'Fats / Oils', // 6
];

// ============================================================
// SECTION 5: View State (used by all controllers)
// ============================================================

enum ViewState {
  initial,
  loading,
  success,
  error,
}

// ============================================================
// SECTION 6: UI Design Tokens
// ============================================================

class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

class AppRadius {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double pill = 100;
}

// ============================================================
// SECTION 7: Supported Locales
// ============================================================

class AppLocales {
  static const String english = 'en';
  static const String hindi = 'hi';
  static const String marathi = 'mr';
  static const String gujarati = 'gu';

  static const List<String> supported = [english, hindi, marathi, gujarati];

  static String displayName(String code) {
    switch (code) {
      case english:
        return 'English';
      case hindi:
        return 'हिन्दी';
      case marathi:
        return 'मराठी';
      case gujarati:
        return 'ગુજરાતી';
      default:
        return code;
    }
  }
}

// ============================================================
// SECTION 8: Mock Data Helpers
// ============================================================

class MockLocations {
  static const List<String> locations = [
    'Rajpur, Nashik',
    'Devgadh, Pune',
    'Chandanpur, Thane',
    'Amravati Tanda, Ahmedabad',
    'Nandurbar, Jaipur',
  ];
}
