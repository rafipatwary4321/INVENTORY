import 'env_loader_stub.dart'
    if (dart.library.io) 'env_loader_io.dart'
    if (dart.library.html) 'env_loader_web.dart' as impl;

/// Loads optional `.env` content without requiring Flutter asset registration.
Future<String?> loadOptionalEnvText() => impl.loadOptionalEnvText();
