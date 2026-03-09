import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../timer_service.dart';
import '../theme.dart';

class SettingsDialog extends StatefulWidget {
  const SettingsDialog({super.key});

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  late double _focus;
  late double _short;
  late double _long;
  late double _cycles;
  late bool _sound;
  late bool _notifications;
  late bool _vibration;
  late bool _cycleMode;

  @override
  void initState() {
    super.initState();
    final timerService = context.read<TimerService>();
    _focus = timerService.focusDurationMinutes.toDouble();
    _short = timerService.shortBreakDurationMinutes.toDouble();
    _long = timerService.longBreakDurationMinutes.toDouble();
    _cycles = timerService.cyclesBeforeLongBreak.toDouble();
    _sound = timerService.isSoundEnabled;
    _notifications = timerService.isNotificationsEnabled;
    _vibration = timerService.isVibrationEnabled;
    _cycleMode = timerService.isCycleModeEnabled;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = AppTheme.accentColor;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [const Color(0xFF0F0F0F), const Color(0xFF1A1A1A)]
                : [const Color(0xFFF5F7FA), const Color(0xFFE4E7EB)],
          ),
        ),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: SafeArea(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                children: [
                  _buildSection('TEMPO', [
                    _buildGlassSlider(
                      icon: Icons.timer_outlined,
                      label: 'Focus',
                      value: _focus,
                      min: 1,
                      max: 90,
                      suffix: 'min',
                      onChanged: (v) => setState(() => _focus = v),
                    ),
                    _buildGlassSlider(
                      icon: Icons.coffee_rounded,
                      label: 'Short Break',
                      value: _short,
                      min: 1,
                      max: 30,
                      suffix: 'min',
                      onChanged: (v) => setState(() => _short = v),
                    ),
                    _buildGlassSlider(
                      icon: Icons.bedtime_rounded,
                      label: 'Long Break',
                      value: _long,
                      min: 5,
                      max: 60,
                      suffix: 'min',
                      onChanged: (v) => setState(() => _long = v),
                    ),
                  ]),
                  const SizedBox(height: 24),
                  _buildSection('RHYTHM', [
                    _buildGlassToggle(
                      icon: Icons.loop_rounded,
                      label: 'Auto-Cycle Mode',
                      value: _cycleMode,
                      onChanged: (v) => setState(() => _cycleMode = v),
                    ),
                    if (_cycleMode)
                      _buildGlassSlider(
                        icon: Icons.repeat_rounded,
                        label: 'Sets per Cycle',
                        value: _cycles,
                        min: 1,
                        max: 10,
                        suffix: 'sets',
                        onChanged: (v) => setState(() => _cycles = v),
                      ),
                  ]),
                  const SizedBox(height: 24),
                  _buildSection('SENSES', [
                    _buildGlassToggle(
                      icon: Icons.volume_up_rounded,
                      label: 'Sound Effects',
                      value: _sound,
                      onChanged: (v) => setState(() => _sound = v),
                    ),
                    _buildGlassToggle(
                      icon: Icons.notifications_active_rounded,
                      label: 'Push Notifs',
                      value: _notifications,
                      onChanged: (v) => setState(() => _notifications = v),
                    ),
                    _buildGlassToggle(
                      icon: Icons.vibration_rounded,
                      label: 'Haptic Feedback',
                      value: _vibration,
                      onChanged: (v) => setState(() => _vibration = v),
                    ),
                  ]),
                  const SizedBox(height: 40),
                  GestureDetector(
                    onTap: () {
                      final timerService = context.read<TimerService>();
                      timerService.updateDurations(
                        _focus.toInt(),
                        _short.toInt(),
                        _long.toInt(),
                        _cycles.toInt(),
                        _cycleMode,
                      );
                      if (timerService.isSoundEnabled != _sound)
                        timerService.toggleSound();
                      if (timerService.isNotificationsEnabled !=
                          _notifications) {
                        timerService.toggleNotifications();
                      }
                      if (timerService.isVibrationEnabled != _vibration) {
                        timerService.toggleVibration();
                      }
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [accentColor, accentColor.withOpacity(0.8)],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: accentColor.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          'APPLY SETTINGS',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2.0,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 12),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.5,
              color: Colors.grey,
            ),
          ),
        ),
        ...children,
      ],
    );
  }

  Widget _buildGlassCard({required Widget child}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.05)
            : Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.1)
              : Colors.black.withOpacity(0.05),
          width: 0.5,
        ),
      ),
      child: child,
    );
  }

  Widget _buildGlassSlider({
    required IconData icon,
    required String label,
    required double value,
    required double min,
    required double max,
    required String suffix,
    required ValueChanged<double> onChanged,
  }) {
    final accentColor = AppTheme.accentColor;
    return _buildGlassCard(
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: accentColor),
              const SizedBox(width: 12),
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              Text(
                '${value.toInt()} $suffix',
                style: TextStyle(
                  color: accentColor,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 2,
              activeTrackColor: accentColor,
              inactiveTrackColor: accentColor.withOpacity(0.1),
              thumbColor: accentColor,
              overlayColor: accentColor.withOpacity(0.1),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassToggle({
    required IconData icon,
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final accentColor = AppTheme.accentColor;
    return _buildGlassCard(
      child: Row(
        children: [
          Icon(icon, size: 20, color: accentColor),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const Spacer(),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: accentColor,
          ),
        ],
      ),
    );
  }
}
