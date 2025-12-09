class AppConstants {
  static const String appName = 'Workout Timer';
  static const String appVersion = '1.0.0';

  static const Duration defaultCountdown = Duration(seconds: 10);
  static const Duration defaultAmrapDuration = Duration(minutes: 10);
  static const Duration defaultForTimeCap = Duration(minutes: 20);
  static const Duration defaultEmomDuration = Duration(minutes: 10);
  static const Duration defaultEmomInterval = Duration(minutes: 1);
  static const Duration defaultTabataWork = Duration(seconds: 20);
  static const Duration defaultTabataRest = Duration(seconds: 10);
  static const int defaultTabataRounds = 8;
  static const Duration defaultRestDuration = Duration(minutes: 2);

  static const int minDurationSeconds = 5;
  static const int maxDurationHours = 2;
  static const int maxRounds = 50;
}
