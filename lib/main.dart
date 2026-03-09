import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme.dart';
import 'timer_service.dart';
import 'widgets/timer_display.dart';
import 'widgets/settings_dialog.dart';
import 'profile_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => TimerService(),
      child: const PomodoroApp(),
    ),
  );
}

class PomodoroApp extends StatelessWidget {
  const PomodoroApp({super.key});

  @override
  Widget build(BuildContext context) {
    final timerService = context.watch<TimerService>();
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pomodoro',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: timerService.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: const PomodoroHome(),
    );
  }
}

class PomodoroHome extends StatelessWidget {
  const PomodoroHome({super.key});

  @override
  Widget build(BuildContext context) {
    final timerService = context.watch<TimerService>();
    final accentColor = AppTheme.accentColor;

    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: IconButton(
            icon: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: accentColor.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: ClipOval(
                child: Transform.scale(
                  scale: 1.8, // 50% more zoomed
                  child: Image.asset('assets/pic.jpg', fit: BoxFit.cover),
                ),
              ),
            ),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfileScreen()),
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              timerService.isDarkMode ? Icons.light_mode : Icons.dark_mode,
            ),
            onPressed: () => timerService.toggleTheme(),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => showDialog(
              context: context,
              builder: (context) => const SettingsDialog(),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Mode Tabs
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _ModeTab(
                  label: 'Focus',
                  isActive: timerService.mode == TimerMode.focus,
                  onTap: () => timerService.setMode(TimerMode.focus),
                ),
                _ModeTab(
                  label: 'Short Break',
                  isActive: timerService.mode == TimerMode.shortBreak,
                  onTap: () => timerService.setMode(TimerMode.shortBreak),
                ),
                _ModeTab(
                  label: 'Long Break',
                  isActive: timerService.mode == TimerMode.longBreak,
                  onTap: () => timerService.setMode(TimerMode.longBreak),
                ),
              ],
            ),
            const SizedBox(height: 48),
            // Timer Display
            const TimerDisplay(),
            const SizedBox(height: 48),
            // Controls
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  iconSize: 48,
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Reset Timer?'),
                        content: const Text(
                          'Are you sure you want to reset the current session?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('CANCEL'),
                          ),
                          TextButton(
                            onPressed: () {
                              timerService.resetTimer();
                              Navigator.pop(context);
                            },
                            child: Text(
                              'RESET',
                              style: TextStyle(color: accentColor),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(width: 24),
                ElevatedButton(
                  onPressed: timerService.isRunning
                      ? () => timerService.pauseTimer()
                      : () => timerService.startTimer(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 48,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    timerService.isRunning ? 'PAUSE' : 'START',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 48),
            const SizedBox(height: 48),
            // Session Indicators (only if Cycle Mode is enabled)
            if (timerService.isCycleModeEnabled)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(timerService.cyclesBeforeLongBreak, (
                  index,
                ) {
                  int currentSessionInCycle =
                      timerService.sessionsCompleted %
                      timerService.cyclesBeforeLongBreak;
                  bool filled = index < currentSessionInCycle;

                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: filled
                            ? accentColor
                            : accentColor.withOpacity(0.3),
                      ),
                    ),
                  );
                }),
              ),
          ],
        ),
      ),
    );
  }
}

class _ModeTab extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _ModeTab({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = AppTheme.accentColor;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? accentColor : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive
                ? accentColor
                : Theme.of(
                    context,
                  ).textTheme.bodyLarge?.color?.withOpacity(0.6),
          ),
        ),
      ),
    );
  }
}
