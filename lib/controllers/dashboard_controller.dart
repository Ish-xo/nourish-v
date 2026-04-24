import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants.dart';
import '../repositories/assessment_repository.dart';
import 'assessment_controller.dart';

// ---- Dashboard State ----

class DashboardState {
  final ViewState viewState;
  final Map<String, dynamic> stats;
  final List<Map<String, dynamic>> regionData;
  final List<Map<String, dynamic>> monthlyTrends;
  final String? errorMessage;

  const DashboardState({
    this.viewState = ViewState.initial,
    this.stats = const {},
    this.regionData = const [],
    this.monthlyTrends = const [],
    this.errorMessage,
  });

  DashboardState copyWith({
    ViewState? viewState,
    Map<String, dynamic>? stats,
    List<Map<String, dynamic>>? regionData,
    List<Map<String, dynamic>>? monthlyTrends,
    String? errorMessage,
  }) {
    return DashboardState(
      viewState: viewState ?? this.viewState,
      stats: stats ?? this.stats,
      regionData: regionData ?? this.regionData,
      monthlyTrends: monthlyTrends ?? this.monthlyTrends,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

// ---- Dashboard Controller ----

class DashboardController extends StateNotifier<DashboardState> {
  final AssessmentRepository _repository;

  DashboardController(this._repository) : super(const DashboardState());

  /// Load all dashboard data
  Future<void> loadDashboard() async {
    state = state.copyWith(viewState: ViewState.loading);
    try {
      final results = await Future.wait([
        _repository.getDashboardStats(),
        _repository.getRegionWiseData(),
        _repository.getMonthlyTrends(),
      ]);

      state = state.copyWith(
        viewState: ViewState.success,
        stats: results[0] as Map<String, dynamic>,
        regionData: results[1] as List<Map<String, dynamic>>,
        monthlyTrends: results[2] as List<Map<String, dynamic>>,
      );
    } catch (e) {
      state = state.copyWith(
        viewState: ViewState.error,
        errorMessage: e.toString(),
      );
    }
  }
}

// ---- Riverpod Provider ----

final dashboardControllerProvider =
    StateNotifierProvider<DashboardController, DashboardState>((ref) {
  final repository = ref.watch(assessmentRepositoryProvider);
  return DashboardController(repository);
});
