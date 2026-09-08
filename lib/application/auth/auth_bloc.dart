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
      await AppDatabase.instance.setActiveUser(user.id);
      emit(Authenticated(user));
    } else if (AppDatabase.instance.isLoggedIn && AppDatabase.instance.activeUserId != null) {
      await AppDatabase.instance.loadAccountData(AppDatabase.instance.activeUserId!);
      emit(Authenticated(AuthUser(
        id: AppDatabase.instance.activeUserId!,
        email: AppDatabase.instance.currentBusiness?.email ?? 'user@xenobiz.internal',
        name: AppDatabase.instance.currentBusiness?.name ?? 'User',
        isEmailVerified: true,
      )));
    } else {
      await AppDatabase.instance.clearActiveSessionOnLogout();
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

      await AppDatabase.instance.setActiveUser(user.id);
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
        await AppDatabase.instance.setActiveUser(user.id);
        if (!user.isEmailVerified && _authRepository.currentSession == null) {
          emit(EmailVerificationRequired(user.email));
        } else {
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
    await AppDatabase.instance.clearActiveSessionOnLogout();
    emit(const Unauthenticated());
  }

  void _onAuthSessionStateChanged(
    AuthSessionStateChanged event,
    Emitter<AuthState> emit,
  ) async {
    final eventType = event.sessionState.event;
    debugPrint('[AuthBloc] AuthStateChanged event: $eventType');

    switch (eventType) {
      case AuthChangeEvent.signedIn:
      case AuthChangeEvent.tokenRefreshed:
      case AuthChangeEvent.userUpdated:
        final user = _authRepository.currentUser;
        if (user != null) {
          await AppDatabase.instance.setActiveUser(user.id);
          emit(Authenticated(user));
        }
        break;
      case AuthChangeEvent.signedOut:
        await AppDatabase.instance.clearActiveSessionOnLogout();
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
