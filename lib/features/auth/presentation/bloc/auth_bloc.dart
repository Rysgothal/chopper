import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';

import '../../domain/entities/user.dart';
import '../../domain/failures/auth_failure.dart';
import '../../domain/usecases/get_current_user.dart';
import '../../domain/usecases/sign_in_email.dart';
import '../../domain/usecases/sign_in_google.dart';
import '../../domain/usecases/sign_out.dart';

part 'auth_bloc.freezed.dart';

@freezed
sealed class AuthEvent with _$AuthEvent {
  const factory AuthEvent.signInEmailRequested({
    required String email,
    required String password,
  }) = _SignInEmailRequested;

  const factory AuthEvent.signInGoogleRequested() = _SignInGoogleRequested;
  const factory AuthEvent.signOutRequested() = _SignOutRequested;

  const factory AuthEvent.authStateChanged({User? user}) = _AuthStateChanged;
}

@freezed
sealed class AuthState with _$AuthState {
  const factory AuthState.unauthenticated() = _Unauthenticated;

  const factory AuthState.authenticated(User user) = _Authenticated;

  const factory AuthState.loading() = _Loading;

  const factory AuthState.failure(AuthFailure failure) = _Failure;
}

@injectable
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final SignInEmailUseCase _signInEmail;
  final SignInGoogleUseCase _signInGoogle;
  final SignOutUseCase _signOut;
  final GetCurrentUserUseCase _getCurrentUser;

  AuthBloc(
    this._signInEmail,
    this._signInGoogle,
    this._signOut,
    this._getCurrentUser,
  ) : super(const AuthState.unauthenticated()) {
    on<_SignInEmailRequested>(_onSignInEmail);
    on<_SignInGoogleRequested>(_onSignInGoogle);
    on<_SignOutRequested>(_onSignOut);
    on<_AuthStateChanged>(_onAuthStateChanged);

    _checkInitialAuth();
  }

  Future<void> _checkInitialAuth() async {
    final result = await _getCurrentUser();
    result.fold(
      () => add(const AuthEvent.authStateChanged(user: null)),
      (user) => add(AuthEvent.authStateChanged(user: user)),
    );
  }

  Future<void> _onSignInEmail(
    _SignInEmailRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthState.loading());
    final result = await _signInEmail(
      email: event.email,
      password: event.password,
    );
    result.fold(
      (failure) => emit(AuthState.failure(failure)),
      (user) => emit(AuthState.authenticated(user)),
    );
  }

  Future<void> _onSignInGoogle(
    _SignInGoogleRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthState.loading());
    final result = await _signInGoogle();
    result.fold(
      (failure) => emit(AuthState.failure(failure)),
      (user) => emit(AuthState.authenticated(user)),
    );
  }

  Future<void> _onSignOut(
    _SignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthState.loading());
    final result = await _signOut();
    result.fold(
      (failure) => emit(AuthState.failure(failure)),
      (_) => emit(const AuthState.unauthenticated()),
    );
  }

  Future<void> _onAuthStateChanged(
    _AuthStateChanged event,
    Emitter<AuthState> emit,
  ) async {
    if (event.user != null) {
      emit(AuthState.authenticated(event.user!));
    } else {
      emit(const AuthState.unauthenticated());
    }
  }
}