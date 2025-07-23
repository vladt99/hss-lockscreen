import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'auth_cubit.dart';

/// A widget that conditionally displays a lock screen on web in debug mode
class HssLockScreen extends StatelessWidget {
  /// The password required to unlock the screen
  final String password;

  /// The child widget to display when unlocked
  final Widget child;

  /// Optional custom lock screen background color
  final Color? backgroundColor;

  /// Optional custom blur intensity (default: 12.0)
  final double blurIntensity;

  /// Optional custom accent color for the lock screen theme
  final Color? accentColor;

  const HssLockScreen({
    super.key,
    required this.password,
    required this.child,
    this.backgroundColor,
    this.blurIntensity = 12.0,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    // Only show lock screen on web in debug mode
    if (!kIsWeb || !kDebugMode) {
      return child;
    }

    return BlocProvider(
      create: (context) => AuthCubit(password: password)..checkAuthStatus(),
      child: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 800),
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position:
                      Tween<Offset>(
                        begin: const Offset(0, 0.1),
                        end: Offset.zero,
                      ).animate(
                        CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOutCubic,
                        ),
                      ),
                  child: child,
                ),
              );
            },
            child: state is AuthAuthenticated
                ? child
                : _LockScreenOverlay(
                    key: const ValueKey('lock_screen'),
                    backgroundColor: backgroundColor,
                    blurIntensity: blurIntensity,
                    accentColor: accentColor ?? Theme.of(context).primaryColor,
                    authState: state,
                    child: child,
                  ),
          );
        },
      ),
    );
  }
}

/// Internal widget that displays the lock screen overlay
class _LockScreenOverlay extends StatefulWidget {
  final Widget child;
  final Color? backgroundColor;
  final double blurIntensity;
  final Color accentColor;
  final AuthState authState;

  const _LockScreenOverlay({
    super.key,
    required this.child,
    this.backgroundColor,
    required this.blurIntensity,
    required this.accentColor,
    required this.authState,
  });

  @override
  State<_LockScreenOverlay> createState() => _LockScreenOverlayState();
}

