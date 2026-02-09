import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:time_keeper/generated/common/common.pbenum.dart';
import 'package:time_keeper/providers/auth_provider.dart';
import 'package:time_keeper/utils/permissions.dart';
import 'package:time_keeper/providers/session_provider.dart';
import 'package:time_keeper/utils/time.dart';
import 'package:time_keeper/views/home/checked_in_list.dart';
import 'package:time_keeper/views/home/kiosk_dialog.dart';
import 'package:time_keeper/views/home/session_info_bar.dart';

class HomeView extends ConsumerWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionList = ref.watch(sessionsProvider);

    // filter unfinished sessions sorted by start time
    final unfinishedSessions =
        sessionList.values
            .where((session) => !session.finished && session.hasStartTime())
            .toList()
          ..sort(
            (a, b) =>
                a.startTime.toDateTime().compareTo(b.startTime.toDateTime()),
          );

    final currentSession = unfinishedSessions.isNotEmpty
        ? unfinishedSessions.first
        : null;
    final nextSession = unfinishedSessions.length > 1
        ? unfinishedSessions[1]
        : null;

    final roles = ref.watch(rolesProvider);
    final hasKiosk = roles.any((role) => role.hasPermission(Role.KIOSK));

    return Column(
      children: [
        if (hasKiosk)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 8),
            child: Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                icon: const Icon(Icons.how_to_reg),
                label: const Text('Kiosk Check In / Out'),
                onPressed: () {
                  KioskDialog(sessions: unfinishedSessions).show(context);
                },
              ),
            ),
          ),
        SessionInfoBar(
          currentSession: currentSession,
          nextSession: nextSession,
        ),
        Expanded(child: CheckedInList(sessions: unfinishedSessions)),
      ],
    );
  }
}
