import 'package:equatable/equatable.dart';

enum SegmentType {
  amrap,
  forTime,
  emom,
  tabata,
  rest,
}

sealed class WorkoutSegment extends Equatable {
  final String id;
  final String? name;
  final int rounds;

  const WorkoutSegment({
    required this.id,
    this.name,
    this.rounds = 1,
  });

  SegmentType get type;
  Duration get totalDuration;

  Map<String, dynamic> toJson();

  factory WorkoutSegment.fromJson(Map<String, dynamic> json) {
    final type = SegmentType.values.byName(json['type'] as String);
    return switch (type) {
      SegmentType.amrap => AmrapSegment.fromJson(json),
      SegmentType.forTime => ForTimeSegment.fromJson(json),
      SegmentType.emom => EmomSegment.fromJson(json),
      SegmentType.tabata => TabataSegment.fromJson(json),
      SegmentType.rest => RestSegment.fromJson(json),
    };
  }

  WorkoutSegment copyWith({
    String? id,
    String? name,
    int? rounds,
  });

  @override
  List<Object?> get props => [id, name, rounds];
}

class AmrapSegment extends WorkoutSegment {
  final Duration duration;

  const AmrapSegment({
    required super.id,
    super.name,
    super.rounds,
    required this.duration,
  });

  @override
  SegmentType get type => SegmentType.amrap;

  @override
  Duration get totalDuration => duration * rounds;

  @override
  Map<String, dynamic> toJson() => {
        'type': type.name,
        'id': id,
        'name': name,
        'rounds': rounds,
        'durationSeconds': duration.inSeconds,
      };

  factory AmrapSegment.fromJson(Map<String, dynamic> json) => AmrapSegment(
        id: json['id'] as String,
        name: json['name'] as String?,
        rounds: json['rounds'] as int? ?? 1,
        duration: Duration(seconds: json['durationSeconds'] as int),
      );

  @override
  AmrapSegment copyWith({
    String? id,
    String? name,
    int? rounds,
    Duration? duration,
  }) =>
      AmrapSegment(
        id: id ?? this.id,
        name: name ?? this.name,
        rounds: rounds ?? this.rounds,
        duration: duration ?? this.duration,
      );

  @override
  List<Object?> get props => [...super.props, duration];
}

class ForTimeSegment extends WorkoutSegment {
  final Duration? timeCap;

  const ForTimeSegment({
    required super.id,
    super.name,
    super.rounds,
    this.timeCap,
  });

  @override
  SegmentType get type => SegmentType.forTime;

  @override
  Duration get totalDuration => (timeCap ?? const Duration(hours: 1)) * rounds;

  @override
  Map<String, dynamic> toJson() => {
        'type': type.name,
        'id': id,
        'name': name,
        'rounds': rounds,
        'timeCapSeconds': timeCap?.inSeconds,
      };

  factory ForTimeSegment.fromJson(Map<String, dynamic> json) => ForTimeSegment(
        id: json['id'] as String,
        name: json['name'] as String?,
        rounds: json['rounds'] as int? ?? 1,
        timeCap: json['timeCapSeconds'] != null
            ? Duration(seconds: json['timeCapSeconds'] as int)
            : null,
      );

  @override
  ForTimeSegment copyWith({
    String? id,
    String? name,
    int? rounds,
    Duration? timeCap,
  }) =>
      ForTimeSegment(
        id: id ?? this.id,
        name: name ?? this.name,
        rounds: rounds ?? this.rounds,
        timeCap: timeCap ?? this.timeCap,
      );

  @override
  List<Object?> get props => [...super.props, timeCap];
}

class EmomSegment extends WorkoutSegment {
  final Duration totalTime;
  final Duration intervalDuration;

  const EmomSegment({
    required super.id,
    super.name,
    super.rounds,
    required this.totalTime,
    required this.intervalDuration,
  });

  @override
  SegmentType get type => SegmentType.emom;

  @override
  Duration get totalDuration => totalTime * rounds;

  int get intervalCount => totalTime.inSeconds ~/ intervalDuration.inSeconds;

