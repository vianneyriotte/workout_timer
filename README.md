# Workout Timer

A Flutter workout timer app inspired by SmartWOD Timer. Supports multiple timer types for functional fitness, CrossFit, and HIIT training.

## Features

### Timer Types
- **AMRAP** - As Many Rounds As Possible with countdown timer
- **FOR TIME** - Stopwatch mode with optional time cap
- **EMOM** - Every Minute On the Minute with customizable intervals
- **TABATA** - High Intensity Interval Training with work/rest periods
- **REST** - Rest periods between segments

### Key Features
- Mix different timer types in a single workout
- Loop segments and groups multiple times
- Save and load workout presets
- Large, clear timer display
- Landscape mode support
- Audio beeps for transitions
- Screen wake lock during workouts
- Round counter for AMRAP

## Getting Started

### Prerequisites
- Flutter SDK 3.2.0 or higher
- Dart 3.0 or higher

### Installation

1. Clone the repository
```bash
git clone <repository-url>
cd workout_timer
```

2. Install dependencies
```bash
flutter pub get
```

3. Run the app
```bash
flutter run
```

### Building

```bash
# Android
flutter build apk

# iOS
flutter build ios
```

## Project Structure

```
lib/
├── main.dart
├── app.dart
├── core/
│   ├── router/         # Navigation
│   ├── theme/          # App theme and colors
│   └── constants/      # App constants
├── features/
│   ├── home/           # Home screen
│   ├── timer_selection/ # Timer configuration
│   ├── workout_builder/ # Custom workout builder
│   ├── timer/          # Timer execution
│   ├── presets/        # Saved workouts
│   └── settings/       # App settings
└── shared/
    ├── widgets/        # Reusable widgets
    ├── utils/          # Utilities
    └── services/       # Services (audio, etc.)
```

## Architecture

- **State Management**: Riverpod
- **Navigation**: GoRouter
- **Storage**: SharedPreferences
- **Audio**: audioplayers

## Usage

### Creating a Simple Timer
1. Open the app
2. Select a timer type (AMRAP, FOR TIME, EMOM, or TABATA)
3. Configure the duration and settings
4. Tap "Start" to begin

### Creating a Custom Workout
1. Tap "Custom Workout" on the home screen
2. Add segments using the "Add Segment" button
3. Configure each segment's type and duration
4. Optionally group segments and set loop counts
5. Tap "Start Workout" to begin

### Saving Workouts
- From the timer config screen: Tap "Save" and enter a name
- From the workout builder: Tap "Save" to save the current workout
- Access saved workouts from the home screen or "Saved Workouts"

## Audio Files

Add a `beep.mp3` file to `assets/audio/` for custom beep sounds. If not present, the app will use system sounds.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is open source and available under the MIT License.
