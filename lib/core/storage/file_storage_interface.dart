/// Abstract file storage interface extensible for future Git-based sync
abstract class FileStorageInterface {
  /// Stores a file and returns to file path
  Future<String> storeFile({
    required String promptId,
    required String fileName,
    required List<int> bytes,
  });

  /// Gets a file as bytes
  Future<List<int>> getFile(String filePath);

  /// Deletes a file
  Future<void> deleteFile(String filePath);

  /// Gets to base directory for storing files
  Future<String> getStorageDirectory();

  /// Validates if file format is supported
  bool isSupportedFileType(String fileName);

  /// Gets file type from file name
  String getFileType(String fileName);

  /// Cleans up all files for a prompt
  Future<void> cleanupPromptFiles(String promptId);

  /// Hook for future sync implementations
  Future<void> onFileStored(String filePath);

  /// Hook for future sync implementations
  Future<void> onFileDeleted(String filePath);
}
