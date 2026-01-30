// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$UpdateInfoImpl _$$UpdateInfoImplFromJson(Map<String, dynamic> json) =>
    _$UpdateInfoImpl(
      currentVersion: json['currentVersion'] as String,
      latestVersion: json['latestVersion'] as String,
      releaseNotes: json['releaseNotes'] as String,
      downloadUrl: json['downloadUrl'] as String,
      isUpdateAvailable: json['isUpdateAvailable'] as bool,
      isMandatory: json['isMandatory'] as bool,
      releaseDate: json['releaseDate'] as String? ?? '',
      fileSize: json['fileSize'] as String? ?? '',
    );

Map<String, dynamic> _$$UpdateInfoImplToJson(_$UpdateInfoImpl instance) =>
    <String, dynamic>{
      'currentVersion': instance.currentVersion,
      'latestVersion': instance.latestVersion,
      'releaseNotes': instance.releaseNotes,
      'downloadUrl': instance.downloadUrl,
      'isUpdateAvailable': instance.isUpdateAvailable,
      'isMandatory': instance.isMandatory,
      'releaseDate': instance.releaseDate,
      'fileSize': instance.fileSize,
    };
