import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../features/timer/domain/models/models.dart';

class TimerControls extends StatelessWidget {
  final TimerStatus status;
  final VoidCallback onStart;
  final VoidCallback onPause;
  final VoidCallback onReset;
  final VoidCallback? onComplete;
  final bool showComplete;

  const TimerControls({
    super.key,
    required this.status,
    required this.onStart,
    required this.onPause,
    required this.onReset,
    this.onComplete,
    this.showComplete = false,
  });

  @override
  Widget build(BuildContext context) {
    final showSideButtons = status != TimerStatus.idle && status != TimerStatus.completed;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (showSideButtons) ...[
          _ControlButton(
            icon: Icons.refresh,
            onPressed: onReset,
            color: AppColors.textSecondary,
            size: 48,
          ),
          const SizedBox(width: 24),
        ],
        _MainControlButton(
          status: status,
          onStart: onStart,
          onPause: onPause,
          onReset: onReset,
        ),
        if (showSideButtons) ...[
          const SizedBox(width: 24),
          if (showComplete && onComplete != null)
            _ControlButton(
              icon: Icons.check,
              onPressed: onComplete!,
              color: AppColors.success,
              size: 48,
            )
          else
            const SizedBox(width: 48),
        ],
      ],
    );
  }
}

class AddRoundButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String label;
  final int? count;

  const AddRoundButton({
    super.key,
    required this.onPressed,
    this.label = '+1 Round',
    this.count,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        onPressed();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.15),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.primary, width: 2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add, color: AppColors.primary, size: 24),
            const SizedBox(width: 8),
            Text(
              count != null ? '$label ($count)' : label,
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MainControlButton extends StatelessWidget {
  final TimerStatus status;
  final VoidCallback onStart;
  final VoidCallback onPause;
  final VoidCallback onReset;

  const _MainControlButton({
    required this.status,
    required this.onStart,
    required this.onPause,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final (icon, color, callback) = switch (status) {
      TimerStatus.idle => (Icons.play_arrow, AppColors.primary, onStart),
      TimerStatus.countdown => (Icons.pause, AppColors.prepare, onPause),
      TimerStatus.running => (Icons.pause, AppColors.work, onPause),
      TimerStatus.paused => (Icons.play_arrow, AppColors.primary, onStart),
      TimerStatus.rest => (Icons.pause, AppColors.rest, onPause),
      TimerStatus.completed => (Icons.refresh, AppColors.primary, onReset),
    };

    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        callback();
      },
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Icon(
          icon,
          size: 40,
          color: AppColors.background,
        ),
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String? label;
  final VoidCallback onPressed;
  final Color color;
  final double size;

  const _ControlButton({
    required this.icon,
    this.label,
    required this.onPressed,
    required this.color,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onPressed();
      },
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 2),
        ),
        child: label != null
            ? Center(
                child: Text(
                  label!,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              )
            : Icon(icon, color: color, size: 24),
      ),
    );
  }
}
