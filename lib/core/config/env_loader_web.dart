import 'package:http/http.dart' as http;

Future<String?> loadOptionalEnvText() async {
  try {
    final res = await http.get(Uri.parse('.env'));
    if (res.statusCode < 200 || res.statusCode >= 300) return null;
    final text = res.body.trim();
    return text.isEmpty ? null : res.body;
  } catch (_) {
    return null;
  }
}
