import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthChangeEvent;
import '../../infrastructure/authentication/auth_repository.dart';
import '../../infrastructure/authentication/auth_service.dart';
import '../../infrastructure/database/app_database.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;
  StreamSubscription? _authSubscription;

  AuthBloc({required AuthRepository repository})
      : _authRepository = repository,
        super(const AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthLoginRequested>(_onAuthLoginRequested);
    on<AuthRegisterRequested>(_onAuthRegisterRequested);
    on<AuthPasswordResetRequested>(_onAuthPasswordResetRequested);
    on<AuthSignOutRequested>(_onAuthSignOutRequested);
    on<AuthSessionStateChanged>(_onAuthSessionStateChanged);

    // Listen to Supabase auth stream
    _authSubscription = _authRepository.authStateChanges.listen((data) {
      add(AuthSessionStateChanged(data));
    });
  }

  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    final user = _authRepository.currentUser;
    final session = _authRepository.currentSession;

    if (session != null && user != null) {
      if (!user.isEmailVerified && !AppDatabase.instance.isDemoMode) {
        // If email confirmation is strictly required in project config
        // emit(EmailVerificationRequired(user.email));
      }
      AppDatabase.instance.isLoggedIn = true;
      emit(Authenticated(user));
    } else if (AppDatabase.instance.isDemoMode && AppDatabase.instance.isLoggedIn) {
      // Preserve offline demo mode exploration
      emit(const Authenticated(AuthUser(
        id: 'demo_user',
        email: 'demo@xenobiz.com',
        name: 'Demo User',
        isEmailVerified: true,
      )));
    } else {
      AppDatabase.instance.isLoggedIn = false;
      emit(const Unauthenticated());
    }
  }

  Future<void> _onAuthLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final user = await _authRepository.signInWithPassword(
        email: event.email,
        password: event.password,
      );

      AppDatabase.instance.isDemoMode = false;
      AppDatabase.instance.isLoggedIn = true;

      emit(Authenticated(user));
    } on AuthFailure catch (e) {
      emit(AuthenticationError(e.message));
    } catch (e) {
      emit(const AuthenticationError('Failed to login. Please try again.'));
    }
  }

  Future<void> _onAuthRegisterRequested(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final user = await _authRepository.signUp(
        email: event.email,
        password: event.password,
        name: event.name,
      );

      if (user != null) {
        AppDatabase.instance.isDemoMode = false;
        if (!user.isEmailVerified && _authRepository.currentSession == null) {
          emit(EmailVerificationRequired(user.email));
        } else {
          AppDatabase.instance.isLoggedIn = true;
          emit(Authenticated(user));
        }
      } else {
        emit(EmailVerificationRequired(event.email));
      }
    } on AuthFailure catch (e) {
      emit(AuthenticationError(e.message));
    } catch (e) {
      emit(const AuthenticationError('Failed to register account. Please try again.'));
    }
  }

  Future<void> _onAuthPasswordResetRequested(
    AuthPasswordResetRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      await _authRepository.resetPassword(event.email);
      emit(PasswordResetEmailSent(event.email));
    } on AuthFailure catch (e) {
      emit(AuthenticationError(e.message));
    } catch (e) {
      emit(const AuthenticationError('Failed to send password reset email.'));
    }
  }

  Future<void> _onAuthSignOutRequested(
    AuthSignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    await _authRepository.signOut();
    AppDatabase.instance.isLoggedIn = false;
    AppDatabase.instance.isDemoMode = false;
    await AppDatabase.instance.saveLocalState();
    emit(const Unauthenticated());
  }

  void _onAuthSessionStateChanged(
    AuthSessionStateChanged event,
    Emitter<AuthState> emit,
  ) {
    final eventType = event.sessionState.event;
    debugPrint('[AuthBloc] AuthStateChanged event: $eventType');

    switch (eventType) {
      case AuthChangeEvent.signedIn:
      case AuthChangeEvent.tokenRefreshed:
      case AuthChangeEvent.userUpdated:
        final user = _authRepository.currentUser;
        if (user != null) {
          AppDatabase.instance.isLoggedIn = true;
          emit(Authenticated(user));
        }
        break;
      case AuthChangeEvent.signedOut:
        AppDatabase.instance.isLoggedIn = false;
        emit(const Unauthenticated());
        break;
      case AuthChangeEvent.passwordRecovery:
        final user = _authRepository.currentUser;
        if (user != null) {
          emit(Authenticated(user));
        }
        break;
      default:
        break;
    }
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }
}
