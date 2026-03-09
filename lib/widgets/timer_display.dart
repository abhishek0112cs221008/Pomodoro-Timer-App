import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../timer_service.dart';
import '../theme.dart';

class TimerDisplay extends StatelessWidget {
  const TimerDisplay({super.key});

  @override
  Widget build(BuildContext context) {
    final timerService = context.watch<TimerService>();
    final accentColor = AppTheme.accentColor;

    double percent =
        timerService.secondsRemaining / timerService.currentMaxSeconds;
    // Ensure percent is between 0 and 1
    percent = percent.clamp(0.0, 1.0);

    return CircularPercentIndicator(
      radius: 120.0,
      lineWidth: 8.0,
      percent: percent,
      center: Text(
        timerService.timeString,
        style: const TextStyle(
          fontSize: 64,
          fontWeight: FontWeight.w200,
          fontFamily: 'monospace', // Or a custom clean font if available
        ),
      ),
      progressColor: accentColor,
      backgroundColor: accentColor.withOpacity(0.1),
      circularStrokeCap: CircularStrokeCap.round,
      animateFromLastPercent: true,
      curve: Curves.easeInOut,
    );
  }
}
