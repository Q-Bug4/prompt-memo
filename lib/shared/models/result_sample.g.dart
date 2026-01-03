// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'result_sample.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ResultSampleImpl _$$ResultSampleImplFromJson(Map<String, dynamic> json) =>
    _$ResultSampleImpl(
      id: json['id'] as String,
      promptId: json['promptId'] as String,
      fileType: $enumDecode(_$FileTypeEnumMap, json['fileType']),
      filePath: json['filePath'] as String,
      fileName: json['fileName'] as String,
      fileSize: (json['fileSize'] as num).toInt(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      mimeType: json['mimeType'] as String?,
      width: (json['width'] as num?)?.toInt(),
      height: (json['height'] as num?)?.toInt(),
      durationSeconds: (json['durationSeconds'] as num?)?.toInt(),
    );

Map<String, dynamic> _$$ResultSampleImplToJson(_$ResultSampleImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'promptId': instance.promptId,
      'fileType': _$FileTypeEnumMap[instance.fileType]!,
      'filePath': instance.filePath,
      'fileName': instance.fileName,
      'fileSize': instance.fileSize,
      'createdAt': instance.createdAt.toIso8601String(),
      'mimeType': instance.mimeType,
      'width': instance.width,
      'height': instance.height,
      'durationSeconds': instance.durationSeconds,
    };

const _$FileTypeEnumMap = {
  FileType.text: 'text',
  FileType.image: 'image',
  FileType.video: 'video',
};
