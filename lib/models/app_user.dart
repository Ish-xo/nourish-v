// ============================================================
// app_user.dart — Nourish V Worker/Admin Profile Model
// Updated: Phase 4 — TFLite predictive risk system
// ============================================================
//
// AppUser represents an authenticated field worker (ASHA/Anganwadi) or
// district admin. The two new fields [isRural] and [hasHealthcareAccess]
// represent geographic/operational context for the worker's deployment.
// They are injected silently into every ML payload by AssessmentController.

/// User model representing an authenticated worker or admin.
/// Stored in Firestore `users/{uid}` collection.
class AppUser {
  final String uid;
  final String email;
  final String name;
  final UserRole role;
  final String location;
  final DateTime createdAt;

  /// Whether this worker is deployed in a rural/remote area.
  /// Impacts ML risk prediction — rural deployments correlate with
  /// reduced access to supplementary nutrition programs.
  final bool isRural;

  /// Whether the worker's assigned area has reasonable access to a
  /// Primary Health Centre (PHC) or equivalent facility.
  /// Impacts ML risk prediction — lack of healthcare access is a
  /// compounding risk factor for malnutrition outcomes.
  final bool hasHealthcareAccess;

  const AppUser({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    required this.location,
    required this.createdAt,
    this.isRural = true, // Default: assume rural deployment for coverage
    this.hasHealthcareAccess = false, // Default: conservative assumption
  });

  bool get isAdmin => role == UserRole.admin;
  bool get isWorker => role == UserRole.worker;

  /// Deserialize from a Firestore document map.
  factory AppUser.fromFirestore(Map<String, dynamic> data) {
    return AppUser(
      uid: data['uid'] as String,
      email: data['email'] as String,
      name: data['name'] as String,
      role: data['role'] == 'admin' ? UserRole.admin : UserRole.worker,
      location: data['location'] as String? ?? 'Unknown Location',
      createdAt: (data['createdAt'] as dynamic).toDate(),
      // New fields — default to true/false if not yet set in Firestore
      // (backwards-compatible with existing user documents)
      isRural: data['isRural'] as bool? ?? true,
      hasHealthcareAccess: data['hasHealthcareAccess'] as bool? ?? false,
    );
  }

  /// Serialize to a Firestore document map.
  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'role': role == UserRole.admin ? 'admin' : 'worker',
      'location': location,
      'createdAt': createdAt,
      'isRural': isRural,
      'hasHealthcareAccess': hasHealthcareAccess,
    };
  }

  AppUser copyWith({
    String? name,
    String? location,
    bool? isRural,
    bool? hasHealthcareAccess,
  }) {
    return AppUser(
      uid: uid,
      email: email,
      name: name ?? this.name,
      role: role,
      location: location ?? this.location,
      createdAt: createdAt,
      isRural: isRural ?? this.isRural,
      hasHealthcareAccess: hasHealthcareAccess ?? this.hasHealthcareAccess,
    );
  }
}

enum UserRole {
  worker,
  admin,
}
