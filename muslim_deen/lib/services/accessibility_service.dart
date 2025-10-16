import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter/services.dart';
import 'package:muslim_deen/service_locator.dart';
import 'package:muslim_deen/services/logger_service.dart';
import 'package:muslim_deen/services/navigation_service.dart';
import 'package:muslim_deen/views/home_view.dart';
import 'package:muslim_deen/views/qibla_view.dart';
import 'package:muslim_deen/views/tesbih_view.dart';
import 'package:muslim_deen/views/mosque_view.dart';
import 'package:muslim_deen/views/settings_view.dart';

/// Enhanced accessibility service for MuslimDeen app
/// 
/// This service provides comprehensive accessibility features including screen reader
/// support, voice commands, haptic feedback, and cognitive assistance. It's designed
/// to make the MuslimDeen app accessible to users with visual impairments, motor
/// disabilities, and other accessibility needs.
/// 
/// Features:
/// - Text-to-speech with enhanced Islamic term pronunciation
/// - Voice command navigation for hands-free operation
/// - Haptic feedback with customizable intensity
/// - Screen change announcements for blind users
/// - Prayer time announcements with context
/// - Accessible UI components with semantic labels
/// - Voice navigation through app screens
/// 
/// Usage:
/// ```dart
/// final accessibility = AccessibilityService();
/// await accessibility.initialize();
/// await accessibility.speak('Welcome to MuslimDeen');
/// await accessibility.startListening();
/// ```
/// 
/// Design Patterns:
/// - Singleton: Ensures consistent accessibility settings
/// - Strategy Pattern: Different feedback strategies for different needs
/// - Observer Pattern: Reacts to app lifecycle changes
/// - Command Pattern: Encapsulates voice commands as executable actions
/// 
/// Performance Considerations:
/// - Efficient speech synthesis with caching
/// - Optimized haptic feedback patterns
/// - Lazy initialization of speech recognition
/// - Minimal resource usage
/// 
/// Dependencies:
/// - flutter_tts: For text-to-speech functionality
/// - speech_to_text: For voice command recognition
/// - LoggerService: For centralized logging
/// - NavigationService: For voice-controlled navigation
class AccessibilityService {
  static final AccessibilityService _instance =
      AccessibilityService._internal();
  factory AccessibilityService() => _instance;
  AccessibilityService._internal();

  final FlutterTts _tts = FlutterTts();
  final SpeechToText _speech = SpeechToText();
  bool _isInitialized = false;
  bool _speechEnabled = false;

  // Accessibility settings
  bool _voiceNavigationEnabled = false;
  double _speechRate = 0.8;
  double _speechVolume = 1.0;
  double _hapticFeedbackStrength = 0.5;

  // Current scroll controller for accessibility scrolling
  ScrollController? currentScrollController;

  // Voice navigation commands
  /// Predefined voice commands for navigation control
  /// 
  /// This mapping defines the voice commands that users can speak to
  /// navigate through the app. Each command is associated with a
  /// specific navigation action.
  static const Map<String, VoiceCommand> _voiceCommands = {
    'open prayer': VoiceCommand.action(NavigationAction.prayer),
    'open qibla': VoiceCommand.action(NavigationAction.qibla),
    'open tasbih': VoiceCommand.action(NavigationAction.tasbih),
    'open mosque': VoiceCommand.action(NavigationAction.mosque),
    'open settings': VoiceCommand.action(NavigationAction.settings),
    'go back': VoiceCommand.action(NavigationAction.back),
    'scroll down': VoiceCommand.action(NavigationAction.scrollDown),
    'scroll up': VoiceCommand.action(NavigationAction.scrollUp),
    'next page': VoiceCommand.action(NavigationAction.nextPage),
    'previous page': VoiceCommand.action(NavigationAction.previousPage),
  };

