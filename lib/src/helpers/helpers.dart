import 'dart:convert';

// ---------------------------------------------------------------------------
// Utility Helpers
// ---------------------------------------------------------------------------

/// Returns MIME type based on file extension extracted from [path].
///
/// Used primarily when serving static files so correct
/// `Content-Type` headers can be attached to responses.
///
/// If extension is unknown, defaults to:
///
/// ```
/// application/octet-stream
/// ```
///
/// Example:
/// ```dart
/// final mime = getMimeType("image.png");
/// print(mime); // image/png
/// ```
String getMimeType(String path) {
  final ext = path.split('.').last.toLowerCase();
  switch (ext) {
    case 'jpg':
    case 'jpeg':
      return 'image/jpeg';
    case 'png':
      return 'image/png';
    case 'gif':
      return 'image/gif';
    case 'svg':
      return 'image/svg+xml';
    case 'pdf':
      return 'application/pdf';
    case 'txt':
      return 'text/plain';
    case 'csv':
      return 'text/csv';
    case 'json':
      return 'application/json';
    case 'html':
      return 'text/html';
    case 'zip':
      return 'application/zip';
    default:
      return 'application/octet-stream';
  }
}

/// Attempts to parse a JSON string safely.
///
/// Returns:
/// • `Map<String, dynamic>` if valid JSON object
/// • `null` if parsing fails or invalid JSON
///
/// This helper prevents exceptions when handling incoming
/// request or socket payloads.
///
/// Example:
/// ```dart
/// final data = isValidJsonData('{"name":"Alex"}');
/// if (data != null) {
///   print(data['name']);
/// }
/// ```
///
/// Typical use cases:
/// • WebSocket message parsing
/// • request body parsing
/// • validation pipelines
Map<String, dynamic>? isValidJsonData(String data) {
  try {
    final json = jsonDecode(data);
    return json;
  } catch (e) {
    return null;
  }
}
