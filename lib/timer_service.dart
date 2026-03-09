import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:vibration/vibration.dart';
import 'database_service.dart';

enum TimerMode { focus, shortBreak, longBreak }

class TimerService extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  TimerMode _mode = TimerMode.focus;
  int _focusDuration = 25 * 60;
  int _shortBreakDuration = 5 * 60;
  int _longBreakDuration = 15 * 60;

  int _secondsRemaining = 25 * 60;
  bool _isRunning = false;
  Timer? _timer;

  int _sessionsCompleted = 0;
  bool _isDarkMode = true;
  String _userName = 'Abc';
  int _streakCount = 0;
  List<String> _completedDates = [];
  int _cyclesBeforeLongBreak = 4;
  bool _isSoundEnabled = true;
  bool _isNotificationsEnabled = true;
  bool _isVibrationEnabled = true;
  bool _isCycleModeEnabled = true;

  TimerService() {
    _init();
  }

  // Getters
  TimerMode get mode => _mode;
  int get secondsRemaining => _secondsRemaining;
  bool get isRunning => _isRunning;
  int get sessionsCompleted => _sessionsCompleted;
  bool get isDarkMode => _isDarkMode;
  String get userName => _userName;
  int get streakCount => _streakCount;
  List<String> get completedDates => _completedDates;
  int get cyclesBeforeLongBreak => _cyclesBeforeLongBreak;
  bool get isSoundEnabled => _isSoundEnabled;
  bool get isNotificationsEnabled => _isNotificationsEnabled;
  bool get isVibrationEnabled => _isVibrationEnabled;
  bool get isCycleModeEnabled => _isCycleModeEnabled;

  int get currentMaxSeconds {
    switch (_mode) {
      case TimerMode.focus:
        return _focusDuration;
      case TimerMode.shortBreak:
        return _shortBreakDuration;
      case TimerMode.longBreak:
        return _longBreakDuration;
    }
  }

  int get focusDurationMinutes => _focusDuration ~/ 60;
  int get shortBreakDurationMinutes => _shortBreakDuration ~/ 60;
  int get longBreakDurationMinutes => _longBreakDuration ~/ 60;

  Future<void> _init() async {
    // Load Settings from SQLite
    final String? focusStr = await _db.getSetting('focusDuration');
    _focusDuration = (int.tryParse(focusStr ?? '25') ?? 25) * 60;

    final String? shortStr = await _db.getSetting('shortBreakDuration');
    _shortBreakDuration = (int.tryParse(shortStr ?? '5') ?? 5) * 60;

    final String? longStr = await _db.getSetting('longBreakDuration');
    _longBreakDuration = (int.tryParse(longStr ?? '15') ?? 15) * 60;

    final String? darkStr = await _db.getSetting('isDarkMode');
    _isDarkMode = darkStr == 'false' ? false : true;

    _userName = await _db.getSetting('userName') ?? 'Abc';

    final String? cyclesStr = await _db.getSetting('cyclesBeforeLongBreak');
    _cyclesBeforeLongBreak = int.tryParse(cyclesStr ?? '4') ?? 4;

    final String? soundStr = await _db.getSetting('isSoundEnabled');
    _isSoundEnabled = soundStr == 'false' ? false : true;

    final String? notifStr = await _db.getSetting('isNotificationsEnabled');
    _isNotificationsEnabled = notifStr == 'false' ? false : true;

    final String? vibStr = await _db.getSetting('isVibrationEnabled');
    _isVibrationEnabled = vibStr == 'false' ? false : true;

    final String? cycleModeStr = await _db.getSetting('isCycleModeEnabled');
    _isCycleModeEnabled = cycleModeStr == 'false' ? false : true;

    // Load Session Data
    _sessionsCompleted = await _db.getTotalSessions();
    _completedDates = await _db.getCompletedDates();
    _calculateStreak();

    _secondsRemaining = _focusDuration;

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    await _notificationsPlugin.initialize(initializationSettings);

    notifyListeners();
  }

  void startTimer() {
    if (_isRunning) return;
    _isRunning = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        _secondsRemaining--;
        notifyListeners();
      } else {
        _onTimerComplete();
      }
    });
    notifyListeners();
  }

  void pauseTimer() {
    _isRunning = false;
    _timer?.cancel();
    notifyListeners();
  }

  void resetTimer() {
    pauseTimer();
    _secondsRemaining = currentMaxSeconds;
    notifyListeners();
  }

  void setMode(TimerMode mode) {
    pauseTimer();
    _mode = mode;
    _secondsRemaining = currentMaxSeconds;
    notifyListeners();
  }

  Future<void> _onTimerComplete() async {
    pauseTimer();
    await _playNotificationSound();

    if (_mode == TimerMode.focus) {
      // Focus session ended
      await _showNotification('Focus Session Ended', 'Time for a break!');
      await _triggerVibration();

      String today = DateTime.now().toIso8601String().split('T')[0];
      await _db.addSession(today, 'focus');

      _sessionsCompleted = await _db.getTotalSessions();
      _completedDates = await _db.getCompletedDates();
      _calculateStreak();

      if (_isCycleModeEnabled) {
        if (_sessionsCompleted % _cyclesBeforeLongBreak == 0) {
          setMode(TimerMode.longBreak);
        } else {
          setMode(TimerMode.shortBreak);
        }
      }
    } else {
      // Break ended
      if (_isCycleModeEnabled) {
        await _showNotification(
          'Cycle Completed! 🎯',
          'Focus + Break finished. Ready for the next one?',
        );
        await _triggerVibration(isLong: true);
        setMode(TimerMode.focus);
      } else {
        await _showNotification('Break Ended', 'Ready to start again?');
        await _triggerVibration();
      }
    }

    notifyListeners();
  }

  void _calculateStreak() {
    if (_completedDates.isEmpty) {
      _streakCount = 0;
    } else {
      _completedDates.sort();
      int streak = 1;

      DateTime today = DateTime.parse(
        DateTime.now().toIso8601String().split('T')[0],
      );
      DateTime lastSession = DateTime.parse(_completedDates.last);

      if (today.difference(lastSession).inDays > 1) {
        _streakCount = 0;
        return;
      }

      for (int i = _completedDates.length - 2; i >= 0; i--) {
        DateTime current = DateTime.parse(_completedDates[i]);
        DateTime next = DateTime.parse(_completedDates[i + 1]);
        if (next.difference(current).inDays == 1) {
          streak++;
        } else if (next.difference(current).inDays > 1) {
          break;
        }
      }
      _streakCount = streak;
    }
  }

  Future<void> _playNotificationSound() async {
    if (!_isSoundEnabled) return;
    try {
      await _audioPlayer.play(AssetSource('beep.mp3'));
    } catch (e) {
      debugPrint("Error playing sound: $e");
    }
  }

  Future<void> _showNotification(String title, String body) async {
    if (!_isNotificationsEnabled) return;

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'pomodoro_channel',
          'Pomodoro Notifications',
          importance: Importance.max,
          priority: Priority.high,
          showWhen: true,
        );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );
    await _notificationsPlugin.show(0, title, body, platformChannelSpecifics);
  }

  Future<void> _triggerVibration({bool isLong = false}) async {
    if (!_isVibrationEnabled) return;
    if (await Vibration.hasVibrator() ?? false) {
      if (isLong) {
        Vibration.vibrate(
          pattern: [0, 500, 200, 500],
        ); // Specific pattern for cycle completion
      } else {
        Vibration.vibrate(duration: 800);
      }
    }
  }

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    _db.saveSetting('isDarkMode', _isDarkMode.toString());
    notifyListeners();
  }

  void updateDurations(
    int focus,
    int short,
    int long, [
    int? cycles,
    bool? cycleMode,
  ]) {
    _focusDuration = focus * 60;
    _shortBreakDuration = short * 60;
    _longBreakDuration = long * 60;
    if (cycles != null) _cyclesBeforeLongBreak = cycles;
    if (cycleMode != null) _isCycleModeEnabled = cycleMode;

    _db.saveSetting('focusDuration', focus.toString());
    _db.saveSetting('shortBreakDuration', short.toString());
    _db.saveSetting('longBreakDuration', long.toString());
    if (cycles != null) {
      _db.saveSetting('cyclesBeforeLongBreak', cycles.toString());
    }
    if (cycleMode != null) {
      _db.saveSetting('isCycleModeEnabled', cycleMode.toString());
    }

    if (!_isRunning) {
      _secondsRemaining = currentMaxSeconds;
    }
    notifyListeners();
  }

  void toggleCycleMode() {
    _isCycleModeEnabled = !_isCycleModeEnabled;
    _db.saveSetting('isCycleModeEnabled', _isCycleModeEnabled.toString());
    notifyListeners();
  }

  void toggleSound() {
    _isSoundEnabled = !_isSoundEnabled;
    _db.saveSetting('isSoundEnabled', _isSoundEnabled.toString());
    notifyListeners();
  }

  void toggleNotifications() {
    _isNotificationsEnabled = !_isNotificationsEnabled;
    _db.saveSetting(
      'isNotificationsEnabled',
      _isNotificationsEnabled.toString(),
    );
    notifyListeners();
  }

  void toggleVibration() {
    _isVibrationEnabled = !_isVibrationEnabled;
    _db.saveSetting('isVibrationEnabled', _isVibrationEnabled.toString());
    notifyListeners();
  }

  void updateUserName(String name) {
    _userName = name;
    _db.saveSetting('userName', name);
    notifyListeners();
  }

  String get timeString {
    int minutes = _secondsRemaining ~/ 60;
    int seconds = _secondsRemaining % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
