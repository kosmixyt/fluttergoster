import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_fullscreen/flutter_fullscreen.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../services/api_service.dart';
import '../main.dart';

class PlayerPage extends StatefulWidget {
  final String videoUrl;
  final String title;
  final Map<String, String>? headers;
  final Duration? startPosition;

  const PlayerPage({
    Key? key,
    required this.videoUrl,
    this.title = '',
    this.headers,
    this.startPosition,
  }) : super(key: key);

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  late final Player _player;
  late final VideoController _controller;
  bool _isFullScreen = false;

  @override
  void initState() {
    super.initState();
    _player = Player();
    _controller = VideoController(_player);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initializePlayer();

    // Set preferred orientations for the video player
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    // Hide system UI for immersive experience
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  Future<void> _initializePlayer() async {
    // Récupère ApiService via le provider
    final apiService = ApiServiceProvider.of(context);

    // Utilise les headers avec cookies d'ApiService en utilisant la méthode publique
    final Map<String, String> headers = apiService.getHeadersWithCookies(
      widget.headers,
    );

    // Configure the media
    await _player.open(
      Media(widget.videoUrl, httpHeaders: headers),
      play: true,
    );

    // Set initial position if specified
    if (widget.startPosition != null) {
      await _player.seek(widget.startPosition!);
    }
  }

  void _toggleFullScreen() {
    setState(() {
      _isFullScreen = !_isFullScreen;
    });

    if (_isFullScreen) {
      // // Force landscape orientation and immersive mode
      // SystemChrome.setPreferredOrientations([
      //   DeviceOrientation.landscapeLeft,
      //   DeviceOrientation.landscapeRight,
      // ]);
      FullScreen.setFullScreen(true);
    } else {
      // // Reset to original orientation and immersive mode
      // SystemChrome.setPreferredOrientations([
      //   DeviceOrientation.portraitUp,
      // ]);
      FullScreen.setFullScreen(false);
    }
  }

  @override
  void dispose() {
    _player.dispose();

    FullScreen.setFullScreen(false); // Reset full screen on dispose

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Video(
        controller: _controller,
        controls: (VideoState state) {
          return MaterialControls(
            player: _player,
            videoTitle: widget.title,
            onBackPressed: () => Navigator.pop(context),
            onFullscreenPressed: _toggleFullScreen,
            isFullscreen: _isFullScreen,
          );
        },
      ),
    );
  }
}

// Custom controls class to implement video controls
class MaterialControls extends StatefulWidget {
  final Player player;
  final String videoTitle;
  final VoidCallback onBackPressed;
  final VoidCallback onFullscreenPressed;
  final bool isFullscreen;

  const MaterialControls({
    Key? key,
    required this.player,
    required this.videoTitle,
    required this.onBackPressed,
    required this.onFullscreenPressed,
    required this.isFullscreen,
  }) : super(key: key);

  @override
  State<MaterialControls> createState() => _MaterialControlsState();
}

class _MaterialControlsState extends State<MaterialControls> {
  bool _isControlsVisible = true;
  Timer? _hideControlsTimer;
  double _lastVolume = 1.0; // Store the last non-zero volume level
  String _currentSubtitle = "No Subs";
  String _currentAudioTrack = "Audio";

  @override
  void initState() {
    super.initState();
    _startHideControlsTimer();
    // Initialize track information
    _updateTrackInfo();
  }

