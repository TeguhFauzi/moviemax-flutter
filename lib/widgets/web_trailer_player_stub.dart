/// Stub implementation for non-web platforms (Android/iOS).
/// Does nothing — web iframe not available on native platforms.
void registerIFrameView({
  required String viewId,
  required String trailerKey,
  required int startSeconds,
}) {
  // No-op on non-web platforms
}
