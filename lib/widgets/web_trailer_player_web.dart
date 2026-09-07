// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

/// Web implementation — registers an IFrame element for YouTube embeds.
void registerIFrameView({
  required String viewId,
  required String trailerKey,
  required int startSeconds,
}) {
  ui_web.platformViewRegistry.registerViewFactory(
    viewId,
    (int id) => html.IFrameElement()
      ..src = trailerKey.startsWith('http')
          ? trailerKey
          : 'https://www.youtube-nocookie.com/embed/$trailerKey?autoplay=1&mute=0&controls=1&modestbranding=1&rel=0&enablejsapi=1&start=$startSeconds'
      ..style.border = 'none'
      ..style.width = '100%'
      ..style.height = '100%'
      ..allow =
          'accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture'
      ..allowFullscreen = true,
  );
}