  /// Initialize the accessibility service
  /// 
  /// Sets up text-to-speech and speech recognition services with
  /// appropriate configurations. This method should be called during
  /// app initialization to ensure accessibility features are available.
  /// 
  /// Algorithm:
  /// 1. Configure TTS language and speech parameters
  /// 2. Initialize speech recognition with error handling
  /// 3. Set up speech callbacks for status updates
  /// 4. Apply user preferences for speech settings
  /// 5. Set initialization flag
  /// 
  /// Error Handling:
  /// - Graceful degradation if TTS or speech fails
  /// - Detailed error logging without throwing exceptions
  /// - Service remains functional even with partial failures
  /// 
  /// Performance:
  /// - Asynchronous initialization to prevent blocking
  /// - Configurable speech parameters for performance tuning
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Configure TTS settings
      await _tts.setLanguage('en-US');

      // Initialize speech recognition
      final speechAvailable = await _speech.initialize(
        onError:
            (error) => locator<LoggerService>().debug('Speech error: $error'),
        onStatus:
            (status) =>
                locator<LoggerService>().debug('Speech status: $status'),
      );

      await _tts.setSpeechRate(_speechRate);
      await _tts.setVolume(_speechVolume);
      await _tts.setPitch(1.0);
      await _tts.awaitSpeakCompletion(true);

      // Set speech recognition availability
      _speechEnabled = speechAvailable;

