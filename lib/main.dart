import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/repositories/medicine_repository.dart';
import 'core/repositories/settings_repository.dart';
import 'core/services/hive_service.dart';
import 'core/services/notification_service.dart';
import 'core/theme/theme.dart';
import 'features/dashboard/presentation/bloc/dashboard_cubit.dart';
import 'features/dashboard/presentation/pages/splash_page.dart';
import 'features/history/presentation/bloc/history_cubit.dart';
import 'features/medicine/presentation/bloc/medicine_cubit.dart';
import 'features/settings/presentation/bloc/settings_cubit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Services
  await HiveService.init();
  await NotificationService.init();
  
  // Request notifications permission on start
  await NotificationService.requestPermissions();

  final medicineRepository = MedicineRepository();
  final settingsRepository = SettingsRepository();

  // Run initial synchronization for missed and ongoing doses
  await medicineRepository.syncMissedOccurrences();
  await medicineRepository.syncOngoingOccurrences();

  runApp(MyApp(
    medicineRepository: medicineRepository,
    settingsRepository: settingsRepository,
  ));
}

class MyApp extends StatelessWidget {
  final MedicineRepository medicineRepository;
  final SettingsRepository settingsRepository;

  const MyApp({
    super.key,
    required this.medicineRepository,
    required this.settingsRepository,
  });

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<MedicineRepository>.value(value: medicineRepository),
        RepositoryProvider<SettingsRepository>.value(value: settingsRepository),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<SettingsCubit>(
            create: (context) => SettingsCubit(settingsRepository)..loadSettings(),
          ),
          BlocProvider<MedicineCubit>(
            create: (context) => MedicineCubit(medicineRepository),
          ),
          BlocProvider<DashboardCubit>(
            create: (context) => DashboardCubit(medicineRepository),
          ),
          BlocProvider<HistoryCubit>(
            create: (context) => HistoryCubit(medicineRepository),
          ),
        ],
        child: MaterialApp(
          title: 'Pillminder',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.system, // Dynamically matches device preference
          home: const SplashPage(),
          debugShowCheckedModeBanner: false,
        ),
      ),
    );
  }
}
