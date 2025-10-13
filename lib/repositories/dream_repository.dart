// lib/repositories/dream_repository.dart
// Dream Repository - Abstracts data source implementation
// Follows Dependency Inversion Principle

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../models/dream_model.dart';

/// Abstract repository interface
/// Allows for easy testing and swapping implementations
abstract class DreamRepository {
  Stream<List<Dream>> watchUserDreams(String userId);
  Future<void> createDream(String dreamId, Dream dream);
  Future<void> updateDream(String dreamId, Map<String, dynamic> data);
  Future<String> uploadAudio(String userId, File audioFile, String fileName);
  Future<void> deleteDream(String dreamId);
}

/// Firebase implementation of DreamRepository
/// 
/// SOLID Principles:
/// - Single Responsibility: Only handles Firestore/Storage operations
/// - Dependency Inversion: Implements abstract interface
/// - Open/Closed: Can be extended without modification
class FirebaseDreamRepository implements DreamRepository {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  
  FirebaseDreamRepository({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;
  
  @override
  Stream<List<Dream>> watchUserDreams(String userId) {
    return _firestore
        .collection('dreams')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Dream.fromMap(data);
      }).toList();
    });
  }
  
  @override
  Future<void> createDream(String dreamId, Dream dream) async {
    final dreamMap = dream.toMap();
    await _firestore.collection('dreams').doc(dreamId).set(dreamMap);
  }
  
  @override
  Future<void> updateDream(String dreamId, Map<String, dynamic> data) async {
    data['updatedAt'] = Timestamp.fromDate(DateTime.now());
    await _firestore.collection('dreams').doc(dreamId).update(data);
  }
  
  @override
  Future<String> uploadAudio(
    String userId,
    File audioFile,
    String fileName,
  ) async {
    final Reference storageRef = _storage
        .ref()
        .child('users')
        .child(userId)
        .child('dreams')
        .child(fileName);

    final SettableMetadata metadata = SettableMetadata(
      contentType: 'audio/mp4',
      customMetadata: {
        'uploadedBy': userId,
        'uploadedAt': DateTime.now().toIso8601String(),
        'fileSize': audioFile.lengthSync().toString(),
        'codec': 'aac',
      },
    );

    final UploadTask uploadTask = storageRef.putFile(audioFile, metadata);
    final TaskSnapshot snapshot = await uploadTask;
    final String downloadUrl = await snapshot.ref.getDownloadURL();
    
    return downloadUrl;
  }
  
  @override
  Future<void> deleteDream(String dreamId) async {
    await _firestore.collection('dreams').doc(dreamId).delete();
  }
}

/// Mock implementation for testing
/// Can be used without Firebase
class MockDreamRepository implements DreamRepository {
  final List<Dream> _mockDreams = [];
  
  @override
  Stream<List<Dream>> watchUserDreams(String userId) {
    return Stream.value(
      _mockDreams.where((d) => d.userId == userId).toList(),
    );
  }
  
  @override
  Future<void> createDream(String dreamId, Dream dream) async {
    _mockDreams.add(dream);
  }
  
  @override
  Future<void> updateDream(String dreamId, Map<String, dynamic> data) async {
    final index = _mockDreams.indexWhere((d) => d.id == dreamId);
    if (index != -1) {
      // Update mock dream
      final dream = _mockDreams[index];
      _mockDreams[index] = Dream(
        id: dream.id,
        userId: dream.userId,
        audioUrl: data['audioUrl'] ?? dream.audioUrl,
        fileName: data['fileName'] ?? dream.fileName,
        title: data['title'] ?? dream.title,
        dreamText: data['dreamText'] ?? dream.dreamText,
        analysis: data['analysis'] ?? dream.analysis,
        mood: data['mood'] ?? dream.mood,
        status: DreamStatus.values.firstWhere(
          (s) => s.name == (data['status'] ?? dream.status.name),
          orElse: () => dream.status,
        ),
        createdAt: dream.createdAt,
      );
    }
  }
  
  @override
  Future<String> uploadAudio(
    String userId,
    File audioFile,
    String fileName,
  ) async {
    // Mock upload - return fake URL
    return 'mock://audio/$userId/$fileName';
  }
  
  @override
  Future<void> deleteDream(String dreamId) async {
    _mockDreams.removeWhere((d) => d.id == dreamId);
  }
}

