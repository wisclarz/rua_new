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
  final DateTime? date; // Added for compatibility
  final DreamStatus status;
  final String? analysis;
  final String? dreamText;
  final String? title; // Added title property
  final String? content; // Added content property (alias for dreamText)
  final String? mood;
  final Map<String, dynamic>? analysisData;
  final DateTime? updatedAt;

  Dream({
    required this.id,
    required this.userId,
    this.audioUrl,
    this.fileName,
    required this.createdAt,
    DateTime? date,
    required this.status,
    this.analysis,
    this.dreamText,
    this.title,
    this.content,
    this.mood,
    this.analysisData,
    this.updatedAt,
  }) : date = date ?? createdAt;

  // Getter for content (returns dreamText or content)
  String? get displayContent => content ?? dreamText;
  
  // Getter for title (auto-generates from content if not provided)
  String? get displayTitle {
    if (title != null && title!.isNotEmpty) {
      return title;
    }
    
    // Auto-generate title from content
    final text = displayContent;
    if (text != null && text.isNotEmpty) {
      // Take first 30 characters and add "..."
      if (text.length <= 30) {
        return text;
      } else {
        return '${text.substring(0, 30)}...';
      }
    }
    
    return 'Başlıksız Rüya';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'audioUrl': audioUrl,
      'fileName': fileName,
      'createdAt': createdAt.toIso8601String(),
      'date': date?.toIso8601String(),
      'status': statusName,
      'analysis': analysis,
      'dreamText': dreamText,
      'title': title,
      'content': content,
      'mood': mood,
      'analysisData': analysisData,
      'updatedAt': updatedAt?.toIso8601String(),
    };
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
    final dateToFormat = date ?? createdAt;
    return '${dateToFormat.day}/${dateToFormat.month}/${dateToFormat.year} ${dateToFormat.hour}:${dateToFormat.minute.toString().padLeft(2, '0')}';
  }

  Dream copyWith({
    String? id,
    String? userId,
    String? audioUrl,
    String? fileName,
    DateTime? createdAt,
    DateTime? date,
    DreamStatus? status,
    String? analysis,
    String? dreamText,
    String? title,
    String? content,
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
      date: date ?? this.date,
      status: status ?? this.status,
      analysis: analysis ?? this.analysis,
      dreamText: dreamText ?? this.dreamText,
      title: title ?? this.title,
      content: content ?? this.content,
      mood: mood ?? this.mood,
      analysisData: analysisData ?? this.analysisData,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}