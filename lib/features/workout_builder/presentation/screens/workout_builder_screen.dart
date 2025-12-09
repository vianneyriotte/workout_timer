import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  bool _isSelectionMode = false;
  final Set<String> _selectedSegmentIds = {};

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isSelectionMode ? 'Select Segments' : 'Workout Builder'),
        leading: IconButton(
          icon: Icon(_isSelectionMode ? Icons.close : Icons.arrow_back),
          onPressed: _isSelectionMode ? _exitSelectionMode : () => context.pop(),
        ),
        actions: _isSelectionMode
            ? [
                if (_selectedSegmentIds.length >= 2)
                  TextButton.icon(
                    onPressed: _createBlockFromSelection,
                    icon: const Icon(Icons.group_work, color: AppColors.primary),
                    label: const Text(
                      'Create Block',
                      style: TextStyle(color: AppColors.primary),
                    ),
                  ),
              ]
            : [
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
          if (_isSelectionMode)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppColors.primary.withOpacity(0.1),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Select segments to group into a block (${_selectedSegmentIds.length} selected)',
                      style: TextStyle(color: AppColors.primary, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: _groups.isEmpty ? _buildEmptyState() : _buildSegmentList(),
          ),
          if (!_isSelectionMode) _buildBottomBar(),
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
            'Tap "Add Segment" to build your workout',
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
        HapticFeedback.mediumImpact();
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
          isSelectionMode: _isSelectionMode,
          selectedSegmentIds: _selectedSegmentIds,
          onSegmentSelected: _toggleSegmentSelection,
          onLongPress: _enterSelectionMode,
          onEdit: () => _editGroup(groupIndex),
          onDelete: () => _deleteGroup(groupIndex),
          onAddSegment: () => _addSegmentToGroup(groupIndex),
          onEditSegment: (segmentIndex) =>
              _editSegment(groupIndex, segmentIndex),
          onDeleteSegment: (segmentIndex) =>
              _deleteSegment(groupIndex, segmentIndex),
          onRoundsChanged: (rounds) => _updateGroupRounds(groupIndex, rounds),
          onDissolveGroup: () => _dissolveGroup(groupIndex),
          onReorderSegments: (oldIndex, newIndex) =>
              _reorderSegmentsInGroup(groupIndex, oldIndex, newIndex),
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

  void _enterSelectionMode(String segmentId) {
    HapticFeedback.mediumImpact();
    setState(() {
      _isSelectionMode = true;
      _selectedSegmentIds.add(segmentId);
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedSegmentIds.clear();
    });
  }

  void _toggleSegmentSelection(String segmentId) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_selectedSegmentIds.contains(segmentId)) {
        _selectedSegmentIds.remove(segmentId);
      } else {
        _selectedSegmentIds.add(segmentId);
      }
    });
  }

  void _createBlockFromSelection() async {
    final selectedSegments = <WorkoutSegment>[];
    final groupsToRemove = <int>[];

    for (var groupIndex = 0; groupIndex < _groups.length; groupIndex++) {
      final group = _groups[groupIndex];
      final segmentsToKeep = <WorkoutSegment>[];

      for (final segment in group.segments) {
        if (_selectedSegmentIds.contains(segment.id)) {
          selectedSegments.add(segment);
        } else {
          segmentsToKeep.add(segment);
        }
      }

      if (segmentsToKeep.isEmpty) {
        groupsToRemove.add(groupIndex);
      } else if (segmentsToKeep.length != group.segments.length) {
        _groups[groupIndex] = group.copyWith(segments: segmentsToKeep);
      }
    }

    for (var i = groupsToRemove.length - 1; i >= 0; i--) {
      _groups.removeAt(groupsToRemove[i]);
    }

    if (selectedSegments.isEmpty) {
      _exitSelectionMode();
      return;
    }

    final rounds = await showDialog<int>(
      context: context,
      builder: (context) => _BlockRoundsDialog(
        segmentCount: selectedSegments.length,
      ),
    );

    if (rounds != null) {
      HapticFeedback.mediumImpact();
      setState(() {
        _groups.add(SegmentGroup(
          id: _uuid.v4(),
          segments: selectedSegments,
          rounds: rounds,
        ));
      });
    } else {
      for (final segment in selectedSegments) {
        _groups.add(SegmentGroup(
          id: _uuid.v4(),
          segments: [segment],
        ));
      }
    }

    _exitSelectionMode();
  }

  void _dissolveGroup(int groupIndex) {
    HapticFeedback.lightImpact();
    setState(() {
      final group = _groups.removeAt(groupIndex);
      for (var i = 0; i < group.segments.length; i++) {
        _groups.insert(
          groupIndex + i,
          SegmentGroup(
            id: _uuid.v4(),
            segments: [group.segments[i]],
          ),
        );
      }
    });
  }

  void _reorderSegmentsInGroup(int groupIndex, int oldIndex, int newIndex) {
    HapticFeedback.lightImpact();
    setState(() {
      final group = _groups[groupIndex];
      final segments = List<WorkoutSegment>.from(group.segments);
      if (newIndex > oldIndex) newIndex--;
      final segment = segments.removeAt(oldIndex);
      segments.insert(newIndex, segment);
      _groups[groupIndex] = group.copyWith(segments: segments);
    });
  }

  void _showAddSegmentDialog() async {
    final segment = await showDialog<WorkoutSegment>(
      context: context,
      builder: (context) => const SegmentEditorDialog(),
    );

    if (segment != null) {
      HapticFeedback.lightImpact();
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
      HapticFeedback.lightImpact();
      setState(() {
        final group = _groups[groupIndex];
        _groups[groupIndex] = group.copyWith(
          segments: [...group.segments, segment],
        );
      });
    }
  }

  void _editGroup(int groupIndex) {}

  void _deleteGroup(int groupIndex) async {
    final group = _groups[groupIndex];
    final isBlock = group.segments.length > 1;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isBlock ? 'Delete Block?' : 'Delete Segment?'),
        content: Text(
          isBlock
              ? 'This will delete the block with ${group.segments.length} segments.'
              : 'This will delete this segment.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              HapticFeedback.mediumImpact();
              Navigator.pop(context, true);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _groups.removeAt(groupIndex);
      });
    }
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

  void _deleteSegment(int groupIndex, int segmentIndex) async {
    final segment = _groups[groupIndex].segments[segmentIndex];

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Segment?'),
        content: Text(
          'Delete ${segment.type.name.toUpperCase()} segment?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              HapticFeedback.mediumImpact();
              Navigator.pop(context, true);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
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
  }

  void _updateGroupRounds(int groupIndex, int rounds) {
    HapticFeedback.lightImpact();
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
    HapticFeedback.mediumImpact();
    final workout = _createWorkout();
    context.push('/timer', extra: workout);
  }

  void _saveWorkout() {
    HapticFeedback.lightImpact();
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
  final bool isSelectionMode;
  final Set<String> selectedSegmentIds;
  final Function(String) onSegmentSelected;
  final Function(String) onLongPress;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onAddSegment;
  final Function(int) onEditSegment;
  final Function(int) onDeleteSegment;
  final Function(int) onRoundsChanged;
  final VoidCallback onDissolveGroup;
  final Function(int, int) onReorderSegments;

  const _GroupCard({
    super.key,
    required this.group,
    required this.groupIndex,
    required this.isSelectionMode,
    required this.selectedSegmentIds,
    required this.onSegmentSelected,
    required this.onLongPress,
    required this.onEdit,
    required this.onDelete,
    required this.onAddSegment,
    required this.onEditSegment,
    required this.onDeleteSegment,
    required this.onRoundsChanged,
    required this.onDissolveGroup,
    required this.onReorderSegments,
  });

  @override
  Widget build(BuildContext context) {
    final isBlock = group.segments.length > 1;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: isBlock
            ? Border.all(color: AppColors.custom.withOpacity(0.5), width: 2)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isBlock) _buildGroupHeader(context),
          if (isBlock)
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: group.segments.length,
              onReorder: onReorderSegments,
              itemBuilder: (context, index) {
                final segment = group.segments[index];
                return _SegmentTile(
                  key: ValueKey(segment.id),
                  segment: segment,
                  isSelectionMode: isSelectionMode,
                  isSelected: selectedSegmentIds.contains(segment.id),
                  onTap: isSelectionMode
                      ? () => onSegmentSelected(segment.id)
                      : () => onEditSegment(index),
                  onLongPress: () => onLongPress(segment.id),
                  onEdit: () => onEditSegment(index),
                  onDelete: () => onDeleteSegment(index),
                  showActions: !isSelectionMode,
                );
              },
            )
          else
            ...group.segments.asMap().entries.map((entry) {
              final segment = entry.value;
              return _SegmentTile(
                key: ValueKey(segment.id),
                segment: segment,
                isSelectionMode: isSelectionMode,
                isSelected: selectedSegmentIds.contains(segment.id),
                onTap: isSelectionMode
                    ? () => onSegmentSelected(segment.id)
                    : () => onEditSegment(entry.key),
                onLongPress: () => onLongPress(segment.id),
                onEdit: () => onEditSegment(entry.key),
                onDelete: () => onDeleteSegment(entry.key),
                showActions: !isSelectionMode,
              );
            }),
          if (isBlock && !isSelectionMode)
            Padding(
              padding: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
              child: Row(
                children: [
                  TextButton.icon(
                    onPressed: onAddSegment,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: onDissolveGroup,
                    icon: const Icon(Icons.call_split, size: 18),
                    label: const Text('Dissolve'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                    ),
                  ),
                ],
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
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.custom.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.group_work, size: 16, color: AppColors.custom),
                const SizedBox(width: 6),
                Text(
                  'BLOCK ${groupIndex + 1}',
                  style: const TextStyle(
                    color: AppColors.custom,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${group.rounds}x',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
                fontSize: 16,
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
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool showActions;

  const _SegmentTile({
    super.key,
    required this.segment,
    required this.isSelectionMode,
    required this.isSelected,
    required this.onTap,
    required this.onLongPress,
    required this.onEdit,
    required this.onDelete,
    required this.showActions,
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
    return InkWell(
      onTap: onTap,
      onLongPress: isSelectionMode ? null : onLongPress,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : null,
        ),
        child: Row(
          children: [
            if (isSelectionMode)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Icon(
                  isSelected ? Icons.check_circle : Icons.circle_outlined,
                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                ),
              ),
            Container(
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
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    segment.type.name.toUpperCase(),
                    style: TextStyle(
                      color: _color,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    _getSubtitle(),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (segment.rounds > 1)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                margin: const EdgeInsets.only(right: 8),
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
            if (showActions) ...[
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 18),
                onPressed: onEdit,
                color: AppColors.textSecondary,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 18),
                onPressed: onDelete,
                color: AppColors.error,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
            ],
          ],
        ),
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

class _BlockRoundsDialog extends StatefulWidget {
  final int segmentCount;

  const _BlockRoundsDialog({required this.segmentCount});

  @override
  State<_BlockRoundsDialog> createState() => _BlockRoundsDialogState();
}

class _BlockRoundsDialogState extends State<_BlockRoundsDialog> {
  int _rounds = 1;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Block'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Group ${widget.segmentCount} segments into a block',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Rounds:'),
              const SizedBox(width: 16),
              IconButton(
                icon: const Icon(Icons.remove),
                onPressed: _rounds > 1
                    ? () {
                        HapticFeedback.lightImpact();
                        setState(() => _rounds--);
                      }
                    : null,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$_rounds',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  setState(() => _rounds++);
                },
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            HapticFeedback.mediumImpact();
            Navigator.pop(context, _rounds);
          },
          child: const Text('Create'),
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
                        HapticFeedback.lightImpact();
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
                  HapticFeedback.lightImpact();
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
                    HapticFeedback.selectionClick();
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
