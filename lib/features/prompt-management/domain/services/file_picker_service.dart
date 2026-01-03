import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:prompt_memo/core/storage/filesystem_storage.dart';

/// Service for picking files of various types
class FilePickerService {
  final FilesystemStorage _storage = FilesystemStorage();

  /// Pick a text file
  Future<PickedFile?> pickTextFile() async {
    if (kIsWeb) return null;

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['txt'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) return null;

    final file = result.files.first;
    if (!_storage.isSupportedFileType(file.name)) return null;

    return PickedFile(
      name: file.name,
      bytes: file.bytes,
      path: file.path,
      type: PickedFileType.text,
    );
  }

  /// Pick an image file
  Future<PickedFile?> pickImageFile() async {
    final picker = ImagePicker();

    if (kIsWeb) {
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image == null) return null;

      final bytes = await image.readAsBytes();
      return PickedFile(
        name: image.name,
        bytes: bytes,
        path: image.path,
        type: PickedFileType.image,
      );
    }

    // For desktop, use file picker
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );

    if (result == null || result.files.isEmpty) return null;

    final file = result.files.first;
    if (!_storage.isSupportedFileType(file.name)) return null;

    return PickedFile(
      name: file.name,
      bytes: file.bytes,
      path: file.path,
      type: PickedFileType.image,
    );
  }

  /// Pick a video file
  Future<PickedFile?> pickVideoFile() async {
    if (kIsWeb) return null;

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp4', 'webm', 'mov'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) return null;

    final file = result.files.first;
    if (!_storage.isSupportedFileType(file.name)) return null;

    return PickedFile(
      name: file.name,
      bytes: file.bytes,
      path: file.path,
      type: PickedFileType.video,
    );
  }

  /// Get image dimensions from bytes
  Future<ImageDimensions?> getImageDimensions(List<int> bytes) async {
    try {
      // For web or simple implementation, return null
      // In a real app, you'd use an image decoder
      return null;
    } catch (e) {
      return null;
    }
  }
}

/// Represents a picked file
class PickedFile {
  final String name;
  final List<int>? bytes;
  final String? path;
  final PickedFileType type;

  PickedFile({
    required this.name,
    required this.bytes,
    required this.path,
    required this.type,
  });

  int get size => bytes?.length ?? 0;
}

/// Type of picked file
enum PickedFileType {
  text,
  image,
  video,
}

/// Image dimensions
class ImageDimensions {
  final int width;
  final int height;

  const ImageDimensions({
    required this.width,
    required this.height,
  });
}
