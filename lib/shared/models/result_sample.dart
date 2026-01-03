import 'package:freezed_annotation/freezed_annotation.dart';

part 'result_sample.freezed.dart';
part 'result_sample.g.dart';

enum FileType { text, image, video }

@freezed
class ResultSample with _$ResultSample {
  const factory ResultSample({
    required String id,
    required String promptId,
    required FileType fileType,
    required String filePath,
    required String fileName,
    required int fileSize,
    required DateTime createdAt,
    String? mimeType,
    int? width,
    int? height,
    int? durationSeconds,
  }) = _ResultSample;

  factory ResultSample.fromJson(Map<String, dynamic> json) =>
      _$ResultSampleFromJson(json);
}
