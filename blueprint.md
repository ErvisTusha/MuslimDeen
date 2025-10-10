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
- **Persistence**: Immediate save to SharedPreferences (no debouncing)
- **Decision**: Changed from 750ms debounced save to immediate persistence to prevent data loss on app close
- **Data Flow**:
  ```
  UI Change → SettingsNotifier.updateX() → _saveSettings() → SharedPreferences
  App Start → SettingsNotifier.build() → _loadSettings() → State Update → UI Rebuild
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
    G --> H[_loadSettings()]
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
*Document reflects current implementation after settings persistence, notification service fixes, and permission implementation*</content>
<parameter name="filePath">/home/et/Desktop/MuslimDeen/blueprint.md