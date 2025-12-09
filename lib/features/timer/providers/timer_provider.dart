import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/services/audio_service.dart';
import '../domain/models/models.dart';

class TimerNotifier extends StateNotifier<TimerState> {
  final AudioService _audioService;
  Timer? _timer;
  bool _halfwayAnnounced = false;
  bool _tenSecondsAnnounced = false;

  TimerNotifier(this._audioService, Workout workout)
      : super(TimerState(workout: workout));

  void start() {
    if (state.status == TimerStatus.completed) return;

    if (state.status == TimerStatus.idle) {
      _startCountdown();
    } else if (state.status == TimerStatus.paused) {
      _resumeTimer();
    }
  }

  void _startCountdown() {
    final countdown = state.workout.countdownDuration;
    if (countdown == null || countdown.inSeconds == 0) {
      _startWorkout();
      return;
    }

    state = state.copyWith(
      status: TimerStatus.countdown,
      remainingTime: countdown,
      startedAt: DateTime.now(),
    );

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final remaining = state.remainingTime - const Duration(seconds: 1);

      if (remaining.inSeconds <= 3 && remaining.inSeconds > 0) {
        _audioService.playCountdownBeep();
      }

      if (remaining.inSeconds <= 0) {
        _timer?.cancel();
        _audioService.playStartBeep();
        _startWorkout();
      } else {
        state = state.copyWith(remainingTime: remaining);
      }
    });
  }

  void _startWorkout() {
    _initializeSegment();
    _startTimer();
  }

  void _initializeSegment() {
    final segment = state.currentSegment;
    if (segment == null) {
      _completeWorkout();
      return;
    }

    _halfwayAnnounced = false;
    _tenSecondsAnnounced = false;

    final segmentName = switch (segment) {
      AmrapSegment() => 'AMRAP, Let\'s go!',
      ForTimeSegment() => 'For Time, Let\'s go!',
      EmomSegment() => 'EMOM, Let\'s go!',
      TabataSegment() => 'Tabata, Let\'s go!',
      RestSegment() => 'Rest',
    };
    _audioService.announceSegmentStart(segmentName);

    final (remainingTime, phase) = switch (segment) {
      AmrapSegment(:final duration) => (duration, TimerPhase.work),
      ForTimeSegment() => (Duration.zero, TimerPhase.work),
      EmomSegment(:final intervalDuration) => (intervalDuration, TimerPhase.work),
      TabataSegment(:final workDuration) => (workDuration, TimerPhase.work),
      RestSegment(:final duration) => (duration, TimerPhase.rest),
    };

    state = state.copyWith(
      status: TimerStatus.running,
      phase: phase,
      remainingTime: remainingTime,
      elapsedTime: Duration.zero,
      currentTabataRound: segment is TabataSegment ? 1 : 0,
      currentEmomInterval: segment is EmomSegment ? 1 : 0,
    );
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    if (state.status != TimerStatus.running) return;

    final segment = state.currentSegment;
    if (segment == null) {
      _completeWorkout();
      return;
    }

    switch (segment) {
      case AmrapSegment():
        _tickAmrap();
      case ForTimeSegment():
        _tickForTime();
      case EmomSegment():
        _tickEmom();
      case TabataSegment():
        _tickTabata();
      case RestSegment():
        _tickRest();
    }
  }

  void _tickAmrap() {
    final segment = state.currentSegment as AmrapSegment;
    final remaining = state.remainingTime - const Duration(seconds: 1);
    final totalSeconds = segment.duration.inSeconds;
    final halfwayPoint = totalSeconds ~/ 2;

    if (!_halfwayAnnounced && remaining.inSeconds == halfwayPoint && halfwayPoint > 5) {
      _halfwayAnnounced = true;
      _audioService.announceHalfway();
    }

    if (!_tenSecondsAnnounced && remaining.inSeconds == 10 && totalSeconds > 12) {
      _tenSecondsAnnounced = true;
      _audioService.announceTenSeconds();
    } else if (remaining.inSeconds <= 3 && remaining.inSeconds > 0) {
      _audioService.playWarningBeep();
    }

    if (remaining.inSeconds <= 0) {
      _audioService.playCompleteBeep();
      _moveToNextSegment();
    } else {
      state = state.copyWith(
        remainingTime: remaining,
        elapsedTime: state.elapsedTime + const Duration(seconds: 1),
      );
    }
  }

  void _tickForTime() {
    final segment = state.currentSegment as ForTimeSegment;
    final elapsed = state.elapsedTime + const Duration(seconds: 1);

    if (segment.timeCap != null) {
      final totalSeconds = segment.timeCap!.inSeconds;
      final remaining = segment.timeCap! - elapsed;
      final halfwayPoint = totalSeconds ~/ 2;

      if (!_halfwayAnnounced && remaining.inSeconds == halfwayPoint && halfwayPoint > 5) {
        _halfwayAnnounced = true;
        _audioService.announceHalfway();
      }

      if (!_tenSecondsAnnounced && remaining.inSeconds == 10 && totalSeconds > 12) {
        _tenSecondsAnnounced = true;
        _audioService.announceTenSeconds();
      } else if (remaining.inSeconds <= 3 && remaining.inSeconds > 0) {
        _audioService.playWarningBeep();
      }

      if (elapsed >= segment.timeCap!) {
        _audioService.playCompleteBeep();
        _moveToNextSegment();
        return;
      }
    }

    state = state.copyWith(
      elapsedTime: elapsed,
      remainingTime: segment.timeCap != null
          ? segment.timeCap! - elapsed
          : Duration.zero,
    );
  }

  void _tickEmom() {
    final segment = state.currentSegment as EmomSegment;
    final remaining = state.remainingTime - const Duration(seconds: 1);
    final elapsed = state.elapsedTime + const Duration(seconds: 1);
    final intervalSeconds = segment.intervalDuration.inSeconds;
    final halfwayPoint = intervalSeconds ~/ 2;

    if (!_halfwayAnnounced && remaining.inSeconds == halfwayPoint && halfwayPoint > 5) {
      _halfwayAnnounced = true;
      _audioService.announceHalfway();
    }

    if (!_tenSecondsAnnounced && remaining.inSeconds == 10 && intervalSeconds > 12) {
      _tenSecondsAnnounced = true;
      _audioService.announceTenSeconds();
    } else if (remaining.inSeconds <= 3 && remaining.inSeconds > 0) {
      _audioService.playWarningBeep();
    }

    if (remaining.inSeconds <= 0) {
      final nextInterval = state.currentEmomInterval + 1;
      if (nextInterval > segment.intervalCount) {
        _audioService.playCompleteBeep();
        _moveToNextSegment();
      } else {
        _audioService.announceEmomRound(nextInterval);
        _halfwayAnnounced = false;
        _tenSecondsAnnounced = false;
        state = state.copyWith(
          remainingTime: segment.intervalDuration,
          elapsedTime: elapsed,
          currentEmomInterval: nextInterval,
        );
      }
    } else {
      state = state.copyWith(
        remainingTime: remaining,
        elapsedTime: elapsed,
      );
    }
  }

  void _tickTabata() {
    final segment = state.currentSegment as TabataSegment;
    final remaining = state.remainingTime - const Duration(seconds: 1);

    if (remaining.inSeconds <= 3 && remaining.inSeconds > 0) {
      _audioService.playWarningBeep();
    }

    if (remaining.inSeconds <= 0) {
      if (state.phase == TimerPhase.work) {
        _audioService.playRestBeep();
        state = state.copyWith(
          phase: TimerPhase.rest,
          remainingTime: segment.restDuration,
        );
      } else {
        final nextRound = state.currentTabataRound + 1;
        if (nextRound > segment.tabataRounds) {
          _audioService.playCompleteBeep();
          _moveToNextSegment();
        } else {
          _audioService.playWorkBeep();
          state = state.copyWith(
            phase: TimerPhase.work,
            remainingTime: segment.workDuration,
            currentTabataRound: nextRound,
          );
        }
      }
    } else {
      state = state.copyWith(
        remainingTime: remaining,
        elapsedTime: state.elapsedTime + const Duration(seconds: 1),
      );
    }
  }

  void _tickRest() {
    final remaining = state.remainingTime - const Duration(seconds: 1);

    if (remaining.inSeconds <= 3 && remaining.inSeconds > 0) {
      _audioService.playWarningBeep();
    }

    if (remaining.inSeconds <= 0) {
      _audioService.playWorkBeep();
      _moveToNextSegment();
    } else {
      state = state.copyWith(
        remainingTime: remaining,
        elapsedTime: state.elapsedTime + const Duration(seconds: 1),
      );
    }
  }

  void _moveToNextSegment() {
    final group = state.currentGroup;
    if (group == null) {
      _completeWorkout();
      return;
    }

    var nextSegmentIndex = state.currentSegmentIndex;
    var nextSegmentRound = state.currentSegmentRound + 1;
    var nextGroupIndex = state.currentGroupIndex;
    var nextGroupRound = state.currentGroupRound;
    var nextWorkoutRound = state.currentWorkoutRound;

    final currentSegment = group.segments[nextSegmentIndex];
    if (nextSegmentRound >= currentSegment.rounds) {
      nextSegmentRound = 0;
      nextSegmentIndex++;
    }

    if (nextSegmentIndex >= group.segments.length) {
      nextSegmentIndex = 0;
      nextGroupRound++;
    }

    if (nextGroupRound >= group.rounds) {
      nextGroupRound = 0;
      nextGroupIndex++;
    }

    if (nextGroupIndex >= state.workout.groups.length) {
      nextGroupIndex = 0;
      nextWorkoutRound++;
    }

    if (nextWorkoutRound >= state.workout.rounds) {
      _completeWorkout();
      return;
    }

    state = state.copyWith(
      currentSegmentIndex: nextSegmentIndex,
      currentSegmentRound: nextSegmentRound,
      currentGroupIndex: nextGroupIndex,
      currentGroupRound: nextGroupRound,
      currentWorkoutRound: nextWorkoutRound,
    );

    _initializeSegment();
  }

  void _completeWorkout() {
    _timer?.cancel();
    _audioService.announceWorkoutComplete();
    state = state.copyWith(status: TimerStatus.completed);
  }

  void pause() {
    if (state.status != TimerStatus.running) return;
    _timer?.cancel();
    state = state.copyWith(
      status: TimerStatus.paused,
      pausedAt: DateTime.now(),
    );
  }

  void _resumeTimer() {
    state = state.copyWith(
      status: TimerStatus.running,
      pausedAt: null,
    );
    _startTimer();
  }

  void reset() {
    _timer?.cancel();
    state = TimerState(workout: state.workout);
  }

  void addRound() {
    final newRoundNumber = state.roundsCompleted + 1;
    final cumulativeTime = state.elapsedTime;

    // Calculate lap time (time since last round)
    final previousCumulativeTime = state.lapTimes.isNotEmpty
        ? state.lapTimes.last.cumulativeTime
        : Duration.zero;
    final lapTime = cumulativeTime - previousCumulativeTime;

    final newLapTime = LapTime(
      roundNumber: newRoundNumber,
      cumulativeTime: cumulativeTime,
      lapTime: lapTime,
    );

    state = state.copyWith(
      roundsCompleted: newRoundNumber,
      lapTimes: [...state.lapTimes, newLapTime],
    );
  }

  void completeForTime() {
    final segment = state.currentSegment;
    if (segment is! ForTimeSegment) return;

    final roundTimes = [...state.roundTimes, state.elapsedTime];
    state = state.copyWith(roundTimes: roundTimes);
    _moveToNextSegment();
  }

  void stopAll() {
    _timer?.cancel();
    _audioService.stop();
  }

  @override
  void dispose() {
    stopAll();
    super.dispose();
  }
}

final timerProvider =
    StateNotifierProvider.family<TimerNotifier, TimerState, Workout>(
  (ref, workout) {
    final audioService = ref.watch(audioServiceProvider);
    return TimerNotifier(audioService, workout);
  },
);

final currentWorkoutProvider = StateProvider<Workout?>((ref) => null);
