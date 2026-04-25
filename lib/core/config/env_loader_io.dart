import 'dart:io';

Future<String?> loadOptionalEnvText() async {
  final file = File('.env');
  if (!await file.exists()) return null;
  final content = await file.readAsString();
  final trimmed = content.trim();
  return trimmed.isEmpty ? null : content;
}
