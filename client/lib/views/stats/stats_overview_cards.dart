import 'package:flutter/material.dart';
import 'package:time_keeper/generated/db/db.pb.dart';
import 'package:time_keeper/utils/time.dart';
import 'package:time_keeper/views/stats/stats_helpers.dart';

class StatsOverviewCards extends StatelessWidget {
  final Map<String, Session> filteredSessions;
  final Map<String, MemberHoursData> memberHours;
  final AttendanceInsights insights;

  const StatsOverviewCards({
    super.key,
    required this.filteredSessions,
    required this.memberHours,
    required this.insights,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    double totalRegular = 0;
    double totalOvertime = 0;
    for (final h in memberHours.values) {
      totalRegular += h.regularSecs;
      totalOvertime += h.overtimeSecs;
    }

    // Average scheduled session duration
    double avgSessionDuration = 0;
    final sessionsWithTimes = filteredSessions.values
        .where((s) => s.hasStartTime() && s.hasEndTime())
        .toList();
    if (sessionsWithTimes.isNotEmpty) {
      double totalScheduledSecs = 0;
      for (final s in sessionsWithTimes) {
        totalScheduledSecs += s.endTime
            .toDateTime()
            .difference(s.startTime.toDateTime())
            .inSeconds;
      }
      avgSessionDuration = totalScheduledSecs / sessionsWithTimes.length;
    }

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _StatCard(
          icon: Icons.event,
          label: 'Total Sessions',
          value: '${filteredSessions.length}',
          color: theme.colorScheme.primary,
        ),
        _StatCard(
          icon: Icons.schedule,
          label: 'Total Hours',
          value: formatSecsAsHoursMinutes(totalRegular + totalOvertime),
          color: theme.colorScheme.secondary,
        ),
        _StatCard(
          icon: Icons.timer,
          label: 'Avg Session Duration',
          value: formatSecsAsHoursMinutes(avgSessionDuration),
          color: Colors.blue,
        ),
        _StatCard(
          icon: Icons.warning_amber,
          label: 'Total Overtime',
          value: formatSecsAsHoursMinutes(totalOvertime),
          color: theme.colorScheme.error,
        ),
        _StatCard(
          icon: Icons.people,
          label: 'Unique Members',
          value: '${insights.uniqueMembers}',
          color: Colors.green,
        ),
        _StatCard(
          icon: Icons.groups,
          label: 'Avg Attendance',
          value: insights.avgAttendancePerSession.toStringAsFixed(1),
          color: theme.colorScheme.tertiary,
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
