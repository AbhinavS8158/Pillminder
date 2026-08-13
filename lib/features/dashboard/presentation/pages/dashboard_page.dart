import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/models/dose_occurrence_model.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/repositories/medicine_repository.dart';
import '../bloc/dashboard_cubit.dart';
import '../bloc/dashboard_state.dart';
import '../../../reminder/presentation/pages/reminder_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final TextEditingController _searchController = TextEditingController();
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    context.read<DashboardCubit>().loadDashboardData();
    
    // Center today (index 7) on load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _centerSelectedDate(7, immediate: true);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  int _findSelectedIndex(List<DateTime> dates, DateTime selectedDate) {
    for (int i = 0; i < dates.length; i++) {
      if (DateUtils.isSameDay(dates[i], selectedDate)) {
        return i;
      }
    }
    return 7;
  }

  void _centerSelectedDate(int index, {bool immediate = false}) {
    if (_scrollController.hasClients) {
      final screenWidth = MediaQuery.of(context).size.width;
      // Item width is 56 (width) + 8 (margin) = 64
      final targetOffset = (index * 64.0) - (screenWidth / 2) + (64.0 / 2) + 16.0;
      final maxScroll = _scrollController.position.maxScrollExtent;
      final minScroll = _scrollController.position.minScrollExtent;
      final boundedOffset = targetOffset.clamp(minScroll, maxScroll);

      if (immediate) {
        _scrollController.jumpTo(boundedOffset);
      } else {
        _scrollController.animateTo(
          boundedOffset,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<DashboardCubit, DashboardState>(
          builder: (context, state) {
            if (state.status == DashboardStatus.initial ||
                state.status == DashboardStatus.loading && state.occurrences.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state.status == DashboardStatus.error) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: AppTheme.missedRed),
                    const SizedBox(height: 16),
                    Text(
                      'Something went wrong',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(state.errorMessage, textAlign: TextAlign.center),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context.read<DashboardCubit>().loadDashboardData(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () => context.read<DashboardCubit>().loadDashboardData(),
              child: CustomScrollView(
                slivers: [
                  // App Bar / Header
                  SliverToBoxAdapter(child: _buildHeader(state)),

                  // Stats Panel
                  SliverToBoxAdapter(child: _buildStatsGrid(state)),

                  // Date Strip
                  SliverToBoxAdapter(child: _buildDateStrip(state)),

                  // Search Bar
                  SliverToBoxAdapter(child: _buildSearchBar()),

                  // Schedule List
                  _buildDoseList(state),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(DashboardState state) {
    final todayStr = DateFormat('EEEE, d MMMM').format(state.selectedDate);
    final isTodaySelected = DateUtils.isSameDay(state.selectedDate, DateTime.now());

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isTodaySelected ? "Today's Schedule" : DateFormat('d MMM yyyy').format(state.selectedDate),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                todayStr,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          // Small badge indicating overall adherence
          if (state.totalDoses > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.primaryTeal.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${((state.takenDoses / state.totalDoses) * 100).toInt()}% Done',
                style: const TextStyle(
                  color: AppTheme.primaryTeal,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(DashboardState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // Taken Progress Bar
          if (state.totalDoses > 0) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: state.totalDoses > 0 ? (state.takenDoses / state.totalDoses) : 0.0,
                minHeight: 8,
                backgroundColor: AppTheme.primaryTeal.withOpacity(0.1),
                valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.successGreen),
              ),
            ),
            const SizedBox(height: 16),
          ],
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: 'Taken',
                  count: state.takenDoses,
                  color: AppTheme.successGreen,
                  icon: Icons.check_circle_outline,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  title: 'Pending',
                  count: state.pendingDoses,
                  color: AppTheme.pendingAmber,
                  icon: Icons.hourglass_empty_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: 'Missed',
                  count: state.missedDoses,
                  color: AppTheme.missedRed,
                  icon: Icons.cancel_outlined,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  title: 'Skipped',
                  count: state.skippedDoses,
                  color: AppTheme.skippedGray,
                  icon: Icons.next_plan_outlined,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required int count,
    required Color color,
    required IconData icon,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSlate : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  count.toString(),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  title,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateStrip(DashboardState state) {
    final today = DateTime.now();
    
    // Generate dates: 7 days before selected date to 7 days after
    final dates = List<DateTime>.generate(15, (index) {
      return today.subtract(Duration(days: 7 - index));
    });

    final selectedIndex = _findSelectedIndex(dates, state.selectedDate);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _centerSelectedDate(selectedIndex);
    });

    return Container(
      height: 90,
      margin: const EdgeInsets.only(top: 20),
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: dates.length,
        itemBuilder: (context, index) {
          final date = dates[index];
          final isSelected = DateUtils.isSameDay(date, state.selectedDate);
          final isToday = DateUtils.isSameDay(date, today);
          
          return GestureDetector(
            onTap: () {
              context.read<DashboardCubit>().changeDate(date);
              _centerSelectedDate(index);
            },
            child: Container(
              width: 56,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                gradient: isSelected ? AppTheme.primaryGradient : null,
                color: isSelected
                    ? null
                    : (Theme.of(context).brightness == Brightness.dark
                        ? AppTheme.darkSlate
                        : Colors.white),
                borderRadius: BorderRadius.circular(16),
                border: isToday && !isSelected
                    ? Border.all(color: AppTheme.primaryTeal, width: 1.5)
                    : null,
                boxShadow: [
                  if (isSelected)
                    BoxShadow(
                      color: AppTheme.primaryTeal.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  else
                    BoxShadow(
                      color: Colors.black.withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.3 : 0.02),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('E').format(date).toUpperCase().substring(0, 2),
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    date.day.toString(),
                    style: TextStyle(
                      color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: TextField(
        controller: _searchController,
        onChanged: (val) => context.read<DashboardCubit>().changeSearchQuery(val),
        decoration: InputDecoration(
          hintText: 'Search medicine, type, or description...',
          prefixIcon: const Icon(Icons.search, color: AppTheme.primaryTeal),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    context.read<DashboardCubit>().changeSearchQuery('');
                  },
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildDoseList(DashboardState state) {
    final filtered = state.filteredOccurrences;

    if (filtered.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                state.searchQuery.isNotEmpty ? Icons.search_off : Icons.medical_services_outlined,
                size: 80,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
              ),
              const SizedBox(height: 16),
              Text(
                state.searchQuery.isNotEmpty ? 'No matches found' : 'All Clear!',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                state.searchQuery.isNotEmpty
                    ? 'Try searching with a different term'
                    : 'No medicines scheduled for this day.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
              ),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 80), // extra padding at bottom for FAB spacing
      sliver: SliverList(
        delegate: SliverChildBuilderRow(
          (context, index) {
            final occ = filtered[index];
            final medicine = state.medicines[occ.medicineId];
            final medName = medicine?.name ?? 'Deleted Medicine';
            final medType = medicine?.type ?? 'Other';
            
            // Format scheduled time
            final scheduledTime = occ.snoozedUntil ?? occ.scheduledAt;
            final timeStr = DateFormat('hh:mm a').format(scheduledTime);

            Color statusColor;
            IconData statusIcon;
            String statusText = occ.status.toUpperCase();

            switch (occ.status) {
              case 'taken':
                statusColor = AppTheme.successGreen;
                statusIcon = Icons.check_circle;
                statusText = 'Taken';
                break;
              case 'skipped':
                statusColor = AppTheme.skippedGray;
                statusIcon = Icons.next_plan;
                statusText = 'Skipped';
                break;
              case 'missed':
                statusColor = AppTheme.missedRed;
                statusIcon = Icons.cancel;
                statusText = 'Missed';
                break;
              default:
                statusColor = AppTheme.primaryTeal;
                statusIcon = Icons.hourglass_top;
                statusText = 'Pending';
            }

            if (occ.snoozedUntil != null && occ.status == 'pending') {
              statusColor = AppTheme.pendingAmber;
              statusIcon = Icons.snooze;
              statusText = 'Snoozed';
            }

            final isDark = Theme.of(context).brightness == Brightness.dark;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 0,
              color: isDark ? AppTheme.darkSlate : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: isDark ? const Color(0xFF334155).withOpacity(0.5) : const Color(0xFFE2E8F0),
                  width: 1,
                ),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  // Navigate to the dedicated Reminder Screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ReminderPage(occurrenceId: occ.id),
                    ),
                  ).then((_) {
                    // Refresh dashboard after returning
                    context.read<DashboardCubit>().refreshData();
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      // Time indicator
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            timeStr.split(' ')[0],
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                            ),
                          ),
                          Text(
                            timeStr.split(' ')[1],
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      // Divider line
                      Container(
                        height: 40,
                        width: 1.5,
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      ),
                      const SizedBox(width: 16),
                      // Medicine details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              medName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${occ.dose} • $medType',
                              style: TextStyle(
                                fontSize: 13,
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (occ.foodInstruction.trim().isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.restaurant_menu,
                                      size: 14,
                                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4)),
                                  const SizedBox(width: 4),
                                  Text(
                                    occ.foodInstruction,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ),
                            ]
                          ],
                        ),
                      ),
                      // Status Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(statusIcon, size: 14, color: statusColor),
                            const SizedBox(width: 4),
                            Text(
                              statusText,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: statusColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
          childCount: filtered.length,
        ),
      ),
    );
  }
}

// Helper utility for generating custom lists in slivers
class SliverChildBuilderRow extends SliverChildBuilderDelegate {
  SliverChildBuilderRow(
    Widget Function(BuildContext, int) builder, {
    int? childCount,
  }) : super(builder, childCount: childCount);
}
