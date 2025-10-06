// lib/models/dream_model.dart - camelCase/snake_case Uyumlu

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
  
  // Başlık (hem eski hem yeni format)
  final String title;
  final String? baslik; // YENİ: 3 kelimelik başlık
  
  final String? dreamText;
  
  // Duygular (hem eski hem yeni format)
  final String mood; // Backward compatibility için (ana_duygu ile aynı)
  final Map<String, dynamic>? duygular; // YENİ: {ana_duygu, alt_duygular}
  
  // Semboller (hem eski hem yeni format)
  final List<String>? symbols;
  final List<String>? semboller; // YENİ (aynı data)
  
  // Analiz (hem eski hem yeni format)
  final String? analysis; // Backward compatibility
  final String? analiz; // YENİ
  
  // Yeni alanlar
  final String? ruhSagligi; // YENİ: Ruh sağlığı değerlendirmesi
  
  // Eski alanlar (backward compatibility için)
  final String? interpretation; // Artık kullanılmıyor ama eski veriler için
  final String? connectionToPast; // Artık kullanılmıyor
  
  final DreamStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Dream({
    required this.id,
    required this.userId,
    required this.audioUrl,
    this.fileName,
    required this.title,
    this.baslik,
    this.dreamText,
    required this.mood,
    this.duygular,
    this.symbols,
    this.semboller,
    this.analysis,
    this.analiz,
    this.ruhSagligi,
    this.interpretation,
    this.connectionToPast,
    required this.status,
    required this.createdAt,
    this.updatedAt,
  });

  // Firestore'dan oku
  factory Dream.fromMap(Map<String, dynamic> map) {
    // Duygular objesi parse
    Map<String, dynamic>? parsedDuygular;
    if (map['duygular'] != null) {
      parsedDuygular = Map<String, dynamic>.from(map['duygular']);
    }
    
    // Ana duygu - HEM camelCase HEM snake_case destekle
    String finalMood = 'Belirsiz';
    if (parsedDuygular != null) {
      // Önce camelCase'e bak, yoksa snake_case'e bak
      finalMood = parsedDuygular['anaDuygu'] ?? 
                  parsedDuygular['ana_duygu'] ?? 
                  'Belirsiz';
    }
    if (finalMood == 'Belirsiz' && map['mood'] != null) {
      finalMood = map['mood'];
    }
    
    return Dream(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      audioUrl: map['audioUrl'] ?? '',
      fileName: map['fileName'],
      
      // Başlık: Önce baslik'e bak, yoksa title kullan
      title: map['baslik'] ?? map['title'] ?? 'Başlıksız Rüya',
      baslik: map['baslik'],
      
      dreamText: map['dreamText'] ?? map['dream_text'],
      
      // Duygular
      mood: finalMood,
      duygular: parsedDuygular,
      
      // Semboller
      symbols: _parseStringList(map['symbols'] ?? map['semboller']),
      semboller: _parseStringList(map['semboller'] ?? map['symbols']),
      
      // Analiz
      analysis: map['analiz'] ?? map['analysis'] ?? map['interpretation'],
      analiz: map['analiz'] ?? map['analysis'],
      
      // Yeni alanlar
      ruhSagligi: map['ruhSagligi'] ?? map['ruh_sagligi'],
      
      // Eski alanlar
      interpretation: map['interpretation'],
      connectionToPast: map['connectionToPast'] ?? map['connection_to_past'],
      
      status: _parseStatus(map['status']),
      createdAt: _parseDateTime(map['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDateTime(map['updatedAt'] ?? map['updated_at']),
    );
  }

  // Firestore'a yaz
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'audioUrl': audioUrl,
      'fileName': fileName,
      
      // Başlık (her iki format da)
      'title': baslik ?? title,
      'baslik': baslik ?? title,
      
      'dreamText': dreamText,
      'dream_text': dreamText,
      
      // Duygular (her iki format da)
      'mood': duygular?['anaDuygu'] ?? duygular?['ana_duygu'] ?? mood,
      'duygular': duygular ?? {
        'anaDuygu': mood,
        'altDuygular': <String>[],
      },
      
      // Semboller (her iki format da)
      'symbols': semboller ?? symbols,
      'semboller': semboller ?? symbols,
      
      // Analiz (her iki format da)
      'analysis': analiz ?? analysis,
      'analiz': analiz ?? analysis,
      'interpretation': analiz ?? analysis, // Backward compatibility
      
      // Yeni alanlar
      'ruhSagligi': ruhSagligi,
      'ruh_sagligi': ruhSagligi,
      
      // Eski alanlar
      'connectionToPast': connectionToPast,
      'connection_to_past': connectionToPast,
      
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // Helper: String list parse
  static List<String>? _parseStringList(dynamic value) {
    if (value == null) return null;
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return null;
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
    String? baslik,
    String? dreamText,
    String? mood,
    Map<String, dynamic>? duygular,
    List<String>? symbols,
    List<String>? semboller,
    String? analysis,
    String? analiz,
    String? ruhSagligi,
    String? interpretation,
    String? connectionToPast,
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
      baslik: baslik ?? this.baslik,
      dreamText: dreamText ?? this.dreamText,
      mood: mood ?? this.mood,
      duygular: duygular ?? this.duygular,
      symbols: symbols ?? this.symbols,
      semboller: semboller ?? this.semboller,
      analysis: analysis ?? this.analysis,
      analiz: analiz ?? this.analiz,
      ruhSagligi: ruhSagligi ?? this.ruhSagligi,
      interpretation: interpretation ?? this.interpretation,
      connectionToPast: connectionToPast ?? this.connectionToPast,
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
  String get displayTitle => 'Rüyanız: ${baslik ?? title}';

  // YENİ: Ana duygu getter - HEM camelCase HEM snake_case
  String get anaDuygu {
    if (duygular != null) {
      // Önce camelCase'e bak, yoksa snake_case'e bak
      return duygular!['anaDuygu'] ?? 
             duygular!['ana_duygu'] ?? 
             mood;
    }
    return mood;
  }
  
  // YENİ: Alt duygular getter - HEM camelCase HEM snake_case
  List<String> get altDuygular {
    if (duygular != null) {
      // Önce camelCase'e bak, yoksa snake_case'e bak
      var altDuygularList = duygular!['altDuygular'] ?? 
                           duygular!['alt_duygular'];
      if (altDuygularList is List) {
        return List<String>.from(altDuygularList);
      }
    }
    return [];
  }
  
  // YENİ: Tüm semboller (yeni veya eski formatı döndür)
  List<String> get allSymbols {
    if (semboller != null && semboller!.isNotEmpty) return semboller!;
    if (symbols != null && symbols!.isNotEmpty) return symbols!;
    return [];
  }
  
  // YENİ: Analiz metni (yeni veya eski formatı döndür)
  String get fullAnalysis {
    if (analiz != null && analiz!.isNotEmpty) return analiz!;
    if (analysis != null && analysis!.isNotEmpty) return analysis!;
    return 'Analiz bekleniyor...';
  }

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
  
  // YENİ: Ruh sağlığı emoji (görsel için)
  String get ruhSagligiEmoji {
    if (ruhSagligi == null || ruhSagligi!.isEmpty) return '🧘';
    
    final lower = ruhSagligi!.toLowerCase();
    if (lower.contains('endişe') || lower.contains('kaygı') || lower.contains('korku')) {
      return '😰';
    } else if (lower.contains('üzgün') || lower.contains('umutsuz')) {
      return '😔';
    } else if (lower.contains('öfke') || lower.contains('kızgın')) {
      return '😠';
    } else if (lower.contains('huzur') || lower.contains('mutlu')) {
      return '😊';
    } else if (lower.contains('güçlü') || lower.contains('özgüven')) {
      return '💪';
    } else if (lower.contains('enerjik') || lower.contains('neşeli')) {
      return '🌟';
    }
    return '🧘';
  }
}