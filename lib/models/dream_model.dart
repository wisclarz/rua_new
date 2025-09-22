// Firebase temporarily disabled for UI development  
// import 'package:cloud_firestore/cloud_firestore.dart';

enum DreamStatus {
  processing,
  completed,
  failed,
}

class Dream {
  final String id;
  final String userId;
  final String? audioUrl;
  final String? fileName;
  final DateTime createdAt;
  final DreamStatus status;
  final String? analysis;
  final String? dreamText; // Added for the mock data
  final String? mood; // Added for the mock data
  final Map<String, dynamic>? analysisData;
  final DateTime? updatedAt;

  Dream({
    required this.id,
    required this.userId,
    this.audioUrl,
    this.fileName,
    required this.createdAt,
    required this.status,
    this.analysis,
    this.dreamText, // Added parameter
    this.mood, // Added parameter
    this.analysisData,
    this.updatedAt,
  });

  // Firebase temporarily disabled for UI development
  /*
  factory Dream.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    return Dream(
      id: doc.id,
      userId: data['userId'] ?? '',
      audioUrl: data['audioUrl'],
      fileName: data['fileName'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: _parseStatus(data['status']),
      analysis: data['analysis'],
      dreamText: data['dreamText'],
      mood: data['mood'],
      analysisData: data['analysisData'],
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
  */

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'audioUrl': audioUrl,
      'fileName': fileName,
      'createdAt': createdAt.toIso8601String(),
      'status': statusName,
      'analysis': analysis,
      'dreamText': dreamText,
      'mood': mood,
      'analysisData': analysisData,
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  static DreamStatus _parseStatus(String? status) {
    switch (status) {
      case 'completed':
        return DreamStatus.completed;
      case 'failed':
        return DreamStatus.failed;
      case 'processing':
      default:
        return DreamStatus.processing;
    }
  }

  String get statusText {
    switch (status) {
      case DreamStatus.processing:
        return 'Analiz Ediliyor';
      case DreamStatus.completed:
        return 'Tamamlandı';
      case DreamStatus.failed:
        return 'Başarısız';
    }
  }

  String get statusName {
    switch (status) {
      case DreamStatus.processing:
        return 'processing';
      case DreamStatus.completed:
        return 'completed';
      case DreamStatus.failed:
        return 'failed';
    }
  }

  String get formattedDate {
    return '${createdAt.day}/${createdAt.month}/${createdAt.year} ${createdAt.hour}:${createdAt.minute.toString().padLeft(2, '0')}';
  }

  Dream copyWith({
    String? id,
    String? userId,
    String? audioUrl,
    String? fileName,
    DateTime? createdAt,
    DreamStatus? status,
    String? analysis,
    String? dreamText,
    String? mood,
    Map<String, dynamic>? analysisData,
    DateTime? updatedAt,
  }) {
    return Dream(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      audioUrl: audioUrl ?? this.audioUrl,
      fileName: fileName ?? this.fileName,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      analysis: analysis ?? this.analysis,
      dreamText: dreamText ?? this.dreamText,
      mood: mood ?? this.mood,
      analysisData: analysisData ?? this.analysisData,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
