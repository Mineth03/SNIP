import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../models/profile.dart';
import '../../../shared/widgets/snip_button.dart';
import '../../../shared/widgets/snip_text_field.dart';
import '../../../theme/snip_colors.dart';
import '../../../theme/snip_spacing.dart';
import '../providers/auth_providers.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  UserRole _role = UserRole.customer;
  bool _obscure = true;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authControllerProvider.notifier).signUp(
          email: _email.text,
          password: _password.text,
          fullName: _name.text,
          role: _role,
          phone: _phone.text,
        );
    final state = ref.read(authControllerProvider);
    if (!mounted) return;
    if (state.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.error.toString())),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account created. You can sign in now.')),
      );
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Create account')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(SnipSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Join SNIP',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: SnipSpacing.sm),
                Text(
                  'Book salons or manage your business.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: SnipColors.secondaryText,
                      ),
                ),
                const SizedBox(height: SnipSpacing.lg),
                Text('I am a', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: SnipSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: _RoleChip(
                        label: 'Customer',
                        selected: _role == UserRole.customer,
                        onTap: () => setState(() => _role = UserRole.customer),
                      ),
                    ),
                    const SizedBox(width: SnipSpacing.sm),
                    Expanded(
                      child: _RoleChip(
                        label: 'Salon owner',
                        selected: _role == UserRole.salonOwner,
                        onTap: () => setState(() => _role = UserRole.salonOwner),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: SnipSpacing.lg),
                SnipTextField(
                  controller: _name,
                  label: 'Full name',
                  prefixIcon: Icons.person_outline,
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Name is required' : null,
                ),
                const SizedBox(height: SnipSpacing.md),
                SnipTextField(
                  controller: _email,
                  label: 'Email',
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.email_outlined,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Email is required';
                    if (!v.contains('@')) return 'Enter a valid email';
                    return null;
                  },
                ),
                const SizedBox(height: SnipSpacing.md),
                SnipTextField(
                  controller: _phone,
                  label: 'Phone (optional)',
                  keyboardType: TextInputType.phone,
                  prefixIcon: Icons.phone_outlined,
                ),
                const SizedBox(height: SnipSpacing.md),
                SnipTextField(
                  controller: _password,
                  label: 'Password',
                  obscureText: _obscure,
                  prefixIcon: Icons.lock_outline,
                  suffixIcon: IconButton(
                    icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                  validator: (v) {
                    if (v == null || v.length < 6) return 'Min 6 characters';
                    return null;
                  },
                ),
                const SizedBox(height: SnipSpacing.xl),
                PrimaryCTA(
                  label: 'Create account',
                  isLoading: authState.isLoading,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  const _RoleChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(SnipSpacing.radiusSm),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: SnipSpacing.md),
        decoration: BoxDecoration(
          color: selected
              ? SnipColors.primary.withValues(alpha: 0.12)
              : SnipColors.lightGray,
          borderRadius: BorderRadius.circular(SnipSpacing.radiusSm),
          border: Border.all(
            color: selected ? SnipColors.primary : Colors.transparent,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: selected ? SnipColors.primary : SnipColors.dark,
              ),
        ),
      ),
    );
  }
}
