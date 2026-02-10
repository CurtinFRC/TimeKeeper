import 'package:flutter/material.dart';
import 'package:time_keeper/generated/db/db.pb.dart';
import 'package:time_keeper/utils/time.dart';

enum SessionStatus { current, overtime, upcoming, finished }

SessionStatus getSessionStatus(Session session) {
  if (session.finished) return SessionStatus.finished;

  final now = DateTime.now();
  final start = session.startTime.toDateTime();
  final end = session.endTime.toDateTime();

  if (now.isBefore(start)) return SessionStatus.upcoming;
  if (now.isAfter(end)) return SessionStatus.overtime;
  return SessionStatus.current;
}

Color statusColor(SessionStatus status) {
  switch (status) {
    case SessionStatus.current:
      return Colors.green;
    case SessionStatus.overtime:
      return Colors.red;
    case SessionStatus.upcoming:
      return Colors.blue;
    case SessionStatus.finished:
      return Colors.grey;
  }
}

String statusLabel(SessionStatus status) {
  switch (status) {
    case SessionStatus.current:
      return 'Current';
    case SessionStatus.overtime:
      return 'OVERTIME';
    case SessionStatus.upcoming:
      return 'Upcoming';
    case SessionStatus.finished:
      return 'Finished';
  }
}

/// Sort: current/overtime first, then upcoming (soonest first), then finished (newest first).
int compareSessionEntries(
  MapEntry<String, Session> a,
  MapEntry<String, Session> b,
) {
  final aStatus = getSessionStatus(a.value);
  final bStatus = getSessionStatus(b.value);

  const order = {
    SessionStatus.current: 0,
    SessionStatus.overtime: 0,
    SessionStatus.upcoming: 1,
    SessionStatus.finished: 2,
  };

  final statusCmp = order[aStatus]!.compareTo(order[bStatus]!);
  if (statusCmp != 0) return statusCmp;

  final aTime = a.value.startTime.toDateTime();
  final bTime = b.value.startTime.toDateTime();

  // Upcoming: soonest first. Current/Overtime/Finished: newest first.
  if (aStatus == SessionStatus.upcoming) {
    return aTime.compareTo(bTime);
  }
  return bTime.compareTo(aTime);
}

// Date/time formatting

const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

String formatDate(DateTime dt) {
  final weekday = _weekdays[dt.weekday - 1];
  final month = _months[dt.month - 1];
  return '$weekday, $month ${dt.day}';
}

String formatTime(DateTime dt) {
  final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
  final minute = dt.minute.toString().padLeft(2, '0');
  final period = dt.hour < 12 ? 'AM' : 'PM';
  return '$hour:$minute $period';
}

String formatDuration(Duration d) {
  final hours = d.inHours;
  final minutes = d.inMinutes.remainder(60);
  if (hours > 0) return '${hours}h ${minutes}m';
  return '${minutes}m';
}
