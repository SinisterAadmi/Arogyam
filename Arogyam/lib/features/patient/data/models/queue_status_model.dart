class QueueStatusModel {
  final String clinicName;
  final String tokenNumber;
  final int peopleAhead;
  final String currentlyServing;
  final String estimatedWaitTime;
  final String status;
  final bool isInQueue;
  final String? message;
  final String? completedAt;

  QueueStatusModel({
    required this.clinicName,
    required this.tokenNumber,
    required this.peopleAhead,
    required this.currentlyServing,
    required this.estimatedWaitTime,
    required this.status,
    this.isInQueue = true,
    this.message,
    this.completedAt,
  });

  factory QueueStatusModel.notInQueue({String message = "You're not currently in a queue"}) {
    return QueueStatusModel(
      clinicName: '',
      tokenNumber: '',
      peopleAhead: 0,
      currentlyServing: '',
      estimatedWaitTime: '',
      status: 'none',
      isInQueue: false,
      message: message,
      completedAt: null,
    );
  }

  factory QueueStatusModel.fromJson(Map<String, dynamic> json) {
    final statusStr = json['status']?.toString().toLowerCase() ?? '';
    final isInactive = statusStr.isEmpty ||
        statusStr == 'none' ||
        statusStr == 'completed' ||
        statusStr == 'done' ||
        statusStr == 'absent';

    if (isInactive ||
        (json.containsKey('message') && (json['clinicName'] == null || json['tokenNumber'] == null))) {
      return QueueStatusModel.notInQueue(
        message: json['message']?.toString() ?? "You're not currently in a queue",
      );
    }

    return QueueStatusModel(
      clinicName: json['clinicName']?.toString() ?? '',
      tokenNumber: json['tokenNumber']?.toString() ?? '',
      peopleAhead: json['peopleAhead'] is int
          ? json['peopleAhead']
          : int.tryParse(json['peopleAhead']?.toString() ?? '0') ?? 0,
      currentlyServing: json['currentlyServing']?.toString() ?? '',
      estimatedWaitTime: json['estimatedWaitTime'] != null
          ? (json['estimatedWaitTime'].toString().contains('min')
              ? json['estimatedWaitTime'].toString()
              : '${json['estimatedWaitTime']} mins')
          : '',
      status: statusStr.isNotEmpty ? statusStr : 'waiting',
      isInQueue: true,
      message: json['message']?.toString(),
      completedAt: json['completedAt']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'clinicName': clinicName,
      'tokenNumber': tokenNumber,
      'peopleAhead': peopleAhead,
      'currentlyServing': currentlyServing,
      'estimatedWaitTime': estimatedWaitTime,
      'status': status,
      'isInQueue': isInQueue,
      if (message != null) 'message': message,
      if (completedAt != null) 'completedAt': completedAt,
    };
  }
}
