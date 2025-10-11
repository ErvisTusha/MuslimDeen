# Blueprint: Muslim Deen App

## Current Architecture Overview

### Tech Stack
- **Framework**: Flutter (Dart)
- **State Management**: Riverpod (NotifierProvider for settings, StateNotifier for complex state)
- **Local Storage**: SQLite database (sqflite) for structured data persistence
- **Notifications**: flutter_local_notifications
- **Prayer Calculations**: adhan_dart package
- **Location Services**: geolocator, geocoding
- **Compass**: flutter_compass
- **Dependency Injection**: GetIt (service locator pattern)

### Core Components

#### 1. Settings Management
- **Provider**: `settingsProvider` (NotifierProvider<SettingsNotifier, AppSettings>)
- **Persistence**: SQLite database with key-value table, automatic migration from SharedPreferences
- **Decision**: Database provides better structure, query capabilities, and future sync preparation
- **Data Flow**:
  ```
  UI Change → SettingsNotifier.updateX() → _saveSettings() → DatabaseService.saveSettings()
  App Start → SettingsNotifier.build() → _initializeSettings() → DatabaseService.getSettings() → State Update → UI Rebuild
  Migration: First launch → Check database → If empty → Migrate from SharedPreferences → Save to database
  ```

#### 2. Notification Service
- **Implementation**: Core functionality with proper permission handling
- **Features**: Prayer time notifications, Tesbih reminders
- **Storage**: Uses timezone package for scheduling
- **Permissions**: Uses permission_handler for cross-platform permission requests

#### 3. Service Locator Pattern
- **Library**: GetIt
- **Services**: LoggerService, StorageService, NotificationService, PrayerService, etc.
- **Initialization**: Async initialization in `setupLocator()` called before `runApp()`

### Data Flow

#### Settings Persistence
```mermaid
flowchart TD
    A[User changes setting] --> B[UI calls notifier.updateX()]
    B --> C[State updated immediately]
    C --> D[_saveSettings() called]
    D --> E[JSON encode state]
    E --> F[DatabaseService.saveSettings()]
    F --> G[SQLite INSERT/UPDATE]
    G --> H[UI reflects change]
```

#### Data Migration
```mermaid
flowchart TD
    A[App Launch] --> B[SettingsNotifier._initializeSettings()]
    B --> C[Try DatabaseService.getSettings()]
    C --> D{Settings exist?}
    D -->|Yes| E[Load from database]
    D -->|No| F[Try SharedPreferences.getString()]
    F --> G{Legacy data?}
    G -->|Yes| H[Load legacy data]
    H --> I[DatabaseService.saveSettings()]
    I --> J[Delete legacy SharedPreferences]
    G -->|No| K[Use AppSettings.defaults]
    E --> L[State = loaded settings]
    H --> L
    K --> L
```

#### App Initialization
```mermaid
flowchart TD
    A[main()] --> B[setupLocator()]
    B --> C[Initialize DatabaseService]
    C --> D[Create SQLite tables if needed]
    D --> E[Register services with GetIt]
    E --> F[runApp()]
    F --> G[ProviderScope]
    G --> H[SettingsNotifier.build()]
    H --> I[_initializeSettings()]
    I --> J[DatabaseService.getSettings()]
    J --> K{Settings exist?}
    K -->|Yes| L[Load from database]
    K -->|No| M[Migrate from SharedPreferences]
    L --> N[State = loaded settings]
    M --> N
    N --> O[MaterialApp with themeMode from state]
```

### Recent Architectural Decisions

#### 1. Settings Persistence Strategy (October 2025)
- **Problem**: Settings not persisting on app close due to 750ms debounce timer
- **Solution**: Immediate save for all setting changes
- **Impact**: Prevents data loss, slightly increases I/O but acceptable for settings
- **Files Changed**: `lib/providers/settings_notifier.dart`

#### 2. NotificationService Simplification (October 2025)
- **Problem**: Complex NotificationService with compilation errors and missing implementations
- **Solution**: Simplified stub implementation with core required methods
- **Impact**: App compiles and runs, notifications work with basic functionality
- **Files Changed**: `lib/services/notification_service.dart`

