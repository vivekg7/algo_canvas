import 'dart:async';
import 'dart:collection';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:algo_canvas/core/algorithm.dart';
import 'package:algo_canvas/core/algorithm_state.dart';

enum PlaybackState { idle, playing, paused, finished }

class VisualizerController extends ChangeNotifier {
  VisualizerController(this._algorithm);

  final Algorithm _algorithm;

  // -- Batch / Streaming state --
  final List<AlgorithmState> _states = [];
  int _currentIndex = -1;
  StreamSubscription<AlgorithmState>? _streamSubscription;
  bool _streamDone = false;
  static const _streamBufferAhead = 100;

  // -- Live mode state --
  final Queue<AlgorithmState> _liveBuffer = Queue();
  int _liveBufferIndex = -1; // position within buffer (0 = oldest)
  int _liveGeneration = 0;
  static const _liveBufferSize = 50;

  // -- Interactive mode state --
  AlgorithmState? _interactiveState;

  // -- Shared state --
  PlaybackState _playbackState = PlaybackState.idle;
  double _speed = 1.0;
  Timer? _timer;

  // -- Public getters --

  AlgorithmMode get mode => _algorithm.mode;
  PlaybackState get playbackState => _playbackState;
  double get speed => _speed;
  bool get isPlaying => _playbackState == PlaybackState.playing;

  AlgorithmState? get currentState {
    if (_algorithm.mode == AlgorithmMode.interactive) return _interactiveState;
    if (_algorithm.mode == AlgorithmMode.live) {
      if (_liveBuffer.isEmpty || _liveBufferIndex < 0) return null;
      return _liveBuffer.elementAt(_liveBufferIndex);
    }
    return _currentIndex >= 0 && _currentIndex < _states.length
        ? _states[_currentIndex]
        : null;
  }

  int get currentIndex {
    if (_algorithm.mode == AlgorithmMode.interactive) return 0;
    if (_algorithm.mode == AlgorithmMode.live) return _liveGeneration;
    return _currentIndex;
  }

  int get totalSteps {
    if (_algorithm.mode == AlgorithmMode.interactive) return 0;
    if (_algorithm.mode == AlgorithmMode.live) return _liveGeneration;
    return _states.length;
  }

  double get progress {
    if (_algorithm.mode == AlgorithmMode.interactive) return 0;
    if (_algorithm.mode == AlgorithmMode.live) return 0;
    return _states.length <= 1 ? 0.0 : _currentIndex / (_states.length - 1);
  }

  /// Whether we're viewing a past state in live mode's buffer.
  bool get isViewingLiveHistory =>
      _algorithm.mode == AlgorithmMode.live &&
      _liveBufferIndex < _liveBuffer.length - 1;

  // -- Initialization --

  Future<void> initialize() async {
    _states.clear();
    _currentIndex = -1;
    _streamDone = false;
    _liveBuffer.clear();
    _liveBufferIndex = -1;
    _liveGeneration = 0;

    switch (_algorithm.mode) {
      case AlgorithmMode.batch:
        final generated = await _algorithm.generate();
        _states.addAll(generated);
        if (_states.isNotEmpty) {
          _currentIndex = 0;
          _playbackState = PlaybackState.paused;
        }

      case AlgorithmMode.streaming:
        _streamSubscription = _algorithm.stream().listen(
          (state) {
            _states.add(state);
            _manageStreamFlow();
            notifyListeners();
          },
          onDone: () {
            _streamDone = true;
            notifyListeners();
          },
        );
        while (_states.isEmpty && !_streamDone) {
          await Future<void>.delayed(const Duration(milliseconds: 10));
        }
        if (_states.isNotEmpty) {
          _currentIndex = 0;
          _playbackState = PlaybackState.paused;
        }

      case AlgorithmMode.live:
        final initial = _algorithm.createInitialState();
        if (initial != null) {
          _liveBuffer.add(initial);
          _liveBufferIndex = 0;
          _playbackState = PlaybackState.paused;
        }

      case AlgorithmMode.interactive:
        final initial = _algorithm.createInitialState();
        if (initial != null) {
          _interactiveState = initial;
          _playbackState = PlaybackState.paused;
        }
    }

    notifyListeners();
  }

  // -- Playback controls --

  void play() {
    if (_algorithm.mode == AlgorithmMode.live) {
      // Jump to latest state if viewing history
      if (_liveBuffer.isNotEmpty) {
        _liveBufferIndex = _liveBuffer.length - 1;
      }
      _playbackState = PlaybackState.playing;
      _startTimer();
      notifyListeners();
      return;
    }

    if (_states.isEmpty) return;
    if (_playbackState == PlaybackState.finished) {
      _currentIndex = 0;
    }
    _playbackState = PlaybackState.playing;
    _resumeStreamIfNeeded();
    _startTimer();
    notifyListeners();
  }

  void pause() {
    _playbackState = PlaybackState.paused;
    _stopTimer();
    notifyListeners();
  }

