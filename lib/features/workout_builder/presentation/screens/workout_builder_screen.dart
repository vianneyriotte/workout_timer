import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/utils/time_formatter.dart';
import '../../../presets/data/presets_repository.dart';
import '../../../timer/domain/models/models.dart';
import '../widgets/segment_editor_dialog.dart';

class WorkoutBuilderScreen extends ConsumerStatefulWidget {
  const WorkoutBuilderScreen({super.key});

  @override
  ConsumerState<WorkoutBuilderScreen> createState() =>
      _WorkoutBuilderScreenState();
}

class _WorkoutBuilderScreenState extends ConsumerState<WorkoutBuilderScreen> {
  final _uuid = const Uuid();
  final _nameController = TextEditingController(text: 'Custom Workout');

  final List<SegmentGroup> _groups = [];
  int _workoutRounds = 1;
  Duration _countdownDuration = const Duration(seconds: 10);

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout Builder'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton.icon(
            onPressed: _showAddSegmentDialog,
            icon: const Icon(Icons.add, color: AppColors.primary),
            label: const Text(
              'Add Segment',
              style: TextStyle(color: AppColors.primary),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showWorkoutSettings,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _groups.isEmpty ? _buildEmptyState() : _buildSegmentList(),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.fitness_center,
            size: 64,
            color: AppColors.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No segments yet',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap "Add Segment" in the top bar to build your workout',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textMuted,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentList() {
    return ReorderableListView.builder(
      padding: const EdgeInsets.only(bottom: 100, top: 16),
      itemCount: _groups.length,
      onReorder: (oldIndex, newIndex) {
        setState(() {
          if (newIndex > oldIndex) newIndex--;
          final group = _groups.removeAt(oldIndex);
          _groups.insert(newIndex, group);
        });
      },
      itemBuilder: (context, groupIndex) {
        final group = _groups[groupIndex];
        return _GroupCard(
          key: ValueKey(group.id),
          group: group,
          groupIndex: groupIndex,
          onEdit: () => _editGroup(groupIndex),
          onDelete: () => _deleteGroup(groupIndex),
          onAddSegment: () => _addSegmentToGroup(groupIndex),
          onEditSegment: (segmentIndex) =>
              _editSegment(groupIndex, segmentIndex),
          onDeleteSegment: (segmentIndex) =>
              _deleteSegment(groupIndex, segmentIndex),
          onRoundsChanged: (rounds) => _updateGroupRounds(groupIndex, rounds),
        );
      },
    );
  }

  Widget _buildBottomBar() {
    final totalDuration = _calculateTotalDuration();
    final totalSegments = _groups.fold<int>(
      0,
      (sum, g) => sum + g.segments.length,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _InfoChip(
                  icon: Icons.layers,
                  label: '$totalSegments segments',
                ),
                _InfoChip(
                  icon: Icons.timer,
                  label: TimeFormatter.formatDurationShort(totalDuration),
                ),
                if (_workoutRounds > 1)
                  _InfoChip(
                    icon: Icons.repeat,
                    label: '$_workoutRounds rounds',
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _groups.isEmpty ? null : _saveWorkout,
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Save'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _groups.isEmpty ? null : _startWorkout,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Start Workout'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Duration _calculateTotalDuration() {
    var total = Duration.zero;
    for (final group in _groups) {
      total += group.totalDuration;
    }
    return total * _workoutRounds;
  }

  void _showAddSegmentDialog() async {
    final segment = await showDialog<WorkoutSegment>(
      context: context,
      builder: (context) => const SegmentEditorDialog(),
    );

    if (segment != null) {
      setState(() {
        _groups.add(SegmentGroup(
          id: _uuid.v4(),
          segments: [segment],
        ));
      });
    }
  }

  void _addSegmentToGroup(int groupIndex) async {
    final segment = await showDialog<WorkoutSegment>(
      context: context,
      builder: (context) => const SegmentEditorDialog(),
    );

    if (segment != null) {
      setState(() {
        final group = _groups[groupIndex];
        _groups[groupIndex] = group.copyWith(
          segments: [...group.segments, segment],
        );
      });
    }
  }

  void _editGroup(int groupIndex) {
    // Group editing is handled via the rounds counter in the card
  }

  void _deleteGroup(int groupIndex) {
    setState(() {
      _groups.removeAt(groupIndex);
    });
  }

  void _editSegment(int groupIndex, int segmentIndex) async {
    final currentSegment = _groups[groupIndex].segments[segmentIndex];
    final segment = await showDialog<WorkoutSegment>(
      context: context,
      builder: (context) => SegmentEditorDialog(segment: currentSegment),
    );

    if (segment != null) {
      setState(() {
        final group = _groups[groupIndex];
        final segments = List<WorkoutSegment>.from(group.segments);
        segments[segmentIndex] = segment;
        _groups[groupIndex] = group.copyWith(segments: segments);
      });
    }
  }

  void _deleteSegment(int groupIndex, int segmentIndex) {
    setState(() {
      final group = _groups[groupIndex];
      final segments = List<WorkoutSegment>.from(group.segments);
      segments.removeAt(segmentIndex);

      if (segments.isEmpty) {
        _groups.removeAt(groupIndex);
      } else {
        _groups[groupIndex] = group.copyWith(segments: segments);
      }
    });
  }

  void _updateGroupRounds(int groupIndex, int rounds) {
    setState(() {
      _groups[groupIndex] = _groups[groupIndex].copyWith(rounds: rounds);
    });
  }

  void _showWorkoutSettings() async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _WorkoutSettingsSheet(
        name: _nameController.text,
        rounds: _workoutRounds,
        countdown: _countdownDuration,
        onNameChanged: (name) => _nameController.text = name,
        onRoundsChanged: (rounds) => setState(() => _workoutRounds = rounds),
        onCountdownChanged: (d) => setState(() => _countdownDuration = d),
      ),
    );
  }

  Workout _createWorkout() {
    return Workout(
      id: _uuid.v4(),
      name: _nameController.text,
      groups: _groups,
      rounds: _workoutRounds,
      countdownDuration: _countdownDuration,
      createdAt: DateTime.now(),
    );
  }

  void _startWorkout() {
    final workout = _createWorkout();
    context.push('/timer', extra: workout);
  }

  void _saveWorkout() {
    final workout = _createWorkout();
    ref.read(presetsProvider.notifier).addPreset(workout);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Workout "${workout.name}" saved'),
        backgroundColor: AppColors.success,
      ),
    );
  }
}

