import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taxos_ui/taxos_ui.dart';

import '../../core/auth.dart';
import '../../core/settings.dart';

/// Opened from the profile icon on Home: who is signed in, and sign out.
Future<void> showAccountSheet(BuildContext context) => showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      builder: (_) => const _AccountSheet(),
    );

class _AccountSheet extends ConsumerWidget {
  const _AccountSheet();

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final t = context.ui;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Sign out?', style: Theme.of(ctx).textTheme.titleLarge),
        content: Text(
          'Your draft return on this phone will be cleared. Sign in again any time.',
          style: TextStyle(fontSize: 16, color: t.text, height: 1.4),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: t.negative),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (ok == true) {
      if (context.mounted) Navigator.of(context).pop();
      await ref.read(authProvider.notifier).signOut();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.ui;
    final session = ref.watch(authProvider).valueOrNull;
    final name = (session?.name.isNotEmpty ?? false) ? session!.name : 'Your account';
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Space.gutter, 0, Space.gutter, Space.gutter),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                IconWell(icon: Icons.person_outline, size: 52),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: Theme.of(context).textTheme.titleLarge),
                      if (session != null)
                        Text(session.maskedPhone, style: TextStyle(fontSize: 15, color: t.textMuted)),
                    ],
                  ),
                ),
              ],
            ),
            if (session?.demo ?? false) ...[
              const SizedBox(height: 16),
              const InfoCard(
                title: 'Demo sign-in',
                detail: 'This build runs on your phone only. Your data is not backed up.',
              ),
            ],
            const SizedBox(height: 24),
            AppButton(
              label: 'Sign out',
              icon: Icons.logout,
              style: AppButtonStyle.secondary,
              destructive: true,
              expand: true,
              onPressed: () => _confirmSignOut(context, ref),
            ),
            const SizedBox(height: 12),
            Text(
              '${AppConfig.appName} · ${AppConfig.tagline}',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: t.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
