// ============================================================
// firebase_assessment_repository.dart
// Nourish V — Firebase Firestore Implementation
// Updated: Phase 4 — TFLite Predictive Risk System
//
// Implements AssessmentRepository using Cloud Firestore.
// Firestore offline persistence is enabled by default via
// the Firebase SDK — all queries work offline automatically.
// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/patient.dart';
import '../models/assessment.dart';
import '../core/constants.dart';
import 'assessment_repository.dart';

class FirebaseAssessmentRepository implements AssessmentRepository {
  final _firestore = FirebaseFirestore.instance;

  // ---- Collection References ----

  CollectionReference<Map<String, dynamic>> get _patientsCol =>
      _firestore.collection('patients');

  CollectionReference<Map<String, dynamic>> get _assessmentsCol =>
      _firestore.collection('assessments');

  // ============================================================
  // PATIENT OPERATIONS
  // ============================================================

  @override
  Future<void> savePatient(Patient patient) async {
    await _patientsCol.doc(patient.id).set(patient.toFirestore());
  }

  @override
  Future<void> updatePatient(Patient patient) async {
    // Use merge:true so that fields like createdAt/workerUid
    // (which may not be in the updated map) are preserved.
    await _patientsCol
        .doc(patient.id)
        .set(patient.toFirestore(), SetOptions(merge: true));
  }

  @override
  Future<List<Patient>> getPatientsForWorker(String workerUid) async {
    final snapshot = await _patientsCol
        .where('workerUid', isEqualTo: workerUid)
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs
        .map((doc) => Patient.fromFirestore(doc.data()))
        .toList();
  }

  @override
  Future<List<Patient>> getAllPatients() async {
    final snapshot =
        await _patientsCol.orderBy('createdAt', descending: true).get();
    return snapshot.docs
        .map((doc) => Patient.fromFirestore(doc.data()))
        .toList();
  }

  @override
  Future<Patient?> getPatientById(String patientId) async {
    final doc = await _patientsCol.doc(patientId).get();
    if (!doc.exists || doc.data() == null) return null;
    return Patient.fromFirestore(doc.data()!);
  }

  // ============================================================
  // ASSESSMENT OPERATIONS
  // ============================================================

  @override
  Future<void> saveAssessment(Assessment assessment) async {
    await _assessmentsCol
        .doc(assessment.id)
        .set(assessment.toFirestore());
  }

  @override
  Future<List<Assessment>> getAssessmentsForWorker(String workerUid) async {
    final snapshot = await _assessmentsCol
        .where('workerUid', isEqualTo: workerUid)
        .orderBy('assessmentDate', descending: true)
        .get();
    return snapshot.docs
        .map((doc) => Assessment.fromFirestore(doc.data()))
        .toList();
  }

  @override
  Future<List<Assessment>> getAssessmentsForPatient(String patientId) async {
    final snapshot = await _assessmentsCol
        .where('patientId', isEqualTo: patientId)
        .orderBy('assessmentDate', descending: true)
        .get();
    return snapshot.docs
        .map((doc) => Assessment.fromFirestore(doc.data()))
        .toList();
  }

  @override
  Future<List<Assessment>> getAllAssessments() async {
    final snapshot = await _assessmentsCol
        .orderBy('assessmentDate', descending: true)
        .get();
    return snapshot.docs
        .map((doc) => Assessment.fromFirestore(doc.data()))
        .toList();
  }

  // ============================================================
  // ADMIN DASHBOARD ANALYTICS
  // These aggregate over the new riskCategory field instead of
  // the old MalnutritionStatus enum.
  // ============================================================

  @override
  Future<Map<String, dynamic>> getDashboardStats() async {
    final snapshot = await _assessmentsCol.get();
    final assessments = snapshot.docs
        .map((d) => Assessment.fromFirestore(d.data()))
        .toList();

    final total = assessments.length;
    final low =
        assessments.where((a) => a.riskCategory == RiskCategory.low).length;
    final moderate = assessments
        .where((a) => a.riskCategory == RiskCategory.moderate)
        .length;
    final high =
        assessments.where((a) => a.riskCategory == RiskCategory.high).length;

    return {
      'totalScreened': total,
      'lowRiskCount': low,
      'moderateRiskCount': moderate,
      'highRiskCount': high,
      'lowPercent': total > 0 ? (low / total * 100).round() : 0,
      'moderatePercent': total > 0 ? (moderate / total * 100).round() : 0,
      'highPercent': total > 0 ? (high / total * 100).round() : 0,
      // Legacy keys kept for dashboard_controller compatibility
      'healthyPercent': total > 0 ? (low / total * 100).round() : 0,
      'atRiskPercent': total > 0 ? (moderate / total * 100).round() : 0,
      'severePercent': total > 0 ? (high / total * 100).round() : 0,
    };
  }

  @override
  Future<List<Map<String, dynamic>>> getRegionWiseData() async {
    final snapshot = await _assessmentsCol.get();
    final assessments = snapshot.docs
        .map((d) => Assessment.fromFirestore(d.data()))
        .toList();

    // Group by location
    final Map<String, List<Assessment>> byRegion = {};
    for (final a in assessments) {
      byRegion.putIfAbsent(a.location, () => []).add(a);
    }

    return byRegion.entries.map((e) {
      final list = e.value;
      return {
        'region': e.key,
        'total': list.length,
        'low': list.where((a) => a.riskCategory == RiskCategory.low).length,
        'moderate':
            list.where((a) => a.riskCategory == RiskCategory.moderate).length,
        'high': list.where((a) => a.riskCategory == RiskCategory.high).length,
        // Legacy keys
        'healthy':
            list.where((a) => a.riskCategory == RiskCategory.low).length,
        'atRisk':
            list.where((a) => a.riskCategory == RiskCategory.moderate).length,
        'severe':
            list.where((a) => a.riskCategory == RiskCategory.high).length,
      };
    }).toList();
  }

  @override
  Future<List<Map<String, dynamic>>> getMonthlyTrends() async {
    final snapshot = await _assessmentsCol
        .orderBy('assessmentDate', descending: false)
        .get();
    final assessments = snapshot.docs
        .map((d) => Assessment.fromFirestore(d.data()))
        .toList();

    // Group by month
    final Map<String, List<Assessment>> byMonth = {};
    for (final a in assessments) {
      final key =
          '${a.assessmentDate.year}-${a.assessmentDate.month.toString().padLeft(2, '0')}';
      byMonth.putIfAbsent(key, () => []).add(a);
    }

    return byMonth.entries.map((e) {
      final list = e.value;
      // Average risk probability per month for trend line
      final avgRisk = list.isEmpty
          ? 0.0
          : list.map((a) => a.futureRiskProbability).reduce((a, b) => a + b) /
              list.length;
      return {
        'month': e.key,
        'total': list.length,
        'avgRiskProbability': avgRisk,
        'low': list.where((a) => a.riskCategory == RiskCategory.low).length,
        'moderate':
            list.where((a) => a.riskCategory == RiskCategory.moderate).length,
        'high': list.where((a) => a.riskCategory == RiskCategory.high).length,
        // Legacy keys
        'healthy':
            list.where((a) => a.riskCategory == RiskCategory.low).length,
        'atRisk':
            list.where((a) => a.riskCategory == RiskCategory.moderate).length,
        'severe':
            list.where((a) => a.riskCategory == RiskCategory.high).length,
      };
    }).toList();
  }
}
