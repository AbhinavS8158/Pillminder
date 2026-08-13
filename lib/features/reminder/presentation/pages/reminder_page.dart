import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/repositories/medicine_repository.dart';
import '../../../../core/repositories/settings_repository.dart';
import '../bloc/reminder_cubit.dart';
import '../bloc/reminder_state.dart';

class ReminderPage extends StatelessWidget {
  final String occurrenceId;

  const ReminderPage({super.key, required this.occurrenceId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ReminderCubit(
        medicineRepository: context.read<MedicineRepository>(),
        settingsRepository: context.read<SettingsRepository>(),
      )..showReminder(occurrenceId),
      child: const ReminderView(),
    );
  }
}

class ReminderView extends StatelessWidget {
  const ReminderView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ReminderCubit, ReminderState>(
      listener: (context, state) {
        if (state is ReminderSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppTheme.successGreen,
            ),
          );
          Navigator.pop(context);
        } else if (state is ReminderError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppTheme.missedRed,
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is ReminderLoading || state is ReminderInitial) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (state is ReminderActive) {
          final occ = state.occurrence;
          final med = state.medicine;
          final timeStr = DateFormat('hh:mm a').format(occ.snoozedUntil ?? occ.scheduledAt);

          return Scaffold(
            appBar: AppBar(
              title: const Text('Medicine Reminder'),
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Spacer(),
                    
                    // Large visual capsule/pill representation
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryTeal.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.medical_services_outlined,
                        size: 80,
                        color: AppTheme.primaryTeal,
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // Medicine Name and details
                    Text(
                      med.name,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${occ.dose} • ${med.type}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    
                    // Description
                    if (med.description.trim().isNotEmpty) ...[
                      Text(
                        med.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Time & Instructions Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppTheme.darkSlate
                            : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? const Color(0xFF334155).withOpacity(0.5)
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Scheduled Time',
                                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Colors.grey),
                              ),
                              Text(
                                timeStr,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primaryTeal),
                              ),
                            ],
                          ),
                          if (occ.foodInstruction.trim().isNotEmpty) ...[
                            const SizedBox(height: 12),
                            const Divider(height: 1),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Food Instruction',
                                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Colors.grey),
                                ),
                                Text(
                                  occ.foodInstruction,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    
                    const Spacer(),
                    
                    // Actions Panel
                    Column(
                      children: [
                        // Taken Button (Primary Success)
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: AppTheme.successGradient,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.successGreen.withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: () => context.read<ReminderCubit>().takeMedicine(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check, color: Colors.white),
                                SizedBox(width: 8),
                                Text(
                                  'Taken',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Snooze & Skip Row
                        Row(
                          children: [
                            // Snooze Button
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => _showSnoozeOptions(context),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  side: const BorderSide(color: AppTheme.pendingAmber, width: 2),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.snooze, color: AppTheme.pendingAmber),
                                    SizedBox(width: 8),
                                    Text(
                                      'Snooze',
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.pendingAmber),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            
                            // Skip Button
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => context.read<ReminderCubit>().skipMedicine(),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  side: const BorderSide(color: AppTheme.skippedGray, width: 2),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.skip_next, color: AppTheme.skippedGray),
                                    SizedBox(width: 8),
                                    Text(
                                      'Skip',
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.skippedGray),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          );
        }

        return const Scaffold(
          body: Center(child: Text('Reminder closed.')),
        );
      },
    );
  }

  void _showSnoozeOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(20.0),
                child: Text(
                  'Select Snooze Interval',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const Divider(height: 1),
              _buildSnoozeOption(context, bottomSheetContext, minutes: 5),
              _buildSnoozeOption(context, bottomSheetContext, minutes: 10),
              _buildSnoozeOption(context, bottomSheetContext, minutes: 15),
              _buildSnoozeOption(context, bottomSheetContext, minutes: 30),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSnoozeOption(BuildContext context, BuildContext bottomSheetContext, {required int minutes}) {
    return ListTile(
      leading: const Icon(Icons.timer_outlined, color: AppTheme.primaryTeal),
      title: Text('$minutes Minutes'),
      onTap: () {
        Navigator.pop(bottomSheetContext); // Close bottom sheet
        context.read<ReminderCubit>().snoozeMedicine(customSnoozeMinutes: minutes);
      },
    );
  }
}