class _LockScreenOverlayState extends State<_LockScreenOverlay>
    with TickerProviderStateMixin {
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _passwordFocusNode = FocusNode();
  late AnimationController _shakeController;
  late AnimationController _pulseController;
  late Animation<double> _shakeAnimation;
  late Animation<double> _pulseAnimation;
  bool _obscurePassword = true;
  bool _isAuthenticating = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();

    // Auto-focus the password field after a short delay
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _passwordFocusNode.requestFocus();
        }
      });
    });
  }

  void _initializeAnimations() {
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _shakeAnimation = Tween<double>(begin: 0, end: 8).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );

    _pulseAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _passwordFocusNode.dispose();
    _shakeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(_LockScreenOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Handle authentication state changes
    if (widget.authState != oldWidget.authState) {
      _handleAuthStateChange();
    }
  }

  void _handleAuthStateChange() {
    if (widget.authState is AuthUnauthenticated) {
      final state = widget.authState as AuthUnauthenticated;
      if (state.errorMessage != null &&
          state.errorMessage!.contains('Incorrect')) {
        _triggerShakeAnimation();
        _passwordController.clear();
      }
    }
    setState(() {
      _isAuthenticating = false;
    });
  }

  void _triggerShakeAnimation() {
    _shakeController.reset();
    _shakeController.forward();
    HapticFeedback.mediumImpact();
  }

  Future<void> _handleAuthentication() async {
    if (_passwordController.text.isEmpty) return;

    setState(() {
      _isAuthenticating = true;
    });

    HapticFeedback.lightImpact();
    final authCubit = context.read<AuthCubit>();
    await authCubit.authenticate(_passwordController.text);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLoading = widget.authState is AuthLoading;
    final errorMessage = widget.authState is AuthUnauthenticated
        ? (widget.authState as AuthUnauthenticated).errorMessage
        : null;

    return Material(
      child: Stack(
        children: [
          // Blurred background
          ImageFiltered(
            imageFilter: ImageFilter.blur(
              sigmaX: widget.blurIntensity,
              sigmaY: widget.blurIntensity,
            ),
            child: widget.child,
          ),

          // Gradient overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  widget.backgroundColor?.withValues(alpha: 0.3) ??
                      Colors.black.withValues(alpha: 0.3),
                  widget.backgroundColor?.withValues(alpha: 0.6) ??
                      Colors.black.withValues(alpha: 0.6),
                ],
              ),
            ),
          ),

          // Lock screen content
          Center(
            child: AnimatedBuilder(
              animation: _shakeAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(
                    _shakeAnimation.value *
                        (_shakeController.value > 0.5 ? -1 : 1),
                    0,
                  ),
                  child: child,
                );
              },
              child: Container(
                constraints: const BoxConstraints(maxWidth: 420),
                margin: const EdgeInsets.all(32),
                child: Card(
                  elevation: 24,
                  shadowColor: widget.accentColor.withValues(alpha: 0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          theme.cardColor,
                          theme.cardColor.withValues(alpha: 0.9),
                        ],
                      ),
                    ),
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildLockIcon(),
                        const SizedBox(height: 32),
                        _buildTitle(theme),
                        const SizedBox(height: 12),
                        _buildSubtitle(theme),
                        const SizedBox(height: 40),
                        _buildPasswordField(theme, isLoading),
                        if (errorMessage != null) ...[
                          const SizedBox(height: 16),
                          _buildErrorMessage(errorMessage, theme),
                        ],
                        const SizedBox(height: 32),
                        _buildLoginButton(theme, isLoading),
                        const SizedBox(height: 24),
                        _buildDebugInfo(theme),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLockIcon() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  widget.accentColor.withValues(alpha: 0.2),
                  widget.accentColor.withValues(alpha: 0.1),
                ],
              ),
            ),
            child: Icon(
              Icons.lock_outline_rounded,
              size: 48,
              color: widget.accentColor,
            ),
          ),
        );
      },
    );
  }

  Widget _buildTitle(ThemeData theme) {
    return Text(
      'Secure Access',
      style: theme.textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.bold,
        color: theme.colorScheme.onSurface,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildSubtitle(ThemeData theme) {
    return Text(
      'Enter your password to continue',
      style: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildPasswordField(ThemeData theme, bool isLoading) {
    return TextField(
      controller: _passwordController,
      focusNode: _passwordFocusNode,
      obscureText: _obscurePassword,
      enabled: !isLoading && !_isAuthenticating,
      onSubmitted: (_) => _handleAuthentication(),
      decoration: InputDecoration(
        labelText: 'Password',
        prefixIcon: Icon(Icons.key_rounded, color: widget.accentColor),
        suffixIcon: IconButton(
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Icon(
              _obscurePassword
                  ? Icons.visibility_rounded
                  : Icons.visibility_off_rounded,
              key: ValueKey(_obscurePassword),
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          onPressed: () {
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: theme.dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: widget.accentColor, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: theme.dividerColor),
        ),
        filled: true,
        fillColor: theme.colorScheme.surface.withValues(alpha: 0.5),
      ),
    );
  }

  Widget _buildErrorMessage(String message, ThemeData theme) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.error.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: theme.colorScheme.error,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginButton(ThemeData theme, bool isLoading) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: (isLoading || _isAuthenticating)
            ? null
            : _handleAuthentication,
        style: ElevatedButton.styleFrom(
          backgroundColor: widget.accentColor,
          foregroundColor: Colors.white,
          elevation: 8,
          shadowColor: widget.accentColor.withValues(alpha: 0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: (isLoading || _isAuthenticating)
              ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.lock_open_rounded, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      'Unlock',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildDebugInfo(ThemeData theme) {
    if (!kDebugMode) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'Debug Mode • Web Only',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          fontStyle: FontStyle.italic,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
