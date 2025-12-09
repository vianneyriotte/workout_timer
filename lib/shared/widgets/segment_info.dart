import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../features/timer/domain/models/models.dart';

class SegmentInfo extends StatelessWidget {
  final TimerState timerState;

  const SegmentInfo({
    super.key,
    required this.timerState,
  });

  @override
  Widget build(BuildContext context) {
    final segment = timerState.currentSegment;
    if (segment == null) return const SizedBox.shrink();

    final color = _getSegmentColor(segment.type);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            segment.type.name.toUpperCase(),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 14,
              letterSpacing: 1,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          timerState.statusText,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: _getPhaseColor(timerState.phase),
              ),
        ),
        const SizedBox(height: 16),
        _buildSegmentDetails(context, segment, timerState),
      ],
    );
  }

  Widget _buildSegmentDetails(
    BuildContext context,
    WorkoutSegment segment,
    TimerState state,
  ) {
    return switch (segment) {
      AmrapSegment() => _AmrapDetails(
          roundsCompleted: state.roundsCompleted,
        ),
      ForTimeSegment(:final timeCap) => _ForTimeDetails(
          timeCap: timeCap,
          elapsed: state.elapsedTime,
        ),
      EmomSegment(:final intervalCount) => _EmomDetails(
          currentInterval: state.currentEmomInterval,
          totalIntervals: intervalCount,
        ),
      TabataSegment(:final tabataRounds) => _TabataDetails(
          currentRound: state.currentTabataRound,
          totalRounds: tabataRounds,
          phase: state.phase,
        ),
      RestSegment() => const SizedBox.shrink(),
    };
  }

  Color _getSegmentColor(SegmentType type) {
    return switch (type) {
      SegmentType.amrap => AppColors.amrap,
      SegmentType.forTime => AppColors.forTime,
      SegmentType.emom => AppColors.emom,
      SegmentType.tabata => AppColors.tabata,
      SegmentType.rest => AppColors.rest,
    };
  }

  Color _getPhaseColor(TimerPhase phase) {
    return switch (phase) {
      TimerPhase.work => AppColors.work,
      TimerPhase.rest => AppColors.rest,
      TimerPhase.prepare => AppColors.prepare,
    };
  }
}

class _ForTimeDetails extends StatelessWidget {
  final Duration? timeCap;
  final Duration elapsed;

  const _ForTimeDetails({
    required this.timeCap,
    required this.elapsed,
  });

  @override
  Widget build(BuildContext context) {
    if (timeCap == null) return const SizedBox.shrink();

    final remaining = timeCap! - elapsed;
    final remainingText = _formatDuration(remaining.isNegative ? Duration.zero : remaining);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.flag, color: AppColors.textSecondary, size: 20),
        const SizedBox(width: 8),
        Text(
          'Cap: $remainingText',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

class _AmrapDetails extends StatelessWidget {
  final int roundsCompleted;

  const _AmrapDetails({required this.roundsCompleted});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.repeat, color: AppColors.textSecondary, size: 20),
        const SizedBox(width: 8),
        Text(
          'Rounds: $roundsCompleted',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
      ],
    );
  }
}

class _EmomDetails extends StatelessWidget {
  final int currentInterval;
  final int totalIntervals;

  const _EmomDetails({
    required this.currentInterval,
    required this.totalIntervals,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.timer, color: AppColors.textSecondary, size: 20),
        const SizedBox(width: 8),
        Text(
          'Interval $currentInterval / $totalIntervals',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
      ],
    );
  }
}

class _TabataDetails extends StatelessWidget {
  final int currentRound;
  final int totalRounds;
  final TimerPhase phase;

  const _TabataDetails({
    required this.currentRound,
    required this.totalRounds,
    required this.phase,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.fitness_center,
                color: AppColors.textSecondary, size: 20),
            const SizedBox(width: 8),
            Text(
              'Round $currentRound / $totalRounds',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: phase == TimerPhase.work
                ? AppColors.work.withOpacity(0.2)
                : AppColors.rest.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            phase == TimerPhase.work ? 'WORK' : 'REST',
            style: TextStyle(
              color: phase == TimerPhase.work ? AppColors.work : AppColors.rest,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