#### 3. Notification Permission Implementation (October 2025)
- **Problem**: Notification permission request was stubbed out, always returning granted
- **Solution**: Implemented proper permission request using permission_handler package
- **Impact**: Cross-platform permission handling with proper status mapping
- **Files Changed**: `lib/services/notification_service.dart`

#### 4. Prayer vs Tesbih Notification Separation (October 2025)
- **Problem**: Rescheduling prayer (azan) notifications cancelled the tesbih reminder, causing dhikr alerts to disappear unexpectedly.
- **Solution**: Added a dedicated `cancelPrayerNotifications` helper and updated all prayer scheduling flows to rely on it instead of the global cancel.
- **Impact**: Prayer notifications can be refreshed without touching the tasbih reminder, ensuring dhikr alerts remain consistent.
- **Files Changed**: `lib/services/notification_service.dart`, `lib/views/home_view.dart`, `lib/providers/settings_notifier.dart`, `lib/services/notification_rescheduler_service.dart`

#### 5. Prayer Notification Custom Sound (October 2025)
- **Problem**: Azan notifications always played the default system tone, ignoring the sound selected in Settings.
- **Solution**: Extended the notification service to map scheduled prayers to the chosen azan audio and configure notification channels with that sound.
- **Impact**: Dhuhr, Asr, Maghrib, and Isha notifications now honour the user's selected azan, aligning alerts with in-app previews.
- **Files Changed**: `lib/services/notification_service.dart`

#### 6. Notification System Mode Compliance (October 2025)
- **Problem**: Prayer and tesbih alerts risked overriding a user's silent/vibrate preference by using alarm-focused audio attributes.
- **Solution**: Updated Android notification channel configuration to rely on standard notification audio attributes and vibration defaults so the OS enforces silent/vibrate behaviour.
- **Impact**: Both azan and tesbih reminders now follow the device sound profile—vibrating on vibrate mode and remaining quiet when muted.
- **Files Changed**: `lib/services/notification_service.dart`

#### 7. Local Database Implementation (October 2025)
- **Problem**: SharedPreferences limitations for complex data relationships, query capabilities, and future Google Drive sync preparation.
- **Solution**: Implemented comprehensive SQLite database with structured tables for settings, prayer history, tasbih history, and user location data.
- **Impact**: Better data persistence, complex queries support, backward compatibility with automatic migration from SharedPreferences.
- **Database Schema**:
  - `settings` table: key-value storage for app settings
  - `prayer_history` table: date-based prayer completion tracking
  - `tasbih_history` table: date and dhikr-type based counting with statistics
  - `user_location` table: GPS coordinates with names for location history
- **Migration Strategy**: Automatic migration from SharedPreferences to database on first app launch
- **Files Changed**: `lib/services/database_service.dart`, `lib/providers/settings_notifier.dart`, `lib/services/prayer_history_service.dart`, `lib/services/tasbih_history_service.dart`, `lib/providers/service_providers.dart`, `pubspec.yaml`

#### 7. Tasbih Vibration Enhancement (October 2025)
- **Problem**: Tasbih counter vibration feedback failed on certain devices due to inconsistent HapticFeedback support across platforms.
- **Solution**: Integrated vibration package for robust device vibration detection and control, with HapticFeedback as fallback.
- **Impact**: Improved vibration reliability across Android and iOS devices, ensuring consistent haptic feedback when counting dhikr.
- **Files Changed**: `lib/views/tesbih_view.dart`, `pubspec.yaml`

#### 8. Code Quality & Error Handling Improvements (October 2025)
- **Problem**: Hardcoded log levels, missing error boundaries, potential memory leaks, inconsistent navigation
- **Solution**: 
  - Made logger level environment-based (debug vs production)
  - Added comprehensive error handling in mosque_view with clipboard fallback
  - Enhanced audio player disposal with try-catch blocks
  - Created centralized NavigationService for consistent routing
- **Impact**: More robust error handling, better resource management, improved debugging experience
- **Files Changed**: `lib/services/logger_service.dart`, `lib/views/mosque_view.dart`, `lib/views/tesbih_view.dart`, `lib/services/navigation_service.dart`

