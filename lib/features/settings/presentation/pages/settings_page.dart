import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/models/app_settings_model.dart';
import '../bloc/settings_cubit.dart';
import '../bloc/settings_state.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late AudioPlayer _audioPlayer;
  String? _playingSoundKey;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _audioPlayer.onPlayerComplete.listen((_) {
      setState(() {
        _playingSoundKey = null;
      });
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _previewSound(String soundKey) async {
    // If same sound is playing, stop it
    if (_playingSoundKey == soundKey) {
      await _audioPlayer.stop();
      setState(() {
        _playingSoundKey = null;
      });
      return;
    }

    // Stop current audio play
    await _audioPlayer.stop();

    String assetName = 'alarm1.wav';
    if (soundKey == 'alarm2') {
      assetName = 'alarm2.wav';
    } else if (soundKey == 'alarm3') {
      assetName = 'alarm3.wav';
    }

    try {
      await _audioPlayer.play(AssetSource('sounds/$assetName'));
      setState(() {
        _playingSoundKey = soundKey;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not play sound: $e'),
            backgroundColor: AppTheme.missedRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<SettingsCubit, SettingsState>(
          builder: (context, state) {
            if (state is SettingsLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is SettingsLoaded) {
              final settings = state.settings;
              return CustomScrollView(
                slivers: [
                  // App Bar / Header
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Preferences',
                            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: -0.5),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Configure app behavior and notifications',
                            style: TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // General settings list
                  SliverList(
                    delegate: SliverListList(
                      [
                        const SizedBox(height: 12),
                        _buildSectionHeader('Notifications'),
                        _buildSwitchTile(
                          title: 'Receive Reminders',
                          subtitle: 'Enable or disable all medicine alarms',
                          value: settings.notificationsEnabled,
                          icon: Icons.notifications_active_outlined,
                          onChanged: (val) => context.read<SettingsCubit>().toggleNotifications(val),
                        ),
                        if (settings.notificationsEnabled) ...[
                          _buildSwitchTile(
                            title: 'Device Vibration',
                            subtitle: 'Vibrate alongside alarm sounds',
                            value: settings.vibration,
                            icon: Icons.vibration,
                            onChanged: (val) => context.read<SettingsCubit>().toggleVibration(val),
                          ),
                          _buildSnoozeTile(context, settings),
                          const SizedBox(height: 16),
                          _buildSectionHeader('Reminder Sounds'),
                          _buildSoundTile(settings, label: 'Pulse Alarm (Default)', keyVal: 'alarm1'),
                          _buildSoundTile(settings, label: 'Siren Alarm', keyVal: 'alarm2'),
                          _buildSoundTile(settings, label: 'Melody Alarm', keyVal: 'alarm3'),
                        ],
                        const SizedBox(height: 40),
                        Center(
                          child: Text(
                            'Medicine Reminder App v1.0.0',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ],
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: AppTheme.primaryTeal,
          fontWeight: FontWeight.bold,
          fontSize: 12,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required IconData icon,
    required ValueChanged<bool> onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSlate : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155).withOpacity(0.5) : const Color(0xFFE2E8F0),
        ),
      ),
      child: SwitchListTile(
        secondary: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryTeal.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.notifications, color: AppTheme.primaryTeal),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        value: value,
        onChanged: onChanged,
        activeColor: AppTheme.primaryTeal,
      ),
    );
  }

  Widget _buildSnoozeTile(BuildContext context, AppSettingsModel settings) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSlate : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155).withOpacity(0.5) : const Color(0xFFE2E8F0),
        ),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryTeal.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.snooze, color: AppTheme.primaryTeal),
        ),
        title: const Text('Default Snooze Interval', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        subtitle: Text('Current: ${settings.defaultSnoozeMinutes} minutes', style: const TextStyle(fontSize: 12)),
        trailing: DropdownButton<int>(
          value: settings.defaultSnoozeMinutes,
          underline: const SizedBox.shrink(),
          onChanged: (val) {
            if (val != null) {
              context.read<SettingsCubit>().updateDefaultSnooze(val);
            }
          },
          items: const [
            DropdownMenuItem(value: 5, child: Text('5 min')),
            DropdownMenuItem(value: 10, child: Text('10 min')),
            DropdownMenuItem(value: 15, child: Text('15 min')),
            DropdownMenuItem(value: 30, child: Text('30 min')),
          ],
        ),
      ),
    );
  }

  Widget _buildSoundTile(AppSettingsModel settings, {required String label, required String keyVal}) {
    final isSelected = settings.sound == keyVal || (settings.sound == 'default' && keyVal == 'alarm1');
    final isPlaying = _playingSoundKey == keyVal;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSlate : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected
              ? AppTheme.primaryTeal
              : (isDark ? const Color(0xFF334155).withOpacity(0.5) : const Color(0xFFE2E8F0)),
          width: isSelected ? 1.5 : 1.0,
        ),
      ),
      child: ListTile(
        title: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: isSelected ? AppTheme.primaryTeal : null,
          ),
        ),
        leading: Radio<String>(
          value: keyVal,
          groupValue: settings.sound == 'default' ? 'alarm1' : settings.sound,
          activeColor: AppTheme.primaryTeal,
          onChanged: (val) {
            if (val != null) {
              context.read<SettingsCubit>().updateSound(val);
            }
          },
        ),
        trailing: IconButton(
          icon: Icon(
            isPlaying ? Icons.stop_circle : Icons.play_circle_fill,
            color: isPlaying ? AppTheme.missedRed : AppTheme.primaryTeal,
            size: 32,
          ),
          onPressed: () => _previewSound(keyVal),
        ),
      ),
    );
  }
}

// Helper utility for generating custom lists in slivers
class SliverListList extends SliverChildListDelegate {
  SliverListList(List<Widget> children) : super(children);
}
