import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../config/env_config.dart';

import 'web_trailer_player_stub.dart'
    if (dart.library.html) 'web_trailer_player_web.dart' as platform;

class WebTrailerPlayer extends StatefulWidget {
  final String trailerKey;
  final String backdropPath;
  final int startSeconds;

  const WebTrailerPlayer({
    Key? key,
    required this.trailerKey,
    required this.backdropPath,
    this.startSeconds = 0,
  }) : super(key: key);

  @override
  State<WebTrailerPlayer> createState() => _WebTrailerPlayerState();
}

class _WebTrailerPlayerState extends State<WebTrailerPlayer> {
  late String _viewId;
  bool _isRegistered = false;

  @override
  void initState() {
    super.initState();
    _registerFactory();
  }

  @override
  void didUpdateWidget(covariant WebTrailerPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.trailerKey != widget.trailerKey) {
      _registerFactory();
    }
  }

  void _registerFactory() {
    if (kIsWeb && widget.trailerKey.isNotEmpty) {
      _viewId = 'youtube-player-${widget.trailerKey}-${DateTime.now().millisecondsSinceEpoch}';
      platform.registerIFrameView(
        viewId: _viewId,
        trailerKey: widget.trailerKey,
        startSeconds: widget.startSeconds,
      );
      setState(() {
        _isRegistered = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb && widget.trailerKey.isNotEmpty && _isRegistered) {
      return HtmlElementView(viewType: _viewId);
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        widget.backdropPath.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: '${EnvConfig.tmdbBackdropBaseUrl}${widget.backdropPath}',
                fit: BoxFit.cover,
              )
            : Container(color: Colors.black),
        Container(
          color: Colors.black38,
          child: const Center(
            child: Icon(Icons.movie_rounded, color: Colors.white70, size: 64),
          ),
        ),
      ],
    );
  }
}
