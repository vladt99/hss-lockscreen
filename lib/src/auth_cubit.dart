import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Abstract interface for secure storage operations
abstract class SecureStorageInterface {
  Future<String?> read({required String key});
  Future<void> write({required String key, required String value});
  Future<void> delete({required String key});
}

/// Default implementation using FlutterSecureStorage
class DefaultSecureStorage implements SecureStorageInterface {
  const DefaultSecureStorage();

  static const _storage = FlutterSecureStorage();

  @override
  Future<String?> read({required String key}) async {
    try {
      return await _storage.read(key: key);
    } catch (e) {
      _logError('SecureStorage read error', e);
      return null;
    }
  }

  @override
  Future<void> write({required String key, required String value}) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (e) {
      _logError('SecureStorage write error', e);
      rethrow;
    }
  }

  @override
  Future<void> delete({required String key}) async {
    try {
      await _storage.delete(key: key);
    } catch (e) {
      _logError('SecureStorage delete error', e);
    }
  }

  void _logError(String message, Object error) {
    if (kDebugMode) {
      print('$message: $error');
    }
  }
}

/// States for the authentication process
sealed class AuthState {}

/// Initial state when auth status is unknown
final class AuthInitial extends AuthState {}

/// State when checking authentication status
final class AuthLoading extends AuthState {}

/// State when user is authenticated
final class AuthAuthenticated extends AuthState {}

/// State when user needs to authenticate
final class AuthUnauthenticated extends AuthState {
  final String? errorMessage;

  AuthUnauthenticated({this.errorMessage});
}

/// Cubit for managing authentication state and secure storage
class AuthCubit extends Cubit<AuthState> {
  static const String _authTimestampKey = 'hss_lock_screen_auth_timestamp';
  static const int _maxAuthDays = 20;

  final SecureStorageInterface _secureStorage;
  final String _password;

  AuthCubit({required String password, SecureStorageInterface? secureStorage})
    : _password = password,
      _secureStorage = secureStorage ?? const DefaultSecureStorage(),
      super(AuthInitial());

  /// Check if the user should be authenticated based on stored timestamp
  Future<void> checkAuthStatus() async {
    emit(AuthLoading());

    try {
      final timestampString = await _secureStorage.read(key: _authTimestampKey);

      if (timestampString == null) {
        emit(AuthUnauthenticated());
        return;
      }

      final timestamp = DateTime.tryParse(timestampString);
      if (timestamp == null) {
        emit(AuthUnauthenticated());
        return;
      }

      final daysDifference = DateTime.now().difference(timestamp).inDays;

      if (daysDifference > _maxAuthDays) {
        await _secureStorage.delete(key: _authTimestampKey);
        emit(
          AuthUnauthenticated(
            errorMessage: 'Session expired. Please log in again.',
          ),
        );
      } else {
        emit(AuthAuthenticated());
      }
    } catch (e) {
      _logError('Error checking auth status', e);
      emit(AuthUnauthenticated(errorMessage: 'Authentication check failed.'));
    }
  }

  /// Attempt to authenticate with the provided password
  Future<void> authenticate(String inputPassword) async {
    if (inputPassword.isEmpty) {
      emit(AuthUnauthenticated(errorMessage: 'Please enter a password.'));
      return;
    }

    if (inputPassword == _password) {
      try {
        await _secureStorage.write(
          key: _authTimestampKey,
          value: DateTime.now().toIso8601String(),
        );
        emit(AuthAuthenticated());
      } catch (e) {
        _logError('Error saving auth timestamp', e);
        emit(
          AuthUnauthenticated(errorMessage: 'Failed to save authentication.'),
        );
      }
    } else {
      emit(
        AuthUnauthenticated(
          errorMessage: 'Incorrect password. Please try again.',
        ),
      );
    }
  }

  /// Clear authentication
  Future<void> clearAuth() async {
    try {
      await _secureStorage.delete(key: _authTimestampKey);
      emit(AuthUnauthenticated());
    } catch (e) {
      _logError('Error clearing auth', e);
    }
  }

  void _logError(String message, Object error) {
    if (kDebugMode) {
      print('$message: $error');
    }
  }
}
