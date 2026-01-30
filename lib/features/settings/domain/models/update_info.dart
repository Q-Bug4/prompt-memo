import 'package:freezed_annotation/freezed_annotation.dart';

part 'update_info.freezed.dart';
part 'update_info.g.dart';

@freezed
class UpdateInfo with _$UpdateInfo {
  const factory UpdateInfo({
    required String currentVersion,
    required String latestVersion,
    required String releaseNotes,
    required String downloadUrl,
    required bool isUpdateAvailable,
    required bool isMandatory,
    @Default('') String releaseDate,
    @Default('') String fileSize,
  }) = _UpdateInfo;

  factory UpdateInfo.fromJson(Map<String, dynamic> json) =>
      _$UpdateInfoFromJson(json);
}
