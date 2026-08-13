import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/services/notification_service.dart';
import 'dashboard_page.dart';
import '../../../history/presentation/pages/history_page.dart';
import '../../../settings/presentation/pages/settings_page.dart';
import '../../../medicine/presentation/pages/add_medicine_page.dart';
import '../../../reminder/presentation/pages/reminder_page.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;
  StreamSubscription<String>? _notificationSubscription;

  final List<Widget> _pages = [
    const DashboardPage(),
    const HistoryPage(),
    const SettingsPage(),
  ];

  @override
  void initState() {
    super.initState();
    _checkNotificationAppLaunch();
    
    // Subscribe to notification clicks when the app is in foreground/background
    _notificationSubscription = NotificationService.selectNotificationStream.stream.listen((payload) {
      if (mounted) {
        _navigateToReminder(payload);
      }
    });
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    super.dispose();
  }

  Future<void> _checkNotificationAppLaunch() async {
    final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    final details = await flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();
    if (details?.didNotificationLaunchApp ?? false) {
      final payload = details?.notificationResponse?.payload;
      if (payload != null) {
        // Delay navigation slightly to ensure the view context is fully loaded
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _navigateToReminder(payload);
          }
        });
      }
    }
  }

  void _navigateToReminder(String payload) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReminderPage(occurrenceId: payload),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard, color: AppTheme.primaryTeal),
            label: 'Schedule',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history, color: AppTheme.primaryTeal),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings, color: AppTheme.primaryTeal),
            label: 'Settings',
          ),
        ],
      ),
      floatingActionButton: _selectedIndex != 2 // Hide FAB on Settings page
          ? Container(
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryTeal.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: FloatingActionButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AddMedicinePage()),
                  );
                },
                backgroundColor: Colors.transparent,
                elevation: 0,
                child: const Icon(Icons.add, color: Colors.white, size: 28),
              ),
            )
          : null,
    );
  }
}