#### 9. Prayer History & Statistics Feature (October 2025)
- **Problem**: No way to track prayer completion or view spiritual progress
- **Solution**: 
  - Created PrayerHistoryService with local storage for prayer tracking
  - Built PrayerStatsView showing weekly/monthly stats, completion rates, and streaks
  - Added methods for marking prayers complete/incomplete
- **Impact**: Users can now track their prayer consistency and see motivating statistics
- **Files Changed**: `lib/services/prayer_history_service.dart`, `lib/views/prayer_stats_view.dart`, `lib/services/storage_service.dart`

#### 10. Dhikr Reminders Feature (October 2025)
- **Problem**: No automated reminders to encourage dhikr throughout the day
- **Solution**: 
  - Extended AppSettings with dhikrRemindersEnabled and dhikrReminderInterval fields
  - Created DhikrReminderService to schedule periodic notifications
  - Leverages existing notification infrastructure
- **Impact**: Users receive gentle reminders to engage in dhikr at customizable intervals
- **Files Changed**: `lib/models/app_settings.dart`, `lib/services/dhikr_reminder_service.dart`

#### 11. Ramadan Last 10 Nights Banner (October 2025)
- **Problem**: No special UI to highlight the blessed last 10 nights of Ramadan
- **Solution**: 
  - Created RamadanCountdownBanner widget using Hijri calendar
  - Automatically displays during Ramadan days 21-30
  - Shows countdown and highlights odd nights (potential Laylat al-Qadr)
- **Impact**: Spiritually meaningful feature that appears automatically during the holiest nights
- **Files Changed**: `lib/widgets/ramadan_countdown_banner.dart`

### Core Services (Updated October 2025)

#### Navigation Service
- **Purpose**: Centralized navigation management
- **Pattern**: Singleton with GlobalKey<NavigatorState>
- **Features**: Push, pop, replace, and complex navigation flows with logging

#### Prayer History Service
- **Purpose**: Track prayer completion and generate statistics
- **Storage**: SharedPreferences with date-keyed entries
- **Features**: Mark prayers complete, weekly/monthly stats, streak calculation, completion rate
- **Data Retention**: 90 days of history

#### Dhikr Reminder Service
- **Purpose**: Schedule periodic dhikr reminder notifications
- **Integration**: Uses NotificationService for scheduling
- **Features**: Configurable intervals, automatic cycling through dhikr types
- **Notification IDs**: 2000-2009 (base 2000, max 10 reminders)

### Key Design Patterns

#### 1. Provider Pattern for State Management
- Riverpod providers for reactive state updates
- Notifier pattern for complex state logic
- Consumer widgets for UI updates

#### 2. Service Layer Pattern
- Business logic separated from UI
- Dependency injection via service locator
- Async initialization for proper startup sequence

#### 3. Repository Pattern (Planned)
- Currently direct service usage
- Future: Repository layer for data abstraction

### System Interactions

#### External Dependencies
- **SharedPreferences**: Local key-value storage
- **flutter_local_notifications**: System notification scheduling
- **timezone**: Time zone handling for notifications
- **adhan_dart**: Islamic prayer time calculations

#### Internal Data Flow
- Settings changes trigger immediate persistence
- Location services provide coordinates for prayer calculations
- Notification service schedules based on prayer times
- UI rebuilds reactively to state changes

### Future Considerations

#### Immediate Next Steps
- Integrate prayer tracking UI into prayer_view.dart (checkboxes for marking prayers complete)
- Add dhikr reminder settings UI in settings_view.dart (toggle and interval selector)
- Integrate RamadanCountdownBanner into home_view.dart
- Add navigation to prayer stats from home screen

#### Performance Optimizations
- Consider caching prayer times to reduce calculations
- Implement background location updates for better accuracy
- Add offline prayer time storage

#### Feature Extensions
- Add more notification customization options
- Implement prayer time adjustments per user preference
- Add mosque finder with real API integration

#### Code Quality
- Add comprehensive unit tests
- Implement error boundaries for better error handling
- Add analytics for user behavior tracking

---

*Last Updated: October 11, 2025*
*Document reflects current implementation including prayer history tracking, dhikr reminders, Ramadan countdown, improved error handling, and centralized navigation*
