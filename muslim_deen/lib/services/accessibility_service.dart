import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter/services.dart';
import 'package:muslim_deen/service_locator.dart';
import 'package:muslim_deen/services/navigation_service.dart';
import 'package:muslim_deen/views/home_view.dart';
import 'package:muslim_deen/views/qibla_view.dart';
import 'package:muslim_deen/views/tesbih_view.dart';
import 'package:muslim_deen/views/mosque_view.dart';
import 'package:muslim_deen/views/settings_view.dart';

/// Enhanced accessibility service for MuslimDeen app
/// Provides screen reader support, voice commands, and cognitive assistance
class AccessibilityService {
  static final AccessibilityService _instance = AccessibilityService._internal();
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
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Configure TTS settings
      await _tts.setLanguage('en-US');
      
      // Initialize speech recognition
      final speechAvailable = await _speech.initialize(
        onError: (error) => print('Speech error: $error'),
        onStatus: (status) => print('Speech status: $status'),
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
      print('Accessibility initialization failed: $e');
      _isInitialized = false;
    }
  }

  /// Speak text with enhanced accessibility features
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
      print('TTS error: $e');
    }
  }

  /// Stop speaking
  Future<void> stop() async {
    if (_isInitialized) {
      await _tts.stop();
    }
  }

  /// Start voice recognition for commands
  Future<String?> startListening() async {
    if (!_isInitialized || !_speechEnabled) return null;

    try {
      final bool available = await _speech.initialize(
        onError: (error) => print('Speech error: $error'),
        onStatus: (status) => print('Speech status: $status'),
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
      print('Speech recognition error: $e');
      return null;
    }
  }

  /// Stop voice recognition
  Future<void> stopListening() async {
    if (_isInitialized) {
      await _speech.stop();
    }
  }

  /// Provide haptic feedback with customizable strength
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
          await Future<void>.delayed(Duration(milliseconds: (100 * _hapticFeedbackStrength).toInt()));
          await HapticFeedback.lightImpact();
          break;
        case HapticType.error:
          await HapticFeedback.heavyImpact();
          await Future<void>.delayed(Duration(milliseconds: (150 * _hapticFeedbackStrength).toInt()));
          await HapticFeedback.heavyImpact();
          break;
        case HapticType.navigation:
          await HapticFeedback.lightImpact();
          await Future<void>.delayed(Duration(milliseconds: (50 * _hapticFeedbackStrength).toInt()));
          break;
      }
    } catch (e) {
      print('Haptic feedback error: $e');
    }
  }

  /// Announce screen changes for blind users
  Future<void> announceScreenChange(String screenName, {String? description}) async {
    String announcement = 'Screen changed to $screenName';
    if (description != null) {
      announcement += '. $description';
    }
    await speak(announcement, important: true);
  }

  /// Read prayer times with enhanced context
  Future<void> announcePrayerTime(String prayerName, DateTime time, {bool isNext = false}) async {
    final now = DateTime.now();
    final formattedTime = _formatTimeForSpeech(time);
    final String priority = isNext ? 'next prayer' : 'prayer';
    
    final announcement = '$priority: $prayerName. Time: $formattedTime${_getTimeRelation(time, now)}';
    await speak(announcement, important: isNext);
  }

  /// Enhance Islamic terms for better pronunciation
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
        if (currentScrollController != null && currentScrollController!.hasClients) {
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
        if (currentScrollController != null && currentScrollController!.hasClients) {
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
        if (currentScrollController != null && currentScrollController!.hasClients) {
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
        if (currentScrollController != null && currentScrollController!.hasClients) {
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
  String _formatTimeForSpeech(DateTime time) {
    final hour = time.hour;
    final minute = time.minute;
    return '$hour ${minute == 0 ? '' : 'and $minute minutes'}';
  }

  /// Get time relation for context
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
  String _formatDuration(Duration duration) {
    if (duration.inMinutes < 60) {
      return '${duration.inMinutes} minutes';
    } else {
      return '${duration.inHours} ${duration.inHours == 1 ? 'hour' : 'hours'}';
    }
  }

  /// Getters for accessibility status
  bool get isInitialized => _isInitialized;
  bool get speechEnabled => _speechEnabled;
  bool get voiceNavigationEnabled => _voiceNavigationEnabled;

  /// Setters for accessibility settings
  Future<void> setVoiceNavigationEnabled(bool enabled) async {
    _voiceNavigationEnabled = enabled;
    if (enabled) {
      await speak('Voice navigation enabled. Say "open prayer" or other commands to navigate.');
    } else {
      await speak('Voice navigation disabled');
    }
  }

  Future<void> setSpeechRate(double rate) async {
    _speechRate = rate.clamp(0.1, 1.0);
    if (_isInitialized) {
      await _tts.setSpeechRate(_speechRate);
    }
  }

  Future<void> setSpeechVolume(double volume) async {
    _speechVolume = volume.clamp(0.0, 1.0);
    if (_isInitialized) {
      await _tts.setVolume(_speechVolume);
    }
  }

  Future<void> setHapticFeedbackStrength(double strength) async {
    _hapticFeedbackStrength = strength.clamp(0.0, 1.0);
  }

  /// Cleanup resources
  void dispose() {
    _tts.stop();
    _speech.stop();
    _isInitialized = false;
  }
}

/// Voice command data structure
class VoiceCommand {
  final NavigationAction action;
  final String? description;

  const VoiceCommand.action(this.action, [this.description]);
}

/// Navigation actions for voice commands
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
enum HapticType {
  light,
  medium,
  heavy,
  success,
  error,
  navigation,
}

/// Enhanced widget for accessibility
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
        _accessibility.speak(widget.semanticLabel!, important: widget.important);
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
