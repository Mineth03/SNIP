import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/snip_button.dart';
import '../../../theme/snip_colors.dart';
import '../../../theme/snip_spacing.dart';
import '../providers/auth_providers.dart';
import '../../../repositories/auth_repository.dart';
import '../../../repositories/profile_repository.dart';

class InviteBarberScreen extends ConsumerStatefulWidget {
  const InviteBarberScreen({super.key, required this.token});

  final String token;

  @override
  ConsumerState<InviteBarberScreen> createState() => _InviteBarberScreenState();
}

class _InviteBarberScreenState extends ConsumerState<InviteBarberScreen> {
  bool _accepting = false;
  String? _error;
  bool _done = false;

  Future<void> _accept() async {
    setState(() {
      _accepting = true;
      _error = null;
    });
    try {
      await ref
          .read(profileRepositoryProvider)
          .acceptBarberInvite(widget.token);
      ref.invalidate(currentProfileProvider);
      setState(() => _done = true);
      if (mounted) context.go('/barber/dashboard');
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _accepting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authRepositoryProvider).currentSession;
    final authed = session != null;

    return Scaffold(
      appBar: AppBar(title: const Text('Salon invitation')),
      body: Padding(
        padding: const EdgeInsets.all(SnipSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.token.isEmpty)
              const Text(
                'Missing invitation token.',
                style: TextStyle(color: SnipColors.error),
              )
            else if (_error != null)
              Text(_error!, style: const TextStyle(color: SnipColors.error))
            else if (_done)
              const Text('You’re on the salon team!')
            else if (!authed) ...[
              const Text(
                'Sign in or create a free SNIP customer account with the invited email, then return here to join the salon team.',
              ),
              const SizedBox(height: SnipSpacing.md),
              PrimaryCTA(
                label: 'Sign in',
                onPressed: () => context.go(
                  '/login?next=${Uri.encodeComponent('/invite/barber?token=${widget.token}')}',
                ),
              ),
              const SizedBox(height: SnipSpacing.sm),
              OutlinedButton(
                onPressed: () => context.go('/register'),
                child: const Text('Create account'),
              ),
            ] else ...[
              const Text(
                'Accept this invitation to join the salon as a barber. You can keep booking as a customer and switch views from your profile.',
              ),
              const SizedBox(height: SnipSpacing.md),
              PrimaryCTA(
                label: _accepting ? 'Accepting...' : 'Accept invitation',
                isLoading: _accepting,
                onPressed: _accept,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
