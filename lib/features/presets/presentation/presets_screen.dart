import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/utils/time_formatter.dart';
import '../../timer/domain/models/models.dart';
import '../data/presets_repository.dart';

class PresetsScreen extends ConsumerWidget {
  const PresetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final presets = ref.watch(presetsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Workouts'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: presets.isEmpty
          ? _buildEmptyState(context)
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: presets.length,
              itemBuilder: (context, index) {
                final workout = presets[index];
                return _PresetCard(
                  workout: workout,
                  onTap: () => context.push('/timer', extra: workout),
                  onDelete: () =>
                      ref.read(presetsProvider.notifier).removePreset(workout.id),
                );
              },
            ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.bookmark_border,
            size: 64,
            color: AppColors.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No saved workouts',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Save workouts from the timer configuration or builder',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textMuted,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _PresetCard extends StatelessWidget {
  final Workout workout;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _PresetCard({
    required this.workout,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(workout.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (_) => _confirmDelete(context),
      onDismissed: (_) => onDelete(),
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        workout.name,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                    ),
                    Icon(
                      Icons.play_circle_filled,
                      color: AppColors.primary,
                      size: 32,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildSegmentChips(),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _InfoItem(
                      icon: Icons.layers,
                      label: '${workout.totalSegments} segments',
                    ),
                    const SizedBox(width: 16),
                    _InfoItem(
                      icon: Icons.timer,
                      label: TimeFormatter.formatDurationShort(
                          workout.totalDuration),
                    ),
                    if (workout.rounds > 1) ...[
                      const SizedBox(width: 16),
                      _InfoItem(
                        icon: Icons.repeat,
                        label: '${workout.rounds} rounds',
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSegmentChips() {
    final types = <SegmentType>{};
    for (final group in workout.groups) {
      for (final segment in group.segments) {
        types.add(segment.type);
      }
    }

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: types.map((type) {
        final color = _getTypeColor(type);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            type.name.toUpperCase(),
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      }).toList(),
    );
  }

  Color _getTypeColor(SegmentType type) {
    return switch (type) {
      SegmentType.amrap => AppColors.amrap,
      SegmentType.forTime => AppColors.forTime,
      SegmentType.emom => AppColors.emom,
      SegmentType.tabata => AppColors.tabata,
      SegmentType.rest => AppColors.rest,
    };
  }

  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Workout?'),
        content: Text('Are you sure you want to delete "${workout.name}"?'),
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
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoItem({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
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
