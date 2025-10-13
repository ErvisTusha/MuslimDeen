import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:muslim_deen/models/app_constants.dart';
import 'package:muslim_deen/service_locator.dart';
import 'package:muslim_deen/services/logger_service.dart';

/// Service for managing audio playback in the app
class AudioPlayerService {
  static AudioPlayerService? _instance;
  final LoggerService _logger = locator<LoggerService>();

  // Audio players for different purposes
  AudioPlayer? _dhikrPlayer;
  AudioPlayer? _counterPlayer;
  AudioPlayer? _adhanPlayer;

  // Audio state
  bool _isDhikrPlaying = false;
  bool _isCounterPlaying = false;
  bool _isAdhanPlaying = false;

  // Audio settings
  double _dhikrVolume = 1.0;
  double _counterVolume = 0.7;
  double _adhanVolume = 1.0;

  AudioPlayerService() {
    _instance = this;
  }

  static AudioPlayerService get instance {
    _instance ??= AudioPlayerService();
    return _instance!;
  }

  /// Initialize the audio service
  Future<void> init() async {
    try {
      _dhikrPlayer = AudioPlayer();
      _counterPlayer = AudioPlayer();
      _adhanPlayer = AudioPlayer();

      // Set up error handling
      _setupPlayerListeners();

      _logger.info('AudioPlayerService initialized successfully');
    } catch (e, s) {
      _logger.error('Failed to initialize AudioPlayerService', error: e, stackTrace: s);
      rethrow;
    }
  }

  void _setupPlayerListeners() {
    _dhikrPlayer?.onPlayerComplete.listen((event) {
      _isDhikrPlaying = false;
      _logger.debug('Dhikr audio playback completed');
    });

    _counterPlayer?.onPlayerComplete.listen((event) {
      _isCounterPlaying = false;
      _logger.debug('Counter audio playback completed');
    });

    _adhanPlayer?.onPlayerComplete.listen((event) {
      _isAdhanPlaying = false;
      _logger.debug('Adhan audio playback completed');
    });

    // Error listeners
    _dhikrPlayer?.onPlayerStateChanged.listen((state) {
      if (state == PlayerState.completed) {
        _isDhikrPlaying = false;
      }
    });

    _counterPlayer?.onPlayerStateChanged.listen((state) {
      if (state == PlayerState.completed) {
        _isCounterPlaying = false;
      }
    });

    _adhanPlayer?.onPlayerStateChanged.listen((state) {
      if (state == PlayerState.completed) {
        _isAdhanPlaying = false;
      }
    });
  }

  /// Play dhikr pronunciation audio
  Future<void> playDhikrAudio(String dhikr) async {
    if (_isDhikrPlaying) {
      await stopDhikrAudio();
    }

    try {
      final audioFile = _getDhikrAudioFile(dhikr);
      if (audioFile == null) {
        _logger.warning('No audio file found for dhikr: $dhikr');
        return;
      }

      _isDhikrPlaying = true;
      await _dhikrPlayer?.setVolume(_dhikrVolume);
      await _dhikrPlayer?.play(AssetSource(audioFile));

      _logger.debug('Playing dhikr audio: $dhikr');
    } catch (e, s) {
      _isDhikrPlaying = false;
      _logger.error('Error playing dhikr audio for $dhikr', error: e, stackTrace: s);
    }
  }

  /// Stop dhikr audio playback
  Future<void> stopDhikrAudio() async {
    try {
      await _dhikrPlayer?.stop();
      _isDhikrPlaying = false;
      _logger.debug('Dhikr audio stopped');
    } catch (e, s) {
      _logger.error('Error stopping dhikr audio', error: e, stackTrace: s);
    }
  }

  /// Play counter sound (tesbih click)
  Future<void> playCounterSound() async {
    if (_isCounterPlaying) return;

    try {
      _isCounterPlaying = true;
      await _counterPlayer?.setVolume(_counterVolume);
      await _counterPlayer?.play(AssetSource('audio/tesbih.mp3'));

      _logger.debug('Playing counter sound');
    } catch (e, s) {
      _isCounterPlaying = false;
      _logger.error('Error playing counter sound', error: e, stackTrace: s);
    }
  }

