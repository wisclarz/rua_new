// lib/services/service_locator.dart
// Simple Service Locator for Dependency Injection
// Alternative to heavier DI frameworks like get_it

import '../repositories/dream_repository.dart';
import 'n8n_service.dart';
import 'openai_service.dart';

/// Simple service locator pattern
/// 
/// SOLID Principles:
/// - Dependency Inversion: Services depend on abstractions
/// - Single Responsibility: Only manages service instances
/// 
/// Usage:
/// ```dart
/// final repository = ServiceLocator.dreamRepository;
/// ```
class ServiceLocator {
  ServiceLocator._(); // Private constructor

  // Singleton instances
  static DreamRepository? _dreamRepository;
  static N8nService? _n8nService;
  static OpenAIService? _openAIService;

  /// Get or create DreamRepository instance
  static DreamRepository get dreamRepository {
    _dreamRepository ??= FirebaseDreamRepository();
    return _dreamRepository!;
  }

  /// Get or create N8nService instance
  static N8nService get n8nService {
    _n8nService ??= N8nService();
    return _n8nService!;
  }

  /// Get or create OpenAIService instance
  static OpenAIService get openAIService {
    _openAIService ??= OpenAIService();
    return _openAIService!;
  }

  /// Register custom implementations (useful for testing)
  static void registerDreamRepository(DreamRepository repository) {
    _dreamRepository = repository;
  }

  static void registerN8nService(N8nService service) {
    _n8nService = service;
  }

  static void registerOpenAIService(OpenAIService service) {
    _openAIService = service;
  }

  /// Reset all services (useful for testing)
  static void reset() {
    _dreamRepository = null;
    _n8nService = null;
    _openAIService = null;
  }
}

