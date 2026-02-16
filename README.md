# HabitBee - Habit Tracker App

An offline-first Habit Tracker application built with Flutter, featuring a Material 3 Expressive UI with a unique honeycomb design theme.

## Features

### Core Features
- **Create and Manage Habits**: Add habits with customizable names, categories, colors, and icons
- **Daily Tracking**: Mark habits as complete for any date
- **Date Strip Navigation**: View habits for different days with a honeycomb-style date picker
- **Reminders**: Set daily reminders with custom times and repeat schedules
- **Analytics**: Track your progress with beautiful charts and statistics
- **Offline-First**: All data stored locally using Hive database
- **Dark Mode**: Support for both light and dark themes

### Screens
1. **Splash Screen**: Animated app introduction
2. **Home Screen**: View today's habits with date navigation
3. **Add/Edit Habit**: Create or modify habits with full customization
4. **Analytics**: View completion statistics and charts
5. **Progress Screen**: Coming soon placeholder
6. **Settings**: Theme toggle, data export/import, app info

## Technical Stack

- **Framework**: Flutter 3.x
- **State Management**: Provider
- **Local Database**: Hive (with Hive Flutter)
- **UI Design**: Material 3 Expressive
- **Charts**: FL Chart
- **Notifications**: flutter_local_notifications
- **Icons**: Material Design Icons + Custom icons

## Project Structure

```
lib/
├── main.dart                          # App entry point
├── src/
│   ├── app.dart                       # Main app widget
│   ├── core/
│   │   ├── constants/                 # App constants
│   │   ├── services/                  # Notification service
│   │   ├── theme/
│   │   │   └── app_theme.dart         # Light/Dark themes
│   │   └── utils/                     # Utility functions
│   ├── data/
│   │   ├── models/                    # Data models (Habit, HabitCompletion, AppSettings)
│   │   ├── repositories/              # Data access layer
│   │   └── services/                  # Storage service (Hive)
│   └── features/
│       ├── add_habit/                 # Add/Edit habit feature
│       ├── analytics/                 # Analytics feature
│       ├── home/                      # Home screen with widgets
│       ├── navigation/                # Bottom navigation
│       ├── progress/                  # Progress screen (WIP)
│       ├── settings/                  # Settings screen
│       └── splash/                    # Splash screen
```

## Installation

1. Clone the repository
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Generate Hive adapters:
   ```bash
   flutter pub run build_runner build
   ```
4. Generate app icons:
   ```bash
   flutter pub run flutter_launcher_icons
   ```
5. Run the app:
   ```bash
   flutter run
   ```

## Build

### Android
```bash
flutter build apk --release
```

### iOS
```bash
flutter build ios --release
```

## Design System

### Color Palette
- **Primary**: Golden Yellow (#FFC107)
- **Secondary**: Dark Yellow (#FFA000)
- **Background Light**: Off White (#F5F5F5)
- **Background Dark**: Near Black (#1A1A1A)
- **Habit Colors**: 10 soft pastel colors for habit customization

### Typography
- **Font Family**: Poppins (Google Fonts)
- **Style**: Material 3 Expressive with rounded corners

## License

This project is for educational purposes.

## Credits

Built with Flutter and Material Design 3.
