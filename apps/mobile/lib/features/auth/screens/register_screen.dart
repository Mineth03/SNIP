import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../models/profile.dart';
import '../../../shared/widgets/snip_button.dart';
import '../../../shared/widgets/snip_logo.dart';
import '../../../shared/widgets/snip_text_field.dart';
import '../../../shared/widgets/theme_toggle_button.dart';
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
          email: _email.text.trim(),
          password: _password.text,
          fullName: _name.text.trim(),
          role: _role,
          phone: _phone.text.trim(),
        );
    final state = ref.read(authControllerProvider);
    if (!mounted) return;
    if (state.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.error.toString()),
          backgroundColor: SnipColors.error,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account created! Please sign in.'),
          backgroundColor: SnipColors.primary,
        ),
      );
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
        actions: const [
          ThemeToggleButton(),
          SizedBox(width: SnipSpacing.sm),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: SnipSpacing.lg,
              vertical: SnipSpacing.sm,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Center(
                      child: SnipLogo(
                        variant: SnipLogoVariant.stacked,
                        size: 78,
                      ),
                    ),
                    const SizedBox(height: SnipSpacing.xs),
                    Center(
                      child: Text(
                        'Join thousands of satisfied clients and salons',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: SnipColors.secondaryText,
                        ),
                      ),
                    ),
                    const SizedBox(height: SnipSpacing.lg),

                    // Auth Card
                    Container(
                      padding: const EdgeInsets.all(SnipSpacing.lg),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF162032) : Colors.white,
                        borderRadius:
                            BorderRadius.circular(SnipSpacing.radiusMd),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF24334D)
                              : SnipColors.border,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black
                                .withValues(alpha: isDark ? 0.3 : 0.05),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Account Details',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: SnipSpacing.sm),

                          // Role selection cards
                          Text(
                            'I WANT TO JOIN AS:',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: SnipColors.secondaryText,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: SnipSpacing.xs),
                          Row(
                            children: [
                              Expanded(
                                child: _RoleCard(
                                  label: 'Customer',
                                  sublabel: 'Book & Queue',
                                  icon: Icons.person_rounded,
                                  selected: _role == UserRole.customer,
                                  isDark: isDark,
                                  onTap: () => setState(
                                      () => _role = UserRole.customer),
                                ),
                              ),
                              const SizedBox(width: SnipSpacing.sm),
                              Expanded(
                                child: _RoleCard(
                                  label: 'Salon Owner',
                                  sublabel: 'Manage Salon',
                                  icon: Icons.storefront_rounded,
                                  selected: _role == UserRole.salonOwner,
                                  isDark: isDark,
                                  onTap: () => setState(
                                      () => _role = UserRole.salonOwner),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: SnipSpacing.md),

                          // Full Name
                          SnipTextField(
                            controller: _name,
                            label: 'Full name',
                            hint: 'e.g. Alex Silva',
                            prefixIcon: Icons.person_outline,
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'Name is required'
                                : null,
                          ),
                          const SizedBox(height: SnipSpacing.md),

                          // Email
                          SnipTextField(
                            controller: _email,
                            label: 'Email',
                            hint: 'you@example.com',
                            keyboardType: TextInputType.emailAddress,
                            prefixIcon: Icons.email_outlined,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Email is required';
                              }
                              if (!v.contains('@')) {
                                return 'Enter a valid email';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: SnipSpacing.md),

                          // Phone
                          SnipTextField(
                            controller: _phone,
                            label: 'Phone (optional)',
                            hint: '+94 77 123 4567',
                            keyboardType: TextInputType.phone,
                            prefixIcon: Icons.phone_outlined,
                          ),
                          const SizedBox(height: SnipSpacing.md),

                          // Password
                          SnipTextField(
                            controller: _password,
                            label: 'Password',
                            hint: '••••••••',
                            obscureText: _obscure,
                            prefixIcon: Icons.lock_outline,
                            suffixIcon: IconButton(
                              icon: Icon(_obscure
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined),
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure),
                            ),
                            validator: (v) {
                              if (v == null || v.length < 6) {
                                return 'Min 6 characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: SnipSpacing.lg),

                          // CTA Button
                          PrimaryCTA(
                            label: 'Create account →',
                            isLoading: authState.isLoading,
                            onPressed: _submit,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: SnipSpacing.lg),

                    // Sign in link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Already have an account?',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: SnipColors.secondaryText,
                          ),
                        ),
                        TextButton(
                          onPressed: () => context.go('/login'),
                          child: Text(
                            'Sign In →',
                            style: TextStyle(
                              color: SnipColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.label,
    required this.sublabel,
    required this.icon,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  final String label;
  final String sublabel;
  final IconData icon;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(SnipSpacing.radiusSm),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(
          vertical: SnipSpacing.sm,
          horizontal: SnipSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: selected
              ? SnipColors.primary.withValues(alpha: isDark ? 0.2 : 0.08)
              : (isDark ? const Color(0xFF1E2D44) : SnipColors.lightGray),
          borderRadius: BorderRadius.circular(SnipSpacing.radiusSm),
          border: Border.all(
            color: selected
                ? SnipColors.primary
                : (isDark ? const Color(0xFF324666) : SnipColors.border),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 24,
              color: selected
                  ? SnipColors.primary
                  : (isDark ? Colors.white60 : SnipColors.secondaryText),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: selected
                    ? SnipColors.primary
                    : (isDark ? Colors.white : SnipColors.dark),
              ),
            ),
            Text(
              sublabel,
              style: TextStyle(
                fontSize: 10,
                color: isDark ? Colors.white54 : SnipColors.secondaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
