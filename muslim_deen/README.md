# Muslim Deen

A comprehensive Islamic app providing essential tools for Muslims.

## Features

- 🕌 Prayer times calculation based on your location
- 🧭 Qibla direction finder with compass
- 📿 Digital tasbih (prayer beads) counter
- 🔍 Nearby mosque finder
- 📅 Hijri date converter
- 🌙 Multiple calculation methods support
- 🔔 Prayer time notifications
- 🌐 Multilingual support (English, Arabic, Turkish, Albanian, French)
- 🎨 Light/Dark/System theme modes

## Architecture

This app follows a clean architecture pattern with clear separation of concerns:

```
┌─────────────────────────────────────────────────────────────┐
│                         UI Layer                            │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │   Views     │  │   Widgets   │  │   Navigation        │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────────────┐
│                    Business Logic Layer                     │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │  Providers  │  │   Models    │  │   State Management  │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────────────┐
│                      Service Layer                          │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │  Services   │  │   Storage   │  │   External APIs     │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

### Key Architectural Patterns
- **Service Locator Pattern**: Centralized dependency injection using GetIt
- **Provider Pattern**: Reactive state management with Riverpod
- **Repository Pattern**: Data access abstraction for storage and APIs
- **Observer Pattern**: Notification and event handling

## Technical Details

Built with Flutter using:
- Riverpod for state management
- GetIt for service location
- Adhan library for prayer time calculations (Muslim World League)
- Geolocator for location services
- Flutter Compass for qibla direction

### Core Components
- **PrayerService**: Handles prayer time calculations with multi-layer caching
- **LocationService**: GPS location tracking with intelligent fallbacks
- **NotificationService**: Prayer time notifications with proper scheduling
- **DatabaseService**: Local data persistence with SQLite
- **LoggerService**: Centralized logging system

### Performance Optimizations
- Multi-layer caching strategy with precomputation
- Request deduplication to prevent redundant API calls
- Lazy loading of UI components
- Intelligent location caching with movement pattern analysis

## Documentation

For detailed information about the codebase, architecture, and development guidelines:

- [📚 Documentation Index](DOCUMENTATION_INDEX.md) - Comprehensive codebase overview
- [🤝 Contributing Guidelines](CONTRIBUTING.md) - Development standards and practices

## Getting Started

To run this project:

1. Ensure Flutter (3.7.2+) is installed
2. Clone the repository
3. Run `flutter pub get`
4. Run `flutter run -d android` or `flutter run -d ios`

**Important**: This app supports Android and iOS only. Web platform is not supported due to native service dependencies.

## Platform Support

- ✅ Android
- ✅ iOS
- ❌ Web (not supported)

## License

This project is licensed under the MIT License - see the LICENSE file for details.
