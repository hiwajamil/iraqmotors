/// Result of a browser-native pick-and-upload on web.
class WebPickUploadResult {
  const WebPickUploadResult({
    required this.ok,
    this.url,
    this.error,
    this.cancelled = false,
  });

  final bool ok;
  final String? url;
  final String? error;
  final bool cancelled;
}
