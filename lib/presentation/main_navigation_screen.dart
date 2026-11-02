import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/recovery/recovery_details_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/strain/strain_details_screen.dart';
import 'screens/trends/trends_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    RecoveryDetailsScreen(),
    StrainDetailsScreen(),
    TrendsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: AppColors.borderSubtle, width: 1),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_rounded),
              activeIcon: Icon(
                Icons.dashboard_rounded,
                color: AppColors.limeAccent,
              ),
              label: 'Today',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.speed_rounded),
              activeIcon: Icon(
                Icons.speed_rounded,
                color: AppColors.limeAccent,
              ),
              label: 'Recovery',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bolt_rounded),
              activeIcon: Icon(Icons.bolt_rounded, color: AppColors.limeAccent),
              label: 'Strain',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.insights_rounded),
              activeIcon: Icon(
                Icons.insights_rounded,
                color: AppColors.limeAccent,
              ),
              label: 'Trends',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.tune_rounded),
              activeIcon: Icon(Icons.tune_rounded, color: AppColors.limeAccent),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}
