import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/utils/time_formatter.dart';
import '../../../shared/widgets/duration_picker.dart';
import '../../presets/data/presets_repository.dart';
import '../../timer/domain/models/models.dart';

class TimerConfigScreen extends ConsumerStatefulWidget {
  final String timerType;

  const TimerConfigScreen({
    super.key,
    required this.timerType,
  });

  @override
  ConsumerState<TimerConfigScreen> createState() => _TimerConfigScreenState();
}

class _TimerConfigScreenState extends ConsumerState<TimerConfigScreen> {
  final _uuid = const Uuid();

  Duration _duration = const Duration(minutes: 20);
  Duration _workDuration = const Duration(seconds: 20);
  Duration _restDuration = const Duration(seconds: 10);
  Duration _intervalDuration = const Duration(minutes: 1);
  Duration? _timeCap = const Duration(minutes: 20);
  int _rounds = 8;
  int _emomRounds = 10;
  bool _hasTimeCap = true;
  int _countdownSeconds = 10;

  List<int> _tempo = [4, 0, 1, 2];
  Duration _tempoRoundDuration = const Duration(minutes: 1);
  int _tempoRounds = 5;

  String get _title => switch (widget.timerType) {
        'amrap' => 'AMRAP',
        'fortime' => 'FOR TIME',
        'emom' => 'EMOM',
        'tabata' => 'TABATA',
        'tempo' => 'TEMPO',
        _ => 'Timer',
      };

