import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/theme.dart';
import '../bloc/history_cubit.dart';
import '../bloc/history_state.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<HistoryCubit>().loadHistory();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<HistoryCubit, HistoryState>(
          builder: (context, state) {
            if (state.status == HistoryStatus.initial ||
                state.status == HistoryStatus.loading && state.occurrences.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            return CustomScrollView(
              slivers: [
                // Header
                SliverToBoxAdapter(child: _buildHeader(state)),

                // Filters (Search + Status row + Date pickers)
                SliverToBoxAdapter(child: _buildFiltersSection(state)),

                // List
                _buildHistoryList(state),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(HistoryState state) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Treatment History',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Keep track of your adherence over time',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersSection(HistoryState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        children: [
          // Search Input
          TextField(
            controller: _searchController,
            onChanged: (val) => context.read<HistoryCubit>().changeSearchQuery(val),
            decoration: InputDecoration(
              hintText: 'Search history...',
              prefixIcon: const Icon(Icons.search, color: AppTheme.primaryTeal),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        context.read<HistoryCubit>().changeSearchQuery('');
                      },
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 12),
          // Status Filters Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildStatusChip(state, label: 'All Doses', filterVal: 'all'),
                const SizedBox(width: 8),
                _buildStatusChip(state, label: 'Taken', filterVal: 'taken', color: AppTheme.successGreen),
                const SizedBox(width: 8),
                _buildStatusChip(state, label: 'Missed', filterVal: 'missed', color: AppTheme.missedRed),
                const SizedBox(width: 8),
                _buildStatusChip(state, label: 'Skipped', filterVal: 'skipped', color: AppTheme.skippedGray),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Date Filter Trigger
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: state.selectedDate != null ? AppTheme.primaryTeal : Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    state.selectedDate != null
                        ? 'Filtered: ${DateFormat('d MMM yyyy').format(state.selectedDate!)}'
                        : 'Filter by Specific Date',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: state.selectedDate != null ? AppTheme.primaryTeal : Colors.grey,
                    ),
                  ),
                ],
              ),
              if (state.selectedDate != null)
                IconButton(
                  icon: const Icon(Icons.cancel, size: 20, color: AppTheme.missedRed),
                  onPressed: () => context.read<HistoryCubit>().changeDateFilter(null),
                )
              else
                TextButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now().subtract(const Duration(days: 365)),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      context.read<HistoryCubit>().changeDateFilter(picked);
                    }
                  },
                  child: const Text(
                    'Select Date',
                    style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryTeal),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(
    HistoryState state, {
    required String label,
    required String filterVal,
    Color? color,
  }) {
    final isSelected = state.statusFilter == filterVal;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (val) {
        if (val) {
          context.read<HistoryCubit>().changeStatusFilter(filterVal);
        }
      },
      selectedColor: color?.withOpacity(0.2) ?? AppTheme.primaryTeal.withOpacity(0.2),
      checkmarkColor: color ?? AppTheme.primaryTeal,
      labelStyle: TextStyle(
        fontWeight: FontWeight.bold,
        color: isSelected
            ? (color ?? AppTheme.primaryTeal)
            : (isDark ? Colors.white60 : Colors.black54),
      ),
      backgroundColor: isDark ? AppTheme.darkSlate : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isSelected
              ? (color ?? AppTheme.primaryTeal)
              : (isDark ? Colors.transparent : Colors.grey.shade300),
          width: 1.5,
        ),
      ),
    );
  }

  Widget _buildHistoryList(HistoryState state) {
    final filtered = state.filteredOccurrences;

    if (filtered.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.history_toggle_off,
                size: 80,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
              ),
              const SizedBox(height: 16),
              const Text(
                'No History Found',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Once you act on a reminder or a scheduled dose passes, it will appear here.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
              ),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final occ = filtered[index];
            final medicine = state.medicines[occ.medicineId];
            final medName = medicine?.name ?? 'Deleted Medicine';
            final typeStr = medicine?.type ?? 'Other';

            final timeStr = DateFormat('hh:mm a').format(occ.snoozedUntil ?? occ.scheduledAt);
            final dateStr = DateFormat('d MMM yyyy').format(occ.scheduledAt);

            Color statusColor;
            IconData statusIcon;
            String statusText;

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
              default:
                statusColor = AppTheme.missedRed;
                statusIcon = Icons.cancel;
                statusText = 'Missed';
            }

            final isDark = Theme.of(context).brightness == Brightness.dark;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              color: isDark ? AppTheme.darkSlate : Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: isDark ? const Color(0xFF334155).withOpacity(0.5) : const Color(0xFFE2E8F0),
                  width: 1,
                ),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        medName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, color: statusColor, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            statusText,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Text(
                      '${occ.dose} • $typeStr',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Scheduled: $dateStr at $timeStr',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                    if (occ.actionAt != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Logged: ${DateFormat('d MMM hh:mm a').format(occ.actionAt!)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.primaryTeal.withOpacity(0.8),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    if (occ.foodInstruction.trim().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.restaurant_menu,
                              size: 12,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4)),
                          const SizedBox(width: 4),
                          Text(
                            occ.foodInstruction,
                            style: TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                            ),
                          ),
                        ],
                      ),
                    ]
                  ],
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
