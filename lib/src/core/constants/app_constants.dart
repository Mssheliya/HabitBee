class AppConstants {
  static const String appName = 'HabitBee';
  static const String appVersion = '1.0.0';
  
  // Hive Boxes
  static const String habitsBox = 'habits_box';
  static const String settingsBox = 'settings_box';
  static const String completionsBox = 'completions_box';
  
  // Categories
  static const List<String> habitCategories = [
    'Health',
    'Fitness',
    'Productivity',
    'Learning',
    'Mindfulness',
    'Social',
    'Creativity',
    'Finance',
    'Reading',
    'Writing',
    'Other',
  ];
  
  // Icons (Material Icons names)
  static const List<String> habitIcons = [
    'fitness_center',
    'directions_run',
    'self_improvement',
    'menu_book',
    'water_drop',
    'bedtime',
    'restaurant',
    'savings',
    'work',
    'palette',
    'music_note',
    'code',
    'nature',
    'chat',
    'local_florist',
    'wb_sunny',
    'nights_stay',
    'favorite',
    'star',
    'emoji_events',
  ];
  
  // Notification
  static const String notificationChannelId = 'habit_reminders';
  static const String notificationChannelName = 'Habit Reminders';
  static const String notificationChannelDescription = 'Reminders for your daily habits';
}
