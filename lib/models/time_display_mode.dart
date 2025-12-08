/// Enum representing the different time display modes for project totals
enum TimeDisplayMode {
  instance,
  day,
  week,
  month,
  project;

  String get label {
    switch (this) {
      case TimeDisplayMode.instance:
        return 'Instance';
      case TimeDisplayMode.day:
        return 'Day';
      case TimeDisplayMode.week:
        return 'Week';
      case TimeDisplayMode.month:
        return 'Month';
      case TimeDisplayMode.project:
        return 'Project';
    }
  }

  String get description {
    switch (this) {
      case TimeDisplayMode.instance:
        return 'Current instance duration';
      case TimeDisplayMode.day:
        return 'Total time today';
      case TimeDisplayMode.week:
        return 'Total time this week';
      case TimeDisplayMode.month:
        return 'Total time this month';
      case TimeDisplayMode.project:
        return 'Complete project total';
    }
  }
}
