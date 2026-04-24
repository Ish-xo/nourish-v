// ============================================================
// app_router.dart — Nourish V Route Configuration
// Updated: Phase 4 — TFLite Risk System
//
// CHANGES:
//   - Removed /camera (CameraView deleted)
//   - Removed /results (replaced by /assessment-result)
//   - Added /assessment → AssessmentFormView (takes Patient arg)
//   - Updated /assessment-result → takes Assessment arg
// ============================================================

import 'package:flutter/material.dart';
import 'package:nourish_v/core/animations.dart';
import 'package:nourish_v/models/assessment.dart';
import 'package:nourish_v/models/patient.dart';
import 'package:nourish_v/views/auth/login_view.dart';
import 'package:nourish_v/views/dashboard/supervisor_dashboard_view.dart';
import 'package:nourish_v/views/data_entry/patient_form_view.dart';
import 'package:nourish_v/views/data_entry/assessment_form_view.dart';
import 'package:nourish_v/views/home/home_view.dart';
import 'package:nourish_v/views/reports/government_report_view.dart';
import 'package:nourish_v/views/results/assessment_detail_view.dart';
import 'package:nourish_v/views/results/assessment_result_view.dart';
import 'package:nourish_v/views/settings/settings_view.dart';
import 'package:nourish_v/views/splash/splash_view.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return FadeScalePageRoute(settings: settings, page: const SplashView());

      case '/login':
        return FadeScalePageRoute(settings: settings, page: const LoginView());

      case '/home':
        return FadeScalePageRoute(settings: settings, page: const HomeView());

      // ---- Registration (no arg) OR Edit baseline (Patient arg) ----
      case '/data-entry':
        return SlidePageRoute(settings: settings, page: PatientFormView(key: UniqueKey()));

      // ---- Monthly checkup: takes Patient as argument ----
      case '/assessment':
        final patient = settings.arguments as Patient;
        return SlidePageRoute(
          settings: settings,
          page: AssessmentFormView(patient: patient),
        );

      // ---- Result view: takes Assessment as argument ----
      case '/assessment-result':
        final assessment = settings.arguments as Assessment;
        return FadeScalePageRoute(
          settings: settings,
          page: AssessmentResultView(assessment: assessment),
        );

      // ---- Assessment history detail ----
      case '/assessment-detail':
        final assessment = settings.arguments as Assessment;
        return SlidePageRoute(
          settings: settings,
          page: AssessmentDetailView(assessment: assessment),
        );

      case '/dashboard':
        return SlidePageRoute(settings: settings, page: const SupervisorDashboardView());

      case '/settings':
        return SlidePageRoute(settings: settings, page: const SettingsView());

      case '/government-reports':
        return SlidePageRoute(settings: settings, page: const GovernmentReportView());

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('Route not found: ${settings.name}'),
            ),
          ),
        );
    }
  }
}