  void stepForward() {
    if (_algorithm.mode == AlgorithmMode.live) {
      if (_liveBufferIndex < _liveBuffer.length - 1) {
        // Step forward through buffer
        _liveBufferIndex++;
      } else {
        // Compute one new state
        _tickLive();
      }
      _playbackState = PlaybackState.paused;
      _stopTimer();
      notifyListeners();
      return;
    }

    if (_currentIndex < _states.length - 1) {
      _currentIndex++;
      _playbackState = PlaybackState.paused;
      _stopTimer();
      _manageStreamFlow();
      notifyListeners();
    }
  }

  void stepBackward() {
    if (_algorithm.mode == AlgorithmMode.live) {
      if (_liveBufferIndex > 0) {
        _liveBufferIndex--;
        _playbackState = PlaybackState.paused;
        _stopTimer();
        notifyListeners();
      }
      return;
    }

    if (_currentIndex > 0) {
      _currentIndex--;
      _playbackState = PlaybackState.paused;
      _stopTimer();
      notifyListeners();
    }
  }

  void reset() {
    _stopTimer();
    if (_algorithm.mode == AlgorithmMode.interactive) {
      _interactiveState = _algorithm.createInitialState();
      _playbackState = PlaybackState.paused;
      notifyListeners();
      return;
    }
    if (_algorithm.mode == AlgorithmMode.live) {
      _liveBuffer.clear();
      _liveBufferIndex = -1;
      _liveGeneration = 0;
      final initial = _algorithm.createInitialState();
      if (initial != null) {
        _liveBuffer.add(initial);
        _liveBufferIndex = 0;
      }
      _playbackState = PlaybackState.paused;
      notifyListeners();
      return;
    }

    if (_states.isNotEmpty) {
      _currentIndex = 0;
      _playbackState = PlaybackState.paused;
    }
    notifyListeners();
  }

  void setSpeed(double speed) {
    _speed = speed.clamp(0.25, 16.0);
    if (isPlaying) {
      _stopTimer();
      _startTimer();
    }
    notifyListeners();
  }

  /// Jump to a specific step index (batch/streaming only).
  void seekTo(int index) {
    if (_algorithm.mode == AlgorithmMode.live) return;
    if (index < 0 || index >= _states.length) return;
    _currentIndex = index;
    if (_playbackState == PlaybackState.finished) {
      _playbackState = PlaybackState.paused;
    }
    _stopTimer();
    _playbackState = PlaybackState.paused;
    _manageStreamFlow();
    notifyListeners();
  }

  // -- Timer --

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
    if (_algorithm.mode == AlgorithmMode.live) {
      _tickLive();
      notifyListeners();
      return;
    }

    if (_currentIndex < _states.length - 1) {
      _currentIndex++;
      _manageStreamFlow();
      notifyListeners();
    } else if (_algorithm.mode == AlgorithmMode.streaming && !_streamDone) {
      _resumeStreamIfNeeded();
    } else {
      _playbackState = PlaybackState.finished;
      _stopTimer();
      notifyListeners();
    }
  }

  // -- Live mode helpers --

  void _tickLive() {
    final current = _liveBuffer.isNotEmpty ? _liveBuffer.last : null;
    if (current == null) return;

    final next = _algorithm.tick(current);
    if (next == null) {
      _playbackState = PlaybackState.finished;
      _stopTimer();
      return;
    }

    _liveGeneration++;
    _liveBuffer.addLast(next);
    if (_liveBuffer.length > _liveBufferSize) {
      _liveBuffer.removeFirst();
    }
    _liveBufferIndex = _liveBuffer.length - 1;
  }

  // -- Stream flow control --

  void _manageStreamFlow() {
    if (_algorithm.mode != AlgorithmMode.streaming || _streamDone) return;
    final buffered = _states.length - 1 - _currentIndex;
    if (buffered >= _streamBufferAhead) {
      _streamSubscription?.pause();
    } else if (buffered < _streamBufferAhead ~/ 2) {
      _resumeStreamIfNeeded();
    }
  }

  void _resumeStreamIfNeeded() {
    if (_algorithm.mode != AlgorithmMode.streaming || _streamDone) return;
    if (_streamSubscription?.isPaused ?? false) {
      _streamSubscription?.resume();
    }
  }

  // -- Interactive mode --

  void handleInteractionStart(Offset normalizedPosition) {
    if (_algorithm.mode != AlgorithmMode.interactive || _interactiveState == null) return;
    final newState = _algorithm.onInteractionStart(_interactiveState!, normalizedPosition);
    if (newState != null) {
      _interactiveState = newState;
      notifyListeners();
    }
  }

  void handleInteractionUpdate(Offset normalizedPosition) {
    if (_algorithm.mode != AlgorithmMode.interactive || _interactiveState == null) return;
    final newState = _algorithm.onInteractionUpdate(_interactiveState!, normalizedPosition);
    if (newState != null) {
      _interactiveState = newState;
      notifyListeners();
    }
  }

  void handleInteractionEnd() {
    if (_algorithm.mode != AlgorithmMode.interactive || _interactiveState == null) return;
    final newState = _algorithm.onInteractionEnd(_interactiveState!);
    if (newState != null) {
      _interactiveState = newState;
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
