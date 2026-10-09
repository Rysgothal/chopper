// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'package:firebase_auth/firebase_auth.dart' as _i59;
import 'package:firebase_core/firebase_core.dart' as _i982;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;

import '../../features/auth/data/datasources/firebase_auth_data_source.dart'
    as _i492;
import '../../features/auth/data/repositories/auth_repository_impl.dart'
    as _i153;
import '../../features/auth/domain/repositories/auth_repository.dart' as _i787;
import '../../features/auth/domain/usecases/get_current_user.dart' as _i111;
import '../../features/auth/domain/usecases/sign_in_email.dart' as _i1048;
import '../../features/auth/domain/usecases/sign_in_google.dart' as _i770;
import '../../features/auth/domain/usecases/sign_out.dart' as _i568;
import '../../features/auth/presentation/bloc/auth_bloc.dart' as _i797;
import 'modules.dart' as _i738;

// initializes the registration of main-scope dependencies inside of GetIt
Future<_i174.GetIt> init(
  _i174.GetIt getIt, {
  String? environment,
  _i526.EnvironmentFilter? environmentFilter,
}) async {
  final gh = _i526.GetItHelper(
    getIt,
    environment,
    environmentFilter,
  );
  final firebaseModule = _$FirebaseModule();
  await gh.factoryAsync<_i982.FirebaseApp>(
    () => firebaseModule.firebaseApp,
    preResolve: true,
  );
  gh.lazySingleton<_i59.FirebaseAuth>(
      () => firebaseModule.firebaseAuth(gh<_i982.FirebaseApp>()));
  gh.lazySingleton<_i492.FirebaseAuthDataSource>(
      () => _i492.FirebaseAuthDataSource(gh<_i59.FirebaseAuth>()));
  gh.lazySingleton<_i787.AuthRepository>(
      () => _i153.AuthRepositoryImpl(gh<_i492.FirebaseAuthDataSource>()));
  gh.factory<_i111.GetCurrentUserUseCase>(
      () => _i111.GetCurrentUserUseCase(gh<_i787.AuthRepository>()));
  gh.factory<_i1048.SignInEmailUseCase>(
      () => _i1048.SignInEmailUseCase(gh<_i787.AuthRepository>()));
  gh.factory<_i770.SignInGoogleUseCase>(
      () => _i770.SignInGoogleUseCase(gh<_i787.AuthRepository>()));
  gh.factory<_i568.SignOutUseCase>(
      () => _i568.SignOutUseCase(gh<_i787.AuthRepository>()));
  gh.factory<_i797.AuthBloc>(() => _i797.AuthBloc(
        gh<_i1048.SignInEmailUseCase>(),
        gh<_i770.SignInGoogleUseCase>(),
        gh<_i568.SignOutUseCase>(),
        gh<_i111.GetCurrentUserUseCase>(),
      ));
  return getIt;
}

class _$FirebaseModule extends _i738.FirebaseModule {}