  Color get _color => switch (widget.timerType) {
        'amrap' => AppColors.amrap,
        'fortime' => AppColors.forTime,
        'emom' => AppColors.emom,
        'tabata' => AppColors.tabata,
        'tempo' => AppColors.tempo,
        _ => AppColors.primary,
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: _buildConfigForm(),
              ),
            ),
            _buildBottomButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigForm() {
    return switch (widget.timerType) {
      'amrap' => _buildAmrapConfig(),
      'fortime' => _buildForTimeConfig(),
      'emom' => _buildEmomConfig(),
      'tabata' => _buildTabataConfig(),
      'tempo' => _buildTempoConfig(),
      _ => const SizedBox.shrink(),
    };
  }

  Widget _buildAmrapConfig() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDescription(
          'Set the total duration for your AMRAP workout. '
          'Complete as many rounds as possible within the time limit.',
        ),
        const SizedBox(height: 32),
        DurationPicker(
          label: 'Duration',
          initialDuration: _duration,
          onChanged: (d) => setState(() => _duration = d),
          minDuration: const Duration(seconds: 10),
          maxDuration: const Duration(hours: 12),
        ),
        const SizedBox(height: 16),
        _buildPresetDurations([5, 10, 15, 20, 30]),
        const SizedBox(height: 24),
        _buildCountdownPicker(),
      ],
    );
  }

  Widget _buildForTimeConfig() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDescription(
          'Complete your workout as fast as possible. '
          'Optionally set a time cap to limit the maximum duration.',
        ),
        const SizedBox(height: 32),
        SwitchListTile(
          title: const Text('Time Cap'),
          subtitle: const Text('Set a maximum time limit'),
          value: _hasTimeCap,
          onChanged: (v) {
            HapticFeedback.selectionClick();
            setState(() => _hasTimeCap = v);
          },
          activeColor: _color,
          contentPadding: EdgeInsets.zero,
        ),
        if (_hasTimeCap) ...[
          const SizedBox(height: 16),
          DurationPicker(
            label: 'Time Cap',
            initialDuration: _timeCap ?? const Duration(minutes: 20),
            onChanged: (d) => setState(() => _timeCap = d),
            minDuration: const Duration(seconds: 10),
            maxDuration: const Duration(hours: 12),
          ),
          const SizedBox(height: 16),
          _buildPresetDurations([10, 15, 20, 30, 45]),
        ],
        const SizedBox(height: 24),
        _buildCountdownPicker(),
      ],
    );
  }

  Widget _buildEmomConfig() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDescription(
          'Perform exercises at the start of every minute. '
          'Rest for the remaining time until the next interval begins.',
        ),
        const SizedBox(height: 32),
        DurationPicker(
          label: 'Round Duration',
          initialDuration: _intervalDuration,
          onChanged: (d) => setState(() => _intervalDuration = d),
          minDuration: const Duration(seconds: 10),
          maxDuration: const Duration(minutes: 30),
        ),
        const SizedBox(height: 24),
        _buildEmomRoundsPicker(),
        const SizedBox(height: 16),
        _buildIntervalInfo(),
        const SizedBox(height: 24),
        _buildCountdownPicker(),
      ],
    );
  }

  Widget _buildEmomRoundsPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Number of Rounds',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.remove),
                onPressed: _emomRounds > 1
                    ? () {
                        HapticFeedback.lightImpact();
                        setState(() => _emomRounds--);
                      }
                    : null,
              ),
              const SizedBox(width: 16),
              Text(
                '$_emomRounds',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 16),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: _emomRounds < 60
                    ? () {
                        HapticFeedback.lightImpact();
                        setState(() => _emomRounds++);
                      }
                    : null,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Wrap(
            spacing: 8,
            children: [5, 10, 15, 20, 30].map((r) {
              return ChoiceChip(
                label: Text('$r'),
                selected: _emomRounds == r,
                showCheckmark: false,
                onSelected: (_) {
                  HapticFeedback.selectionClick();
                  setState(() => _emomRounds = r);
                },
                selectedColor: _color.withOpacity(0.3),
                labelStyle: TextStyle(
                  color: _emomRounds == r ? _color : AppColors.textSecondary,
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildTabataConfig() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDescription(
          'High intensity interval training. '
          'Alternate between work and rest periods for the specified rounds.',
        ),
        const SizedBox(height: 32),
        DurationPicker(
          label: 'Work Duration',
          initialDuration: _workDuration,
          onChanged: (d) => setState(() => _workDuration = d),
          minDuration: const Duration(seconds: 5),
          maxDuration: const Duration(minutes: 5),
        ),
        const SizedBox(height: 24),
        DurationPicker(
          label: 'Rest Duration',
          initialDuration: _restDuration,
          onChanged: (d) => setState(() => _restDuration = d),
          minDuration: const Duration(seconds: 5),
          maxDuration: const Duration(minutes: 5),
        ),
        const SizedBox(height: 24),
        _buildRoundsPicker(),
        const SizedBox(height: 16),
        _buildTabataInfo(),
        const SizedBox(height: 24),
        _buildCountdownPicker(),
      ],
    );
  }

  Widget _buildTempoConfig() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDescription(
          'Control movement speed with a 4-digit tempo: '
          'eccentric-bottom-concentric-top. Each number counts down vocally.',
        ),
        const SizedBox(height: 32),
        _buildTempoPicker(),
        const SizedBox(height: 24),
        DurationPicker(
          label: 'Round Duration',
          initialDuration: _tempoRoundDuration,
          onChanged: (d) => setState(() => _tempoRoundDuration = d),
          minDuration: const Duration(seconds: 10),
          maxDuration: const Duration(minutes: 10),
        ),
        const SizedBox(height: 24),
        _buildTempoRoundsPicker(),
        const SizedBox(height: 16),
        _buildTempoInfo(),
        const SizedBox(height: 24),
        _buildCountdownPicker(),
      ],
    );
  }

  Widget _buildTempoPicker() {
    final labels = ['Eccentric', 'Bottom', 'Concentric', 'Top'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tempo Pattern',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(4, (index) {
            return Column(
              children: [
                Text(
                  labels[index],
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: 70,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.add, size: 20),
                        onPressed: _tempo[index] < 10
                            ? () {
                                HapticFeedback.lightImpact();
                                setState(() {
                                  _tempo = List.from(_tempo);
                                  _tempo[index]++;
                                });
                              }
                            : null,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minHeight: 32),
                      ),
                      Text(
                        '${_tempo[index]}',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: _color,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.remove, size: 20),
                        onPressed: _tempo[index] > 0
                            ? () {
                                HapticFeedback.lightImpact();
                                setState(() {
                                  _tempo = List.from(_tempo);
                                  _tempo[index]--;
                                });
                              }
                            : null,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minHeight: 32),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }),
        ),
        const SizedBox(height: 12),
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _tempo.join(' - '),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _color,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTempoRoundsPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Number of Rounds',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.remove),
                onPressed: _tempoRounds > 1
                    ? () {
                        HapticFeedback.lightImpact();
                        setState(() => _tempoRounds--);
                      }
                    : null,
              ),
              const SizedBox(width: 16),
              Text(
                '$_tempoRounds',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 16),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: _tempoRounds < 20
                    ? () {
                        HapticFeedback.lightImpact();
                        setState(() => _tempoRounds++);
                      }
                    : null,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Wrap(
            spacing: 8,
            children: [1, 3, 5, 8, 10].map((r) {
              return ChoiceChip(
                label: Text('$r'),
                selected: _tempoRounds == r,
                showCheckmark: false,
                onSelected: (_) {
                  HapticFeedback.selectionClick();
                  setState(() => _tempoRounds = r);
                },
                selectedColor: _color.withOpacity(0.3),
                labelStyle: TextStyle(
                  color: _tempoRounds == r ? _color : AppColors.textSecondary,
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildTempoInfo() {
    final repDuration = _tempo.fold(0, (sum, t) => sum + (t == 0 ? 1 : t));
    final totalDuration = _tempoRoundDuration.inSeconds * _tempoRounds;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.timer, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Text(
                '${repDuration}s per rep • ${TimeFormatter.formatDurationShort(_tempoRoundDuration)} per round',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Total: ${TimeFormatter.formatDurationShort(Duration(seconds: totalDuration))}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: _color,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescription(String text) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: _color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetDurations(List<int> minutes) {
    return Wrap(
      spacing: 8,
      children: minutes.map((m) {
        final presetDuration = Duration(minutes: m);
        final bool isSelected;
        if (widget.timerType == 'fortime') {
          isSelected = _timeCap == presetDuration;
        } else {
          isSelected = _duration == presetDuration;
        }
        return ChoiceChip(
          label: Text('${m}min'),
          selected: isSelected,
          showCheckmark: false,
          onSelected: (_) {
            HapticFeedback.selectionClick();
            setState(() {
              if (widget.timerType == 'fortime') {
                _timeCap = presetDuration;
              } else {
                _duration = presetDuration;
              }
            });
          },
          selectedColor: _color.withOpacity(0.3),
          labelStyle: TextStyle(
            color: isSelected ? _color : AppColors.textSecondary,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRoundsPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rounds',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.remove),
                onPressed: _rounds > 1
                    ? () {
                        HapticFeedback.lightImpact();
                        setState(() => _rounds--);
                      }
                    : null,
              ),
              const SizedBox(width: 16),
              Text(
                '$_rounds',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 16),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: _rounds < 50
                    ? () {
                        HapticFeedback.lightImpact();
                        setState(() => _rounds++);
                      }
                    : null,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Wrap(
            spacing: 8,
            children: [4, 6, 8, 10, 12].map((r) {
              return ChoiceChip(
                label: Text('$r'),
                selected: _rounds == r,
                showCheckmark: false,
                onSelected: (_) {
                  HapticFeedback.selectionClick();
                  setState(() => _rounds = r);
                },
                selectedColor: _color.withOpacity(0.3),
                labelStyle: TextStyle(
                  color: _rounds == r ? _color : AppColors.textSecondary,
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildIntervalInfo() {
    final totalDuration = _intervalDuration * _emomRounds;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.timer, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Text(
            'Total: ${TimeFormatter.formatDurationShort(totalDuration)}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabataInfo() {
    final totalDuration = Duration(
      seconds: (_workDuration.inSeconds + _restDuration.inSeconds) * _rounds,
    );
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.timer, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Text(
            'Total: ${TimeFormatter.formatDurationShort(totalDuration)}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountdownPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Countdown',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.remove),
                onPressed: _countdownSeconds > 0
                    ? () {
                        HapticFeedback.lightImpact();
                        setState(() => _countdownSeconds--);
                      }
                    : null,
              ),
              const SizedBox(width: 16),
              Text(
                '${_countdownSeconds}s',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 16),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: _countdownSeconds < 30
                    ? () {
                        HapticFeedback.lightImpact();
                        setState(() => _countdownSeconds++);
                      }
                    : null,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Wrap(
            spacing: 8,
            children: [0, 3, 5, 10, 15].map((s) {
              return ChoiceChip(
                label: Text('${s}s'),
                selected: _countdownSeconds == s,
                showCheckmark: false,
                onSelected: (_) {
                  HapticFeedback.selectionClick();
                  setState(() => _countdownSeconds = s);
                },
                selectedColor: _color.withOpacity(0.3),
                labelStyle: TextStyle(
                  color: _countdownSeconds == s ? _color : AppColors.textSecondary,
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomButtons() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _savePreset,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Save'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _color,
                side: BorderSide(color: _color),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: _startWorkout,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Start'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _color,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Workout _createWorkout() {
    final id = _uuid.v4();
    final countdown = Duration(seconds: _countdownSeconds);

    return switch (widget.timerType) {
      'amrap' => QuickWorkout.amrap(
          id: id,
          duration: _duration,
          countdownDuration: countdown,
        ),
      'fortime' => QuickWorkout.forTime(
          id: id,
          timeCap: _hasTimeCap ? _timeCap ?? const Duration(minutes: 20) : null,
          countdownDuration: countdown,
        ),
      'emom' => QuickWorkout.emom(
          id: id,
          totalTime: _intervalDuration * _emomRounds,
          intervalDuration: _intervalDuration,
          countdownDuration: countdown,
        ),
      'tabata' => QuickWorkout.tabata(
          id: id,
          workDuration: _workDuration,
          restDuration: _restDuration,
          rounds: _rounds,
          countdownDuration: countdown,
        ),
      'tempo' => QuickWorkout.tempo(
          id: id,
          tempoPattern: _tempo,
          tempoRounds: _tempoRounds,
          roundDuration: _tempoRoundDuration,
          countdownDuration: countdown,
        ),
      _ => throw UnimplementedError(),
    };
  }

  void _startWorkout() {
    HapticFeedback.mediumImpact();
    final workout = _createWorkout();
    context.push('/timer', extra: workout);
  }

  void _savePreset() async {
    HapticFeedback.lightImpact();
    final nameController = TextEditingController(text: _title);

    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save Workout'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Workout name',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, nameController.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (name != null && name.isNotEmpty) {
      final workout = _createWorkout().copyWith(name: name);
      ref.read(presetsProvider.notifier).addPreset(workout);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Workout "$name" saved'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }
}
