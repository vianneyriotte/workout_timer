import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../features/timer/domain/models/models.dart';
import '../utils/time_formatter.dart';

class TimerDisplay extends StatelessWidget {
  final Duration time;
  final TimerPhase phase;
  final bool isCountUp;
  final double? progress;

  const TimerDisplay({
    super.key,
    required this.time,
    required this.phase,
    this.isCountUp = false,
    this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final color = switch (phase) {
      TimerPhase.work => AppColors.work,
      TimerPhase.rest => AppColors.rest,
      TimerPhase.prepare => AppColors.prepare,
    };

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (progress != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress!.clamp(0.0, 1.0),
                backgroundColor: AppColors.surface,
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 8,
              ),
            ),
          ),
        const SizedBox(height: 24),
        Text(
          TimeFormatter.formatDuration(time),
          style: Theme.of(context).textTheme.displayLarge?.copyWith(
                color: color,
                fontSize: _calculateFontSize(context),
                fontWeight: FontWeight.w300,
                letterSpacing: -2,
              ),
        ),
      ],
    );
  }

  double _calculateFontSize(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    if (isLandscape) {
      return screenWidth * 0.2;
    }
    return screenWidth * 0.25;
  }
}
