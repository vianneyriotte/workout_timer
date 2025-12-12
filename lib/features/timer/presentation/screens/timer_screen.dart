import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../domain/models/models.dart';
import '../../providers/timer_provider.dart';

class TimerScreen extends ConsumerStatefulWidget {
  final Workout workout;

  const TimerScreen({
    super.key,
    required this.workout,
  });

  @override
  ConsumerState<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends ConsumerState<TimerScreen> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final timerState = ref.watch(timerProvider(widget.workout));
    final timerNotifier = ref.read(timerProvider(widget.workout).notifier);
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: isLandscape
            ? _LandscapeLayout(
                timerState: timerState,
                timerNotifier: timerNotifier,
                onClose: () => _confirmExit(context, timerState, timerNotifier),
              )
            : _PortraitLayout(
                timerState: timerState,
                timerNotifier: timerNotifier,
                onClose: () => _confirmExit(context, timerState, timerNotifier),
              ),
      ),
    );
  }

  void _confirmExit(
    BuildContext context,
    TimerState state,
    TimerNotifier notifier,
  ) async {
    if (state.status == TimerStatus.idle ||
        state.status == TimerStatus.completed) {
      notifier.stopAll();
      context.pop();
      return;
    }

    if (state.status == TimerStatus.countdown) {
      notifier.stopAll();
      context.pop();
      return;
    }

    notifier.pause();

    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit Workout?'),
        content: const Text(
          'Your progress will be lost. Are you sure you want to exit?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Exit'),
          ),
        ],
      ),
    );

    if (shouldExit == true && mounted) {
      notifier.stopAll();
      context.pop();
    }
  }
}

class _PortraitLayout extends StatelessWidget {
  final TimerState timerState;
  final TimerNotifier timerNotifier;
  final VoidCallback onClose;

  const _PortraitLayout({
    required this.timerState,
    required this.timerNotifier,
    required this.onClose,
  });

  bool get _showAddRound =>
      timerState.currentSegment is AmrapSegment &&
      timerState.status == TimerStatus.running;

  bool get _showAddRep =>
      timerState.currentSegment is ForTimeSegment &&
      timerState.status == TimerStatus.running;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(context),
        const Spacer(),
        SegmentInfo(timerState: timerState),
        const SizedBox(height: 16),
        if (_showAddRound) ...[
          AddRoundButton(onPressed: timerNotifier.addRound),
          const SizedBox(height: 24),
        ],
        if (_showAddRep) ...[
          AddRoundButton(
            onPressed: timerNotifier.addRep,
            label: '+1 Rep',
            count: timerState.forTimeReps > 0 ? timerState.forTimeReps : null,
          ),
          const SizedBox(height: 24),
        ],
        TimerDisplay(
          time: _getDisplayTime(),
          phase: timerState.phase,
          isCountUp: timerState.currentSegment is ForTimeSegment,
          progress: timerState.progress,
        ),
        const Spacer(),
        TimerControls(
          status: timerState.status,
          onStart: timerNotifier.start,
          onPause: timerNotifier.pause,
          onReset: timerNotifier.reset,
          onComplete: timerNotifier.completeForTime,
          showComplete: timerState.currentSegment is ForTimeSegment &&
              timerState.status == TimerStatus.running,
        ),
        const SizedBox(height: 48),
        if (timerState.status == TimerStatus.completed)
          _buildCompletionSummary(context),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: onClose,
            color: AppColors.textSecondary,
          ),
          Text(
            timerState.workout.name,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Duration _getDisplayTime() {
    if (timerState.status == TimerStatus.countdown) {
      return timerState.remainingTime;
    }
    if (timerState.currentSegment is ForTimeSegment) {
      return timerState.elapsedTime;
    }
    return timerState.remainingTime;
  }

  Widget _buildCompletionSummary(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.success.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle, color: AppColors.success, size: 48),
          const SizedBox(height: 12),
          Text(
            'Workout Complete!',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.success,
                  fontWeight: FontWeight.bold,
                ),
          ),
          if (timerState.roundsCompleted > 0) ...[
            const SizedBox(height: 8),
            Text(
              'Rounds: ${timerState.roundsCompleted}',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
          if (timerState.forTimeReps > 0) ...[
            const SizedBox(height: 8),
            Text(
              'Reps: ${timerState.forTimeReps}',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
          if (timerState.lapTimes.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    for (final lap in timerState.lapTimes)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Round ${lap.roundNumber}',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            Row(
                              children: [
                                Text(
                                  _formatDuration(lap.lapTime),
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  '(${_formatDuration(lap.cumulativeTime)})',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ] else if (timerState.roundTimes.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Total time: ${_formatDuration(timerState.elapsedTime)}',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

class _LandscapeLayout extends StatelessWidget {
  final TimerState timerState;
  final TimerNotifier timerNotifier;
  final VoidCallback onClose;

  const _LandscapeLayout({
    required this.timerState,
    required this.timerNotifier,
    required this.onClose,
  });

  bool get _showAddRound =>
      timerState.currentSegment is AmrapSegment &&
      timerState.status == TimerStatus.running;

  bool get _showAddRep =>
      timerState.currentSegment is ForTimeSegment &&
      timerState.status == TimerStatus.running;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SegmentInfo(timerState: timerState),
              const SizedBox(height: 8),
              if (_showAddRound) ...[
                AddRoundButton(onPressed: timerNotifier.addRound),
                const SizedBox(height: 16),
              ],
              if (_showAddRep) ...[
                AddRoundButton(
                  onPressed: timerNotifier.addRep,
                  label: '+1 Rep',
                  count: timerState.forTimeReps > 0 ? timerState.forTimeReps : null,
                ),
                const SizedBox(height: 16),
              ],
              TimerDisplay(
                time: _getDisplayTime(),
                phase: timerState.phase,
                isCountUp: timerState.currentSegment is ForTimeSegment,
                progress: timerState.progress,
              ),
            ],
          ),
        ),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: onClose,
                color: AppColors.textSecondary,
              ),
              const Spacer(),
              TimerControls(
                status: timerState.status,
                onStart: timerNotifier.start,
                onPause: timerNotifier.pause,
                onReset: timerNotifier.reset,
                onComplete: timerNotifier.completeForTime,
                showComplete: timerState.currentSegment is ForTimeSegment &&
                    timerState.status == TimerStatus.running,
              ),
              const Spacer(),
            ],
          ),
        ),
      ],
    );
  }

  Duration _getDisplayTime() {
    if (timerState.status == TimerStatus.countdown) {
      return timerState.remainingTime;
    }
    if (timerState.currentSegment is ForTimeSegment) {
      return timerState.elapsedTime;
    }
    return timerState.remainingTime;
  }
}
