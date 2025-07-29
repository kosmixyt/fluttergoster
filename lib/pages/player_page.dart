import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_fullscreen/flutter_fullscreen.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../services/api_service.dart';
import '../models/data_models.dart';
import '../main.dart';
import '../widgets/cookie_image.dart'; // Add import for CookieImage

class PlayerPage extends StatefulWidget {
  final String transcodeUrl;
  final dynamic sourceItem;
  final String? sourceItemId;
  final String? sourceItemType;
  final String? seasonId;
  final int? seasonNumber;
  final AvailableTorrent? torrentInfo;

  const PlayerPage({
    Key? key,
    required this.transcodeUrl,
    this.sourceItem,
    this.sourceItemId,
    this.sourceItemType,
    this.seasonId,
    this.seasonNumber,
    this.torrentInfo,
  }) : super(key: key);

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage>
    with AutomaticKeepAliveClientMixin {
  late final Player _player;
  late final VideoController _controller;
  bool _isFullScreen = false;
  bool _isLoading = true;
  String _errorMessage = '';
  String _progressMessage = '';
  TranscoderRes? _transcoderData;
  Timer? _progressUpdateTimer;
  late ApiService _apiService;
  bool _showNextCard =
      false; // Add this line to track when to show the next card
  bool _isMobileDevice = false; // Cache the mobile device state
  Size? _cachedScreenSize; // Cache screen size to avoid rebuilds
  bool _didChangeDependenciesCalled =
      false; // Track if dependencies were initialized

  @override
  bool get wantKeepAlive => true;

  @override
  void didUpdateWidget(PlayerPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Don't update on widget changes to prevent rebuilds during resize
    // Only update if critical properties changed
    if (oldWidget.transcodeUrl != widget.transcodeUrl ||
        oldWidget.sourceItemId != widget.sourceItemId) {
      // Only reinitialize if the actual content changed, not just layout
      _initializePlayer();
    }
  }

  @override
  void initState() {
    super.initState();
    _player = Player();
    _controller = VideoController(_player);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Only initialize once to prevent rebuilds on window resize
    if (!_didChangeDependenciesCalled) {
      _didChangeDependenciesCalled = true;

      _apiService = ApiServiceProvider.of(context);

      // Initialize mobile device state
      _updateMobileDeviceState();

      _initializePlayer();

      // Set preferred orientations for the video player
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);

      // Hide system UI for immersive experience
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    }
  }

  // Update mobile device state without causing rebuilds
  void _updateMobileDeviceState() {
    final size = MediaQuery.of(context).size;

    // Only update if size actually changed to avoid unnecessary rebuilds
    if (_cachedScreenSize != size) {
      _cachedScreenSize = size;
      final newIsMobileDevice = size.shortestSide < 600;

      // Only update state if mobile device status actually changed
      if (_isMobileDevice != newIsMobileDevice) {
        _isMobileDevice = newIsMobileDevice;
      }
    }
  }

  void _onProgress(String progressData) {
    setState(() {
      _progressMessage = progressData;
    });
  }

  void _onError(String error) {
    setState(() {
      _errorMessage = error;
      _isLoading = false;
    });
  }

