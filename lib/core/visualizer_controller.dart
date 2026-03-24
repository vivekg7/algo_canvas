import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:algo_canvas/core/algorithm.dart';
import 'package:algo_canvas/core/algorithm_state.dart';

enum PlaybackState { idle, playing, paused, finished }

class VisualizerController extends ChangeNotifier {
  VisualizerController(this._algorithm);

  final Algorithm _algorithm;

  final List<AlgorithmState> _states = [];
  int _currentIndex = -1;
  PlaybackState _playbackState = PlaybackState.idle;
  double _speed = 1.0;
  Timer? _timer;
  StreamSubscription<AlgorithmState>? _streamSubscription;
  bool _streamDone = false;

  // -- Public getters --

  List<AlgorithmState> get states => List.unmodifiable(_states);
  int get currentIndex => _currentIndex;
  int get totalSteps => _states.length;
  PlaybackState get playbackState => _playbackState;
  double get speed => _speed;
  bool get isPlaying => _playbackState == PlaybackState.playing;

  AlgorithmState? get currentState =>
      _currentIndex >= 0 && _currentIndex < _states.length
          ? _states[_currentIndex]
          : null;

  /// Progress from 0.0 to 1.0. Returns 0 when no steps are loaded.
  double get progress =>
      _states.length <= 1 ? 0.0 : _currentIndex / (_states.length - 1);

  // -- Initialization --

  /// Load algorithm states. Call this before playback.
  Future<void> initialize() async {
    _states.clear();
    _currentIndex = -1;
    _streamDone = false;

    if (_algorithm.isStreaming) {
      _streamSubscription = _algorithm.stream().listen(
        (state) {
          _states.add(state);
          // If we're playing and were waiting for more states, the timer
          // will pick it up on the next tick.
          notifyListeners();
        },
        onDone: () {
          _streamDone = true;
          notifyListeners();
        },
      );
      // Wait for at least one state before considering ready.
      while (_states.isEmpty && !_streamDone) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
    } else {
      final generated = await _algorithm.generate();
      _states.addAll(generated);
    }

    if (_states.isNotEmpty) {
      _currentIndex = 0;
      _playbackState = PlaybackState.paused;
    }
    notifyListeners();
  }

  // -- Playback controls --

  void play() {
    if (_states.isEmpty) return;
    if (_playbackState == PlaybackState.finished) {
      _currentIndex = 0;
    }
    _playbackState = PlaybackState.playing;
    _startTimer();
    notifyListeners();
  }

  void pause() {
    _playbackState = PlaybackState.paused;
    _stopTimer();
    notifyListeners();
  }

  void stepForward() {
    if (_currentIndex < _states.length - 1) {
      _currentIndex++;
      _playbackState = PlaybackState.paused;
      _stopTimer();
      notifyListeners();
    }
  }

  void stepBackward() {
    if (_currentIndex > 0) {
      _currentIndex--;
      _playbackState = PlaybackState.paused;
      _stopTimer();
      notifyListeners();
    }
  }

  void reset() {
    _stopTimer();
    if (_states.isNotEmpty) {
      _currentIndex = 0;
      _playbackState = PlaybackState.paused;
    }
    notifyListeners();
  }

  void setSpeed(double speed) {
    _speed = speed.clamp(0.25, 8.0);
    if (isPlaying) {
      _stopTimer();
      _startTimer();
    }
    notifyListeners();
  }

  /// Jump to a specific step index (for scrubbing).
  void seekTo(int index) {
    if (index < 0 || index >= _states.length) return;
    _currentIndex = index;
    if (_playbackState == PlaybackState.finished) {
      _playbackState = PlaybackState.paused;
    }
    _stopTimer();
    _playbackState = PlaybackState.paused;
    notifyListeners();
  }

  // -- Timer management --

  void _startTimer() {
    _stopTimer();
    final interval = Duration(milliseconds: (200 / _speed).round());
    _timer = Timer.periodic(interval, (_) => _tick());
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void _tick() {
    if (_currentIndex < _states.length - 1) {
      _currentIndex++;
      notifyListeners();
    } else if (_algorithm.isStreaming && !_streamDone) {
      // Waiting for more states from the stream — stay playing.
    } else {
      _playbackState = PlaybackState.finished;
      _stopTimer();
      notifyListeners();
    }
  }

  // -- Cleanup --

  @override
  void dispose() {
    _stopTimer();
    _streamSubscription?.cancel();
    super.dispose();
  }
}
