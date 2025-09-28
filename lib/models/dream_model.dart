// lib/models/dream_model.dart - Snake Case uyumlu

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
  final DateTime? date;
  final DreamStatus status;
  final String? analysis;
  final String? dreamText;
  final String? title;
  final String? content;
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

  // Factory constructor from Firestore data (Snake Case compatible)
  factory Dream.fromMap(Map<String, dynamic> map) {
    return Dream(
      id: map['id'] ?? '',
      userId: map['userId'] ?? map['user_id'] ?? '',
      audioUrl: map['audioUrl'] ?? map['audio_url'],
      fileName: map['fileName'] ?? map['file_name'],
      createdAt: _parseDateTime(map['createdAt'] ?? map['created_at']) ?? DateTime.now(),
      date: _parseDateTime(map['date']),
      status: _parseStatus(map['status']),
      analysis: map['analysis'],
      dreamText: map['dreamText'] ?? map['dream_text'], // Support both formats
      title: map['title'],
      content: map['content'],
      mood: map['mood'],
      analysisData: map['analysisData'] as Map<String, dynamic>? ?? 
                    map['analysis_data'] as Map<String, dynamic>?,
      updatedAt: _parseDateTime(map['updatedAt'] ?? map['updated_at']),
    );
  }

  // Helper method to parse DateTime from various formats
  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    
    if (value is DateTime) return value;
    
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return null;
      }
    }
    
    // Firestore Timestamp
    if (value.runtimeType.toString() == 'Timestamp') {
      try {
        return (value as dynamic).toDate();
      } catch (e) {
        return null;
      }
    }
    
    return null;
  }

  // Helper method to parse status
  static DreamStatus _parseStatus(dynamic value) {
    if (value == null) return DreamStatus.processing;
    
    switch (value.toString().toLowerCase()) {
      case 'completed':
        return DreamStatus.completed;
      case 'failed':
        return DreamStatus.failed;
      case 'processing':
      default:
        return DreamStatus.processing;
    }
  }

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

  // Convert to Firestore Map (Snake Case for N8N compatibility)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'user_id': userId, // Both formats for compatibility
      'audioUrl': audioUrl,
      'audio_url': audioUrl,
      'fileName': fileName,
      'file_name': fileName,
      'createdAt': createdAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'date': date?.toIso8601String(),
      'status': statusName,
      'analysis': analysis,
      'dreamText': dreamText,
      'dream_text': dreamText, // N8N compatible field
      'title': title,
      'content': content,
      'mood': mood,
      'analysisData': analysisData,
      'analysis_data': analysisData,
      'updatedAt': updatedAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(), // N8N compatible field
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