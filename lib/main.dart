import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'screens/home_screen.dart';
import 'screens/day_screen.dart';
import 'theme/app_theme.dart';

final _router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/day/:date',
      builder: (context, state) =>
          DayScreen(date: state.pathParameters['date']!),
    ),
  ],
);

void main() {
  runApp(const ProviderScope(child: BusanTripApp()));
}

class BusanTripApp extends StatelessWidget {
  const BusanTripApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: '釜山之旅',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: _router,
    );
  }
}
