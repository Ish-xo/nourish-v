import 'dart:math';

/// Mock Poshan Tracker government reporting service.
/// Formats assessment data into the structure the real Poshan Tracker API
/// would expect and simulates submission.
class PoshanTrackerService {
  /// Format assessment data for Poshan Tracker submission.
  static Map<String, dynamic> formatReport({
    required int totalScreened,
    required int samCount,
    required int mamCount,
    required int healthyCount,
    required String location,
    required List<Map<String, dynamic>> locationBreakdown,
  }) {
    return {
      'reportType': 'ICDS_MONTHLY_NUTRITION_REPORT',
      'reportPeriod': _currentReportPeriod(),
      'location': location,
      'state': 'Maharashtra',
      'submittedBy': 'Nourish V App',
      'data': {
        'totalChildrenScreened': totalScreened,
        'samChildren': samCount,
        'mamChildren': mamCount,
        'normalChildren': healthyCount,
        'samPercentage': totalScreened > 0
            ? (samCount / totalScreened * 100).toStringAsFixed(1)
            : '0.0',
        'mamPercentage': totalScreened > 0
            ? (mamCount / totalScreened * 100).toStringAsFixed(1)
            : '0.0',
        'locationWiseBreakdown': locationBreakdown,
      },
      'metadata': {
        'appVersion': '1.0.0',
        'platform': 'mobile',
        'submissionTimestamp': DateTime.now().toIso8601String(),
      },
    };
  }

  /// Simulate submitting the report to Poshan Tracker.
  /// Returns a mock response with a reference ID.
  static Future<Map<String, dynamic>> submitReport(
    Map<String, dynamic> report,
  ) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 2));

    // Generate a mock reference ID
    final refId = 'PT-${DateTime.now().year}-'
        '${DateTime.now().month.toString().padLeft(2, '0')}-'
        '${Random().nextInt(9999).toString().padLeft(4, '0')}';

    return {
      'success': true,
      'referenceId': refId,
      'message': 'Report submitted successfully to Poshan Tracker',
      'timestamp': DateTime.now().toIso8601String(),
      'status': 'DEMO_MODE',
    };
  }

  static String _currentReportPeriod() {
    final now = DateTime.now();
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[now.month - 1]} ${now.year}';
  }
}
