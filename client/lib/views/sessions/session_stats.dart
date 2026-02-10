import 'package:flutter/material.dart';
import 'package:time_keeper/generated/db/db.pb.dart';
import 'package:time_keeper/utils/time.dart';
import 'package:time_keeper/views/sessions/session_helpers.dart';

class SessionStats extends StatelessWidget {
  final Map<String, Session> sessions;

  const SessionStats({super.key, required this.sessions});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();

    final activeSessions = sessions.values.where((s) {
      final status = getSessionStatus(s);
      return status == SessionStatus.current ||
          status == SessionStatus.overtime;
    }).length;
    final upcomingSessions = sessions.values
        .where((s) => getSessionStatus(s) == SessionStatus.upcoming)
        .length;
    final thisMonth = sessions.values.where((s) {
      final dt = s.startTime.toDateTime();
      return dt.year == now.year && dt.month == now.month;
    }).length;

    final uniqueMembers = <String>{};
    for (final session in sessions.values) {
      for (final ms in session.memberSessions) {
        uniqueMembers.add(ms.teamMemberId);
      }
    }

    return Row(
      children: [
        _StatCard(
          icon: Icons.event,
          label: 'Total',
          value: '${sessions.length}',
          color: theme.colorScheme.primary,
        ),
        const SizedBox(width: 12),
        _StatCard(
          icon: Icons.play_circle,
          label: 'Active',
          value: '$activeSessions',
          color: Colors.green,
        ),
        const SizedBox(width: 12),
        _StatCard(
          icon: Icons.schedule,
          label: 'Upcoming',
          value: '$upcomingSessions',
          color: Colors.blue,
        ),
        const SizedBox(width: 12),
        _StatCard(
          icon: Icons.calendar_month,
          label: 'This Month',
          value: '$thisMonth',
          color: theme.colorScheme.tertiary,
        ),
        const SizedBox(width: 12),
        _StatCard(
          icon: Icons.people,
          label: 'Unique Members',
          value: '${uniqueMembers.length}',
          color: theme.colorScheme.secondary,
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
