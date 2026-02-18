import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event_state.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  late AnimationController _animController;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeIn = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );
    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
    ));
    _animController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(AuthLoginRequested(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 800;

    return Scaffold(
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
              ),
            );
          }
        },
        child: Row(
          children: [
            // ── Left Panel: Hero (only on wide screens) ──
            if (isWide)
              Expanded(
                flex: 5,
                child: _buildHeroPanel(size),
              ),

            // ── Right Panel: Login Form ──
            Expanded(
              flex: isWide ? 4 : 1,
              child: _buildFormPanel(isWide),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroPanel(Size size) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.heroGradient,
      ),
      child: Stack(
        children: [
          // ── Geometric pattern overlay ──
          Positioned.fill(
            child: CustomPaint(
              painter: _SacredGeometryPainter(),
            ),
          ),

          // ── Content ──
          Padding(
            padding: const EdgeInsets.all(AppSpacing.huge),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Logo mark
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: const Center(
                    child: Text(
                      'IM',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                Text(
                  'Igreja\nManager',
                  style: AppTypography.displayLarge.copyWith(
                    color: Colors.white,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: AppSpacing.base),

                Container(
                  width: 48,
                  height: 3,
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                Text(
                  'Gestão inteligente para sua igreja.\nMembros, finanças, patrimônio e EBD\nem uma única plataforma.',
                  style: AppTypography.bodyLarge.copyWith(
                    color: Colors.white.withValues(alpha: 0.7),
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: AppSpacing.massive),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormPanel(bool isWide) {
    return Container(
      color: AppColors.background,
      child: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isWide ? AppSpacing.huge : AppSpacing.xl,
          ),
          child: FadeTransition(
            opacity: _fadeIn,
            child: SlideTransition(
              position: _slideUp,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Mobile logo
                    if (!isWide) ...[
                      Center(
                        child: Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusLg),
                          ),
                          child: const Center(
                            child: Text(
                              'IM',
                              style: TextStyle(
                                color: AppColors.accent,
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -1,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Center(
                        child: Text(
                          'Igreja Manager',
                          style: AppTypography.displaySmall.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxxl),
                    ],

                    // Welcome text
                    Text(
                      'Bem-vindo',
                      style: AppTypography.displaySmall.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Entre com suas credenciais para acessar o sistema.',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),

                    // Form
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Email
                          Text(
                            'E-MAIL',
                            style: AppTypography.labelMedium.copyWith(
                              color: AppColors.textSecondary,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            style: AppTypography.bodyLarge,
                            decoration: const InputDecoration(
                              hintText: 'seu@email.com',
                              prefixIcon: Icon(
                                Icons.mail_outline_rounded,
                                size: 20,
                                color: AppColors.textMuted,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Informe seu e-mail';
                              }
                              if (!value.contains('@')) {
                                return 'E-mail inválido';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: AppSpacing.lg),

                          // Password
                          Text(
                            'SENHA',
                            style: AppTypography.labelMedium.copyWith(
                              color: AppColors.textSecondary,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.done,
                            style: AppTypography.bodyLarge,
                            onFieldSubmitted: (_) => _handleLogin(),
                            decoration: InputDecoration(
                              hintText: '••••••••',
                              prefixIcon: const Icon(
                                Icons.lock_outline_rounded,
                                size: 20,
                                color: AppColors.textMuted,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  size: 20,
                                  color: AppColors.textMuted,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Informe sua senha';
                              }
                              if (value.length < 8) {
                                return 'Senha deve ter no mínimo 8 caracteres';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: AppSpacing.md),

                          // Forgot password
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {
                                // TODO: Forgot password flow
                              },
                              child: Text(
                                'Esqueceu a senha?',
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.accent,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xl),

                          // Login button
                          BlocBuilder<AuthBloc, AuthState>(
                            builder: (context, state) {
                              final isLoading = state is AuthLoading;
                              return SizedBox(
                                height: 52,
                                child: ElevatedButton(
                                  onPressed: isLoading ? null : _handleLogin,
                                  child: isLoading
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            color: AppColors.textOnPrimary,
                                          ),
                                        )
                                      : Text(
                                          'Entrar',
                                          style: AppTypography.buttonLarge
                                              .copyWith(
                                            color: AppColors.textOnPrimary,
                                          ),
                                        ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xxxl),

                    // Footer
                    Center(
                      child: Text(
                        'Igreja Manager v1.0',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
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

/// Custom painter for the geometric pattern on the hero panel.
/// Draws subtle sacred-geometry-inspired circles and lines.
class _SacredGeometryPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.03)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final center = Offset(size.width * 0.6, size.height * 0.35);
    const count = 6;
    const baseRadius = 120.0;

    // Concentric circles
    for (int i = 1; i <= 5; i++) {
      canvas.drawCircle(center, baseRadius * i * 0.6, paint);
    }

    // Radiating lines from center
    for (int i = 0; i < count * 2; i++) {
      final angle = (i * math.pi) / count;
      final end = Offset(
        center.dx + math.cos(angle) * size.width * 0.5,
        center.dy + math.sin(angle) * size.height * 0.5,
      );
      canvas.drawLine(center, end, paint);
    }

    // Small diamond accent
    final diamondPaint = Paint()
      ..color = const Color(0xFFD4A843).withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;

    final diamondCenter = Offset(size.width * 0.75, size.height * 0.2);
    const d = 30.0;
    final diamondPath = Path()
      ..moveTo(diamondCenter.dx, diamondCenter.dy - d)
      ..lineTo(diamondCenter.dx + d * 0.6, diamondCenter.dy)
      ..lineTo(diamondCenter.dx, diamondCenter.dy + d)
      ..lineTo(diamondCenter.dx - d * 0.6, diamondCenter.dy)
      ..close();
    canvas.drawPath(diamondPath, diamondPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
