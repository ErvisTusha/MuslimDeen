# Blueprint: Muslim Deen App

## Current Architecture Overview

### Tech Stack
- **Framework**: Flutter (Dart)
- **State Management**: Riverpod (NotifierProvider for settings, StateNotifier for complex state)
- **Local Storage**: SharedPreferences (for app settings)
- **Notifications**: flutter_local_notifications
- **Prayer Calculations**: adhan_dart package
- **Location Services**: geolocator, geocoding
- **Compass**: flutter_compass
- **Dependency Injection**: GetIt (service locator pattern)

### Core Components

#### 1. Settings Management
- **Provider**: `settingsProvider` (NotifierProvider<SettingsNotifier, AppSettings>)
- **Persistence**: Debounced save to SharedPreferences (750ms) for most changes, immediate save for critical updates
- **Decision**: Uses debounced saving to balance performance with data safety
- **Data Flow**:
  ```
  UI Change → SettingsNotifier.updateX() → _forceSaveSettings() → SharedPreferences
  App Start → SettingsNotifier.build() → _initializeSettings() → State Update → UI Rebuild
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
    E --> F[SharedPreferences.setString()]
    F --> G[UI reflects change]
```

#### App Initialization
```mermaid
flowchart TD
    A[main()] --> B[setupLocator()]
    B --> C[Initialize SharedPreferences]
    C --> D[Register services with GetIt]
    D --> E[runApp()]
    E --> F[ProviderScope]
    F --> G[SettingsNotifier.build()]
    G --> H[_initializeSettings()]
    H --> I[State = loaded settings]
    I --> J[MaterialApp with themeMode from state]
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

#### 7. Tasbih Vibration Enhancement (October 2025)
- **Problem**: Tasbih counter vibration feedback failed on certain devices due to inconsistent HapticFeedback support across platforms.
- **Solution**: Integrated vibration package for robust device vibration detection and control, with HapticFeedback as fallback.
- **Impact**: Improved vibration reliability across Android and iOS devices, ensuring consistent haptic feedback when counting dhikr.
- **Files Changed**: `lib/views/tesbih_view.dart`, `pubspec.yaml`

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

*Last Updated: October 10, 2025*
*Document reflects current implementation after settings persistence, notification service fixes, permission implementation, and prayer/tesbih notification separation*
