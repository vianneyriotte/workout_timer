import 'package:equatable/equatable.dart';

import 'workout.dart';
import 'workout_segment.dart';

class LapTime extends Equatable {
  final int roundNumber;
  final Duration cumulativeTime;
  final Duration lapTime;

  const LapTime({
    required this.roundNumber,
    required this.cumulativeTime,
    required this.lapTime,
  });

  @override
  List<Object?> get props => [roundNumber, cumulativeTime, lapTime];
}

enum TimerStatus {
  idle,
  countdown,
  running,
  paused,
  rest,
  completed,
}

enum TimerPhase {
  work,
  rest,
  prepare,
}

class TimerState extends Equatable {
  final Workout workout;
  final TimerStatus status;
  final TimerPhase phase;
  final int currentGroupIndex;
  final int currentGroupRound;
  final int currentSegmentIndex;
  final int currentSegmentRound;
  final int currentWorkoutRound;
  final Duration remainingTime;
  final Duration elapsedTime;
  final int roundsCompleted;
  final int currentTabataRound;
  final int currentEmomInterval;
  final DateTime? startedAt;
  final DateTime? pausedAt;
  final List<Duration> roundTimes;
  final List<LapTime> lapTimes;

  const TimerState({
    required this.workout,
    this.status = TimerStatus.idle,
    this.phase = TimerPhase.prepare,
    this.currentGroupIndex = 0,
    this.currentGroupRound = 0,
    this.currentSegmentIndex = 0,
    this.currentSegmentRound = 0,
    this.currentWorkoutRound = 0,
    this.remainingTime = Duration.zero,
    this.elapsedTime = Duration.zero,
    this.roundsCompleted = 0,
    this.currentTabataRound = 0,
    this.currentEmomInterval = 0,
    this.startedAt,
    this.pausedAt,
    this.roundTimes = const [],
    this.lapTimes = const [],
  });

  WorkoutSegment? get currentSegment {
    if (currentGroupIndex >= workout.groups.length) return null;
    final group = workout.groups[currentGroupIndex];
    if (currentSegmentIndex >= group.segments.length) return null;
    return group.segments[currentSegmentIndex];
  }

  SegmentGroup? get currentGroup {
    if (currentGroupIndex >= workout.groups.length) return null;
    return workout.groups[currentGroupIndex];
  }

  String get currentSegmentName {
    final segment = currentSegment;
    if (segment == null) return '';
    return segment.name ?? segment.type.name.toUpperCase();
  }

  String get statusText {
    return switch (status) {
      TimerStatus.idle => 'Ready',
      TimerStatus.countdown => 'Get Ready',
      TimerStatus.running => phase == TimerPhase.work ? 'Work' : 'Rest',
      TimerStatus.paused => 'Paused',
      TimerStatus.rest => 'Rest',
      TimerStatus.completed => 'Complete',
    };
  }

  double get progress {
    if (status == TimerStatus.completed) return 1.0;
    if (status == TimerStatus.idle) return 0.0;

    final segment = currentSegment;
    if (segment == null) return 1.0;

    final total = switch (segment) {
      AmrapSegment(:final duration) => duration.inSeconds,
      ForTimeSegment(:final timeCap) => timeCap?.inSeconds ?? 1,
      EmomSegment(:final intervalDuration) => intervalDuration.inSeconds,
      TabataSegment() => phase == TimerPhase.work
          ? (segment as TabataSegment).workDuration.inSeconds
          : (segment as TabataSegment).restDuration.inSeconds,
      RestSegment(:final duration) => duration.inSeconds,
    };

    if (total == 0) return 1.0;

    final result = switch (segment) {
      ForTimeSegment() => elapsedTime.inSeconds / total,
      _ => 1 - (remainingTime.inSeconds / total),
    };

    return result.clamp(0.0, 1.0);
  }

  TimerState copyWith({
    Workout? workout,
    TimerStatus? status,
    TimerPhase? phase,
    int? currentGroupIndex,
    int? currentGroupRound,
    int? currentSegmentIndex,
    int? currentSegmentRound,
    int? currentWorkoutRound,
    Duration? remainingTime,
    Duration? elapsedTime,
    int? roundsCompleted,
    int? currentTabataRound,
    int? currentEmomInterval,
    DateTime? startedAt,
    DateTime? pausedAt,
    List<Duration>? roundTimes,
    List<LapTime>? lapTimes,
  }) {
    return TimerState(
      workout: workout ?? this.workout,
      status: status ?? this.status,
      phase: phase ?? this.phase,
      currentGroupIndex: currentGroupIndex ?? this.currentGroupIndex,
      currentGroupRound: currentGroupRound ?? this.currentGroupRound,
      currentSegmentIndex: currentSegmentIndex ?? this.currentSegmentIndex,
      currentSegmentRound: currentSegmentRound ?? this.currentSegmentRound,
      currentWorkoutRound: currentWorkoutRound ?? this.currentWorkoutRound,
      remainingTime: remainingTime ?? this.remainingTime,
      elapsedTime: elapsedTime ?? this.elapsedTime,
      roundsCompleted: roundsCompleted ?? this.roundsCompleted,
      currentTabataRound: currentTabataRound ?? this.currentTabataRound,
      currentEmomInterval: currentEmomInterval ?? this.currentEmomInterval,
      startedAt: startedAt ?? this.startedAt,
      pausedAt: pausedAt ?? this.pausedAt,
      roundTimes: roundTimes ?? this.roundTimes,
      lapTimes: lapTimes ?? this.lapTimes,
    );
  }

  @override
  List<Object?> get props => [
        workout,
        status,
        phase,
        currentGroupIndex,
        currentGroupRound,
        currentSegmentIndex,
        currentSegmentRound,
        currentWorkoutRound,
        remainingTime,
        elapsedTime,
        roundsCompleted,
        currentTabataRound,
        currentEmomInterval,
        startedAt,
        pausedAt,
        roundTimes,
        lapTimes,
      ];
}
