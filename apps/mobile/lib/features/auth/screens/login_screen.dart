import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/snip_button.dart';
import '../../../shared/widgets/snip_logo.dart';
import '../../../shared/widgets/snip_text_field.dart';
import '../../../shared/widgets/theme_toggle_button.dart';
import '../../../theme/snip_colors.dart';
import '../../../theme/snip_spacing.dart';
import '../providers/auth_providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  String? _selectedDemo;

  static const _demoAccounts = [
    {'label': 'Client', 'email': 'customer@snip.demo'},
    {'label': 'Owner', 'email': 'owner@snip.demo'},
    {'label': 'Barber', 'email': 'barber@snip.demo'},
  ];

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _fillDemo(String label, String email) {
    setState(() {
      _selectedDemo = label;
      _email.text = email;
      _password.text = 'SnipPassword123!';
    });
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Loaded $label demo credentials'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authControllerProvider.notifier).signIn(
          email: _email.text.trim(),
          password: _password.text,
        );
    final state = ref.read(authControllerProvider);
    if (state.hasError && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.error.toString()),
          backgroundColor: SnipColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
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
                    // Brand Logo
                    const Center(
                      child: SnipLogo(
                        variant: SnipLogoVariant.stacked,
                        size: 88,
                      ),
                    ),
                    const SizedBox(height: SnipSpacing.xs),
                    Center(
                      child: Text(
                        'Smart Salon Booking & Management',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: SnipColors.secondaryText,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: SnipSpacing.xl),

                    // Auth Card Container
                    Container(
                      padding: const EdgeInsets.all(SnipSpacing.lg),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF162032) : Colors.white,
                        borderRadius: BorderRadius.circular(SnipSpacing.radiusMd),
                        border: Border.all(
                          color: isDark ? const Color(0xFF24334D) : SnipColors.border,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome back to SNIP',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Sign in to manage your bookings, grow your business, and keep beauty moving.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: SnipColors.secondaryText,
                            ),
                          ),
                          const SizedBox(height: SnipSpacing.md),

                          // Demo Accounts Quick Bar
                          Container(
                            padding: const EdgeInsets.all(SnipSpacing.sm),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF1E2D44)
                                  : SnipColors.lightGray.withValues(alpha: 0.6),
                              borderRadius:
                                  BorderRadius.circular(SnipSpacing.radiusSm),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.auto_awesome,
                                      size: 13,
                                      color: SnipColors.primary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'QUICK DEMO ACCOUNTS',
                                      style: theme.textTheme.labelSmall?.copyWith(
                                        color: SnipColors.primary,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: _demoAccounts.map((demo) {
                                    final isSelected =
                                        _selectedDemo == demo['label'];
                                    return Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 2.0),
                                        child: InkWell(
                                          onTap: () => _fillDemo(
                                              demo['label']!, demo['email']!),
                                          borderRadius: BorderRadius.circular(6),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isSelected
                                                  ? SnipColors.primary
                                                  : (isDark
                                                      ? const Color(0xFF2A3C5A)
                                                      : Colors.white),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              border: Border.all(
                                                color: isSelected
                                                    ? SnipColors.primary
                                                    : (isDark
                                                        ? const Color(0xFF3B4F73)
                                                        : SnipColors.border),
                                              ),
                                            ),
                                            alignment: Alignment.center,
                                            child: Text(
                                              demo['label']!,
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: isSelected
                                                    ? Colors.white
                                                    : (isDark
                                                        ? Colors.white70
                                                        : SnipColors.dark),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: SnipSpacing.md),

                          // Email Field
                          SnipTextField(
                            controller: _email,
                            label: 'Email',
                            hint: 'you@email.com',
                            keyboardType: TextInputType.emailAddress,
                            prefixIcon: Icons.email_outlined,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Email is required';
                              }
                              if (!v.contains('@')) return 'Enter a valid email';
                              return null;
                            },
                          ),
                          const SizedBox(height: SnipSpacing.md),

                          // Password Field
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
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () => context.push('/forgot-password'),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(50, 30),
                              ),
                              child: Text(
                                'Forgot password?',
                                style: TextStyle(
                                  color: SnipColors.primary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: SnipSpacing.sm),

                          // Primary CTA
                          PrimaryCTA(
                            label: 'Sign In →',
                            isLoading: authState.isLoading,
                            onPressed: _submit,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: SnipSpacing.lg),

                    // Bottom navigation to register
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account?",
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: SnipColors.secondaryText,
                          ),
                        ),
                        TextButton(
                          onPressed: () => context.push('/register'),
                          child: Text(
                            'Create account →',
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
