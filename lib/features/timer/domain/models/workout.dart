import 'package:equatable/equatable.dart';

import 'workout_segment.dart';

class SegmentGroup extends Equatable {
  final String id;
  final List<WorkoutSegment> segments;
  final int rounds;

  const SegmentGroup({
    required this.id,
    required this.segments,
    this.rounds = 1,
  });

  Duration get totalDuration {
    final segmentsDuration = segments.fold<Duration>(
      Duration.zero,
      (total, segment) => total + segment.totalDuration,
    );
    return segmentsDuration * rounds;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'segments': segments.map((s) => s.toJson()).toList(),
        'rounds': rounds,
      };

  factory SegmentGroup.fromJson(Map<String, dynamic> json) => SegmentGroup(
        id: json['id'] as String,
        segments: (json['segments'] as List)
            .map((s) => WorkoutSegment.fromJson(s as Map<String, dynamic>))
            .toList(),
        rounds: json['rounds'] as int? ?? 1,
      );

  SegmentGroup copyWith({
    String? id,
    List<WorkoutSegment>? segments,
    int? rounds,
  }) =>
      SegmentGroup(
        id: id ?? this.id,
        segments: segments ?? this.segments,
        rounds: rounds ?? this.rounds,
      );

  @override
  List<Object?> get props => [id, segments, rounds];
}

class Workout extends Equatable {
  final String id;
  final String name;
  final List<SegmentGroup> groups;
  final int rounds;
  final Duration? countdownDuration;
  final DateTime createdAt;
  final DateTime? lastUsedAt;

  const Workout({
    required this.id,
    required this.name,
    required this.groups,
    this.rounds = 1,
    this.countdownDuration = const Duration(seconds: 10),
    required this.createdAt,
    this.lastUsedAt,
  });

  Duration get totalDuration {
    final groupsDuration = groups.fold<Duration>(
      Duration.zero,
      (total, group) => total + group.totalDuration,
    );
    return groupsDuration * rounds;
  }

  int get totalSegments {
    return groups.fold<int>(
      0,
      (total, group) => total + group.segments.length * group.rounds,
    );
  }

  List<WorkoutSegment> get flatSegments {
    final result = <WorkoutSegment>[];
    for (var workoutRound = 0; workoutRound < rounds; workoutRound++) {
      for (final group in groups) {
        for (var groupRound = 0; groupRound < group.rounds; groupRound++) {
          for (final segment in group.segments) {
            for (var segmentRound = 0;
                segmentRound < segment.rounds;
                segmentRound++) {
              result.add(segment);
            }
          }
        }
      }
    }
    return result;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'groups': groups.map((g) => g.toJson()).toList(),
        'rounds': rounds,
        'countdownDurationSeconds': countdownDuration?.inSeconds,
        'createdAt': createdAt.toIso8601String(),
        'lastUsedAt': lastUsedAt?.toIso8601String(),
      };

  factory Workout.fromJson(Map<String, dynamic> json) => Workout(
        id: json['id'] as String,
        name: json['name'] as String,
        groups: (json['groups'] as List)
            .map((g) => SegmentGroup.fromJson(g as Map<String, dynamic>))
            .toList(),
        rounds: json['rounds'] as int? ?? 1,
        countdownDuration: json['countdownDurationSeconds'] != null
            ? Duration(seconds: json['countdownDurationSeconds'] as int)
            : null,
        createdAt: DateTime.parse(json['createdAt'] as String),
        lastUsedAt: json['lastUsedAt'] != null
            ? DateTime.parse(json['lastUsedAt'] as String)
            : null,
      );

  Workout copyWith({
    String? id,
    String? name,
    List<SegmentGroup>? groups,
    int? rounds,
    Duration? countdownDuration,
    DateTime? createdAt,
    DateTime? lastUsedAt,
  }) =>
      Workout(
        id: id ?? this.id,
        name: name ?? this.name,
        groups: groups ?? this.groups,
        rounds: rounds ?? this.rounds,
        countdownDuration: countdownDuration ?? this.countdownDuration,
        createdAt: createdAt ?? this.createdAt,
        lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      );

  @override
  List<Object?> get props => [
        id,
        name,
        groups,
        rounds,
        countdownDuration,
        createdAt,
        lastUsedAt,
      ];
}

class QuickWorkout {
  static Workout amrap({
    required String id,
    required Duration duration,
    String name = 'AMRAP',
    Duration countdownDuration = const Duration(seconds: 10),
  }) {
    return Workout(
      id: id,
      name: name,
      groups: [
        SegmentGroup(
          id: '${id}_group',
          segments: [
            AmrapSegment(
              id: '${id}_segment',
              duration: duration,
            ),
          ],
        ),
      ],
      countdownDuration: countdownDuration,
      createdAt: DateTime.now(),
    );
  }

  static Workout forTime({
    required String id,
    Duration? timeCap,
    String name = 'FOR TIME',
    Duration countdownDuration = const Duration(seconds: 10),
  }) {
    return Workout(
      id: id,
      name: name,
      groups: [
        SegmentGroup(
          id: '${id}_group',
          segments: [
            ForTimeSegment(
              id: '${id}_segment',
              timeCap: timeCap,
            ),
          ],
        ),
      ],
      countdownDuration: countdownDuration,
      createdAt: DateTime.now(),
    );
  }

  static Workout emom({
    required String id,
    required Duration totalTime,
    Duration intervalDuration = const Duration(minutes: 1),
    String name = 'EMOM',
    Duration countdownDuration = const Duration(seconds: 10),
  }) {
    return Workout(
      id: id,
      name: name,
      groups: [
        SegmentGroup(
          id: '${id}_group',
          segments: [
            EmomSegment(
              id: '${id}_segment',
              totalTime: totalTime,
              intervalDuration: intervalDuration,
            ),
          ],
        ),
      ],
      countdownDuration: countdownDuration,
      createdAt: DateTime.now(),
    );
  }

  static Workout tabata({
    required String id,
    Duration workDuration = const Duration(seconds: 20),
    Duration restDuration = const Duration(seconds: 10),
    int rounds = 8,
    String name = 'TABATA',
    Duration countdownDuration = const Duration(seconds: 10),
  }) {
    return Workout(
      id: id,
      name: name,
      groups: [
        SegmentGroup(
          id: '${id}_group',
          segments: [
            TabataSegment(
              id: '${id}_segment',
              workDuration: workDuration,
              restDuration: restDuration,
              tabataRounds: rounds,
            ),
          ],
        ),
      ],
      countdownDuration: countdownDuration,
      createdAt: DateTime.now(),
    );
  }

  static Workout tempo({
    required String id,
    required List<int> tempoPattern,
    required int tempoRounds,
    required Duration roundDuration,
    String name = 'TEMPO',
    Duration countdownDuration = const Duration(seconds: 10),
  }) {
    return Workout(
      id: id,
      name: name,
      groups: [
        SegmentGroup(
          id: '${id}_group',
          segments: [
            TempoSegment(
              id: '${id}_segment',
              tempo: tempoPattern,
              tempoRounds: tempoRounds,
              roundDuration: roundDuration,
            ),
          ],
        ),
      ],
      countdownDuration: countdownDuration,
      createdAt: DateTime.now(),
    );
  }
}
