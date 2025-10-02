// lib/models/dream_model.dart

enum DreamStatus {
  processing,
  completed,
  failed,
}

class Dream {
  final String id;
  final String userId;
  final String audioUrl;
  final String? fileName;
  final String title;
  final String? dreamText;
  final String? analysis;
  final String? interpretation;
  final String? connectionToPast;
  final String mood;
  final List<String>? symbols;
  final DreamStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Dream({
    required this.id,
    required this.userId,
    required this.audioUrl,
    this.fileName,
    required this.title,
    this.dreamText,
    this.analysis,
    this.interpretation,
    this.connectionToPast,
    required this.mood,
    this.symbols,
    required this.status,
    required this.createdAt,
    this.updatedAt,
  });

  // Firestore'dan oku
  factory Dream.fromMap(Map<String, dynamic> map) {
    return Dream(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      audioUrl: map['audioUrl'] ?? '',
      fileName: map['fileName'],
      title: map['title'] ?? 'Başlıksız Rüya',
      dreamText: map['dreamText'],
      analysis: map['analysis'],
      interpretation: map['interpretation'],
      connectionToPast: map['connectionToPast'],
      mood: map['mood'] ?? 'Belirsiz',
      symbols: (map['symbols'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
      status: _parseStatus(map['status']),
      createdAt: _parseDateTime(map['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDateTime(map['updatedAt']),
    );
  }

  // Firestore'a yaz
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'audioUrl': audioUrl,
      'fileName': fileName,
      'title': title,
      'dreamText': dreamText,
      'analysis': analysis,
      'interpretation': interpretation,
      'connectionToPast': connectionToPast,
      'mood': mood,
      'symbols': symbols,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  // Helper: DateTime parse
  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    
    try {
      if (value is DateTime) {
        return value;
      } else if (value is String) {
        return DateTime.parse(value);
      } else if (value.runtimeType.toString().contains('Timestamp')) {
        // Firestore Timestamp
        return (value as dynamic).toDate();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Helper: Status parse
  static DreamStatus _parseStatus(dynamic status) {
    if (status == null) return DreamStatus.processing;
    
    final statusString = status.toString().toLowerCase();
    switch (statusString) {
      case 'completed':
        return DreamStatus.completed;
      case 'failed':
        return DreamStatus.failed;
      case 'processing':
      default:
        return DreamStatus.processing;
    }
  }

  // Copy with
  Dream copyWith({
    String? id,
    String? userId,
    String? audioUrl,
    String? fileName,
    String? title,
    String? dreamText,
    String? analysis,
    String? interpretation,
    String? connectionToPast,
    String? mood,
    List<String>? symbols,
    DreamStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Dream(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      audioUrl: audioUrl ?? this.audioUrl,
      fileName: fileName ?? this.fileName,
      title: title ?? this.title,
      dreamText: dreamText ?? this.dreamText,
      analysis: analysis ?? this.analysis,
      interpretation: interpretation ?? this.interpretation,
      connectionToPast: connectionToPast ?? this.connectionToPast,
      mood: mood ?? this.mood,
      symbols: symbols ?? this.symbols,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Analiz tamamlandı mı?
  bool get isCompleted => status == DreamStatus.completed;
  
  // Analiz yapılıyor mu?
  bool get isProcessing => status == DreamStatus.processing;
  
  // Analiz başarısız mı?
  bool get isFailed => status == DreamStatus.failed;

  // UI için başlık formatı
  String get displayTitle => 'Rüyanız: $title';

  // Tarih formatı
  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    
    if (difference.inMinutes < 1) {
      return 'Az önce';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} dakika önce';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} saat önce';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} gün önce';
    } else {
      // Format: 29/09/2025 12:15
      return '${createdAt.day.toString().padLeft(2, '0')}/'
             '${createdAt.month.toString().padLeft(2, '0')}/'
             '${createdAt.year} '
             '${createdAt.hour.toString().padLeft(2, '0')}:'
             '${createdAt.minute.toString().padLeft(2, '0')}';
    }
  }

  // Status text
  String get statusText {
    switch (status) {
      case DreamStatus.completed:
        return 'Tamamlandı';
      case DreamStatus.processing:
        return 'Analiz Yapılıyor';
      case DreamStatus.failed:
        return 'Başarısız';
    }
  }
}