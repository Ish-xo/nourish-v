// ============================================================
// home_view.dart — Nourish V Home & Navigation Shell
// Updated: Phase 4 — TFLite Risk System
//
// WORKER CHANGES:
//   - "Home" tab is now a Patient Roster (not a static dashboard)
//   - Search bar to filter by patient name / location
//   - FAB: "+ Register New Child" → /data-entry
//   - Tapping a patient card → /assessment (AssessmentFormView)
//   - "History" tab shows past assessments with risk badges
//
// ADMIN: unchanged (Dashboard + Reports + Settings)
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';
import '../../core/animations.dart';
import '../../controllers/localization_controller.dart';
import '../../controllers/assessment_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../core/constants.dart';
import '../../models/patient.dart';
import '../../models/assessment.dart';
import '../dashboard/supervisor_dashboard_view.dart';
import '../reports/government_report_view.dart';
import '../settings/settings_view.dart';

class HomeView extends ConsumerStatefulWidget {
  const HomeView({super.key});

  @override
  ConsumerState<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends ConsumerState<HomeView> {
  int _currentIndex = 0;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final authState = ref.read(authControllerProvider);
      if (authState.isWorker && authState.user != null) {
        // Load both the patient roster and assessment history
        ref
            .read(assessmentControllerProvider.notifier)
            .loadPatientRoster(authState.user!.uid);
        ref
            .read(assessmentControllerProvider.notifier)
            .loadWorkerHistory(authState.user!.uid);
      } else if (authState.isAdmin) {
        ref.read(assessmentControllerProvider.notifier).loadAllHistory();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onBottomNavTap(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(localizationProvider);
    final l10n = ref.read(localizationProvider.notifier);
    final authState = ref.watch(authControllerProvider);

    final isAdmin = authState.isAdmin;
    final tabCount = isAdmin ? 4 : (authState.isWorker ? 3 : 0);

    // Safety clamp: prevents out-of-bounds if role changes mid-session
    if (tabCount > 0 && _currentIndex >= tabCount) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _currentIndex = 0);
      });
    }
    final safeIndex = tabCount > 0 ? _currentIndex.clamp(0, tabCount - 1) : 0;

    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: safeIndex,
          children: isAdmin
              ? [
                  _buildAdminDashboardTab(context, l10n),
                  const SupervisorDashboardView(isEmbedded: true),
                  const GovernmentReportView(isEmbedded: true),
                  const SettingsView(isEmbedded: true),
                ]
              : [
                  _buildRosterTab(context, l10n),
                  _buildHistoryTab(context, l10n),
                  const SettingsView(isEmbedded: true),
                ],
        ),
      ),
      // Removed FAB completely as per user request to move to top of roster
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: safeIndex,
          onTap: _onBottomNavTap,
          selectedLabelStyle:
              GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600),
          unselectedLabelStyle: GoogleFonts.poppins(fontSize: 11),
          items: isAdmin
              ? [
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.home_rounded),
                    label: l10n.tr('Home'),
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.dashboard_rounded),
                    label: l10n.tr('Dashboard'),
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.account_balance_rounded),
                    label: l10n.tr('Reports'),
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.settings_rounded),
                    label: l10n.tr('Settings'),
                  ),
                ]
              : [
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.people_rounded),
                    activeIcon: const Icon(Icons.people_rounded),
                    label: l10n.tr('My Patients'),
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.history_rounded),
                    activeIcon: const Icon(Icons.history_rounded),
                    label: l10n.tr('History'),
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.settings_rounded),
                    activeIcon: const Icon(Icons.settings_rounded),
                    label: l10n.tr('Settings'),
                  ),
                ],
        ),
      ),
    );
  }

  // ---- Shared App Bar Widget ----

  Widget _buildAppBar(BuildContext context, LocalizationController l10n,
      {String? subtitle}) {
    final authState = ref.watch(authControllerProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Image.asset('assets/icon/icon.png'),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.tr('Nourish V'),
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimaryLight,
                ),
              ),
              if (authState.user != null)
                Text(
                  subtitle ?? authState.user!.name,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: AppColors.textSecondaryLight,
                  ),
                ),
            ],
          ),
          const Spacer(),
          if (authState.user != null)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: authState.isAdmin
                    ? const Color(0xFF1565C0).withValues(alpha: 0.1)
                    : AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                l10n.tr(authState.isAdmin ? 'Admin' : 'Worker'),
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: authState.isAdmin
                      ? const Color(0xFF1565C0)
                      : AppColors.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // WORKER: ROSTER TAB
  // ============================================================

  Widget _buildRosterTab(BuildContext context, LocalizationController l10n) {
    final state = ref.watch(assessmentControllerProvider);
    final authState = ref.watch(authControllerProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAppBar(context, l10n),

        // Search Bar
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: TextField(
            controller: _searchController,
            onChanged: (q) =>
                ref.read(assessmentControllerProvider.notifier).filterRoster(q),
            style: GoogleFonts.poppins(fontSize: 14),
            decoration: InputDecoration(
              hintText: l10n.tr('Search patients by name or location...'),
              hintStyle: GoogleFonts.poppins(
                  fontSize: 13, color: AppColors.textSecondaryLight),
              prefixIcon: const Icon(Icons.search_rounded,
                  color: AppColors.primary, size: 22),
              suffixIcon: state.searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded,
                          color: AppColors.textSecondaryLight, size: 20),
                      onPressed: () {
                        _searchController.clear();
                        ref
                            .read(assessmentControllerProvider.notifier)
                            .filterRoster('');
                      },
                    )
                  : null,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ).animate(delay: const Duration(milliseconds: 100)).fadeIn().slideY(begin: 0.1, end: 0),

        // Header row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Text(
                l10n.tr('My Patients'),
                style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimaryLight),
              ),
              const Spacer(),
              if (state.patientRoster.isNotEmpty)
                Text(
                  '${state.filteredRoster.length} ${l10n.tr('children')}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.textSecondaryLight,
                  ),
                ),
            ],
          ),
          ).animate(delay: const Duration(milliseconds: 50)).fadeIn(),

        const SizedBox(height: 16),

        // Action Button: Add New Child (Replaces old FAB)
        if (!authState.isAdmin)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TapScaleWrapper(
              onTap: () => Navigator.pushNamed(context, '/data-entry'),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDark],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.person_add_rounded, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      l10n.tr('Register New Child'),
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ).animate(delay: const Duration(milliseconds: 80)).fadeIn().slideY(begin: 0.1, end: 0),

        const SizedBox(height: 12),

        // Roster List
        Expanded(
          child: state.viewState == ViewState.loading
              ? const Center(child: LoadingPulse())
              : RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () async {
                    if (authState.user != null) {
                      await ref
                          .read(assessmentControllerProvider.notifier)
                          .loadPatientRoster(authState.user!.uid);
                    }
                  },
                  child: state.filteredRoster.isEmpty
                      ? _buildEmptyRoster(l10n)
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                          itemCount: state.filteredRoster.length,
                          itemBuilder: (context, index) {
                            return _buildPatientCard(
                              context,
                              state.filteredRoster[index],
                              state,
                              l10n,
                              index,
                            );
                          },
                        ),
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyRoster(LocalizationController l10n) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 60),
        Center(
          child: Column(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.child_care_rounded,
                    size: 40, color: AppColors.primary),
              ),
              const SizedBox(height: 20),
              Text(
                l10n.tr('No children registered yet'),
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.tr('Tap "+ Register New Child" to add your first patient'),
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: AppColors.textSecondaryLight,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ).animate().fadeIn(duration: const Duration(milliseconds: 600)),
      ],
    );
  }

  Widget _buildPatientCard(
    BuildContext context,
    Patient patient,
    AssessmentState state,
    LocalizationController l10n,
    int index,
  ) {
    // Find the most recent assessment for this patient (if any)
    final latestAssessment = state.history
        .where((a) => a.patientId == patient.id)
        .toList()
      ..sort((a, b) => b.assessmentDate.compareTo(a.assessmentDate));
    final Assessment? lastAssessment =
        latestAssessment.isNotEmpty ? latestAssessment.first : null;

    // Risk badge color
    Color? riskColor;
    if (lastAssessment != null) {
      switch (lastAssessment.riskCategory) {
        case RiskCategory.low:
          riskColor = AppColors.healthy;
          break;
        case RiskCategory.moderate:
          riskColor = AppColors.atRisk;
          break;
        case RiskCategory.high:
          riskColor = AppColors.severe;
          break;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: GlassDecoration.card(),
      child: InkWell(
        onTap: () {
          // Primary tap: go to assessment form
          ref
              .read(assessmentControllerProvider.notifier)
              .selectPatientForAssessment(patient);
          Navigator.pushNamed(context, '/assessment', arguments: patient);
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
          child: Row(
            children: [
              // Avatar initial circle
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.8),
                      AppColors.primaryDark.withValues(alpha: 0.9),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    patient.name.isNotEmpty
                        ? patient.name[0].toUpperCase()
                        : '?',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Patient info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      patient.name,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${patient.ageDisplay} • ${patient.gender == 'M' ? l10n.tr('Boy') : l10n.tr('Girl')} • ${patient.location}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppColors.textSecondaryLight,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (lastAssessment != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${l10n.tr('Last visit')}: ${_formatDate(lastAssessment.assessmentDate)}',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Risk badge (if assessed before)
              if (lastAssessment != null && riskColor != null) ...[
                const SizedBox(width: 6),
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: riskColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: riskColor.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        lastAssessment.riskPercentage,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: riskColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.tr(lastAssessment.riskLabel),
                      style: GoogleFonts.poppins(
                        fontSize: 9,
                        color: riskColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ] else ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.divider.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    l10n.tr('Not assessed'),
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                ),
              ],

              // --- Next arrow indicator ---
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondaryLight.withValues(alpha: 0.4),
                size: 24,
              ),
            ],
          ),
        ),
      ),
    )
        .animate(
            delay: CascadeAnimationHelper.cascadeDelay(index, baseMs: 40))
        .fadeIn(duration: const Duration(milliseconds: 300))
        .slideX(begin: 0.05, end: 0);
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  // ============================================================
  // WORKER: HISTORY TAB
  // ============================================================

  Widget _buildHistoryTab(BuildContext context, LocalizationController l10n) {
    final state = ref.watch(assessmentControllerProvider);
    final authState = ref.watch(authControllerProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAppBar(context, l10n),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            l10n.tr('Assessment History'),
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimaryLight,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: state.viewState == ViewState.loading
              ? const Center(child: LoadingPulse())
              : RefreshIndicator(
                  onRefresh: () async {
                    if (authState.isWorker && authState.user != null) {
                      await ref
                          .read(assessmentControllerProvider.notifier)
                          .loadWorkerHistory(authState.user!.uid);
                    } else if (authState.isAdmin) {
                      await ref
                          .read(assessmentControllerProvider.notifier)
                          .loadAllHistory();
                    }
                  },
                  color: AppColors.primary,
                  child: state.history.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.4,
                              child: Center(
                                child: Text(
                                  l10n.tr('No assessments yet'),
                                  style: GoogleFonts.poppins(
                                      color: AppColors.textSecondaryLight),
                                ),
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: state.history.length,
                          itemBuilder: (context, index) {
                            final a = state.history[index];
                            Color riskColor;
                            switch (a.riskCategory) {
                              case RiskCategory.low:
                                riskColor = AppColors.healthy;
                                break;
                              case RiskCategory.moderate:
                                riskColor = AppColors.atRisk;
                                break;
                              case RiskCategory.high:
                                riskColor = AppColors.severe;
                                break;
                            }

                            return TapScaleWrapper(
                              onTap: () => Navigator.pushNamed(
                                context,
                                '/assessment-detail',
                                arguments: a,
                              ),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(14),
                                decoration: GlassDecoration.card(),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: riskColor.withValues(alpha: 0.12),
                                        borderRadius:
                                            BorderRadius.circular(12),
                                      ),
                                      child: Center(
                                        child: Text(
                                          a.patientName.isNotEmpty
                                              ? a.patientName[0].toUpperCase()
                                              : '?',
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w700,
                                            color: riskColor,
                                            fontSize: 18,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            a.patientName,
                                            style: GoogleFonts.poppins(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          Text(
                                            '${a.location} • ${_formatDate(a.assessmentDate)}',
                                            style: GoogleFonts.poppins(
                                              fontSize: 11,
                                              color:
                                                  AppColors.textSecondaryLight,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color:
                                            riskColor.withValues(alpha: 0.12),
                                        borderRadius:
                                            BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        a.riskPercentage,
                                        style: GoogleFonts.poppins(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: riskColor,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Icon(
                                      Icons.chevron_right_rounded,
                                      color: AppColors.textSecondaryLight
                                          .withValues(alpha: 0.4),
                                      size: 20,
                                    ),
                                  ],
                                ),
                              ),
                            )
                                .animate(
                                    delay: CascadeAnimationHelper.cascadeDelay(
                                        index,
                                        baseMs: 40))
                                .fadeIn(
                                    duration:
                                        const Duration(milliseconds: 300))
                                .slideX(begin: 0.05, end: 0);
                          },
                        ),
                ),
        ),
      ],
    );
  }

  // ============================================================
  // ADMIN: DASHBOARD OVERVIEW TAB
  // ============================================================

  Widget _buildAdminDashboardTab(
      BuildContext context, LocalizationController l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAppBar(context, l10n),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            l10n.tr('Dashboard'),
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimaryLight,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(child: _buildAdminOverview(context, l10n)),
      ],
    );
  }

  Widget _buildAdminOverview(BuildContext context, LocalizationController l10n) {
    final state = ref.watch(assessmentControllerProvider);
    if (state.viewState == ViewState.loading) {
      return const Center(child: LoadingPulse());
    }

    final assessments = state.history;
    final total = assessments.length;
    final highCount =
        assessments.where((a) => a.riskCategory == RiskCategory.high).length;
    final modCount =
        assessments.where((a) => a.riskCategory == RiskCategory.moderate).length;
    final lowCount =
        assessments.where((a) => a.riskCategory == RiskCategory.low).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _adminStatCard(l10n.tr('Total'), '$total', AppColors.primary,
                  Icons.people_rounded),
              const SizedBox(width: 10),
              _adminStatCard(l10n.tr('High Risk'), '$highCount',
                  AppColors.severe, Icons.warning_rounded),
            ],
          )
              .animate(delay: const Duration(milliseconds: 200))
              .fadeIn()
              .slideY(begin: 0.1, end: 0),
          const SizedBox(height: 10),
          Row(
            children: [
              _adminStatCard(l10n.tr('Moderate'), '$modCount', AppColors.atRisk,
                  Icons.info_rounded),
              const SizedBox(width: 10),
              _adminStatCard(l10n.tr('Low Risk'), '$lowCount',
                  AppColors.healthy, Icons.check_circle_rounded),
            ],
          )
              .animate(delay: const Duration(milliseconds: 300))
              .fadeIn()
              .slideY(begin: 0.1, end: 0),
          const SizedBox(height: 20),
          Text(
            l10n.tr('Recent Assessments'),
            style: GoogleFonts.poppins(
                fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          if (assessments.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  l10n.tr('No assessments yet'),
                  style: GoogleFonts.poppins(
                      color: AppColors.textSecondaryLight),
                ),
              ),
            )
          else
            ...assessments.take(10).map((a) {
              Color riskColor;
              switch (a.riskCategory) {
                case RiskCategory.low:
                  riskColor = AppColors.healthy;
                  break;
                case RiskCategory.moderate:
                  riskColor = AppColors.atRisk;
                  break;
                case RiskCategory.high:
                  riskColor = AppColors.severe;
                  break;
              }
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: GlassDecoration.card(),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: riskColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          a.patientName.isNotEmpty
                              ? a.patientName[0].toUpperCase()
                              : '?',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            color: riskColor,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${a.patientName} • ${a.location}',
                        style: GoogleFonts.poppins(
                            fontSize: 12, fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: riskColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        a.riskPercentage,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: riskColor,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _adminStatCard(
      String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
