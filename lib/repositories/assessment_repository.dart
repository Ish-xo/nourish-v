// ============================================================
// assessment_repository.dart — Abstract Data Contract
// Updated: Phase 4 — TFLite Predictive Risk System
//
// Controllers depend ONLY on this interface. The concrete
// Firebase implementation can be swapped without touching
// any controller or view code.
// ============================================================

import '../models/patient.dart';
import '../models/assessment.dart';

/// Abstract data contract for all patient and assessment operations.
/// All controller interactions go through this interface exclusively.
abstract class AssessmentRepository {
  // ---- Patient Operations ----

  /// Save/register a new patient to the data store.
  Future<void> savePatient(Patient patient);

  /// Overwrite an existing patient's baseline data.
  /// Used when a worker corrects registration details.
  Future<void> updatePatient(Patient patient);

  /// Retrieve all patients assigned to a specific worker.
  /// Used by the Home View roster.
  Future<List<Patient>> getPatientsForWorker(String workerUid);

  /// Retrieve all patients (admin-only, for dashboard).
  Future<List<Patient>> getAllPatients();

  /// Retrieve a single patient by their ID.
  /// Used by AssessmentForm's pre-fill pattern.
  Future<Patient?> getPatientById(String patientId);

  // ---- Assessment Operations ----

  /// Save a completed assessment (including TFLite risk output).
  Future<void> saveAssessment(Assessment assessment);

  /// Retrieve all assessments for a specific worker, ordered by date DESC.
  Future<List<Assessment>> getAssessmentsForWorker(String workerUid);

  /// Retrieve all assessments for a specific patient, ordered by date DESC.
  /// Used for the pre-fill pattern and history tab.
  Future<List<Assessment>> getAssessmentsForPatient(String patientId);

  /// Retrieve all assessments across all workers (admin-only).
  Future<List<Assessment>> getAllAssessments();

  // ---- Admin Dashboard Analytics ----

  /// Returns aggregated statistics for the dashboard.
  Future<Map<String, dynamic>> getDashboardStats();

  /// Returns region-wise breakdown for the bar chart.
  Future<List<Map<String, dynamic>>> getRegionWiseData();

  /// Returns monthly trend data for the line chart.
  Future<List<Map<String, dynamic>>> getMonthlyTrends();
}
