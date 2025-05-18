class ProcessingStatus {
  final String taskId;
  final String state;
  final String status;
  final int progress;
  final String? error;
  final String fileName;
  final String fileID;

  ProcessingStatus({
    required this.taskId,
    required this.state,
    required this.status,
    required this.progress,
    this.error,
    required this.fileName,
    this.fileID = '',
  });

  factory ProcessingStatus.fromJson(
    Map<String, dynamic> json,
    String fileName, {
    String fileID = '',
  }) {
    return ProcessingStatus(
      taskId: json['task_id'] ?? '',
      state: json['state'] ?? 'UNKNOWN',
      status: json['status'] ?? '',
      progress: json['progress'] ?? 0,
      error: json['error'],
      fileName: fileName,
      fileID: fileID,
    );
  }

  bool get isComplete => state == 'SUCCESS';
  bool get isError => state == 'ERROR' || state == 'FAILURE';
  bool get isProcessing => state == 'PROCESSING' || state == 'PENDING';
}