class _GroupCard extends StatelessWidget {
  final SegmentGroup group;
  final int groupIndex;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onAddSegment;
  final Function(int) onEditSegment;
  final Function(int) onDeleteSegment;
  final Function(int) onRoundsChanged;

  const _GroupCard({
    super.key,
    required this.group,
    required this.groupIndex,
    required this.onEdit,
    required this.onDelete,
    required this.onAddSegment,
    required this.onEditSegment,
    required this.onDeleteSegment,
    required this.onRoundsChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: group.segments.length > 1
            ? Border.all(color: AppColors.custom.withOpacity(0.3))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (group.segments.length > 1) _buildGroupHeader(context),
          ...group.segments.asMap().entries.map((entry) {
            return _SegmentTile(
              segment: entry.value,
              onEdit: () => onEditSegment(entry.key),
              onDelete: () => onDeleteSegment(entry.key),
            );
          }),
          if (group.segments.length > 1)
            Padding(
              padding: const EdgeInsets.all(8),
              child: TextButton.icon(
                onPressed: onAddSegment,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add to group'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGroupHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.surfaceLight),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.custom.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'GROUP ${groupIndex + 1}',
              style: const TextStyle(
                color: AppColors.custom,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.remove, size: 18),
            onPressed:
                group.rounds > 1 ? () => onRoundsChanged(group.rounds - 1) : null,
            color: AppColors.textSecondary,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              '${group.rounds}x',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add, size: 18),
            onPressed: () => onRoundsChanged(group.rounds + 1),
            color: AppColors.textSecondary,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 18),
            onPressed: onDelete,
            color: AppColors.error,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }
}

class _SegmentTile extends StatelessWidget {
  final WorkoutSegment segment;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _SegmentTile({
    required this.segment,
    required this.onEdit,
    required this.onDelete,
  });

