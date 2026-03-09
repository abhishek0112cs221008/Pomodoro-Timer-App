import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'timer_service.dart';
import 'theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final timerService = context.watch<TimerService>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = AppTheme.accentColor;
    final cardColor = isDark ? Colors.grey[900] : Colors.grey[200];

    // Greeting logic
    String greeting = "Good ";
    var hour = DateTime.now().hour;
    if (hour < 12) {
      greeting += "morning";
    } else if (hour < 17) {
      greeting += "afternoon";
    } else {
      greeting += "evening";
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Profile Image
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 80,
                    backgroundColor: accentColor.withOpacity(0.1),
                    backgroundImage: const AssetImage('assets/pic.jpg'),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: accentColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          width: 3,
                        ),
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Name / Greeting
            GestureDetector(
              onTap: () => _showEditNameDialog(context, timerService),
              child: RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                  children: [
                    TextSpan(text: '$greeting, '),
                    TextSpan(
                      text: timerService.userName,
                      style: TextStyle(
                        decoration: TextDecoration.underline,
                        decorationColor: accentColor.withOpacity(0.5),
                        decorationThickness: 2,
                      ),
                    ),
                    const TextSpan(text: '!'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
            // Streak Card
            _buildCard(
              context,
              cardColor!,
              child: Column(
                children: [
                  const Icon(
                    Icons.local_fire_department,
                    color: Colors.orange,
                    size: 40,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${timerService.streakCount}-day streak',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Streak Calendar Grid (Last 14 days)
                  _buildStreakCalendar(timerService),
                  const SizedBox(height: 16),
                  Text(
                    'Start your journey!',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Rewards Tree Section
            _buildCard(
              context,
              cardColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Milestones',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildRewardTree(timerService, isDark),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildRewardTree(TimerService timerService, bool isDark) {
    final levels = [
      {
        'name': 'Bronze',
        'count': 25,
        'color': Colors.orange[700],
        'icon': Icons.workspace_premium,
        'diff': 'Easy',
      },
      {
        'name': 'Silver',
        'count': 50,
        'color': Colors.blueGrey[300],
        'icon': Icons.shield,
        'diff': 'Medium',
      },
      {
        'name': 'Gold',
        'count': 100,
        'color': Colors.amber,
        'icon': Icons.emoji_events,
        'diff': 'Hard',
      },
      {
        'name': 'Diamond',
        'count': 250,
        'color': Colors.cyanAccent,
        'icon': Icons.diamond,
        'diff': 'Expert',
      },
      {
        'name': 'Platinum',
        'count': 500,
        'color': Colors.purpleAccent,
        'icon': Icons.stars,
        'diff': 'Legendary',
      },
    ];

    final int currentCount = timerService.sessionsCompleted;

    return Column(
      children: List.generate(levels.length, (index) {
        final level = levels[index];
        final bool isLast = index == levels.length - 1;
        final int target = level['count'] as int;
        final bool reached = currentCount >= target;
        final Color levelColor = level['color'] as Color;

        bool isCurrentTarget = false;
        if (!reached) {
          final bool prevReached = index == 0
              ? true
              : currentCount >= (levels[index - 1]['count'] as int);
          if (prevReached) isCurrentTarget = true;
        }

        double subProgress = 0.0;
        if (isCurrentTarget) {
          final int prevTarget = index == 0
              ? 0
              : levels[index - 1]['count'] as int;
          subProgress = (currentCount - prevTarget) / (target - prevTarget);
        }

        return Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Node & Title ──────────────────────────────────────────
                SizedBox(
                  width: 36,
                  child: Center(
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: reached
                            ? levelColor
                            : (isCurrentTarget
                                  ? levelColor.withOpacity(0.12)
                                  : Colors.grey.withOpacity(0.08)),
                        border: Border.all(
                          color: reached
                              ? levelColor
                              : (isCurrentTarget
                                    ? levelColor
                                    : Colors.grey.withOpacity(0.25)),
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        level['icon'] as IconData,
                        size: 16,
                        color: reached
                            ? Colors.white
                            : (isCurrentTarget ? levelColor : Colors.grey),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text(
                            level['name'] as String,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: reached
                                  ? (isDark ? Colors.white : Colors.black87)
                                  : Colors.grey[400],
                            ),
                          ),
                          const Spacer(),
                          if (reached)
                            const Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 16,
                            )
                          else
                            Text(
                              level['diff'] as String,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.1,
                                color: isCurrentTarget
                                    ? levelColor
                                    : Colors.grey.withOpacity(0.3),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Line & SubContent ─────────────────────────────────────
                SizedBox(
                  width: 36,
                  child: isLast
                      ? const SizedBox()
                      : Center(
                          child: Container(
                            width: 2,
                            height: isCurrentTarget
                                ? 80
                                : 30, // Natural spacing
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(1),
                            ),
                            child: Align(
                              alignment: Alignment.topCenter,
                              child: FractionallySizedBox(
                                heightFactor: reached
                                    ? 1.0
                                    : (isCurrentTarget ? subProgress : 0.0),
                                child: Container(width: 2, color: levelColor),
                              ),
                            ),
                          ),
                        ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isCurrentTarget) ...[
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: subProgress,
                            minHeight: 5,
                            backgroundColor: levelColor.withOpacity(0.1),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              levelColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${target - currentCount} sessions to ${level['name']}  •  ${(subProgress * 100).toInt()}%',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                      ] else if (!reached) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Unlocks at $target sessions',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ] else ...[
                        const SizedBox(height: 4),
                        Text(
                          'Unlocked at $target sessions ✓',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green.withOpacity(0.7),
                          ),
                        ),
                      ],
                      if (!isLast) const SizedBox(height: 20),
                    ],
                  ),
                ),
              ],
            ),
          ],
        );
      }),
    );
  }

  Widget _buildStreakCalendar(TimerService timerService) {
    final now = DateTime.now();
    final todayStr = now.toIso8601String().split('T')[0];
    final dates = List.generate(14, (index) {
      return now.subtract(Duration(days: 13 - index));
    });

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: dates.map((date) {
        String dateStr = date.toIso8601String().split('T')[0];
        bool completed = timerService.completedDates.contains(dateStr);
        bool isToday = dateStr == todayStr;
        return Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: completed
                ? AppTheme.accentColor
                : (isToday
                      ? AppTheme.accentColor.withOpacity(0.2)
                      : Colors.grey.withOpacity(0.1)),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: completed
                  ? AppTheme.accentColor
                  : (isToday
                        ? AppTheme.accentColor
                        : Colors.grey.withOpacity(0.3)),
              width: isToday ? 2 : 1,
            ),
          ),
          child: Center(
            child: Text(
              date.day.toString(),
              style: TextStyle(
                fontSize: 10,
                color: completed
                    ? Colors.white
                    : (isToday ? AppTheme.accentColor : Colors.grey),
                fontWeight: (completed || isToday)
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  void _showEditNameDialog(BuildContext context, TimerService timerService) {
    final controller = TextEditingController(text: timerService.userName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Name'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Enter your name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                timerService.updateUserName(controller.text.trim());
              }
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(
    BuildContext context,
    Color color, {
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(24),
      ),
      child: child,
    );
  }
}
