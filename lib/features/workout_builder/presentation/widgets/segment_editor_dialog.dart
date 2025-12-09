import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/duration_picker.dart';
import '../../../timer/domain/models/models.dart';

class SegmentEditorDialog extends StatefulWidget {
  final WorkoutSegment? segment;

  const SegmentEditorDialog({
    super.key,
    this.segment,
  });

  @override
  State<SegmentEditorDialog> createState() => _SegmentEditorDialogState();
}

class _SegmentEditorDialogState extends State<SegmentEditorDialog> {
  final _uuid = const Uuid();

  late SegmentType _selectedType;
  late int _rounds;

  // AMRAP
  Duration _amrapDuration = const Duration(minutes: 20);

  // FOR TIME
  bool _hasTimeCap = true;
  Duration _timeCap = const Duration(minutes: 20);

  // EMOM
  int _emomRounds = 10;
  Duration _emomInterval = const Duration(minutes: 1);

  // TABATA
  Duration _tabataWork = const Duration(seconds: 20);
  Duration _tabataRest = const Duration(seconds: 10);
  int _tabataRounds = 8;

  // REST
  Duration _restDuration = const Duration(minutes: 2);

  // TEMPO
  List<int> _tempo = [4, 0, 1, 2];
  Duration _tempoRoundDuration = const Duration(minutes: 1);
  int _tempoRounds = 5;

  @override
  void initState() {
    super.initState();
    _initializeFromSegment();
  }