  Color get _color => switch (segment.type) {
        SegmentType.amrap => AppColors.amrap,
        SegmentType.forTime => AppColors.forTime,
        SegmentType.emom => AppColors.emom,
        SegmentType.tabata => AppColors.tabata,
        SegmentType.rest => AppColors.rest,
      };

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: _color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Icon(_getIcon(), color: _color, size: 20),
        ),
      ),
      title: Text(
        segment.type.name.toUpperCase(),
        style: TextStyle(
          color: _color,
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(
        _getSubtitle(),
        style: const TextStyle(color: AppColors.textSecondary),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (segment.rounds > 1)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${segment.rounds}x',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 18),
            onPressed: onEdit,
            color: AppColors.textSecondary,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 18),
            onPressed: onDelete,
            color: AppColors.error,
          ),
        ],
      ),
    );
  }

  IconData _getIcon() {
    return switch (segment.type) {
      SegmentType.amrap => Icons.repeat,
      SegmentType.forTime => Icons.timer,
      SegmentType.emom => Icons.schedule,
      SegmentType.tabata => Icons.fitness_center,
      SegmentType.rest => Icons.pause_circle_outline,
    };
  }

  String _getSubtitle() {
    return switch (segment) {
      AmrapSegment(:final duration) =>
        TimeFormatter.formatDurationShort(duration),
      ForTimeSegment(:final timeCap) => timeCap != null
          ? 'Cap: ${TimeFormatter.formatDurationShort(timeCap)}'
          : 'No time cap',
      EmomSegment(:final totalTime, :final intervalDuration) =>
        '${TimeFormatter.formatDurationShort(totalTime)} (${TimeFormatter.formatDurationShort(intervalDuration)} intervals)',
      TabataSegment(
        :final workDuration,
        :final restDuration,
        :final tabataRounds
      ) =>
        '${TimeFormatter.formatDurationShort(workDuration)}/${TimeFormatter.formatDurationShort(restDuration)} x $tabataRounds',
      RestSegment(:final duration) =>
        TimeFormatter.formatDurationShort(duration),
    };
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
      ],
    );
  }
}

class _WorkoutSettingsSheet extends StatefulWidget {
  final String name;
  final int rounds;
  final Duration countdown;
  final Function(String) onNameChanged;
  final Function(int) onRoundsChanged;
  final Function(Duration) onCountdownChanged;

  const _WorkoutSettingsSheet({
    required this.name,
    required this.rounds,
    required this.countdown,
    required this.onNameChanged,
    required this.onRoundsChanged,
    required this.onCountdownChanged,
  });

  @override
  State<_WorkoutSettingsSheet> createState() => _WorkoutSettingsSheetState();
}

class _WorkoutSettingsSheetState extends State<_WorkoutSettingsSheet> {
  late final TextEditingController _nameController;
  late int _rounds;
  late int _countdownSeconds;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.name);
    _rounds = widget.rounds;
    _countdownSeconds = widget.countdown.inSeconds;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Workout Settings',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Workout Name',
              prefixIcon: Icon(Icons.edit),
            ),
            onChanged: widget.onNameChanged,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              const Expanded(
                child: Text('Workout Rounds'),
              ),
              IconButton(
                icon: const Icon(Icons.remove),
                onPressed: _rounds > 1
                    ? () {
                        setState(() => _rounds--);
                        widget.onRoundsChanged(_rounds);
                      }
                    : null,
              ),
              Text(
                '$_rounds',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () {
                  setState(() => _rounds++);
                  widget.onRoundsChanged(_rounds);
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Expanded(
                child: Text('Countdown'),
              ),
              DropdownButton<int>(
                value: _countdownSeconds,
                items: [0, 5, 10, 15, 20, 30]
                    .map((s) => DropdownMenuItem(
                          value: s,
                          child: Text(s == 0 ? 'None' : '${s}s'),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _countdownSeconds = value);
                    widget.onCountdownChanged(Duration(seconds: value));
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Done'),
            ),
          ),
        ],
      ),
    );
  }
}