  /// Stop counter sound
  Future<void> stopCounterSound() async {
    try {
      await _counterPlayer?.stop();
      _isCounterPlaying = false;
      _logger.debug('Counter sound stopped');
    } catch (e, s) {
      _logger.error('Error stopping counter sound', error: e, stackTrace: s);
    }
  }

  /// Play adhan audio
  Future<void> playAdhan(String adhanType) async {
    if (_isAdhanPlaying) {
      await stopAdhan();
    }

    try {
      final audioFile = _getAdhanAudioFile(adhanType);
      if (audioFile == null) {
        _logger.warning('No audio file found for adhan: $adhanType');
        return;
      }

      _isAdhanPlaying = true;
      await _adhanPlayer?.setVolume(_adhanVolume);
      await _adhanPlayer?.play(AssetSource(audioFile));

      _logger.debug('Playing adhan: $adhanType');
    } catch (e, s) {
      _isAdhanPlaying = false;
      _logger.error('Error playing adhan $adhanType', error: e, stackTrace: s);
    }
  }

  /// Stop adhan playback
  Future<void> stopAdhan() async {
    try {
      await _adhanPlayer?.stop();
      _isAdhanPlaying = false;
      _logger.debug('Adhan stopped');
    } catch (e, s) {
      _logger.error('Error stopping adhan', error: e, stackTrace: s);
    }
  }

  /// Set dhikr audio volume (0.0 to 1.0)
  Future<void> setDhikrVolume(double volume) async {
    _dhikrVolume = volume.clamp(0.0, 1.0);
    if (_isDhikrPlaying) {
      await _dhikrPlayer?.setVolume(_dhikrVolume);
    }
    _logger.debug('Dhikr volume set to $_dhikrVolume');
  }

  /// Set counter sound volume (0.0 to 1.0)
  Future<void> setCounterVolume(double volume) async {
    _counterVolume = volume.clamp(0.0, 1.0);
    if (_isCounterPlaying) {
      await _counterPlayer?.setVolume(_counterVolume);
    }
    _logger.debug('Counter volume set to $_counterVolume');
  }

  /// Set adhan volume (0.0 to 1.0)
  Future<void> setAdhanVolume(double volume) async {
    _adhanVolume = volume.clamp(0.0, 1.0);
    if (_isAdhanPlaying) {
      await _adhanPlayer?.setVolume(_adhanVolume);
    }
    _logger.debug('Adhan volume set to $_adhanVolume');
  }

  /// Get the audio file path for a dhikr
  String? _getDhikrAudioFile(String dhikr) {
    return AppConstants.dhikrAudioFiles[dhikr];
  }

  /// Get the audio file path for an adhan type
  String? _getAdhanAudioFile(String adhanType) {
    final audioMap = {
      'makkah': 'audio/makkah_adhan.mp3',
      'madinah': 'audio/madinah_adhan.mp3',
      'al-aqsa': 'audio/alaqsa_adhan.mp3',
      'turkish': 'audio/azaan_turkish.mp3',
    };

    return audioMap[adhanType.toLowerCase()];
  }

  /// Check if dhikr audio is currently playing
  bool get isDhikrPlaying => _isDhikrPlaying;

  /// Check if counter sound is currently playing
  bool get isCounterPlaying => _isCounterPlaying;

  /// Check if adhan is currently playing
  bool get isAdhanPlaying => _isAdhanPlaying;

  /// Dispose of all audio players
  Future<void> dispose() async {
    try {
      await _dhikrPlayer?.dispose();
      await _counterPlayer?.dispose();
      await _adhanPlayer?.dispose();

      _dhikrPlayer = null;
      _counterPlayer = null;
      _adhanPlayer = null;

      _logger.info('AudioPlayerService disposed');
    } catch (e, s) {
      _logger.error('Error disposing AudioPlayerService', error: e, stackTrace: s);
    }
  }
}