  // Add method to update track information
  Future<void> _updateTrackInfo() async {
    // Wait a moment for the player to load track information
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        final subtitles = widget.player.state.tracks.subtitle;
        final audioTracks = widget.player.state.tracks.audio;

        // Get the currently active track IDs
        final activeAudioId = widget.player.state.track.audio;
        final activeSubtitleId = widget.player.state.track.subtitle;

        setState(() {
          // Check if any subtitle is active by looking at the active ID
          _currentSubtitle =
              subtitles.isEmpty
                  ? "No Subs"
                  : (activeSubtitleId != -1 ? "Subtitles On" : "No Subs");

          // Find the active audio track by ID
          final activeAudio =
              audioTracks.isEmpty
                  ? null
                  : audioTracks.firstWhere(
                    (t) => t.id == activeAudioId,
                    orElse: () => audioTracks.first,
                  );

          _currentAudioTrack = activeAudio?.title ?? "Audio";
        });
      }
    });
  }

  // Show subtitle selection dialog
  void _showSubtitleSelectionDialog() {
    final tracks = widget.player.state.tracks.subtitle;
    final activeTrackId = widget.player.state.track.subtitle;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Select Subtitles'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView(
                shrinkWrap: true,
                children: [
                  ListTile(
                    title: const Text('Off'),
                    selected:
                        activeTrackId ==
                        -1, // -1 means no subtitle track is active
                    onTap: () {
                      widget.player.setSubtitleTrack(SubtitleTrack.no());
                      setState(() => _currentSubtitle = "No Subs");
                      Navigator.pop(context);
                    },
                  ),
                  ...tracks.map(
                    (track) => ListTile(
                      title: Text(
                        '${track.title} (${track.language})' ?? 'Unknown',
                      ),
                      selected: track.id == activeTrackId,
                      onTap: () {
                        widget.player.setSubtitleTrack(track);
                        setState(
                          () =>
                              _currentSubtitle = track.title ?? "Subtitles On",
                        );
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  // Show audio track selection dialog
  void _showAudioSelectionDialog() {
    final tracks = widget.player.state.tracks.audio;
    final activeTrackId = widget.player.state.track.audio;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Select Audio Track'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView(
                shrinkWrap: true,
                children: [
                  ...tracks.map(
                    (track) => ListTile(
                      title: Text(track.title ?? 'Audio Track ${track.id}'),
                      subtitle:
                          track.language != null ? Text(track.language!) : null,
                      // Check if this track is the active one
                      selected: track.id == activeTrackId,
                      onTap: () {
                        widget.player.setAudioTrack(track);
                        setState(
                          () => _currentAudioTrack = track.title ?? "Audio",
                        );
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  void _startHideControlsTimer({bool immediate = false}) {
    _cancelHideControlsTimer();
    Duration delay = immediate ? Duration.zero : const Duration(seconds: 3);

    _hideControlsTimer = Timer(delay, () {
      if (mounted) {
        setState(() {
          _isControlsVisible = false;
        });
      }
    });
  }

  void _cancelHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = null;
  }

  void _toggleControls() {
    setState(() {
      _isControlsVisible = !_isControlsVisible;
    });

    if (_isControlsVisible) {
      _startHideControlsTimer();
    } else {
      _cancelHideControlsTimer();
    }
  }

  // Handle mouse hover events
  void _showControls() {
    _cancelHideControlsTimer();
    if (!_isControlsVisible && mounted) {
      setState(() {
        _isControlsVisible = true;
      });
    }
  }

  void _hideControls() {
    _startHideControlsTimer(immediate: false);
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _showControls(),
      onExit: (_) => _hideControls(),
      child: GestureDetector(
        onTap: _toggleControls,
        child: Stack(
          children: [
            // Transparent layer covering the whole video
            Positioned.fill(child: Container(color: Colors.transparent)),

            // Controls overlay that appears/disappears
            if (_isControlsVisible)
              AnimatedOpacity(
                opacity: _isControlsVisible ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: Container(
                  color: Colors.black.withOpacity(0.5),
                  child: Column(
                    children: [
                      // Top controls - Title and back button
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 8.0,
                        ),
                        color: Colors.black.withOpacity(0.7),
                        child: Row(
                          children: [
                            // Back button with arrow
                            IconButton(
                              icon: const Icon(
                                Icons.arrow_back,
                                color: Colors.white,
                              ),
                              onPressed: widget.onBackPressed,
                            ),
                            const SizedBox(width: 8),
                            // Episode title
                            Text(
                              widget.videoTitle,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Spacer(),
                            // Screen cast button
                            IconButton(
                              icon: const Icon(Icons.cast, color: Colors.white),
                              onPressed: () {
                                // Implement casting functionality
                              },
                            ),
                            // HD indicator
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              margin: const EdgeInsets.symmetric(horizontal: 5),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Colors.white,
                                  width: 1.0,
                                ),
                                borderRadius: BorderRadius.circular(4.0),
                              ),
                              child: const Text(
                                'HD',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            // FullHD text
                            const Text(
                              "FullHd",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 12),
                            // CC button for subtitles
                            TextButton(
                              onPressed: () {
                                _showSubtitleSelectionDialog();
                                _startHideControlsTimer();
                              },
                              style: TextButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(50, 30),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 1.0,
                                      ),
                                      borderRadius: BorderRadius.circular(4.0),
                                    ),
                                    child: const Text(
                                      'CC',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    _currentSubtitle == "No Subs"
                                        ? "No Subs"
                                        : "Subs",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Audio control
                            TextButton.icon(
                              onPressed: () {
                                _showAudioSelectionDialog();
                                _startHideControlsTimer();
                              },
                              icon: const Icon(
                                Icons.headset,
                                color: Colors.white,
                                size: 20,
                              ),
                              label: Text(
                                "fre",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                              style: TextButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Spacer to push playback controls to bottom
                      const Spacer(),

                      // Bottom playback controls
                      Container(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        color: Colors.black.withOpacity(0.7),
                        child: Column(
                          children: [
                            // Progress bar with yellow indicator
                            _buildProgressBar(),

                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                              ),
                              child: Row(
                                children: [
                                  // Play/Pause button
                                  StreamBuilder<bool>(
                                    stream: widget.player.stream.playing,
                                    builder: (context, snapshot) {
                                      final playing =
                                          snapshot.data ??
                                          widget.player.state.playing;
                                      return IconButton(
                                        icon: Icon(
                                          playing
                                              ? Icons.pause
                                              : Icons.play_arrow,
                                          color: Colors.white,
                                        ),
                                        iconSize: 28,
                                        onPressed: () {
                                          if (playing) {
                                            widget.player.pause();
                                          } else {
                                            widget.player.play();
                                          }
                                          _startHideControlsTimer();
                                        },
                                      );
                                    },
                                  ),

                                  // Volume controls
                                  _buildVolumeControl(),

                                  const Spacer(),

                                  // Fullscreen button
                                  IconButton(
                                    icon: Icon(
                                      widget.isFullscreen
                                          ? Icons.fullscreen_exit
                                          : Icons.fullscreen,
                                      color: Colors.white,
                                    ),
                                    onPressed: () {
                                      widget.onFullscreenPressed();
                                      _startHideControlsTimer();
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Volume control widget
  Widget _buildVolumeControl() {
    return StreamBuilder<double>(
      stream: widget.player.stream.volume,
      builder: (context, snapshot) {
        // Get current volume with fallback
        double volume = snapshot.data ?? widget.player.state.volume;

        // Convert from player scale (0-1) to slider scale (0-100)
        volume = (volume * 100).clamp(0.0, 100.0);

        // Store non-zero volume for unmute operation
        if (volume > 5 && mounted) {
          _lastVolume = volume;
        }

        return Row(
          children: [
            // Mute/Unmute button with improved icons
            IconButton(
              icon: Icon(
                volume < 5
                    ? Icons.volume_off
                    : volume < 30
                    ? Icons.volume_down
                    : Icons.volume_up,
                color: Colors.white,
              ),
              onPressed: () {
                if (volume < 5) {
                  // When unmuting, restore to a reasonable volume
                  final newVolume = _lastVolume > 10 ? _lastVolume : 50;
                  // Convert from slider scale (0-100) to player scale (0-1)
                  widget.player.setVolume(newVolume / 100);
                } else {
                  // When muting, set volume to 0
                  widget.player.setVolume(0.0);
                }
              },
            ),

            // Volume slider with more precise control
            SizedBox(
              width: 100,
              child: SliderTheme(
                data: SliderThemeData(
                  trackHeight: 2.0,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 6.0,
                  ),
                  overlayShape: const RoundSliderOverlayShape(
                    overlayRadius: 10.0,
                  ),
                  activeTrackColor: Colors.white,
                  inactiveTrackColor: Colors.grey,
                  thumbColor: Colors.white,
                ),
                child: Slider(
                  value: volume,
                  min: 0.0,
                  max: 100.0,
                  onChanged: (value) {
                    double newVolume = value;
                    // Convert from slider scale (0-100) to player scale (0-1)
                    widget.player.setVolume(newVolume / 100);
                  },
                  onChangeStart: (_) {
                    _cancelHideControlsTimer();
                  },
                  onChangeEnd: (value) {
                    // Only explicitly mute if dragged to zero
                    if (value < 5) {
                      if (value <= 1) {
                        // User intended to mute
                        widget.player.setVolume(0.0);
                      } else {
                        // Small value but not zero - ensure audible
                        widget.player.setVolume(5.0);
                      }
                    }
                    _startHideControlsTimer();
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Progress bar widget with yellow indicator
  Widget _buildProgressBar() {
    return StreamBuilder<Duration>(
      stream: widget.player.stream.position,
      builder: (context, positionSnapshot) {
        final position = positionSnapshot.data ?? widget.player.state.position;

        return StreamBuilder<Duration>(
          stream: widget.player.stream.duration,
          builder: (context, durationSnapshot) {
            final duration =
                durationSnapshot.data ?? widget.player.state.duration;
            final double progressPercent =
                duration.inMilliseconds > 0
                    ? (position.inMilliseconds / duration.inMilliseconds).clamp(
                      0.0,
                      1.0,
                    )
                    : 0.0;

            return Column(
              children: [
                // Custom progress bar with yellow indicator
                StreamBuilder<bool>(
                  stream: widget.player.stream.playing,
                  builder: (context, playingSnapshot) {
                    final isPlaying = playingSnapshot.data ?? false;

                    return SliderTheme(
                      data: SliderThemeData(
                        trackHeight: 2.0,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 6.0,
                        ),
                        overlayShape: const RoundSliderOverlayShape(
                          overlayRadius: 10.0,
                        ),
                        activeTrackColor: Colors.grey,
                        inactiveTrackColor: Colors.grey[800],
                        thumbColor:
                            Colors
                                .yellow, // Yellow indicator as shown in the image
                        overlayColor: Colors.yellow.withOpacity(0.3),
                      ),
                      child: Slider(
                        value: progressPercent,
                        min: 0.0,
                        max: 1.0,
                        onChanged: (value) {
                          // Calculate new position based on percentage
                          final newPosition = Duration(
                            milliseconds:
                                (duration.inMilliseconds * value).round(),
                          );

                          // Seek to new position and ensure it's applied
                          widget.player.seek(newPosition);
                        },
                        onChangeStart: (_) {
                          // Pause playback during seek for more accurate positioning
                          final wasPlaying = isPlaying;
                          if (wasPlaying) {
                            // Store play state temporarily
                            widget.player.pause();
                          }
                          _cancelHideControlsTimer();
                        },
                        onChangeEnd: (value) {
                          // Resume playback if it was playing before
                          final newPosition = Duration(
                            milliseconds:
                                (duration.inMilliseconds * value).round(),
                          );

                          // Ensure seek completes properly
                          widget.player.seek(newPosition).then((_) {
                            if (isPlaying) {
                              widget.player.play();
                            }
                          });

                          _startHideControlsTimer();
                        },
                      ),
                    );
                  },
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      Text(
                        _formatDuration(position),
                        style: const TextStyle(color: Colors.white),
                      ),
                      const Spacer(),
                      Text(
                        _formatDuration(duration),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return duration.inHours > 0
        ? '$hours:$minutes:$seconds'
        : '$minutes:$seconds';
  }
}