  // Start sending periodic progress updates to the server
  void _startProgressUpdates() {
    // Cancel any existing timer first
    _progressUpdateTimer?.cancel();

    // Create a new timer that sends updates every 10 seconds
    _progressUpdateTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (_transcoderData != null && mounted) {
        final currentPosition = _player.state.position.inSeconds;
        final totalDuration = _player.state.duration.inSeconds;

        // Check if we're in the last 5 minutes of playback
        if (totalDuration - currentPosition <= 300 && totalDuration > 0) {
          if (!_showNextCard &&
              _transcoderData!.next.TRANSCODE_URL.isNotEmpty) {
            setState(() {
              _showNextCard = true;
            });
          }
        } else if (_showNextCard) {
          setState(() {
            _showNextCard = false;
          });
        }

        // Only send updates if we're actually playing (position > 0)
        if (currentPosition > 0) {
          _apiService
              .sendProgress(
                _transcoderData!.file.id.toString(),
                currentPosition,
                _transcoderData!.mediaId.toString(),
                widget.sourceItemType == 'tv'
                    ? _transcoderData!.getEpisode().toString()
                    : null,
                _player.state.duration.inSeconds,
              )
              .catchError((error) {
                // Silently handle errors to not interrupt playback
                print('Error sending progress update: $error');
              });
        }
      }
    });
  }

  Future<void> _initializePlayer() async {
    try {
      // Get ApiService via the provider
      final apiService = ApiServiceProvider.of(context);
      _apiService = apiService;

      // Fetch the transcoder data
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      final transcoderData = await apiService.getTranscodeData(
        widget.transcodeUrl,
        _onProgress,
        _onError,
      );
      if (!mounted) return;
      setState(() {
        _transcoderData = transcoderData;
        _isLoading = false;
      });

      // If we have the transcoder data, use the download URL to play the video
      if (_transcoderData != null) {
        // Get headers with cookies for the request
        final Map<String, String> headers = apiService.getHeadersWithCookies();

        // Configure the media with the download URL

        await _player.open(
          Media(
            _transcoderData!.downloadUrl,
            httpHeaders: headers,
            start:
                _transcoderData?.current != null
                    ? Duration(seconds: _transcoderData!.current)
                    : Duration(seconds: 0),
          ),
          play: true,
        );

        // Start sending progress updates after video starts playing
        _startProgressUpdates();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to initialize player: $e';
        _isLoading = false;
      });
    }
  }

  void _toggleFullScreen() {
    // Store current state to avoid unnecessary rebuilds
    final currentFullScreenState = _isFullScreen;

    // Change fullscreen mode first
    if (currentFullScreenState) {
      FullScreen.setFullScreen(false);
    } else {
      FullScreen.setFullScreen(true);
    }

    // Only update state if it actually changed
    if (_isFullScreen != !currentFullScreenState) {
      setState(() {
        _isFullScreen = !currentFullScreenState;
      });
    }
  }

  void _playNextVideo() {
    if (_transcoderData != null &&
        _transcoderData!.next.TRANSCODE_URL.isNotEmpty) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder:
              (context) => PlayerPage(
                transcodeUrl: _transcoderData!.next.TRANSCODE_URL,
                sourceItemType: widget.sourceItemType,
                sourceItemId: widget.sourceItemId,
                seasonId: widget.seasonId,
                seasonNumber: widget.seasonNumber,
              ),
        ),
      );
    }
  }

  // Add this method to show next card on demand
  void _showNextCardOnDemand() {
    if (_transcoderData != null &&
        _transcoderData!.next.TRANSCODE_URL.isNotEmpty) {
      setState(() {
        _showNextCard = true;
      });
    }
  }

  // Method to send progress update when user seeks
  void _sendProgressUpdate(int positionInSeconds) {
    if (_transcoderData != null) {
      _apiService
          .sendProgress(
            _transcoderData!.file.id.toString(),
            positionInSeconds,
            _transcoderData!.mediaId.toString(),
            widget.sourceItemType == 'tv'
                ? _transcoderData!.getEpisode().toString()
                : null,
            _player.state.duration.inSeconds,
          )
          .catchError((error) {
            // Silently handle errors to not interrupt playback
            print('Error sending seek progress update: $error');
          });
    }
  }

  @override
  void dispose() {
    // Stop sending progress updates
    _progressUpdateTimer?.cancel();

    // Final progress update before closing
    if (_transcoderData != null && _player.state.position.inSeconds > 0) {
      _apiService.sendProgress(
        _transcoderData!.file.id.toString(),
        _player.state.position.inSeconds,
        _transcoderData!.mediaId.toString(),
        widget.sourceItemType == 'tv'
            ? _transcoderData!.getEpisode().ID.toString()
            : null,
        _player.state.duration.inSeconds,
      );
    }

    // Reset orientation to allow all orientations (including portrait)
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    // Reset system UI mode to normal
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    _player.dispose();
    FullScreen.setFullScreen(false); // Reset full screen on dispose
    super.dispose();
  }

  Widget _buildNextEpisodeCard() {
    // Return nothing if there's no data or no next episode
    if (_transcoderData == null ||
        _transcoderData!.next.TRANSCODE_URL.isEmpty) {
      return const SizedBox.shrink();
    }

    // Return nothing if we shouldn't show the card yet (before last 5 minutes)
    if (!_showNextCard) {
      return const SizedBox.shrink();
    }

    final next = _transcoderData!.next;

    return Positioned(
      right: 20,
      bottom: 120, // Positioned higher above the timeline
      child: AnimatedSlide(
        offset: _showNextCard ? const Offset(0, 0) : const Offset(1, 0),
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeOutCubic,
        child: AnimatedOpacity(
          opacity: _showNextCard ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 500),
          child: GestureDetector(
            onTap: _playNextVideo,
            child: SizedBox(
              width: 280,
              height: 160,
              child: Card(
                clipBehavior: Clip.antiAlias,
                margin: EdgeInsets.zero,
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Background image with overlay gradient
                    next.BACKDROP.isNotEmpty
                        ? CookieImage(
                          imageUrl: next.BACKDROP,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (_, __, ___) => Container(
                                color: Colors.grey[900],
                                child: const Icon(
                                  Icons.movie,
                                  color: Colors.white30,
                                  size: 50,
                                ),
                              ),
                        )
                        : Container(
                          color: Colors.grey[900],
                          child: const Icon(
                            Icons.movie,
                            color: Colors.white30,
                            size: 50,
                          ),
                        ),

                    // Dark gradient overlay
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.2),
                            Colors.black.withOpacity(0.7),
                          ],
                          stops: const [0.7, 1.0],
                        ),
                      ),
                    ),

                    // Close button in top-right corner
                    Positioned(
                      top: 5,
                      right: 5,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _showNextCard = false;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.black38,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),

                    // Play button in center
                    Positioned.fill(
                      child: Center(
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: const BoxDecoration(
                            color: Color(0xFF4169E1), // Royal blue color
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.play_arrow,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ),
                    ),

                    // Bottom text info
                    Positioned(
                      left: 8,
                      right: 8,
                      bottom: 8,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Play Next label
                          const Text(
                            'Play Next',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          // Episode number (extract from info or name)
                          Text(
                            _extractEpisodeInfo(next),
                            style: TextStyle(
                              color: Colors.grey[300],
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),

                          // Episode title
                          Text(
                            next.NAME,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Helper method to extract episode info like "S01E04" from next episode data
  String _extractEpisodeInfo(NextFile next) {
    // Try to extract from INFO field first
    if (next.INFO.isNotEmpty) {
      // Look for patterns like "S01E04" or "1x04"
      RegExp seasonEpisodePattern = RegExp(
        r'S\d+E\d+|[0-9]+x[0-9]+',
        caseSensitive: false,
      );
      final match = seasonEpisodePattern.firstMatch(next.INFO);
      if (match != null) {
        return match.group(0)!.toUpperCase();
      }
    }

    // Try to extract from NAME or FILENAME as fallback
    RegExp episodePattern = RegExp(
      r'S\d+E\d+|[0-9]+x[0-9]+',
      caseSensitive: false,
    );

    final nameMatch = episodePattern.firstMatch(next.NAME);
    if (nameMatch != null) {
      return nameMatch.group(0)!.toUpperCase();
    }

    final fileMatch = episodePattern.firstMatch(next.FILENAME);
    if (fileMatch != null) {
      return fileMatch.group(0)!.toUpperCase();
    }

    return ''; // Return empty if no pattern found
  }

  Widget _buildVideoPlayer() {
    // Store the controls in a variable to avoid recreation
    final videoControls = MaterialControls(
      player: _player,
      videoTitle: _transcoderData!.name,
      onBackPressed: () => Navigator.pop(context),
      onFullscreenPressed: _toggleFullScreen,
      isFullscreen: _isFullScreen,
      onNextPressed: _showNextCardOnDemand,
      hasNext:
          _transcoderData != null &&
          _transcoderData!.next.TRANSCODE_URL.isNotEmpty,
      isMobileDevice: _isMobileDevice,
      onProgressUpdate: _sendProgressUpdate,
    );

    return Video(
      key: ValueKey(
        _transcoderData?.downloadUrl,
      ), // Use ValueKey to preserve state based on video URL
      controller: _controller,
      controls: (VideoState state) => videoControls,
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    // Prevent rebuilds on window resize by avoiding MediaQuery dependencies
    return MediaQuery.removePadding(
      context: context,
      removeTop: true,
      removeBottom: true,
      removeLeft: true,
      removeRight: true,
      child: Scaffold(
        backgroundColor: Colors.black,
        body:
            _isLoading
                ? _buildLoadingView()
                : _errorMessage.isNotEmpty
                ? _buildErrorView()
                : Stack(
                  children: [
                    _buildVideoPlayer(),
                    // Buffering indicator overlay
                    StreamBuilder<bool>(
                      stream: _player.stream.buffering,
                      builder: (context, snapshot) {
                        final isBuffering = snapshot.data ?? false;
                        if (isBuffering) {
                          return Center(
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  const Text(
                                    "Chargement...",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                    // Next episode card
                    _buildNextEpisodeCard(),
                  ],
                ),
      ),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Colors.white),
          const SizedBox(height: 16),
          Text(
            'Loading video...\n$_progressMessage',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 16),
          Text(
            _errorMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }
}

class MaterialControls extends StatefulWidget {
  final Player player;
  final String videoTitle;
  final VoidCallback onBackPressed;
  final VoidCallback onFullscreenPressed;
  final VoidCallback onNextPressed; // Add this parameter
  final bool isFullscreen;
  final bool hasNext; // Add this parameter
  final bool isMobileDevice; // Add this parameter
  final Function(int)?
  onProgressUpdate; // Add this parameter for progress updates

  const MaterialControls({
    super.key,
    required this.player,
    required this.videoTitle,
    required this.onBackPressed,
    required this.onFullscreenPressed,
    required this.onNextPressed, // Add this parameter
    required this.isFullscreen,
    this.hasNext = false, // Add this parameter with default value
    required this.isMobileDevice, // Add this parameter
    this.onProgressUpdate, // Add this parameter
  });

  @override
  State<MaterialControls> createState() => _MaterialControlsState();
}

class _MaterialControlsState extends State<MaterialControls> {
  bool _isControlsVisible = true;
  Timer? _hideControlsTimer;
  double _lastVolume = 1.0; // Store the last non-zero volume level
  String _currentSubtitle = "No Subs";

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

        // Get the currently active track IDs
        final activeSubtitleId = widget.player.state.track.subtitle;

        setState(() {
          // Check if any subtitle is active by looking at the active ID
          _currentSubtitle =
              subtitles.isEmpty
                  ? "No Subs"
                  : (activeSubtitleId != -1 ? "Subtitles On" : "No Subs");
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
                        track.title != null && track.language != null
                            ? '${track.title} (${track.language})'
                            : track.title ?? 'Unknown',
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
                            // Progress bar with yellow indicator (positioned above other controls)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: _buildProgressBar(),
                            ),

                            // Time indicators and controls in a single row
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                              ),
                              child: Row(
                                children: [
                                  // Current position text
                                  StreamBuilder<Duration>(
                                    stream: widget.player.stream.position,
                                    builder: (context, snapshot) {
                                      final position =
                                          snapshot.data ??
                                          widget.player.state.position;
                                      return Text(
                                        _formatDuration(position),
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                      );
                                    },
                                  ),

                                  const Spacer(),

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

                                  // Next episode button
                                  if (widget.hasNext)
                                    IconButton(
                                      icon: const Icon(
                                        Icons.skip_next,
                                        color: Colors.white,
                                      ),
                                      tooltip: 'Next episode',
                                      onPressed: () {
                                        widget.onNextPressed();
                                        _startHideControlsTimer();
                                      },
                                    ),

                                  // Total duration text
                                  StreamBuilder<Duration>(
                                    stream: widget.player.stream.duration,
                                    builder: (context, snapshot) {
                                      final duration =
                                          snapshot.data ??
                                          widget.player.state.duration;
                                      return Text(
                                        _formatDuration(duration),
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                      );
                                    },
                                  ),

                                  const SizedBox(width: 8),

                                  // Fullscreen button (conditionally shown)
                                  if (!widget.isMobileDevice)
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

            return StreamBuilder<bool>(
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
                        Colors.yellow, // Yellow indicator as shown in the image
                    overlayColor: Colors.yellow.withOpacity(0.3),
                  ),
                  child: Slider(
                    value: progressPercent,
                    min: 0.0,
                    max: 1.0,
                    onChanged: (value) {
                      final newPosition = Duration(
                        milliseconds: (duration.inMilliseconds * value).round(),
                      );
                      widget.player.seek(newPosition);
                    },
                    onChangeStart: (_) {
                      final wasPlaying = isPlaying;
                      if (wasPlaying) {
                        widget.player.pause();
                      }
                      _cancelHideControlsTimer();
                    },
                    onChangeEnd: (value) {
                      final newPosition = Duration(
                        milliseconds: (duration.inMilliseconds * value).round(),
                      );
                      widget.player.seek(newPosition).then((_) {
                        if (isPlaying) {
                          widget.player.play();
                        }
                        // Send progress update when user finishes seeking
                        if (widget.onProgressUpdate != null) {
                          widget.onProgressUpdate!(newPosition.inSeconds);
                        }
                      });
                      _startHideControlsTimer();
                    },
                  ),
                );
              },
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
