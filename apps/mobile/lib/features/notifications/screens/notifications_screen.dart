import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../repositories/notification_repository.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/loading_skeleton.dart';
import '../../../theme/snip_colors.dart';
import '../../../theme/snip_spacing.dart';
import '../../auth/providers/auth_providers.dart';

final notificationsProvider = FutureProvider.autoDispose((ref) async {
  final profile = await ref.watch(currentProfileProvider.future);
  if (profile == null) return [];
  return ref.watch(notificationRepositoryProvider).getNotifications(profile.id);
});

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(notificationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () async {
              final profile = ref.read(currentProfileProvider).valueOrNull;
              if (profile == null) return;
              await ref
                  .read(notificationRepositoryProvider)
                  .markAllRead(profile.id);
              ref.invalidate(notificationsProvider);
            },
            child: const Text('Mark all read'),
          ),
        ],
      ),
      body: async.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(SnipSpacing.md),
          child: ListSkeleton(),
        ),
        error: (e, _) => Center(child: Text('$e')),
        data: (items) {
          if (items.isEmpty) {
            return const EmptyState(
              title: 'All caught up',
              message: 'No notifications yet.',
              icon: Icons.notifications_none,
            );
          }
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final n = items[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: n.isRead
                      ? SnipColors.lightGray
                      : SnipColors.primary.withValues(alpha: 0.15),
                  child: Icon(
                    Icons.notifications_outlined,
                    color: n.isRead ? SnipColors.secondaryText : SnipColors.primary,
                  ),
                ),
                title: Text(
                  n.title,
                  style: TextStyle(
                    fontWeight: n.isRead ? FontWeight.w500 : FontWeight.w700,
                  ),
                ),
                subtitle: Text(n.message),
                onTap: () async {
                  await ref
                      .read(notificationRepositoryProvider)
                      .markAsRead(n.id);
                  ref.invalidate(notificationsProvider);
                },
              );
            },
          );
        },
      ),
    );
  }
}
