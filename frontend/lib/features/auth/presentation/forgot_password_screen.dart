import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../data/auth_repository.dart';

/// Combined screen for "Forgot Password" + "Reset Password (with token)".
/// Step 1: User enters e-mail → calls POST /v1/auth/forgot-password.
/// Step 2: User enters token + new password → calls POST /v1/auth/reset-password.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _tokenController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _emailSent = false; // true = show step 2 (token + new password)
  bool _resetDone = false;
  String? _errorMessage;
  bool _obscurePassword = true;

  late final AuthRepository _authRepository;

  @override
  void initState() {
    super.initState();
    _authRepository = AuthRepository(
      apiClient: context.read<ApiClient>(),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _tokenController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _handleSendEmail() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authRepository.forgotPassword(email: _emailController.text.trim());
      setState(() {
        _emailSent = true;
      });
    } catch (e) {
      setState(() {
        // Even on error, the backend returns 200 to prevent email enumeration.
        // If we get here it's a network error.
        _errorMessage = 'Erro de conexão. Tente novamente.';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleResetPassword() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authRepository.resetPassword(
        token: _tokenController.text.trim().toUpperCase(),
        newPassword: _passwordController.text,
      );
      setState(() {
        _resetDone = true;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Token inválido ou expirado. Tente novamente.';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: _resetDone ? _buildSuccessView() : _buildFormView(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.check_circle_outline, size: 72, color: AppColors.success),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Senha Redefinida!',
          style: AppTypography.headingLarge.copyWith(color: AppColors.textPrimary),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Sua senha foi alterada com sucesso. Faça login com a nova senha.',
          textAlign: TextAlign.center,
          style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.xxl),
        SizedBox(
          height: 52,
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Voltar ao Login',
              style: AppTypography.buttonLarge.copyWith(color: AppColors.textOnPrimary),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFormView() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            _emailSent ? 'Redefinir Senha' : 'Esqueceu a Senha?',
            style: AppTypography.headingLarge.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            _emailSent
                ? 'Digite o código enviado para ${_emailController.text} e sua nova senha.'
                : 'Informe seu e-mail e enviaremos instruções para redefinir sua senha.',
            style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.xxl),

          // Error message
          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: AppColors.error, size: 20),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: AppTypography.bodySmall.copyWith(color: AppColors.error),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],

          if (!_emailSent) ...[
            // Step 1: Email
            Text('E-MAIL', style: AppTypography.labelSmall.copyWith(
              color: AppColors.textSecondary, letterSpacing: 1.2,
            )),
            const SizedBox(height: AppSpacing.xs),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Informe seu e-mail';
                if (!v.contains('@')) return 'E-mail inválido';
                return null;
              },
              decoration: const InputDecoration(
                hintText: 'seu@email.com',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              height: 52,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleSendEmail,
                child: _isLoading
                    ? const SizedBox(
                        width: 22, height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.textOnPrimary),
                      )
                    : Text('Enviar Código', style: AppTypography.buttonLarge.copyWith(color: AppColors.textOnPrimary)),
              ),
            ),
          ] else ...[
            // Step 2: Token + New Password
            Text('CÓDIGO', style: AppTypography.labelSmall.copyWith(
              color: AppColors.textSecondary, letterSpacing: 1.2,
            )),
            const SizedBox(height: AppSpacing.xs),
            TextFormField(
              controller: _tokenController,
              textCapitalization: TextCapitalization.characters,
              textInputAction: TextInputAction.next,
              style: AppTypography.headingSmall.copyWith(letterSpacing: 8),
              textAlign: TextAlign.center,
              maxLength: 6,
              validator: (v) {
                if (v == null || v.trim().length < 6) return 'Informe o código de 6 caracteres';
                return null;
              },
              decoration: const InputDecoration(
                hintText: '------',
                counterText: '',
                prefixIcon: Icon(Icons.lock_clock_outlined),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            Text('NOVA SENHA', style: AppTypography.labelSmall.copyWith(
              color: AppColors.textSecondary, letterSpacing: 1.2,
            )),
            const SizedBox(height: AppSpacing.xs),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.next,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Informe a nova senha';
                if (v.length < 8) return 'Senha deve ter no mínimo 8 caracteres';
                return null;
              },
              decoration: InputDecoration(
                hintText: 'Mínimo 8 caracteres',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            Text('CONFIRMAR SENHA', style: AppTypography.labelSmall.copyWith(
              color: AppColors.textSecondary, letterSpacing: 1.2,
            )),
            const SizedBox(height: AppSpacing.xs),
            TextFormField(
              controller: _confirmController,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              validator: (v) {
                if (v != _passwordController.text) return 'As senhas não coincidem';
                return null;
              },
              decoration: const InputDecoration(
                hintText: 'Repita a nova senha',
                prefixIcon: Icon(Icons.lock_outline),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            SizedBox(
              height: 52,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleResetPassword,
                child: _isLoading
                    ? const SizedBox(
                        width: 22, height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.textOnPrimary),
                      )
                    : Text('Redefinir Senha', style: AppTypography.buttonLarge.copyWith(color: AppColors.textOnPrimary)),
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // Resend code
            Center(
              child: TextButton(
                onPressed: _isLoading
                    ? null
                    : () {
                        setState(() {
                          _emailSent = false;
                          _tokenController.clear();
                          _passwordController.clear();
                          _confirmController.clear();
                          _errorMessage = null;
                        });
                      },
                child: Text(
                  'Reenviar código',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
