import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class DurationPicker extends StatefulWidget {
  final Duration initialDuration;
  final ValueChanged<Duration> onChanged;
  final String label;
  final Duration minDuration;
  final Duration maxDuration;
  final bool showHours;

  const DurationPicker({
    super.key,
    required this.initialDuration,
    required this.onChanged,
    required this.label,
    this.minDuration = Duration.zero,
    this.maxDuration = const Duration(hours: 2),
    this.showHours = false,
  });

  @override
  State<DurationPicker> createState() => _DurationPickerState();
}

class _DurationPickerState extends State<DurationPicker> {
  late FixedExtentScrollController _hoursController;
  late FixedExtentScrollController _minutesController;
  late FixedExtentScrollController _secondsController;

  late int _hours;
  late int _minutes;
  late int _seconds;

  @override
  void initState() {
    super.initState();
    _hours = widget.initialDuration.inHours;
    _minutes = widget.initialDuration.inMinutes.remainder(60);
    _seconds = widget.initialDuration.inSeconds.remainder(60);

    _hoursController = FixedExtentScrollController(initialItem: _hours);
    _minutesController = FixedExtentScrollController(initialItem: _minutes);
    _secondsController = FixedExtentScrollController(initialItem: _seconds);
  }

  @override
  void dispose() {
    _hoursController.dispose();
    _minutesController.dispose();
    _secondsController.dispose();
    super.dispose();
  }

  void _updateDuration() {
    var duration = Duration(
      hours: _hours,
      minutes: _minutes,
      seconds: _seconds,
    );

    if (duration < widget.minDuration) {
      duration = widget.minDuration;
      _hours = duration.inHours;
      _minutes = duration.inMinutes.remainder(60);
      _seconds = duration.inSeconds.remainder(60);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _hoursController.jumpToItem(_hours);
        _minutesController.jumpToItem(_minutes);
        _secondsController.jumpToItem(_seconds);
      });
    } else if (duration > widget.maxDuration) {
      duration = widget.maxDuration;
      _hours = duration.inHours;
      _minutes = duration.inMinutes.remainder(60);
      _seconds = duration.inSeconds.remainder(60);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _hoursController.jumpToItem(_hours);
        _minutesController.jumpToItem(_minutes);
        _secondsController.jumpToItem(_seconds);
      });
    }

    widget.onChanged(duration);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 8),
        Container(
          height: 150,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Stack(
            children: [
              Center(
                child: Container(
                  height: 40,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.showHours) ...[
                    _WheelPicker(
                      controller: _hoursController,
                      maxValue: 23,
                      label: 'h',
                      onChanged: (value) {
                        setState(() => _hours = value);
                        _updateDuration();
                      },
                    ),
                    const _Separator(),
                  ],
                  _WheelPicker(
                    controller: _minutesController,
                    maxValue: 59,
                    label: 'm',
                    onChanged: (value) {
                      setState(() => _minutes = value);
                      _updateDuration();
                    },
                  ),
                  const _Separator(),
                  _WheelPicker(
                    controller: _secondsController,
                    maxValue: 59,
                    label: 's',
                    onChanged: (value) {
                      setState(() => _seconds = value);
                      _updateDuration();
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WheelPicker extends StatelessWidget {
  final FixedExtentScrollController controller;
  final int maxValue;
  final ValueChanged<int> onChanged;
  final String label;

  const _WheelPicker({
    required this.controller,
    required this.maxValue,
    required this.onChanged,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 50,
          child: ListWheelScrollView.useDelegate(
            controller: controller,
            itemExtent: 40,
            perspective: 0.005,
            diameterRatio: 1.2,
            physics: const FixedExtentScrollPhysics(),
            onSelectedItemChanged: onChanged,
            childDelegate: ListWheelChildBuilderDelegate(
              childCount: maxValue + 1,
              builder: (context, index) {
                return Center(
                  child: Text(
                    index.toString().padLeft(2, '0'),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _Separator extends StatelessWidget {
  const _Separator();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        ':',
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}