      _isInitialized = true;
    } catch (e) {
      // Graceful degradation if accessibility fails
      locator<LoggerService>().error('Accessibility initialization failed: $e');
      _isInitialized = false;
    }
  }

  /// Speak text with enhanced accessibility features
  /// 
  /// Converts text to speech with enhanced pronunciation for Islamic
  /// terms and support for important announcements. This method
  /// improves the user experience for visually impaired users.
  /// 
  /// Parameters:
  /// - [text]: The text to speak
  /// - [important]: Whether this is an important announcement
  /// 
  /// Algorithm:
  /// 1. Check if service is initialized
  /// 2. Add audio cues for important announcements
  /// 3. Enhance text with better Islamic term pronunciation
  /// 4. Speak the enhanced text
  /// 
  /// Error Handling:
  /// - Logs errors without throwing exceptions
  /// - Continues operation even if speech fails
  /// 
  /// Performance:
  /// - Uses awaitSpeakCompletion for sequential speech
  /// - Caches pronunciation mappings for efficiency
  Future<void> speak(String text, {bool important = false}) async {
    if (!_isInitialized) return;

    try {
      // Add audio cues for important announcements
      if (important) {
        await _tts.speak('⚠️ Important message.');
        await Future<void>.delayed(const Duration(milliseconds: 500));
      }

      // Enhance text with better pronunciation for Islamic terms
      final enhancedText = _enhanceIslamicText(text);
      await _tts.speak(enhancedText);
    } catch (e) {
      locator<LoggerService>().error('TTS error: $e');
    }
  }

  /// Stop speaking
  /// 
  /// Stops any currently active speech synthesis. This is useful
  /// when navigating away from a screen or when user initiates
  /// new speech.
  /// 
  /// Algorithm:
  /// 1. Check if service is initialized
  /// 2. Stop speech synthesis
  /// 
  /// Performance:
  /// - Immediate cancellation of speech
  Future<void> stop() async {
    if (_isInitialized) {
      await _tts.stop();
    }
  }

  /// Start voice recognition for commands
  /// 
  /// Initiates speech recognition to listen for voice commands.
  /// The recognized speech is processed and matched against
  /// predefined commands for navigation control.
  /// 
  /// Algorithm:
  /// 1. Check if service is initialized and speech is enabled
  /// 2. Initialize speech recognition if needed
  /// 3. Start listening with specified parameters
  /// 4. Process recognized speech in callback
  /// 
  /// Performance:
  /// - Limited listening duration to conserve resources
  /// - Configurable pause duration for natural speech
  /// 
  /// Returns:
  /// - Future that completes when listening starts (result handled in callback)
  Future<String?> startListening() async {
    if (!_isInitialized || !_speechEnabled) return null;

    try {
      final bool available = await _speech.initialize(
        onError:
            (error) => locator<LoggerService>().debug('Speech error: $error'),
        onStatus:
            (status) =>
                locator<LoggerService>().debug('Speech status: $status'),
      );

      if (!available) return null;

      await _speech.listen(
        onResult: (result) {
          final recognizedWords = result.recognizedWords;
          _processVoiceCommand(recognizedWords);
        },
        listenFor: const Duration(seconds: 10),
        pauseFor: const Duration(seconds: 3),
      );

      return null; // Result handled in callback
    } catch (e) {
      locator<LoggerService>().error('Speech recognition error: $e');
      return null;
    }
  }

  /// Stop voice recognition
  /// 
  /// Stops any active speech recognition session. This is useful
  /// when the user manually cancels voice input or when the
  /// app needs to stop listening for other reasons.
  /// 
  /// Performance:
  /// - Immediate cancellation of speech recognition
  Future<void> stopListening() async {
    if (_isInitialized) {
      await _speech.stop();
    }
  }

  /// Provide haptic feedback with customizable strength
  /// 
  /// Generates haptic feedback patterns based on the type of
  /// interaction. The intensity can be customized based on
  /// user preferences.
  /// 
  /// Parameters:
  /// - [type]: The type of haptic feedback to provide
  /// 
  /// Algorithm:
  /// 1. Check if service is initialized
  /// 2. Select appropriate haptic pattern
  /// 3. Apply strength customization
  /// 4. Execute haptic feedback
  /// 
  /// Performance:
  /// - Uses device-native haptic feedback
  /// - Customizable intensity for user preference
  Future<void> provideHapticFeedback(HapticType type) async {
    if (!_isInitialized) return;

    try {
      switch (type) {
        case HapticType.light:
          HapticFeedback.lightImpact();
          break;
        case HapticType.medium:
          HapticFeedback.mediumImpact();
          break;
        case HapticType.heavy:
          HapticFeedback.heavyImpact();
          break;
        case HapticType.success:
          await HapticFeedback.heavyImpact();
          await Future<void>.delayed(
            Duration(milliseconds: (100 * _hapticFeedbackStrength).toInt()),
          );
          await HapticFeedback.lightImpact();
          break;
        case HapticType.error:
          await HapticFeedback.heavyImpact();
          await Future<void>.delayed(
            Duration(milliseconds: (150 * _hapticFeedbackStrength).toInt()),
          );
          await HapticFeedback.heavyImpact();
          break;
        case HapticType.navigation:
          await HapticFeedback.lightImpact();
          await Future<void>.delayed(
            Duration(milliseconds: (50 * _hapticFeedbackStrength).toInt()),
          );
          break;
      }
    } catch (e) {
      locator<LoggerService>().error('Haptic feedback error: $e');
    }
  }

  /// Announce screen changes for blind users
  /// 
  /// Provides audio announcements when the user navigates to a
  /// new screen. This helps visually impaired users understand
  /// the current app state and context.
  /// 
  /// Parameters:
  /// - [screenName]: The name of the screen being displayed
  /// - [description]: Optional additional description
  /// 
  /// Algorithm:
  /// 1. Construct announcement message
  /// 2. Add description if provided
  /// 3. Speak announcement as important message
  /// 
  /// Performance:
  /// - Uses important flag for attention
  Future<void> announceScreenChange(
    String screenName, {
    String? description,
  }) async {
    String announcement = 'Screen changed to $screenName';
    if (description != null) {
      announcement += '. $description';
    }
    await speak(announcement, important: true);
  }

  /// Read prayer times with enhanced context
  /// 
  /// Announces prayer times with contextual information about
  /// when the prayer occurs relative to the current time.
  /// This helps users understand prayer schedules without
  /// needing to check the screen.
  /// 
  /// Parameters:
  /// - [prayerName]: The name of the prayer
  /// - [time]: The prayer time
  /// - [isNext]: Whether this is the next prayer
  /// 
  /// Algorithm:
  /// 1. Format time for speech
  /// 2. Determine priority (next prayer vs current)
  /// 3. Calculate time relationship (in X minutes/hours)
  /// 4. Construct contextual announcement
  /// 5. Speak with appropriate importance
  Future<void> announcePrayerTime(
    String prayerName,
    DateTime time, {
    bool isNext = false,
  }) async {
    final now = DateTime.now();
    final formattedTime = _formatTimeForSpeech(time);
    final String priority = isNext ? 'next prayer' : 'prayer';

    final announcement =
        '$priority: $prayerName. Time: $formattedTime${_getTimeRelation(time, now)}';
    await speak(announcement, important: isNext);
  }

  /// Enhance Islamic terms for better pronunciation
  /// 
  /// Replaces Islamic terms with phonetic spellings that improve
  /// text-to-speech pronunciation. This makes the app more
  /// accessible to users unfamiliar with Arabic terms.
  /// 
  /// Parameters:
  /// - [text]: The text to enhance
  /// 
  /// Algorithm:
  /// 1. Apply term-by-term replacements
  /// 2. Use phonetic spellings for better pronunciation
  /// 3. Preserve original text structure
  /// 
  /// Performance:
  /// - Uses efficient string replacement
  /// - Cached mappings for quick lookup
  /// 
  /// Returns:
  /// - Enhanced text with better pronunciation
  String _enhanceIslamicText(String text) {
    // Add pronunciation guides and context
    final replacements = {
      'Qibla': 'Kibla',
      'Dhuhr': 'Duh-hur',
      'Asr': 'Asr',
      'Maghrib': 'Magh-reb',
      'Isha': 'Ish-sha',
      'Fajr': 'Fajr',
      'Ramadan': 'Ramadan',
      'Eid': 'Eed',
      'Dua': 'Doo-ah',
      'Dhikr': 'Dhikr',
      'Salah': 'Sa-laah',
      'Sunnah': 'Sun-nah',
      'Jummah': 'Jum-mah',
      'Halal': 'Ha-lal',
      'Haram': 'Ha-ram',
    };

    String enhanced = text;
    replacements.forEach((original, pronunciation) {
      enhanced = enhanced.replaceAll(original, pronunciation);
    });

    return enhanced;
  }

  /// Process voice commands
  /// 
  /// Processes recognized speech and matches it against predefined
  /// voice commands. If a match is found, the corresponding action
  /// is executed.
  /// 
  /// Parameters:
  /// - [recognizedText]: The text recognized from speech
  /// 
  /// Algorithm:
  /// 1. Convert text to lowercase for matching
  /// 2. Search for matching commands
  /// 3. Execute first matching command
  /// 4. Handle unrecognized commands
  /// 
  /// Performance:
  /// - Efficient string matching
  /// - Early return on first match
  void _processVoiceCommand(String recognizedText) {
    final lowerText = recognizedText.toLowerCase();

    for (final entry in _voiceCommands.entries) {
      if (lowerText.contains(entry.key)) {
        _executeCommand(entry.value);
        return;
      }
    }

    // Command not found
    speak('Command not recognized. Please try again.');
  }

  /// Execute voice commands
  /// 
  /// Executes the action associated with a voice command. This
  /// method handles navigation, scrolling, and other app actions
  /// triggered by voice commands.
  /// 
  /// Parameters:
  /// - [command]: The voice command to execute
  /// 
  /// Algorithm:
  /// 1. Get navigation service instance
  /// 2. Execute appropriate action based on command type
  /// 3. Provide audio feedback for user confirmation
  /// 4. Handle special cases like scrolling
  void _executeCommand(VoiceCommand command) {
    final navigationService = locator.get<NavigationService>();
    switch (command.action) {
      case NavigationAction.prayer:
        speak('Opening prayer screen');
        navigationService.navigateTo<void>(const HomeView());
        break;
      case NavigationAction.qibla:
        speak('Opening Qibla direction');
        navigationService.navigateTo<void>(const QiblaView());
        break;
      case NavigationAction.tasbih:
        speak('Opening Tasbih counter');
        navigationService.navigateTo<void>(const TesbihView());
        break;
      case NavigationAction.mosque:
        speak('Finding nearby mosques');
        navigationService.navigateTo<void>(const MosqueView());
        break;
      case NavigationAction.settings:
        speak('Opening settings');
        navigationService.navigateTo<void>(const SettingsView());
        break;
      case NavigationAction.back:
        speak('Going back');
        navigationService.goBack<void>();
        break;
      case NavigationAction.scrollDown:
        speak('Scrolling down');
        if (currentScrollController != null &&
            currentScrollController!.hasClients) {
          currentScrollController!.animateTo(
            currentScrollController!.offset + 200.0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        } else {
          speak('No scrollable content available');
        }
        break;
      case NavigationAction.scrollUp:
        speak('Scrolling up');
        if (currentScrollController != null &&
            currentScrollController!.hasClients) {
          currentScrollController!.animateTo(
            currentScrollController!.offset - 200.0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        } else {
          speak('No scrollable content available');
        }
        break;
      case NavigationAction.nextPage:
        speak('Next page');
        if (currentScrollController != null &&
            currentScrollController!.hasClients) {
          currentScrollController!.animateTo(
            currentScrollController!.offset + 400.0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        } else {
          speak('No scrollable content available');
        }
        break;
      case NavigationAction.previousPage:
        speak('Previous page');
        if (currentScrollController != null &&
            currentScrollController!.hasClients) {
          currentScrollController!.animateTo(
            currentScrollController!.offset - 400.0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        } else {
          speak('No scrollable content available');
        }
        break;
    }
  }

  /// Format time for speech
  /// 
  /// Converts a DateTime object to a speech-friendly time format.
  /// The format is optimized for text-to-speech clarity.
  /// 
  /// Parameters:
  /// - [time]: The time to format
  /// 
  /// Returns:
  /// - Speech-friendly time string
  String _formatTimeForSpeech(DateTime time) {
    final hour = time.hour;
    final minute = time.minute;
    return '$hour ${minute == 0 ? '' : 'and $minute minutes'}';
  }

  /// Get time relation for context
  /// 
  /// Calculates a human-readable description of the relationship
  /// between a prayer time and the current time.
  /// 
  /// Parameters:
  /// - [prayerTime]: The prayer time
  /// - [now]: The current time
  /// 
  /// Returns:
  /// - Contextual time relationship string
  String _getTimeRelation(DateTime prayerTime, DateTime now) {
    final difference = prayerTime.difference(now);

    if (difference.isNegative) {
      return ' was ${_formatDuration(difference.abs())} ago';
    } else if (difference.inMinutes < 60) {
      return ' in ${difference.inMinutes} minutes';
    } else if (difference.inHours < 2) {
      return ' in about ${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'}';
    } else {
      return ' in about ${difference.inHours ~/ 2} ${difference.inHours ~/ 2 == 1 ? 'hour' : 'hours'}';
    }
  }

  /// Format duration for speech
  /// 
  /// Converts a Duration object to a speech-friendly format.
  /// 
  /// Parameters:
  /// - [duration]: The duration to format
  /// 
  /// Returns:
  /// - Speech-friendly duration string
  String _formatDuration(Duration duration) {
    if (duration.inMinutes < 60) {
      return '${duration.inMinutes} minutes';
    } else {
      return '${duration.inHours} ${duration.inHours == 1 ? 'hour' : 'hours'}';
    }
  }

  /// Getters for accessibility status
  /// 
  /// Provides read-only access to the service's initialization
  /// and configuration state.
  bool get isInitialized => _isInitialized;
  bool get speechEnabled => _speechEnabled;
  bool get voiceNavigationEnabled => _voiceNavigationEnabled;

  /// Setters for accessibility settings
  /// 
  /// Provides methods to update accessibility settings with
  /// immediate effect on the service behavior.
  /// 
  /// Parameters:
  /// - [enabled]: The new value for the setting
  Future<void> setVoiceNavigationEnabled(bool enabled) async {
    _voiceNavigationEnabled = enabled;
    if (enabled) {
      await speak(
        'Voice navigation enabled. Say "open prayer" or other commands to navigate.',
      );
    } else {
      await speak('Voice navigation disabled');
    }
  }

  /// Update speech rate setting
  /// 
  /// Parameters:
  /// - [rate]: The new speech rate (0.1 to 1.0)
  Future<void> setSpeechRate(double rate) async {
    _speechRate = rate.clamp(0.1, 1.0);
    if (_isInitialized) {
      await _tts.setSpeechRate(_speechRate);
    }
  }

  /// Update speech volume setting
  /// 
  /// Parameters:
  /// - [volume]: The new speech volume (0.0 to 1.0)
  Future<void> setSpeechVolume(double volume) async {
    _speechVolume = volume.clamp(0.0, 1.0);
    if (_isInitialized) {
      await _tts.setVolume(_speechVolume);
    }
  }

  /// Update haptic feedback strength setting
  /// 
  /// Parameters:
  /// - [strength]: The new haptic strength (0.0 to 1.0)
  Future<void> setHapticFeedbackStrength(double strength) async {
    _hapticFeedbackStrength = strength.clamp(0.0, 1.0);
  }

  /// Cleanup resources
  /// 
  /// Releases resources used by the accessibility service. This
  /// should be called when the service is no longer needed.
  void dispose() {
    _tts.stop();
    _speech.stop();
    _isInitialized = false;
  }
}

/// Voice command data structure
/// 
/// Encapsulates a voice command with its associated action and
/// optional description.
class VoiceCommand {
  final NavigationAction action;
  final String? description;

  const VoiceCommand.action(this.action, [this.description]);
}

/// Navigation actions for voice commands
/// 
/// Enumeration of supported navigation actions that can be
/// triggered by voice commands.
enum NavigationAction {
  prayer,
  qibla,
  tasbih,
  mosque,
  settings,
  back,
  scrollDown,
  scrollUp,
  nextPage,
  previousPage,
}

/// Types of haptic feedback
/// 
/// Enumeration of different haptic feedback patterns used
/// for various interactions in the app.
enum HapticType { light, medium, heavy, success, error, navigation }

/// Enhanced widget for accessibility
/// 
/// This widget provides enhanced accessibility features including
/// automatic announcements of screen changes and semantic labels.
/// It's designed to make UI components more accessible to
/// users with visual impairments.
class AccessibilityAnnouncer extends StatefulWidget {
  final Widget child;
  final String? semanticLabel;
  final String? hint;
  final bool important;

  const AccessibilityAnnouncer({
    super.key,
    required this.child,
    this.semanticLabel,
    this.hint,
    this.important = false,
  });

  @override
  State<AccessibilityAnnouncer> createState() => _AccessibilityAnnouncerState();
}

class _AccessibilityAnnouncerState extends State<AccessibilityAnnouncer>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  final AccessibilityService _accessibility = AccessibilityService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Announce when widget appears
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.semanticLabel != null) {
        _accessibility.speak(
          widget.semanticLabel!,
          important: widget.important,
        );
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && widget.semanticLabel != null) {
      _accessibility.speak(widget.semanticLabel!, important: widget.important);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.semanticLabel,
      hint: widget.hint,
      button: widget.hint != null,
      child: widget.child,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}

/// Enhanced accessible button
/// 
/// This widget provides an accessible button with haptic feedback,
/// semantic labels, and voice announcement capabilities. It's designed
/// to provide an optimal experience for users with accessibility needs.
class AccessibleButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final String semanticLabel;
  final String? hint;
  final HapticType hapticType;

  const AccessibleButton({
    super.key,
    required this.child,
    this.onPressed,
    required this.semanticLabel,
    this.hint,
    this.hapticType = HapticType.light,
  });

  @override
  Widget build(BuildContext context) {
    return AccessibilityAnnouncer(
      semanticLabel: semanticLabel,
      hint: hint,
      important: false,
      child: Material(
        child: InkWell(
          onTap: () async {
            final accessibility = AccessibilityService();
            await accessibility.provideHapticFeedback(hapticType);

            if (onPressed != null) {
              onPressed!();
            }

            // Announce action
            accessibility.speak(semanticLabel);
          },
          child: child,
        ),
      ),
    );
  }
}