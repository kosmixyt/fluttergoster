import 'dart:async'; // Import for Timer
import 'package:flutter/material.dart';
import 'package:fluttergoster/main.dart';
import 'package:fluttergoster/pages/player_page.dart';
import '../models/data_models.dart';
import '../widgets/cookie_image.dart';
import '../pages/media_details_page.dart';
import '../services/api_service.dart';
import 'package:blur/blur.dart';

enum MediaCardDisplayMode { poster, backdrop }

class MediaCard extends StatefulWidget {
  final SkinnyRender media;
  final double width;
  final double height;
  final MediaCardDisplayMode displayMode;
  final Duration hoverDelay;
  final Function(bool)? onWatchlistChanged;
  final ApiService? apiService; // New parameter

  const MediaCard({
    super.key,
    required this.media,
    this.width = 300.0,
    this.height = 170.0,
    this.displayMode = MediaCardDisplayMode.backdrop,
    this.hoverDelay = const Duration(milliseconds: 1000),
    this.onWatchlistChanged,
    this.apiService, // New optional parameter
  });

  @override
  State<MediaCard> createState() => _MediaCardState();
}

class _MediaCardState extends State<MediaCard>
    with SingleTickerProviderStateMixin {
  bool _isHovering = false;
  bool _isUpdatingWatchlist = false;
  bool _isLongPressed = false; // Add to track long press state
  bool _showHoverDetails = false; // Affiche les détails après le délai
  AnimationController? _animationController;
  Animation<double>? _scaleAnimation;
  Timer? _hoverTimer;
  Timer? _longPressTimer; // Timer to auto-dismiss long press state

  @override
  void initState() {
    super.initState();
    // Create the controller with a protective try-catch block
    try {
      _animationController = AnimationController(
        duration: const Duration(milliseconds: 200),
        vsync: this,
      );
      _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
        CurvedAnimation(parent: _animationController!, curve: Curves.easeInOut),
      );
    } catch (e) {
      print('Error initializing animation controller: $e');
    }
  }

  @override
  void dispose() {
    _hoverTimer?.cancel();
    _longPressTimer?.cancel(); // Cancel the long press timer
    _animationController?.dispose();
    super.dispose();
  }

  // Helper methods to control animation safely
  void _startHoverAnimation() {
    _hoverTimer?.cancel();
    _hoverTimer = Timer(widget.hoverDelay, () {
      if (mounted && _isHovering && _animationController != null) {
        setState(() {
          _showHoverDetails = true;
        });
        _animationController!.forward();
      }
    });
  }

  void _stopHoverAnimation() {
    _hoverTimer?.cancel();
    if (_animationController != null && mounted) {
      _animationController!.reverse();
    }
    if (mounted) {
      setState(() {
        _showHoverDetails = false;
      });
    }
  }

  // Handle long press hover simulation
  void _handleLongPress() {
    setState(() {
      _isLongPressed = true;
      _isHovering = true;
    });
    _startHoverAnimation();

    // Optional: auto-dismiss after some time (can be removed if you want it to stay indefinitely)
    _longPressTimer?.cancel();
    _longPressTimer = Timer(const Duration(seconds: 10), () {
      if (mounted && _isLongPressed) {
        setState(() {
          _isLongPressed = false;
          _isHovering = false;
        });
        _stopHoverAnimation();
      }
    });
  }

  // Don't reset on touch end - let it persist until tapped
  void _handleTouchEnd() {
    // Intentionally empty - we don't want to cancel the hover state on release
    // The state will be canceled on next tap
  }

  // Handle adding or removing from watchlist
  Future<void> _toggleWatchlist() async {
    if (_isUpdatingWatchlist) return; // Prevent multiple requests

    final bool currentStatus = widget.media.watchlisted;
    final String action = currentStatus ? 'remove' : 'add';
    final String itemType = widget.media.type;
    final String itemId = widget.media.id.toString();

    setState(() {
      _isUpdatingWatchlist = true;
    });

    try {
      // Use provided apiService or get it from context if not provided
      final apiService = widget.apiService ?? ApiServiceProvider.of(context);
      bool success = await apiService.modifyWatchlist(action, itemType, itemId);

      if (success && mounted) {
        setState(() {
          // Update the local state
          widget.media.watchlisted = !currentStatus;
          _isUpdatingWatchlist = false;
        });

        // Notify parent if callback is provided
        if (widget.onWatchlistChanged != null) {
          widget.onWatchlistChanged!(!currentStatus);
        }

        // Show feedback with a small overlay
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              currentStatus ? 'Removed from watchlist' : 'Added to watchlist',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.green[700],
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUpdatingWatchlist = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to update watchlist: ${e.toString()}',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red[700],
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovering = true);
        _startHoverAnimation();
      },
      onExit: (_) {
        if (!_isLongPressed) {
          setState(() => _isHovering = false);
          _stopHoverAnimation();
        }
      },
      child: GestureDetector(
        onTap: () {
          if (_isLongPressed) {
            // Cancel long press mode on tap
            setState(() {
              _isLongPressed = false;
              _isHovering = false;
            });
            _stopHoverAnimation();
          } else {
            // Regular navigation
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => MediaDetailsPage(
                      mediaId: widget.media.id.toString(),
                      mediaType: widget.media.type.toString(),
                    ),
              ),
            );
          }
        },
        onLongPress: _handleLongPress,
        onLongPressEnd: (_) => _handleTouchEnd(),
        child:
            _animationController == null
                ? _buildCardWithoutAnimation()
                : AnimatedBuilder(
                  animation: _animationController!,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _scaleAnimation?.value ?? 1.0,
                      child: _buildCardByMode(),
                    );
                  },
                ),
      ),
    );
  }

  // A fallback method to build the card without animation
  Widget _buildCardWithoutAnimation() {
    return _buildCardByMode();
  }

  Widget _buildCardByMode() {
    switch (widget.displayMode) {
      case MediaCardDisplayMode.poster:
        return _buildPosterCard();
      case MediaCardDisplayMode.backdrop:
        return _buildBackdropCard();
    }
  }

  Widget _buildPosterCard() {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;

    // Calculate responsive dimensions
    final aspectRatio = 2.0 / 3.0; // Standard poster aspect ratio (2:3)

    // Adaptive sizing based on screen width - making cards smaller
    double cardWidth;

    if (screenWidth > 1200) {
      // Large screens (desktop)
      cardWidth = screenWidth * 0.08;
    } else if (screenWidth > 800) {
      // Medium screens (tablet)
      cardWidth = screenWidth * 0.12;
    } else if (screenWidth > 600) {
      // Small tablets
      cardWidth = screenWidth * 0.16;
    } else {
      // Mobile screens
      cardWidth = screenWidth * 0.22;
    }

    // Ensure minimum and maximum sizes with proper aspect ratio
    final finalCardWidth = cardWidth.clamp(120.0, 200.0);
    final finalCardHeight = finalCardWidth / aspectRatio;

    return Container(
      width: finalCardWidth,
      height: finalCardHeight,
      margin: EdgeInsets.symmetric(
        horizontal: screenWidth > 600 ? 6.0 : 3.0,
        vertical: 3.0,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.0),
        boxShadow:
            _showHoverDetails
                ? [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.6),
                    blurRadius: 12,
                    spreadRadius: -2,
                  ),
                ]
                : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.0),
        child: Stack(
          clipBehavior: Clip.none, // Allow elements to overflow
          children: [
            // Poster image
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12.0),
                child:
                    widget.media.poster.contains('tmdb')
                        ? Image(
                          image: NetworkImage(widget.media.poster),
                          fit: BoxFit.cover,
                          errorBuilder:
                              (context, error, stackTrace) =>
                                  Container(color: Colors.grey[800]),
                        )
                        : CookieImage(
                          imageUrl: widget.media.poster,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (context, error, stackTrace) =>
                                  Container(color: Colors.grey[800]),
                        ),
              ),
            ),

            // Bottom gradient overlay
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: finalCardHeight * 0.35,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(12.0),
                    bottomRight: Radius.circular(12.0),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
                  ),
                ),
              ),
            ),

            // Blur effect for information section when hovering with smooth transition
            if (_showHoverDetails)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                // Extend blur higher up the card for a smoother transition
                height: finalCardHeight * 0.8,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12.0),
                  child: Stack(
                    children: [
                      // Base blur layer
                      Positioned.fill(
                        child: Blur(
                          blur: 2.5,
                          blurColor: Colors.black,
                          colorOpacity: 0.3,
                          overlay: Container(),
                          child: Container(color: Colors.transparent),
                        ),
                      ),
                      // Gradient overlay for the blur to fade it in
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.center,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.5),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Progress indicator
            if (widget.media.watch.total > 0)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(12),
                    ),
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: LinearProgressIndicator(
                    value:
                        widget.media.watch.current / widget.media.watch.total,
                    backgroundColor: Colors.grey.withOpacity(0.5),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.red),
                    minHeight: 4,
                  ),
                ),
              ),

            // Content information at bottom
            Positioned(
              bottom: 12,
              left: 12,
              right: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Add title when hovering (similar to the screenshot)
                  if (_showHoverDetails) ...[
                    Text(
                      widget.media.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: screenWidth > 600 ? 14 : 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (widget.media.description.isNotEmpty &&
                        widget.media.description != '-1')
                      Opacity(
                        opacity: 0.4,
                        child: Text(
                          widget.media.description,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: screenWidth > 600 ? 10 : 9,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                      ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            widget.media.type.toUpperCase(),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: screenWidth > 600 ? 10 : 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (widget.media.year > 0 &&
                            widget.media.year != -1) ...[
                          const SizedBox(width: 8),
                          Text(
                            '${widget.media.year}',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: screenWidth > 600 ? 12 : 11,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (widget.media.genre.isNotEmpty)
                      Text(
                        widget.media.genre
                            .map((e) => e.name)
                            .where((name) => name != '-1' && name != '0')
                            .join(', '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: screenWidth > 600 ? 12 : 10,
                        ),
                      ),
                    const SizedBox(height: 8),
                    // Watch button
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => PlayerPage(
                                        transcodeUrl: widget.media.transcodeUrl,
                                      ),
                                ),
                              );
                            },
                            icon: Icon(
                              Icons.play_arrow,
                              size: screenWidth > 600 ? 18 : 16,
                            ),
                            label: Text('Watch'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 6),
                              textStyle: TextStyle(
                                fontSize: screenWidth > 600 ? 12 : 10,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Add/Remove button that reflects watchlist state
                        ElevatedButton(
                          onPressed: _toggleWatchlist,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                widget.media.watchlisted
                                    ? Colors.red[700]
                                    : Colors.grey[800],
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            textStyle: TextStyle(
                              fontSize: screenWidth > 600 ? 12 : 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          child: Text(
                            widget.media.watchlisted ? 'Remove' : 'Add',
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Watchlisted indicator (only when not hovering)
            if (widget.media.watchlisted && !_isHovering)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.bookmark, color: Colors.white, size: 16),
                ),
              ),

            // Remove the standalone watchlist button when hovering since we have the Add button
          ],
        ),
      ),
    );
  }

  Widget _buildBackdropCard() {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;

    // Calculate responsive dimensions for backdrop cards
    final aspectRatio = 16.0 / 9.0; // 16:9 aspect ratio
    double cardWidth;

    if (screenWidth > 1200) {
      // Large screens (desktop)
      cardWidth = screenWidth * 0.14;
    } else if (screenWidth > 800) {
      // Medium screens (tablet)
      cardWidth = screenWidth * 0.18;
    } else if (screenWidth > 600) {
      // Small tablets
      cardWidth = screenWidth * 0.25;
    } else {
      // Mobile screens
      cardWidth = screenWidth * 0.35;
    }

    // Calculate height based on aspect ratio
    // Ensure minimum and maximum sizes with proper aspect ratio
    final finalCardWidth = cardWidth.clamp(180.0, 320.0);
    final finalCardHeight = finalCardWidth / aspectRatio;

    return Container(
      width: finalCardWidth,
      height: finalCardHeight,
      margin: EdgeInsets.symmetric(
        horizontal: screenWidth > 600 ? 6.0 : 3.0,
        vertical: 3.0,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.0),
        boxShadow:
            _isHovering
                ? [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.6),
                    blurRadius: 12,
                    spreadRadius: -2,
                  ),
                ]
                : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.0),
        child: Stack(
          clipBehavior: Clip.none, // Allow elements to overflow
          children: [
            // Image de fond
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12.0),
                child:
                    widget.media.backdrop.contains('tmdb')
                        ? Image(
                          image: NetworkImage(widget.media.backdrop),
                          fit: BoxFit.cover,
                          errorBuilder:
                              (context, error, stackTrace) =>
                                  Container(color: Colors.grey[800]),
                        )
                        : CookieImage(
                          imageUrl: widget.media.backdrop,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (context, error, stackTrace) =>
                                  Container(color: Colors.grey[800]),
                        ),
              ),
            ),

            // Dégradé pour le texte
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12.0),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
                  ),
                ),
              ),
            ),

            // Indicateur de progression si regardé
            if (widget.media.watch.total > 0)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(12),
                    ),
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: LinearProgressIndicator(
                    value:
                        widget.media.watch.current / widget.media.watch.total,
                    backgroundColor: Colors.grey.withOpacity(0.5),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.red),
                    minHeight: 4,
                  ),
                ),
              ),

            // Informations
            Positioned(
              bottom: 12,
              left: 12,
              right: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.media.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: screenWidth > 600 ? 16 : 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  // Plus d'informations en hover
                  if (_isHovering) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            widget.media.type.toUpperCase(),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: screenWidth > 600 ? 10 : 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          // '',
                          '${(widget.media.year > 0) ? widget.media.year : ""}${(widget.media.year > 0 && widget.media.runtime.isNotEmpty) ? " • " : ""}${widget.media.runtime}',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: screenWidth > 600 ? 12 : 10,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    if (widget.media.genre.isNotEmpty)
                      Text(
                        widget.media.genre.map((e) => e.name).join(', '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: screenWidth > 600 ? 12 : 10,
                        ),
                      ),
                  ],
                ],
              ),
            ),

            // Watchlisted indicator (only when not hovering)
            if (widget.media.watchlisted && !_isHovering)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.bookmark, color: Colors.white, size: 16),
                ),
              ),

            // Watchlist toggle button on hover
            if (_isHovering)
              Positioned(
                top: 8,
                right: 8,
                child: AnimatedOpacity(
                  opacity: _isHovering ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child:
                      _isUpdatingWatchlist
                          ? Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              shape: BoxShape.circle,
                            ),
                            child: const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            ),
                          )
                          : IconButton(
                            icon: Icon(
                              widget.media.watchlisted
                                  ? Icons.bookmark
                                  : Icons.bookmark_border,
                              color: Colors.white,
                              size: 20,
                            ),
                            padding: EdgeInsets.zero,
                            tooltip:
                                widget.media.watchlisted
                                    ? 'Remove from watchlist'
                                    : 'Add to watchlist',
                            constraints: const BoxConstraints(),
                            iconSize: 24,
                            style: ButtonStyle(
                              backgroundColor: WidgetStateProperty.all(
                                Colors.black.withOpacity(0.6),
                              ),
                              minimumSize: WidgetStateProperty.all(
                                const Size(32, 32),
                              ),
                            ),
                            onPressed: _toggleWatchlist,
                          ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
