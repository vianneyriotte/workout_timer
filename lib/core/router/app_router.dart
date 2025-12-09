import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/home/presentation/home_screen.dart';
import '../../features/presets/presentation/presets_screen.dart';
import '../../features/timer/domain/models/models.dart';
import '../../features/timer/presentation/screens/timer_screen.dart';
import '../../features/timer_selection/presentation/timer_config_screen.dart';
import '../../features/workout_builder/presentation/screens/workout_builder_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/config/:type',
        builder: (context, state) {
          final type = state.pathParameters['type'] ?? 'amrap';
          return TimerConfigScreen(timerType: type);
        },
      ),
      GoRoute(
        path: '/builder',
        builder: (context, state) => const WorkoutBuilderScreen(),
      ),
      GoRoute(
        path: '/timer',
        builder: (context, state) {
          final workout = state.extra as Workout;
          return TimerScreen(workout: workout);
        },
      ),
      GoRoute(
        path: '/presets',
        builder: (context, state) => const PresetsScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.uri}'),
      ),
    ),
  );
});
