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
  return getIt;
}

class _$FirebaseModule extends _i738.FirebaseModule {}
