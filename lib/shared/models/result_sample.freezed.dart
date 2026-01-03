// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'result_sample.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

ResultSample _$ResultSampleFromJson(Map<String, dynamic> json) {
  return _ResultSample.fromJson(json);
}

/// @nodoc
mixin _$ResultSample {
  String get id => throw _privateConstructorUsedError;
  String get promptId => throw _privateConstructorUsedError;
  FileType get fileType => throw _privateConstructorUsedError;
  String get filePath => throw _privateConstructorUsedError;
  String get fileName => throw _privateConstructorUsedError;
  int get fileSize => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  String? get mimeType => throw _privateConstructorUsedError;
  int? get width => throw _privateConstructorUsedError;
  int? get height => throw _privateConstructorUsedError;
  int? get durationSeconds => throw _privateConstructorUsedError;

  /// Serializes this ResultSample to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ResultSample
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ResultSampleCopyWith<ResultSample> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ResultSampleCopyWith<$Res> {
  factory $ResultSampleCopyWith(
    ResultSample value,
    $Res Function(ResultSample) then,
  ) = _$ResultSampleCopyWithImpl<$Res, ResultSample>;
  @useResult
  $Res call({
    String id,
    String promptId,
    FileType fileType,
    String filePath,
    String fileName,
    int fileSize,
    DateTime createdAt,
    String? mimeType,
    int? width,
    int? height,
    int? durationSeconds,
  });
}

/// @nodoc
class _$ResultSampleCopyWithImpl<$Res, $Val extends ResultSample>
    implements $ResultSampleCopyWith<$Res> {
  _$ResultSampleCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ResultSample
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? promptId = null,
    Object? fileType = null,
    Object? filePath = null,
    Object? fileName = null,
    Object? fileSize = null,
    Object? createdAt = null,
    Object? mimeType = freezed,
    Object? width = freezed,
    Object? height = freezed,
    Object? durationSeconds = freezed,
  }) {
    return _then(
      _value.copyWith(
            id:
                null == id
                    ? _value.id
                    : id // ignore: cast_nullable_to_non_nullable
                        as String,
            promptId:
                null == promptId
                    ? _value.promptId
                    : promptId // ignore: cast_nullable_to_non_nullable
                        as String,
            fileType:
                null == fileType
                    ? _value.fileType
                    : fileType // ignore: cast_nullable_to_non_nullable
                        as FileType,
            filePath:
                null == filePath
                    ? _value.filePath
                    : filePath // ignore: cast_nullable_to_non_nullable
                        as String,
            fileName:
                null == fileName
                    ? _value.fileName
                    : fileName // ignore: cast_nullable_to_non_nullable
                        as String,
            fileSize:
                null == fileSize
                    ? _value.fileSize
                    : fileSize // ignore: cast_nullable_to_non_nullable
                        as int,
            createdAt:
                null == createdAt
                    ? _value.createdAt
                    : createdAt // ignore: cast_nullable_to_non_nullable
                        as DateTime,
            mimeType:
                freezed == mimeType
                    ? _value.mimeType
                    : mimeType // ignore: cast_nullable_to_non_nullable
                        as String?,
            width:
                freezed == width
                    ? _value.width
                    : width // ignore: cast_nullable_to_non_nullable
                        as int?,
            height:
                freezed == height
                    ? _value.height
                    : height // ignore: cast_nullable_to_non_nullable
                        as int?,
            durationSeconds:
                freezed == durationSeconds
                    ? _value.durationSeconds
                    : durationSeconds // ignore: cast_nullable_to_non_nullable
                        as int?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ResultSampleImplCopyWith<$Res>
    implements $ResultSampleCopyWith<$Res> {
  factory _$$ResultSampleImplCopyWith(
    _$ResultSampleImpl value,
    $Res Function(_$ResultSampleImpl) then,
  ) = __$$ResultSampleImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String promptId,
    FileType fileType,
    String filePath,
    String fileName,
    int fileSize,
    DateTime createdAt,
    String? mimeType,
    int? width,
    int? height,
    int? durationSeconds,
  });
}

/// @nodoc
class __$$ResultSampleImplCopyWithImpl<$Res>
    extends _$ResultSampleCopyWithImpl<$Res, _$ResultSampleImpl>
    implements _$$ResultSampleImplCopyWith<$Res> {
  __$$ResultSampleImplCopyWithImpl(
    _$ResultSampleImpl _value,
    $Res Function(_$ResultSampleImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ResultSample
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? promptId = null,
    Object? fileType = null,
    Object? filePath = null,
    Object? fileName = null,
    Object? fileSize = null,
    Object? createdAt = null,
    Object? mimeType = freezed,
    Object? width = freezed,
    Object? height = freezed,
    Object? durationSeconds = freezed,
  }) {
    return _then(
      _$ResultSampleImpl(
        id:
            null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                    as String,
        promptId:
            null == promptId
                ? _value.promptId
                : promptId // ignore: cast_nullable_to_non_nullable
                    as String,
        fileType:
            null == fileType
                ? _value.fileType
                : fileType // ignore: cast_nullable_to_non_nullable
                    as FileType,
        filePath:
            null == filePath
                ? _value.filePath
                : filePath // ignore: cast_nullable_to_non_nullable
                    as String,
        fileName:
            null == fileName
                ? _value.fileName
                : fileName // ignore: cast_nullable_to_non_nullable
                    as String,
        fileSize:
            null == fileSize
                ? _value.fileSize
                : fileSize // ignore: cast_nullable_to_non_nullable
                    as int,
        createdAt:
            null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                    as DateTime,
        mimeType:
            freezed == mimeType
                ? _value.mimeType
                : mimeType // ignore: cast_nullable_to_non_nullable
                    as String?,
        width:
            freezed == width
                ? _value.width
                : width // ignore: cast_nullable_to_non_nullable
                    as int?,
        height:
            freezed == height
                ? _value.height
                : height // ignore: cast_nullable_to_non_nullable
                    as int?,
        durationSeconds:
            freezed == durationSeconds
                ? _value.durationSeconds
                : durationSeconds // ignore: cast_nullable_to_non_nullable
                    as int?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ResultSampleImpl implements _ResultSample {
  const _$ResultSampleImpl({
    required this.id,
    required this.promptId,
    required this.fileType,
    required this.filePath,
    required this.fileName,
    required this.fileSize,
    required this.createdAt,
    this.mimeType,
    this.width,
    this.height,
    this.durationSeconds,
  });

  factory _$ResultSampleImpl.fromJson(Map<String, dynamic> json) =>
      _$$ResultSampleImplFromJson(json);

  @override
  final String id;
  @override
  final String promptId;
  @override
  final FileType fileType;
  @override
  final String filePath;
  @override
  final String fileName;
  @override
  final int fileSize;
  @override
  final DateTime createdAt;
  @override
  final String? mimeType;
  @override
  final int? width;
  @override
  final int? height;
  @override
  final int? durationSeconds;

  @override
  String toString() {
    return 'ResultSample(id: $id, promptId: $promptId, fileType: $fileType, filePath: $filePath, fileName: $fileName, fileSize: $fileSize, createdAt: $createdAt, mimeType: $mimeType, width: $width, height: $height, durationSeconds: $durationSeconds)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ResultSampleImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.promptId, promptId) ||
                other.promptId == promptId) &&
            (identical(other.fileType, fileType) ||
                other.fileType == fileType) &&
            (identical(other.filePath, filePath) ||
                other.filePath == filePath) &&
            (identical(other.fileName, fileName) ||
                other.fileName == fileName) &&
            (identical(other.fileSize, fileSize) ||
                other.fileSize == fileSize) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.mimeType, mimeType) ||
                other.mimeType == mimeType) &&
            (identical(other.width, width) || other.width == width) &&
            (identical(other.height, height) || other.height == height) &&
            (identical(other.durationSeconds, durationSeconds) ||
                other.durationSeconds == durationSeconds));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    promptId,
    fileType,
    filePath,
    fileName,
    fileSize,
    createdAt,
    mimeType,
    width,
    height,
    durationSeconds,
  );

  /// Create a copy of ResultSample
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ResultSampleImplCopyWith<_$ResultSampleImpl> get copyWith =>
      __$$ResultSampleImplCopyWithImpl<_$ResultSampleImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ResultSampleImplToJson(this);
  }
}

abstract class _ResultSample implements ResultSample {
  const factory _ResultSample({
    required final String id,
    required final String promptId,
    required final FileType fileType,
    required final String filePath,
    required final String fileName,
    required final int fileSize,
    required final DateTime createdAt,
    final String? mimeType,
    final int? width,
    final int? height,
    final int? durationSeconds,
  }) = _$ResultSampleImpl;

  factory _ResultSample.fromJson(Map<String, dynamic> json) =
      _$ResultSampleImpl.fromJson;

  @override
  String get id;
  @override
  String get promptId;
  @override
  FileType get fileType;
  @override
  String get filePath;
  @override
  String get fileName;
  @override
  int get fileSize;
  @override
  DateTime get createdAt;
  @override
  String? get mimeType;
  @override
  int? get width;
  @override
  int? get height;
  @override
  int? get durationSeconds;

  /// Create a copy of ResultSample
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ResultSampleImplCopyWith<_$ResultSampleImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
