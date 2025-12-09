import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../timer/domain/models/models.dart';

const _presetsKey = 'workout_presets';

class PresetsNotifier extends StateNotifier<List<Workout>> {
  PresetsNotifier() : super([]) {
    _loadPresets();
  }

  Future<void> _loadPresets() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_presetsKey);
    if (data != null) {
      try {
        final list = jsonDecode(data) as List;
        state = list
            .map((item) => Workout.fromJson(item as Map<String, dynamic>))
            .toList();
      } catch (e) {
        state = [];
      }
    }
  }

  Future<void> _savePresets() async {
    final prefs = await SharedPreferences.getInstance();
    final data = jsonEncode(state.map((w) => w.toJson()).toList());
    await prefs.setString(_presetsKey, data);
  }

  void addPreset(Workout workout) {
    state = [...state, workout];
    _savePresets();
  }

  void updatePreset(Workout workout) {
    state = [
      for (final w in state)
        if (w.id == workout.id) workout else w,
    ];
    _savePresets();
  }

  void removePreset(String id) {
    state = state.where((w) => w.id != id).toList();
    _savePresets();
  }

  void reorderPresets(int oldIndex, int newIndex) {
    final preset = state.removeAt(oldIndex);
    state.insert(newIndex, preset);
    state = [...state];
    _savePresets();
  }
}

final presetsProvider =
    StateNotifierProvider<PresetsNotifier, List<Workout>>((ref) {
  return PresetsNotifier();
});
