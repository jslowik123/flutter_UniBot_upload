class ProcessingStatus {
  final String status;
  final int progress;
  final String? error;
  final String fileName;
  final String fileID;
  final bool processing;

  ProcessingStatus({
    required this.status,
    required this.progress,
    this.error,
    required this.fileName,
    required this.fileID,
    required this.processing,
  });

  factory ProcessingStatus.fromFirebase(
    Map<dynamic, dynamic> data,
    String fileName,
    String fileID,
  ) {
    return ProcessingStatus(
      status: data['status'] ?? 'Unbekannt',
      progress: data['progress'] ?? 0,
      error: data['error'],
      fileName: fileName,
      fileID: fileID,
      processing: data['processing'] ?? false,
    );
  }

  bool get isComplete => !processing && progress >= 100;
  bool get isError => error != null;
  bool get isProcessing => processing;
}