  void _initializeFromSegment() {
    final segment = widget.segment;
    if (segment == null) {
      _selectedType = SegmentType.amrap;
      _rounds = 1;
      return;
    }

    _selectedType = segment.type;
    _rounds = segment.rounds;

    switch (segment) {
      case AmrapSegment(:final duration):
        _amrapDuration = duration;
      case ForTimeSegment(:final timeCap):
        _hasTimeCap = timeCap != null;
        if (timeCap != null) _timeCap = timeCap;
      case EmomSegment(:final totalTime, :final intervalDuration):
        _emomRounds = totalTime.inSeconds ~/ intervalDuration.inSeconds;
        _emomInterval = intervalDuration;
      case TabataSegment(
          :final workDuration,
          :final restDuration,
          :final tabataRounds
        ):
        _tabataWork = workDuration;
        _tabataRest = restDuration;
        _tabataRounds = tabataRounds;
      case RestSegment(:final duration):
        _restDuration = duration;
      case TempoSegment(:final tempo, :final tempoRounds, :final roundDuration):
        _tempo = List.from(tempo);
        _tempoRounds = tempoRounds;
        _tempoRoundDuration = roundDuration;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.segment == null ? 'Add Segment' : 'Edit Segment',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 24),
            _buildTypeSelector(),
            const SizedBox(height: 24),
            _buildTypeConfig(),
            const SizedBox(height: 24),
            _buildRoundsPicker(),
            const SizedBox(height: 24),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Type',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: SegmentType.values.map((type) {
            final isSelected = _selectedType == type;
            final color = _getTypeColor(type);
            return ChoiceChip(
              label: Text(type.name.toUpperCase()),
              selected: isSelected,
              showCheckmark: false,
              onSelected: (_) {
                HapticFeedback.selectionClick();
                setState(() => _selectedType = type);
              },
              selectedColor: color.withOpacity(0.3),
              labelStyle: TextStyle(
                color: isSelected ? color : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              avatar: Icon(
                _getTypeIcon(type),
                size: 18,
                color: isSelected ? color : AppColors.textSecondary,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTypeConfig() {
    return switch (_selectedType) {
      SegmentType.amrap => _buildAmrapConfig(),
      SegmentType.forTime => _buildForTimeConfig(),
      SegmentType.emom => _buildEmomConfig(),
      SegmentType.tabata => _buildTabataConfig(),
      SegmentType.rest => _buildRestConfig(),
      SegmentType.tempo => _buildTempoConfig(),
    };
  }

  Widget _buildAmrapConfig() {
    return DurationPicker(
      label: 'Duration',
      initialDuration: _amrapDuration,
      onChanged: (d) => setState(() => _amrapDuration = d),
      minDuration: const Duration(seconds: 10),
      maxDuration: const Duration(hours: 12),
    );
  }

  Widget _buildForTimeConfig() {
    return Column(
      children: [
        SwitchListTile(
          title: const Text('Time Cap'),
          value: _hasTimeCap,
          onChanged: (v) {
            HapticFeedback.selectionClick();
            setState(() => _hasTimeCap = v);
          },
          activeColor: AppColors.forTime,
          contentPadding: EdgeInsets.zero,
        ),
        if (_hasTimeCap)
          DurationPicker(
            label: 'Time Cap',
            initialDuration: _timeCap,
            onChanged: (d) => setState(() => _timeCap = d),
            minDuration: const Duration(seconds: 10),
            maxDuration: const Duration(hours: 12),
          ),
      ],
    );
  }

  Widget _buildEmomConfig() {
    return Column(
      children: [
        DurationPicker(
          label: 'Round Duration',
          initialDuration: _emomInterval,
          onChanged: (d) => setState(() => _emomInterval = d),
          minDuration: const Duration(seconds: 10),
          maxDuration: const Duration(minutes: 30),
        ),
        const SizedBox(height: 16),
        _buildEmomRoundsPicker(),
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
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  '$_emomRounds',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
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
      ],
    );
  }

  Widget _buildTabataConfig() {
    return Column(
      children: [
        DurationPicker(
          label: 'Work Duration',
          initialDuration: _tabataWork,
          onChanged: (d) => setState(() => _tabataWork = d),
          minDuration: const Duration(seconds: 5),
          maxDuration: const Duration(minutes: 5),
        ),
        const SizedBox(height: 16),
        DurationPicker(
          label: 'Rest Duration',
          initialDuration: _tabataRest,
          onChanged: (d) => setState(() => _tabataRest = d),
          minDuration: const Duration(seconds: 5),
          maxDuration: const Duration(minutes: 5),
        ),
        const SizedBox(height: 16),
        _buildTabataRoundsPicker(),
      ],
    );
  }

  Widget _buildRestConfig() {
    return DurationPicker(
      label: 'Rest Duration',
      initialDuration: _restDuration,
      onChanged: (d) => setState(() => _restDuration = d),
      minDuration: const Duration(seconds: 10),
      maxDuration: const Duration(minutes: 10),
    );
  }

  Widget _buildTempoConfig() {
    return Column(
      children: [
        _buildTempoPicker(),
        const SizedBox(height: 16),
        DurationPicker(
          label: 'Round Duration',
          initialDuration: _tempoRoundDuration,
          onChanged: (d) => setState(() => _tempoRoundDuration = d),
          minDuration: const Duration(seconds: 10),
          maxDuration: const Duration(minutes: 10),
        ),
        const SizedBox(height: 16),
        _buildTempoRoundsPicker(),
      ],
    );
  }

  Widget _buildTempoPicker() {
    final labels = ['Ecc', 'Bot', 'Con', 'Top'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Tempo Pattern', style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(4, (index) {
            return Column(
              children: [
                Text(labels[index],
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                Container(
                  width: 55,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.add, size: 18),
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
                        constraints: const BoxConstraints(minHeight: 28),
                      ),
                      Text('${_tempo[index]}',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.tempo)),
                      IconButton(
                        icon: const Icon(Icons.remove, size: 18),
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
                        constraints: const BoxConstraints(minHeight: 28),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }),
        ),
      ],
    );
  }

  Widget _buildTempoRoundsPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Number of Rounds', style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text('$_tempoRounds',
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold)),
              ),
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
      ],
    );
  }

  Widget _buildRoundsPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Segment Rounds',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  '$_rounds',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: _rounds < 20
                    ? () {
                        HapticFeedback.lightImpact();
                        setState(() => _rounds++);
                      }
                    : null,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabataRoundsPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tabata Rounds',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.remove),
                onPressed: _tabataRounds > 1
                    ? () {
                        HapticFeedback.lightImpact();
                        setState(() => _tabataRounds--);
                      }
                    : null,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  '$_tabataRounds',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: _tabataRounds < 50
                    ? () {
                        HapticFeedback.lightImpact();
                        setState(() => _tabataRounds++);
                      }
                    : null,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: _saveSegment,
          child: Text(widget.segment == null ? 'Add' : 'Save'),
        ),
      ],
    );
  }

  void _saveSegment() {
    final id = widget.segment?.id ?? _uuid.v4();

    final segment = switch (_selectedType) {
      SegmentType.amrap => AmrapSegment(
          id: id,
          duration: _amrapDuration,
          rounds: _rounds,
        ),
      SegmentType.forTime => ForTimeSegment(
          id: id,
          timeCap: _hasTimeCap ? _timeCap : null,
          rounds: _rounds,
        ),
      SegmentType.emom => EmomSegment(
          id: id,
          totalTime: _emomInterval * _emomRounds,
          intervalDuration: _emomInterval,
          rounds: _rounds,
        ),
      SegmentType.tabata => TabataSegment(
          id: id,
          workDuration: _tabataWork,
          restDuration: _tabataRest,
          tabataRounds: _tabataRounds,
          rounds: _rounds,
        ),
      SegmentType.rest => RestSegment(
          id: id,
          duration: _restDuration,
          rounds: _rounds,
        ),
      SegmentType.tempo => TempoSegment(
          id: id,
          tempo: _tempo,
          tempoRounds: _tempoRounds,
          roundDuration: _tempoRoundDuration,
          rounds: _rounds,
        ),
    };

    Navigator.pop(context, segment);
  }

  Color _getTypeColor(SegmentType type) {
    return switch (type) {
      SegmentType.amrap => AppColors.amrap,
      SegmentType.forTime => AppColors.forTime,
      SegmentType.emom => AppColors.emom,
      SegmentType.tabata => AppColors.tabata,
      SegmentType.rest => AppColors.rest,
      SegmentType.tempo => AppColors.tempo,
    };
  }

  IconData _getTypeIcon(SegmentType type) {
    return switch (type) {
      SegmentType.amrap => Icons.repeat,
      SegmentType.forTime => Icons.timer,
      SegmentType.emom => Icons.schedule,
      SegmentType.tabata => Icons.fitness_center,
      SegmentType.rest => Icons.pause_circle_outline,
      SegmentType.tempo => Icons.speed,
    };
  }
}
