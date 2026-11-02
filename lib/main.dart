import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'presentation/main_navigation_screen.dart';
import 'presentation/providers/health_provider.dart';
import 'presentation/providers/user_provider.dart';
import 'presentation/providers/workout_provider.dart';
import 'presentation/screens/onboarding/onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Dark navigation bar and status bar styling
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const PulseApp());
}

class PulseApp extends StatelessWidget {
  const PulseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()..init()),
        ChangeNotifierProvider(create: (_) => WorkoutProvider()),
        ChangeNotifierProvider(create: (_) => HealthProvider()),
      ],
      child: MaterialApp(
        title: 'PULSE',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const AppRootRouter(),
      ),
    );
  }
}

class AppRootRouter extends StatefulWidget {
  const AppRootRouter({super.key});

  @override
  State<AppRootRouter> createState() => _AppRootRouterState();
}

class _AppRootRouterState extends State<AppRootRouter> {
  bool _dataInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final userProvider = context.watch<UserProvider>();

    if (!userProvider.isLoading && !_dataInitialized) {
      _dataInitialized = true;
      final workoutProvider = context.read<WorkoutProvider>();
      final healthProvider = context.read<HealthProvider>();
      final profile = userProvider.profile;

      workoutProvider.loadWorkouts(isDemoMode: profile.isDemoMode).then((_) {
        healthProvider.refreshAll(
          profile: profile,
          workouts: workoutProvider.workouts,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();

    if (userProvider.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Colors.limeAccent),
        ),
      );
    }

    if (!userProvider.onboardingCompleted) {
      return const OnboardingScreen();
    }

    return const MainNavigationScreen();
  }
}
