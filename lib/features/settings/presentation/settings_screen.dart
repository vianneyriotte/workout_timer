import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/services/audio_service.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioService = ref.watch(audioServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        children: [
          _SettingsSection(
            title: 'Audio',
            children: [
              SwitchListTile(
                title: const Text('Sound Effects'),
                subtitle: const Text('Play beeps during workouts'),
                value: audioService.enabled,
                onChanged: (value) {
                  audioService.enabled = value;
                },
                activeColor: AppColors.primary,
              ),
              ListTile(
                title: const Text('Test Sound'),
                subtitle: const Text('Tap to play a test beep'),
                trailing: const Icon(Icons.volume_up),
                onTap: () => audioService.playStartBeep(),
              ),
            ],
          ),
          _SettingsSection(
            title: 'About',
            children: [
              const ListTile(
                title: Text('Version'),
                subtitle: Text('1.0.0'),
              ),
              ListTile(
                title: const Text('About Workout Timer'),
                subtitle: const Text('A workout timer inspired by SmartWOD'),
                trailing: const Icon(Icons.info_outline),
                onTap: () => _showAboutDialog(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Workout Timer',
      applicationVersion: '1.0.0',
      applicationIcon: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(
          Icons.timer,
          color: AppColors.background,
          size: 32,
        ),
      ),
      children: [
        const Text(
          'A workout timer app for functional fitness, CrossFit, and HIIT training.',
        ),
        const SizedBox(height: 8),
        const Text(
          'Supports AMRAP, FOR TIME, EMOM, TABATA, and custom mixed workouts.',
        ),
      ],
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(
            title.toUpperCase(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
          ),
        ),
        ...children,
      ],
    );
  }
}