  @override
  Map<String, dynamic> toJson() => {
        'type': type.name,
        'id': id,
        'name': name,
        'rounds': rounds,
        'totalTimeSeconds': totalTime.inSeconds,
        'intervalDurationSeconds': intervalDuration.inSeconds,
      };

  factory EmomSegment.fromJson(Map<String, dynamic> json) => EmomSegment(
        id: json['id'] as String,
        name: json['name'] as String?,
        rounds: json['rounds'] as int? ?? 1,
        totalTime: Duration(seconds: json['totalTimeSeconds'] as int),
        intervalDuration:
            Duration(seconds: json['intervalDurationSeconds'] as int),
      );

  @override
  EmomSegment copyWith({
    String? id,
    String? name,
    int? rounds,
    Duration? totalTime,
    Duration? intervalDuration,
  }) =>
      EmomSegment(
        id: id ?? this.id,
        name: name ?? this.name,
        rounds: rounds ?? this.rounds,
        totalTime: totalTime ?? this.totalTime,
        intervalDuration: intervalDuration ?? this.intervalDuration,
      );

  @override
  List<Object?> get props => [...super.props, totalTime, intervalDuration];
}

class TabataSegment extends WorkoutSegment {
  final Duration workDuration;
  final Duration restDuration;
  final int tabataRounds;

  const TabataSegment({
    required super.id,
    super.name,
    super.rounds,
    required this.workDuration,
    required this.restDuration,
    required this.tabataRounds,
  });

  @override
  SegmentType get type => SegmentType.tabata;

  @override
  Duration get totalDuration =>
      Duration(
        seconds:
            (workDuration.inSeconds + restDuration.inSeconds) * tabataRounds,
      ) *
      rounds;

  @override
  Map<String, dynamic> toJson() => {
        'type': type.name,
        'id': id,
        'name': name,
        'rounds': rounds,
        'workDurationSeconds': workDuration.inSeconds,
        'restDurationSeconds': restDuration.inSeconds,
        'tabataRounds': tabataRounds,
      };

  factory TabataSegment.fromJson(Map<String, dynamic> json) => TabataSegment(
        id: json['id'] as String,
        name: json['name'] as String?,
        rounds: json['rounds'] as int? ?? 1,
        workDuration: Duration(seconds: json['workDurationSeconds'] as int),
        restDuration: Duration(seconds: json['restDurationSeconds'] as int),
        tabataRounds: json['tabataRounds'] as int,
      );

  @override
  TabataSegment copyWith({
    String? id,
    String? name,
    int? rounds,
    Duration? workDuration,
    Duration? restDuration,
    int? tabataRounds,
  }) =>
      TabataSegment(
        id: id ?? this.id,
        name: name ?? this.name,
        rounds: rounds ?? this.rounds,
        workDuration: workDuration ?? this.workDuration,
        restDuration: restDuration ?? this.restDuration,
        tabataRounds: tabataRounds ?? this.tabataRounds,
      );

  @override
  List<Object?> get props =>
      [...super.props, workDuration, restDuration, tabataRounds];
}

class RestSegment extends WorkoutSegment {
  final Duration duration;

  const RestSegment({
    required super.id,
    super.name,
    super.rounds,
    required this.duration,
  });

  @override
  SegmentType get type => SegmentType.rest;

  @override
  Duration get totalDuration => duration * rounds;

  @override
  Map<String, dynamic> toJson() => {
        'type': type.name,
        'id': id,
        'name': name,
        'rounds': rounds,
        'durationSeconds': duration.inSeconds,
      };

  factory RestSegment.fromJson(Map<String, dynamic> json) => RestSegment(
        id: json['id'] as String,
        name: json['name'] as String?,
        rounds: json['rounds'] as int? ?? 1,
        duration: Duration(seconds: json['durationSeconds'] as int),
      );

  @override
  RestSegment copyWith({
    String? id,
    String? name,
    int? rounds,
    Duration? duration,
  }) =>
      RestSegment(
        id: id ?? this.id,
        name: name ?? this.name,
        rounds: rounds ?? this.rounds,
        duration: duration ?? this.duration,
      );

  @override
  List<Object?> get props => [...super.props, duration];
}
