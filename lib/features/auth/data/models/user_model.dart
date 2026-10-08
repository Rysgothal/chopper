import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import '/features/auth/domain/entities/user.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

@freezed
abstract class UserModel with _$UserModel {
  const factory UserModel({
    required String uid,
    required String email,
    String? displayName,
    String? photoUrl,
  }) = _UserModel;

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);

  factory UserModel.fromFirebase(fb.User user) => UserModel(
        uid: user.uid,
        email: user.email ?? '',
        displayName: user.displayName,
        photoUrl: user.photoURL,
      );
}

extension UserModelX on UserModel {
  User toEntity() => User(
        uid: uid,
        email: email,
        displayName: displayName,
        photoUrl: photoUrl,
      );
}

extension UserEntityX on User {
  UserModel toModel() => UserModel(
        uid: uid,
        email: email,
        displayName: displayName,
        photoUrl: photoUrl,
      );
}