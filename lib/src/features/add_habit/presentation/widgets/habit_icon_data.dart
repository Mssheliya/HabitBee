import 'package:flutter/material.dart';

/// A single selectable habit icon entry (string key + outlined Material icon).
class HabitIconOption {
  final String name;
  final IconData icon;

  const HabitIconOption(this.name, this.icon);
}

/// Habit-related icons using Flutter's built-in outlined Material icons.
/// Old string keys are preserved for backward compatibility with saved habits.
const List<HabitIconOption> habitIconOptions = [
  HabitIconOption('directions_run', Icons.directions_run_outlined),
  HabitIconOption('fitness_center', Icons.fitness_center_outlined),
  HabitIconOption('directions_walk', Icons.directions_walk_outlined),
  HabitIconOption('water_drop', Icons.water_drop_outlined),
  HabitIconOption('local_drink', Icons.local_drink_outlined),
  HabitIconOption('menu_book', Icons.menu_book_outlined),
  HabitIconOption('auto_stories', Icons.auto_stories_outlined),
  HabitIconOption('self_improvement', Icons.self_improvement_outlined),
  HabitIconOption('psychology', Icons.psychology_outlined),
  HabitIconOption('spa', Icons.spa_outlined),
  HabitIconOption('bedtime', Icons.bedtime_outlined),
  HabitIconOption('nights_stay', Icons.nights_stay_outlined),
  HabitIconOption('wb_sunny', Icons.wb_sunny_outlined),
  HabitIconOption('restaurant', Icons.restaurant_outlined),
  HabitIconOption('local_cafe', Icons.local_cafe_outlined),
  HabitIconOption('brush', Icons.brush_outlined),
  HabitIconOption('palette', Icons.palette_outlined),
  HabitIconOption('code', Icons.code_outlined),
  HabitIconOption('laptop_mac', Icons.laptop_mac_outlined),
  HabitIconOption('music_note', Icons.music_note_outlined),
  HabitIconOption('headphones', Icons.headphones_outlined),
  HabitIconOption('favorite', Icons.favorite_outline),
  HabitIconOption('local_fire_department', Icons.local_fire_department_outlined),
  HabitIconOption('alarm', Icons.alarm_outlined),
  HabitIconOption('savings', Icons.savings_outlined),
  HabitIconOption('work', Icons.work_outline),
  HabitIconOption('nature', Icons.nature_outlined),
  HabitIconOption('local_florist', Icons.local_florist_outlined),
  HabitIconOption('chat', Icons.chat_bubble_outline),
  HabitIconOption('star', Icons.star_outline),
  HabitIconOption('emoji_events', Icons.emoji_events_outlined),
  HabitIconOption('edit_note', Icons.edit_note_outlined),
  // Food & Drink
  HabitIconOption('icecream', Icons.icecream_outlined),
  HabitIconOption('breakfast_dining', Icons.breakfast_dining_outlined),
  HabitIconOption('lunch_dining', Icons.lunch_dining_outlined),
  HabitIconOption('dinner_dining', Icons.dinner_dining_outlined),
  HabitIconOption('bakery_dining', Icons.bakery_dining_outlined),
  HabitIconOption('local_bar', Icons.local_bar_outlined),
  HabitIconOption('wine_bar', Icons.wine_bar_outlined),
  HabitIconOption('groceries', Icons.local_grocery_store_outlined),
  // Health & Hygiene
  HabitIconOption('monitor_heart', Icons.monitor_heart_outlined),
  HabitIconOption('medical_mask', Icons.masks_outlined),
  HabitIconOption('shower', Icons.shower_outlined),
  HabitIconOption('cleaning', Icons.cleaning_services_outlined),
  HabitIconOption('volunteer', Icons.volunteer_activism_outlined),
  // Sports & Fitness
  HabitIconOption('sports_soccer', Icons.sports_soccer_outlined),
  HabitIconOption('sports_basketball', Icons.sports_basketball_outlined),
  HabitIconOption('sports_tennis', Icons.sports_tennis_outlined),
  HabitIconOption('sports_cricket', Icons.sports_cricket_outlined),
  HabitIconOption('esports', Icons.sports_esports_outlined),
  HabitIconOption('cycling', Icons.directions_bike_outlined),
  HabitIconOption('hiking', Icons.hiking_outlined),
  HabitIconOption('snowboard', Icons.air_outlined),
  // Learning & Work
  HabitIconOption('school', Icons.school_outlined),
  HabitIconOption('library_books', Icons.library_books_outlined),
  HabitIconOption('translate', Icons.translate_outlined),
  HabitIconOption('language', Icons.public_outlined),
  HabitIconOption('calculate', Icons.calculate_outlined),
  HabitIconOption('play_lesson', Icons.play_lesson_outlined),
  // Money & Finance
  HabitIconOption('payments', Icons.payments_outlined),
  HabitIconOption('shopping', Icons.shopping_cart_outlined),
  HabitIconOption('bank', Icons.account_balance_outlined),
  HabitIconOption('query_stats', Icons.query_stats_outlined),
  // Screen & Social
  HabitIconOption('smartphone', Icons.phone_android_outlined),
  HabitIconOption('email', Icons.mail_outline),
  HabitIconOption('forum', Icons.forum_outlined),
  HabitIconOption('group', Icons.groups_outlined),
  HabitIconOption('tv_time', Icons.tv_outlined),
  HabitIconOption('videocam', Icons.videocam_outlined),
  HabitIconOption('gift', Icons.card_giftcard_outlined),
  // Travel & Outdoors
  HabitIconOption('driving', Icons.directions_car_outlined),
  HabitIconOption('travel', Icons.flight_outlined),
  HabitIconOption('park', Icons.park_outlined),
  HabitIconOption('beach', Icons.beach_access_outlined),
  HabitIconOption('pets', Icons.pets_outlined),
  HabitIconOption('deck', Icons.deck_outlined),
  // Mind & Sleep
  HabitIconOption('meditation', Icons.psychology_alt_outlined),
  HabitIconOption('gratitude', Icons.favorite_rounded),
  HabitIconOption('journal', Icons.book_outlined),
];

/// Resolve a saved icon string key to an [IconData].
IconData habitIconData(String iconName) {
  for (final option in habitIconOptions) {
    if (option.name == iconName) return option.icon;
  }
  return Icons.star_outline;
}
