import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Add this import for clipboard functionality
import 'dart:ui'; // Add this import for ImageFilter
import 'package:fluttergoster/pages/player_page.dart';
import 'package:fluttergoster/widgets/content_request_modal.dart';
import 'package:fluttergoster/widgets/torrent_search_modal.dart';
import '../main.dart';
import '../models/data_models.dart';
import '../widgets/cookie_image.dart';
import '../widgets/goster_top_bar.dart';
import 'package:fluttergoster/widgets/media_card.dart';
import '../widgets/torrent_info_button.dart'; // Ajout de l'import

class MediaDetailsPage extends StatefulWidget {
  final String mediaId;
  final String mediaType;

  const MediaDetailsPage({
    super.key,
    required this.mediaId,
    required this.mediaType,
  });

  @override
  State<MediaDetailsPage> createState() => _MediaDetailsPageState();
}

class _MediaDetailsPageState extends State<MediaDetailsPage> {
  dynamic _mediaDetails;
  String? _error;
  bool _loading = true;
  bool _didInitialFetch = false;
  bool _isUpdatingWatchlist = false;
  int _selectedFileIndex = 0; // Track selected file for movies
  final Map<int, int> _selectedEpisodeFileIndices =
      {}; // Track selected files for episodes

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didInitialFetch) {
      _fetchMediaDetails();
      _didInitialFetch = true;
    }
  }

  Future<void> _fetchMediaDetails() async {
    final apiService = ApiServiceProvider.of(context);
    try {
      dynamic details;
      if (widget.mediaType == 'movie') {
        details = await apiService.getMovieDetails(widget.mediaId);
      } else if (widget.mediaType == 'tv') {
        print("Fetching TV details for ID: ${widget.mediaId}");
        details = await apiService.getTVDetails(widget.mediaId);
        print("TV Details: got details:");
      } else {
        throw Exception('Type de média non supporté');
      }

      setState(() {
        _mediaDetails = details;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = "Erreur lors du chargement des détails: ${e.toString()}";
        _loading = false;
      });
    }
  }

  /// Handle adding or removing from watchlist
  Future<void> _toggleWatchlist(
    String itemType,
    String itemId,
    bool currentStatus,
  ) async {
    if (_isUpdatingWatchlist) return; // Prevent multiple requests

    final String action = currentStatus ? 'remove' : 'add';

    setState(() {
      _isUpdatingWatchlist = true;
    });

    try {
      final apiService = ApiServiceProvider.of(context);
      await apiService.modifyWatchlist(action, itemType, itemId);

      // Update the UI based on the item type
      setState(() {
        if (itemType == 'movie' && _mediaDetails is MovieItem) {
          var item = _mediaDetails as MovieItem;
          item.watchlisted = !currentStatus;
        } else if (itemType == 'tv' && _mediaDetails is TVItem) {
          var item = _mediaDetails as TVItem;
          item.WATCHLISTED = !currentStatus;
        }
        _isUpdatingWatchlist = false;
      });

      // Show success message
      if (!mounted) return;
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
    } catch (e) {
      // Update the UI to show error
      setState(() {
        _isUpdatingWatchlist = false;
      });

      if (!mounted) return;
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

  // Updated share file method with clipboard functionality
  Future<void> _shareFile(String fileId) async {
    try {
      final apiService = ApiServiceProvider.of(context);
      final String result = await apiService.createShare(fileId);

      // Show the share link in a dialog
      if (!mounted) return;
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Share Link Created'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Share this link with others:'),
                  const SizedBox(height: 10),
                  InkWell(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: result));
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Link copied to clipboard'),
                          backgroundColor: Colors.green,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: SelectableText(
                              result,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          const Icon(
                            Icons.content_copy,
                            color: Colors.white60,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ],
              backgroundColor: Colors.grey[900],
              titleTextStyle: const TextStyle(
                color: Colors.white,
                fontSize: 18,
              ),
              contentTextStyle: const TextStyle(color: Colors.white70),
            ),
      );
    } catch (e) {
      // Show error message
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create share link: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Détails')),
        body: Center(child: Text(_error!)),
      );
    }

    // Si c'est un film
    if (widget.mediaType == 'movie' && _mediaDetails is MovieItem) {
      return _buildMovieDetails(_mediaDetails);
    }
    // Si c'est une série TV
    else if (widget.mediaType == 'tv' && _mediaDetails is TVItem) {
      return _buildTvDetails(_mediaDetails);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Détails')),
      body: const Center(child: Text('Type de média non reconnu')),
    );
  }

  Widget _buildMovieDetails(MovieItem movie) {
    try {
      final selectedFile =
          movie.files.isNotEmpty ? movie.files[_selectedFileIndex] : null;
      final runtimeMinutes = movie.runtime;

      return Scaffold(
        backgroundColor: Colors.black,
        appBar: const GosterTopBar(showBackButton: true),
        body: Stack(
          children: [
            // Backdrop en plein écran avec flou noir
            Positioned.fill(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CookieImage(
                    imageUrl: movie.backdrop,
                    fit: BoxFit.cover,
                    errorBuilder:
                        (context, error, stackTrace) =>
                            Container(color: Colors.grey[900]),
                  ),
                  // Overlay avec flou noir pour la lisibilité
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.75),
                    ),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Poster à gauche sur PC
            if (MediaQuery.of(context).size.width > 800)
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.25,
                  padding: const EdgeInsets.all(24),
                  child: SafeArea(
                    child: Column(
                      children: [
                        const SizedBox(height: 60), // Espace pour la topbar
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.8),
                                spreadRadius: 0,
                                blurRadius: 30,
                                offset: const Offset(0, 15),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: AspectRatio(
                              aspectRatio: 2 / 3, // Ratio poster standard
                              child: CookieImage(
                                imageUrl: movie.poster,
                                fit: BoxFit.cover,
                                errorBuilder:
                                    (context, error, stackTrace) => Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            Colors.grey[800]!,
                                            Colors.grey[900]!,
                                          ],
                                        ),
                                      ),
                                      child: const Center(
                                        child: Icon(
                                          Icons.movie_rounded,
                                          size: 64,
                                          color: Colors.white30,
                                        ),
                                      ),
                                    ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 280,
                  pinned: true,
                  backgroundColor: Colors.transparent,
                  automaticallyImplyLeading: false,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        CookieImage(
                          imageUrl: movie.backdrop,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (context, error, stackTrace) =>
                                  Container(color: Colors.grey[900]),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              stops: const [0.0, 0.4, 0.8, 1.0],
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.3),
                                Colors.black.withOpacity(0.7),
                                Colors.black.withOpacity(0.95),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Container(
                    padding: EdgeInsets.only(
                      left:
                          MediaQuery.of(context).size.width > 800
                              ? MediaQuery.of(context).size.width * 0.25
                              : 24.0,
                      right: 24.0,
                      top: 8.0,
                      bottom: 32.0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // --- TITRE PRINCIPAL SUR MOBILE (déplacé avant le cadre) ---
                        if (MediaQuery.of(context).size.width <= 800)
                          Container(
                            margin: const EdgeInsets.only(bottom: 20),
                            child: Center(
                              child:
                                  movie.logo.isNotEmpty
                                      ? SizedBox(
                                        height: 80,
                                        child: CookieImage(
                                          imageUrl: movie.logo,
                                          fit: BoxFit.contain,
                                          errorBuilder:
                                              (
                                                context,
                                                error,
                                                stackTrace,
                                              ) => Text(
                                                movie.displayName.toUpperCase(),
                                                textAlign: TextAlign.center,
                                                style: const TextStyle(
                                                  fontSize: 32,
                                                  fontWeight: FontWeight.w800,
                                                  color: Colors.white,
                                                  letterSpacing: 2.0,
                                                  height: 1.0,
                                                ),
                                              ),
                                        ),
                                      )
                                      : Text(
                                        movie.displayName.toUpperCase(),
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 32,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                          letterSpacing: 2.0,
                                          height: 1.0,
                                        ),
                                      ),
                            ),
                          ),

                        // --- NOUVEAU POSTER DESIGN (supprimé sur mobile) ---
                        // Card poster supprimée sur mobile pour plus d'espace

                        // --- TITRE PRINCIPAL (desktop uniquement) ---
                        if (MediaQuery.of(context).size.width > 800)
                          Center(
                            child:
                                movie.logo.isNotEmpty
                                    ? SizedBox(
                                      height: 100,
                                      child: CookieImage(
                                        imageUrl: movie.logo,
                                        fit: BoxFit.contain,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                Text(
                                                  movie.displayName
                                                      .toUpperCase(),
                                                  textAlign: TextAlign.center,
                                                  style: const TextStyle(
                                                    fontSize: 48,
                                                    fontWeight: FontWeight.w800,
                                                    color: Colors.white,
                                                    letterSpacing: 2.0,
                                                    height: 1.0,
                                                  ),
                                                ),
                                      ),
                                    )
                                    : Text(
                                      movie.displayName.toUpperCase(),
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 48,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                        letterSpacing: 2.0,
                                        height: 1.0,
                                      ),
                                    ),
                          ),
                        // --- BADGES INFOS (desktop uniquement) ---
                        if (MediaQuery.of(context).size.width > 800)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                            child: Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[850],
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    child: Text(
                                      movie.year.toString(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[850],
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    child: Text(
                                      movie.voteAverage > 0
                                          ? movie.voteAverage.toString()
                                          : 'N/A',
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        // --- BOUTONS (déplacés ici) ---
                        Container(
                          margin: const EdgeInsets.only(top: 20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: const BorderSide(color: Colors.grey),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                ),
                                onPressed:
                                    _isUpdatingWatchlist
                                        ? null
                                        : () => _toggleWatchlist(
                                          'movie',
                                          movie.id,
                                          movie.watchlisted,
                                        ),
                                child:
                                    _isUpdatingWatchlist
                                        ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  Colors.white,
                                                ),
                                          ),
                                        )
                                        : Text(
                                          movie.watchlisted
                                              ? 'Remove from Watchlist'
                                              : 'Add to Watchlist',
                                        ),
                              ),
                              const SizedBox(width: 12),
                              TorrentInfoButton(
                                itemId: movie.id,

                                itemType: 'movie',
                                hasFiles: movie.files.isNotEmpty,
                                sourceItem:
                                    movie, // Pass the movie as source item
                              ),
                              // Afficher le bouton "Search Torrents" seulement si le film n'a pas de fichiers
                              if (movie.files.isEmpty) ...[
                                const SizedBox(width: 12),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder:
                                          (context) => TorrentSearchModal(
                                            apiService: ApiServiceProvider.of(
                                              context,
                                            ),
                                            mediaId: movie.id,
                                            mediaType: 'movie',
                                          ),
                                    );
                                  },
                                  icon: const Icon(Icons.search),
                                  label: const Text('Search Torrents'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF3B82F6),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ),
                              ],
                              if (movie.files.isEmpty) ...[
                                const SizedBox(width: 12),
                                ContentRequestButton(
                                  itemId: movie.id,
                                  itemType: 'movie',
                                  apiService: ApiServiceProvider.of(context),
                                ),
                                const SizedBox(width: 10),
                              ],
                            ],
                          ),
                        ),

                        // --- FIN BOUTONS ---
                        if (movie.tagline.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: Text(
                              movie.tagline,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        Text(
                          movie.description,
                          style: TextStyle(
                            color: Colors.grey[300],
                            fontSize: 15,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 24),
                        if (movie.director.isNotEmpty)
                          _buildInfoRow('Director', movie.director),
                        if (movie.writer.isNotEmpty)
                          _buildInfoRow('Writer', movie.writer),
                        _buildInfoRow('Duration', '$runtimeMinutes minutes'),
                        if (movie.genre.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          const Text(
                            'Genres',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8.0,
                            runSpacing: 8.0,
                            children:
                                movie.genre
                                    .map(
                                      (genre) => Chip(
                                        label: Text(genre.name),
                                        backgroundColor: Colors.grey[850],
                                        labelStyle: const TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                                    )
                                    .toList(),
                          ),
                        ],
                        // --- BOUTONS PLAY/DOWNLOAD NOUVEAUX ---
                        const SizedBox(height: 32),
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white.withOpacity(0.1),
                                Colors.white.withOpacity(0.05),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.15),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                spreadRadius: 0,
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              // Bouton Play principal redesigné
                              Container(
                                width: double.infinity,
                                height:
                                    MediaQuery.of(context).size.width <= 800
                                        ? 50
                                        : 70, // Plus petit sur mobile
                                decoration: BoxDecoration(
                                  gradient:
                                      selectedFile != null ||
                                              movie.transcodeUrl.isNotEmpty
                                          ? const LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              Color(0xFF6366F1), // Indigo
                                              Color(0xFF8B5CF6), // Violet
                                              Color(0xFF3B82F6), // Blue
                                            ],
                                            stops: [0.0, 0.5, 1.0],
                                          )
                                          : LinearGradient(
                                            colors: [
                                              Colors.grey[700]!,
                                              Colors.grey[800]!,
                                            ],
                                          ),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow:
                                      selectedFile != null ||
                                              movie.transcodeUrl.isNotEmpty
                                          ? [
                                            BoxShadow(
                                              color: const Color(
                                                0xFF6366F1,
                                              ).withOpacity(0.5),
                                              spreadRadius: 0,
                                              blurRadius: 20,
                                              offset: const Offset(0, 8),
                                            ),
                                            BoxShadow(
                                              color: Colors.black.withOpacity(
                                                0.3,
                                              ),
                                              spreadRadius: 0,
                                              blurRadius: 15,
                                              offset: const Offset(0, 5),
                                            ),
                                          ]
                                          : [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(
                                                0.3,
                                              ),
                                              spreadRadius: 0,
                                              blurRadius: 10,
                                              offset: const Offset(0, 3),
                                            ),
                                          ],
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap:
                                        selectedFile != null ||
                                                movie.transcodeUrl.isNotEmpty
                                            ? () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder:
                                                      (context) => PlayerPage(
                                                        transcodeUrl:
                                                            selectedFile != null
                                                                ? selectedFile
                                                                    .transcodeUrl
                                                                : movie
                                                                    .transcodeUrl,
                                                      ),
                                                ),
                                              );
                                            }
                                            : null,
                                    borderRadius: BorderRadius.circular(20),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 32,
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          // Icône avec effet pulsant
                                          Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(
                                                0.2,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.white
                                                      .withOpacity(0.1),
                                                  spreadRadius: 0,
                                                  blurRadius: 10,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: Icon(
                                              selectedFile != null ||
                                                      movie
                                                          .transcodeUrl
                                                          .isNotEmpty
                                                  ? Icons.play_arrow_rounded
                                                  : Icons.download_rounded,
                                              color: Colors.white,
                                              size: 32,
                                            ),
                                          ),
                                          const SizedBox(width: 20),
                                          // Texte principal
                                          Expanded(
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  selectedFile != null ||
                                                          movie
                                                              .transcodeUrl
                                                              .isNotEmpty
                                                      ? (movie.watch.current > 0
                                                          ? 'Reprendre la lecture'
                                                          : 'Regarder maintenant')
                                                      : 'Aucun fichier disponible',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 20,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                if (movie.watch.current > 0 &&
                                                    (selectedFile != null ||
                                                        movie
                                                            .transcodeUrl
                                                            .isNotEmpty))
                                                  Text(
                                                    'Progression: ${(movie.watch.current / movie.watch.total * 100).toStringAsFixed(0)}%',
                                                    style: TextStyle(
                                                      color: Colors.white
                                                          .withOpacity(0.8),
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                          // Barre de progression si applicable
                                          if (movie.watch.current > 0 &&
                                              (selectedFile != null ||
                                                  movie
                                                      .transcodeUrl
                                                      .isNotEmpty))
                                            Container(
                                              width: 6,
                                              height: 40,
                                              decoration: BoxDecoration(
                                                color: Colors.white.withOpacity(
                                                  0.3,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(3),
                                              ),
                                              child: FractionallySizedBox(
                                                alignment:
                                                    Alignment.bottomCenter,
                                                heightFactor:
                                                    movie.watch.current /
                                                    movie.watch.total,
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    gradient:
                                                        const LinearGradient(
                                                          begin:
                                                              Alignment
                                                                  .topCenter,
                                                          end:
                                                              Alignment
                                                                  .bottomCenter,
                                                          colors: [
                                                            Colors.white,
                                                            Color(0xFFFFD700),
                                                          ],
                                                        ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          3,
                                                        ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 20),

                              // Boutons secondaires redesignés
                              Row(
                                children: [
                                  // Bouton Download amélioré
                                  Expanded(
                                    child: Container(
                                      height:
                                          MediaQuery.of(context).size.width <=
                                                  800
                                              ? 42
                                              : 56, // Plus petit sur mobile
                                      decoration: BoxDecoration(
                                        gradient:
                                            selectedFile != null
                                                ? LinearGradient(
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                  colors: [
                                                    const Color(
                                                      0xFF10B981,
                                                    ).withOpacity(0.8),
                                                    const Color(
                                                      0xFF059669,
                                                    ).withOpacity(0.9),
                                                  ],
                                                )
                                                : LinearGradient(
                                                  colors: [
                                                    Colors.grey[700]!
                                                        .withOpacity(0.5),
                                                    Colors.grey[800]!
                                                        .withOpacity(0.7),
                                                  ],
                                                ),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color:
                                              selectedFile != null
                                                  ? const Color(
                                                    0xFF10B981,
                                                  ).withOpacity(0.3)
                                                  : Colors.grey[600]!
                                                      .withOpacity(0.3),
                                          width: 1,
                                        ),
                                        boxShadow:
                                            selectedFile != null
                                                ? [
                                                  BoxShadow(
                                                    color: const Color(
                                                      0xFF10B981,
                                                    ).withOpacity(0.3),
                                                    spreadRadius: 0,
                                                    blurRadius: 12,
                                                    offset: const Offset(0, 4),
                                                  ),
                                                ]
                                                : [],
                                      ),
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          onTap:
                                              selectedFile != null
                                                  ? () {
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      SnackBar(
                                                        content: const Row(
                                                          children: [
                                                            Icon(
                                                              Icons
                                                                  .download_rounded,
                                                              color:
                                                                  Colors.white,
                                                            ),
                                                            SizedBox(width: 8),
                                                            Text(
                                                              'Téléchargement démarré',
                                                            ),
                                                          ],
                                                        ),
                                                        backgroundColor:
                                                            const Color(
                                                              0xFF10B981,
                                                            ),
                                                        duration:
                                                            const Duration(
                                                              seconds: 3,
                                                            ),
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                12,
                                                              ),
                                                        ),
                                                        behavior:
                                                            SnackBarBehavior
                                                                .floating,
                                                      ),
                                                    );
                                                  }
                                                  : null,
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          child: Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal:
                                                  MediaQuery.of(
                                                            context,
                                                          ).size.width <=
                                                          800
                                                      ? 8
                                                      : 16,
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.all(
                                                    8,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white
                                                        .withOpacity(0.2),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          10,
                                                        ),
                                                  ),
                                                  child: Icon(
                                                    Icons.download_rounded,
                                                    color:
                                                        selectedFile != null
                                                            ? Colors.white
                                                            : Colors.grey[500],
                                                    size: 20,
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Flexible(
                                                  child: Text(
                                                    'Télécharger',
                                                    style: TextStyle(
                                                      color:
                                                          selectedFile != null
                                                              ? Colors.white
                                                              : Colors
                                                                  .grey[500],
                                                      fontSize:
                                                          MediaQuery.of(context)
                                                                      .size
                                                                      .width <=
                                                                  800
                                                              ? 14
                                                              : 16,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(width: 16),

                                  // Bouton Partager amélioré
                                  Expanded(
                                    child: Container(
                                      height:
                                          MediaQuery.of(context).size.width <=
                                                  800
                                              ? 42
                                              : 56, // Plus petit sur mobile
                                      decoration: BoxDecoration(
                                        gradient:
                                            selectedFile != null
                                                ? LinearGradient(
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                  colors: [
                                                    const Color(
                                                      0xFFF59E0B,
                                                    ).withOpacity(0.8),
                                                    const Color(
                                                      0xFFD97706,
                                                    ).withOpacity(0.9),
                                                  ],
                                                )
                                                : LinearGradient(
                                                  colors: [
                                                    Colors.grey[700]!
                                                        .withOpacity(0.5),
                                                    Colors.grey[800]!
                                                        .withOpacity(0.7),
                                                  ],
                                                ),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color:
                                              selectedFile != null
                                                  ? const Color(
                                                    0xFFF59E0B,
                                                  ).withOpacity(0.3)
                                                  : Colors.grey[600]!
                                                      .withOpacity(0.3),
                                          width: 1,
                                        ),
                                        boxShadow:
                                            selectedFile != null
                                                ? [
                                                  BoxShadow(
                                                    color: const Color(
                                                      0xFFF59E0B,
                                                    ).withOpacity(0.3),
                                                    spreadRadius: 0,
                                                    blurRadius: 12,
                                                    offset: const Offset(0, 4),
                                                  ),
                                                ]
                                                : [],
                                      ),
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          onTap:
                                              selectedFile != null
                                                  ? () {
                                                    _shareFile(
                                                      selectedFile.id
                                                          .toString(),
                                                    );
                                                  }
                                                  : null,
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          child: Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal:
                                                  MediaQuery.of(
                                                            context,
                                                          ).size.width <=
                                                          800
                                                      ? 8
                                                      : 16,
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.all(
                                                    8,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white
                                                        .withOpacity(0.2),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          10,
                                                        ),
                                                  ),
                                                  child: Icon(
                                                    Icons.share_rounded,
                                                    color:
                                                        selectedFile != null
                                                            ? Colors.white
                                                            : Colors.grey[500],
                                                    size: 20,
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Flexible(
                                                  child: Text(
                                                    'Partager',
                                                    style: TextStyle(
                                                      color:
                                                          selectedFile != null
                                                              ? Colors.white
                                                              : Colors
                                                                  .grey[500],
                                                      fontSize:
                                                          MediaQuery.of(context)
                                                                      .size
                                                                      .width <=
                                                                  800
                                                              ? 14
                                                              : 16,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // --- SÉLECTEUR DE FICHIERS REDESIGNÉ ---
                        if (movie.files.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.symmetric(vertical: 24),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.white.withOpacity(0.1),
                                  Colors.white.withOpacity(0.05),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.15),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  spreadRadius: 0,
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // En-tête redesigné
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        const Color(
                                          0xFF3B82F6,
                                        ).withOpacity(0.1),
                                        const Color(
                                          0xFF6366F1,
                                        ).withOpacity(0.05),
                                      ],
                                    ),
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(24),
                                      topRight: Radius.circular(24),
                                    ),
                                    border: Border(
                                      bottom: BorderSide(
                                        color: Colors.white.withOpacity(0.1),
                                        width: 1,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      // Icône avec effet glassmorphism
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              Color(0xFF3B82F6),
                                              Color(0xFF6366F1),
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(
                                                0xFF3B82F6,
                                              ).withOpacity(0.4),
                                              spreadRadius: 0,
                                              blurRadius: 12,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: const Icon(
                                          Icons.video_library_rounded,
                                          color: Colors.white,
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      // Titre et statistiques
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Fichiers disponibles',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '${movie.files.length} fichier${movie.files.length > 1 ? 's' : ''} • ${_getFilesSize(movie.files)}',
                                              style: TextStyle(
                                                color: Colors.grey[300],
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Badge multiple fichiers
                                      if (movie.files.length > 1)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                Colors.orange.withOpacity(0.2),
                                                Colors.deepOrange.withOpacity(
                                                  0.1,
                                                ),
                                              ],
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                            border: Border.all(
                                              color: Colors.orange.withOpacity(
                                                0.3,
                                              ),
                                              width: 1,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.layers_rounded,
                                                color: Colors.orange[300],
                                                size: 16,
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                'Multiple',
                                                style: TextStyle(
                                                  color: Colors.orange[300],
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                ),

                                // Liste des fichiers redesignée
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child:
                                      movie.files.length == 1
                                          ? _buildEnhancedSingleFileItem(
                                            selectedFile!,
                                          )
                                          : Column(
                                            children: List.generate(movie.files.length, (
                                              index,
                                            ) {
                                              final file = movie.files[index];
                                              final isSelected =
                                                  index == _selectedFileIndex;

                                              return Container(
                                                margin: const EdgeInsets.only(
                                                  bottom: 12,
                                                ),
                                                decoration: BoxDecoration(
                                                  gradient:
                                                      isSelected
                                                          ? LinearGradient(
                                                            begin:
                                                                Alignment
                                                                    .topLeft,
                                                            end:
                                                                Alignment
                                                                    .bottomRight,
                                                            colors: [
                                                              const Color(
                                                                0xFF3B82F6,
                                                              ).withOpacity(
                                                                0.2,
                                                              ),
                                                              const Color(
                                                                0xFF6366F1,
                                                              ).withOpacity(
                                                                0.1,
                                                              ),
                                                            ],
                                                          )
                                                          : LinearGradient(
                                                            colors: [
                                                              Colors.white
                                                                  .withOpacity(
                                                                    0.05,
                                                                  ),
                                                              Colors.white
                                                                  .withOpacity(
                                                                    0.02,
                                                                  ),
                                                            ],
                                                          ),
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                  border: Border.all(
                                                    color:
                                                        isSelected
                                                            ? const Color(
                                                              0xFF3B82F6,
                                                            ).withOpacity(0.6)
                                                            : Colors.white
                                                                .withOpacity(
                                                                  0.1,
                                                                ),
                                                    width: isSelected ? 2 : 1,
                                                  ),
                                                  boxShadow:
                                                      isSelected
                                                          ? [
                                                            BoxShadow(
                                                              color:
                                                                  const Color(
                                                                    0xFF3B82F6,
                                                                  ).withOpacity(
                                                                    0.3,
                                                                  ),
                                                              spreadRadius: 0,
                                                              blurRadius: 12,
                                                              offset:
                                                                  const Offset(
                                                                    0,
                                                                    4,
                                                                  ),
                                                            ),
                                                          ]
                                                          : [],
                                                ),
                                                child: Material(
                                                  color: Colors.transparent,
                                                  child: InkWell(
                                                    onTap: () {
                                                      setState(() {
                                                        _selectedFileIndex =
                                                            index;
                                                      });
                                                    },
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          16,
                                                        ),
                                                    child: Padding(
                                                      padding:
                                                          const EdgeInsets.all(
                                                            16,
                                                          ),
                                                      child:
                                                          _buildEnhancedFileItem(
                                                            file,
                                                            isSelected,
                                                            index,
                                                          ),
                                                    ),
                                                  ),
                                                ),
                                              );
                                            }),
                                          ),
                                ),
                              ],
                            ),
                          ),

                        if (movie.similars.isNotEmpty) ...[
                          const SizedBox(height: 32),
                          _buildSimilarContent(movie.similars),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    } catch (e) {
      return Scaffold(
        appBar: const GosterTopBar(showBackButton: true),
        body: Center(
          child: Text(
            'Erreur lors du chargement des détails du film: ${e.toString()}',
          ),
        ),
      );
    }
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[500],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildTvDetails(TVItem tvSeries) {
    final hasNextEpisode = tvSeries.NEXT.TRANSCODE_URL.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: const GosterTopBar(showBackButton: true),
      body: Stack(
        children: [
          if (MediaQuery.of(context).size.width > 800)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.25,
                child: CookieImage(
                  imageUrl: tvSeries.POSTER,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (context, error, stackTrace) =>
                          Container(color: Colors.grey[900]),
                ),
              ),
            ),

          CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 280,
                pinned: true,
                backgroundColor: Colors.transparent,
                automaticallyImplyLeading: false,
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      CookieImage(
                        imageUrl: tvSeries.BACKDROP,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (context, error, stackTrace) =>
                                Container(color: Colors.grey[900]),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.9),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Container(
                  padding: EdgeInsets.only(
                    left:
                        MediaQuery.of(context).size.width > 800
                            ? MediaQuery.of(context).size.width * 0.28
                            : 24.0,
                    right: 24.0,
                    top: 8.0,
                    bottom: 32.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child:
                            tvSeries.LOGO.isNotEmpty
                                ? SizedBox(
                                  height: 100,
                                  child: CookieImage(
                                    imageUrl: tvSeries.LOGO,
                                    fit: BoxFit.contain,
                                    errorBuilder:
                                        (context, error, stackTrace) => Text(
                                          tvSeries.DISPLAY_NAME.toUpperCase(),
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            fontSize: 48,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.white,
                                            letterSpacing: 2.0,
                                            height: 1.0,
                                          ),
                                        ),
                                  ),
                                )
                                : Text(
                                  tvSeries.DISPLAY_NAME.toUpperCase(),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 48,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: 2.0,
                                    height: 1.0,
                                  ),
                                ),
                      ),

                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey[850],
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: Text(
                                  tvSeries.YEAR.toString(),
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey[850],
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: Text(
                                  tvSeries.Vote_average > 0
                                      ? tvSeries.Vote_average.toString()
                                      : 'N/A',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: const BorderSide(color: Colors.grey),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                              onPressed:
                                  _isUpdatingWatchlist
                                      ? null
                                      : () => _toggleWatchlist(
                                        'tv',
                                        tvSeries.ID,
                                        tvSeries.WATCHLISTED,
                                      ),
                              child:
                                  _isUpdatingWatchlist
                                      ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                        ),
                                      )
                                      : Text(
                                        tvSeries.WATCHLISTED
                                            ? 'Remove from Watchlist'
                                            : 'Add to Watchlist',
                                      ),
                            ),
                            const SizedBox(width: 12),
                            const SizedBox(width: 12),
                            PopupMenuButton<String>(
                              onSelected: (value) {
                                // No files directly accessible at TV series level
                              },
                              itemBuilder:
                                  (context) => [
                                    const PopupMenuItem(
                                      value: 'options',
                                      child: Row(
                                        children: [
                                          Icon(Icons.settings, size: 18),
                                          SizedBox(width: 8),
                                          Text('Series Options'),
                                        ],
                                      ),
                                    ),
                                  ],
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: const BorderSide(color: Colors.grey),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                ),
                                onPressed: null,
                                icon: const Icon(Icons.menu, size: 20),
                                label: const Text('Series Options'),
                              ),
                            ),
                            if (tvSeries.SEASONS.every(
                              (season) =>
                                  season.EPISODES.isEmpty ||
                                  season.EPISODES.every(
                                    (episode) => episode.FILES.isEmpty,
                                  ),
                            ))
                              ContentRequestButton(
                                itemId: tvSeries.ID,
                                itemType: 'tv',
                                apiService: ApiServiceProvider.of(context),
                              ),
                          ],
                        ),
                      ),

                      if (hasNextEpisode)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 24.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextButton.icon(
                                  style: TextButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  onPressed: () {
                                    // Action pour lire le prochain épisode
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) => PlayerPage(
                                              transcodeUrl:
                                                  tvSeries.NEXT.TRANSCODE_URL,
                                            ),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.play_arrow, size: 24),
                                  label: const Text(
                                    'Continue Watching',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      if (hasNextEpisode)
                        Card(
                          color: Colors.grey[900],
                          margin: const EdgeInsets.only(bottom: 16.0),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.schedule,
                                      color: Colors.white70,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Continue: ${tvSeries.NEXT.NAME}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  tvSeries.NEXT.INFO,
                                  style: TextStyle(color: Colors.grey[400]),
                                ),
                              ],
                            ),
                          ),
                        ),

                      if (tvSeries.TAGLINE.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: Text(
                            tvSeries.TAGLINE,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                      Text(
                        tvSeries.DESCRIPTION,
                        style: TextStyle(
                          color: Colors.grey[300],
                          fontSize: 15,
                          height: 1.5,
                        ),
                      ),

                      const SizedBox(height: 24),

                      _buildSeasonsTabView(tvSeries),

                      if (tvSeries.GENRE.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        const Text(
                          'Genres',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8.0,
                          runSpacing: 8.0,
                          children:
                              tvSeries.GENRE
                                  .map(
                                    (genre) => Chip(
                                      label: Text(genre.name),
                                      backgroundColor: Colors.grey[850],
                                      labelStyle: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                  )
                                  .toList(),
                        ),
                      ],

                      if (tvSeries.SIMILARS.isNotEmpty) ...[
                        const SizedBox(height: 32),
                        _buildSimilarContent(tvSeries.SIMILARS),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSeasonsTabView(TVItem tvSeries) {
    return DefaultTabController(
      length: tvSeries.SEASONS.length,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Text(
              'Episodes',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          TabBar(
            isScrollable: true,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            indicatorColor: Colors.blue,
            tabs:
                tvSeries.SEASONS
                    .map(
                      (season) => Tab(text: 'Season ${season.SEASON_NUMBER}'),
                    )
                    .toList(),
          ),

          SizedBox(
            height: 500,
            child: TabBarView(
              children:
                  tvSeries.SEASONS
                      .map(
                        (season) =>
                            _buildSeasonEpisodes(season, tvSeries.ID, tvSeries),
                      )
                      .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeasonEpisodes(SEASON season, String seriesId, TVItem tvSeries) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  season.NAME,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // Affiche le TorrentInfoButton seulement si aucun épisode de la saison n'a de fichiers
              if (!season.EPISODES.any((ep) => ep.FILES.isNotEmpty) &&
                  season.SEASON_NUMBER > 0) ...[
                TorrentInfoButton(
                  itemId: seriesId,
                  itemType: 'tv',
                  hasFiles: false,
                  seasonNumber: season.SEASON_NUMBER,
                  seasonId: season.ID.toString(),
                  sourceItem: season, // Pass the TV series as source item
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder:
                          (context) => TorrentSearchModal(
                            apiService: ApiServiceProvider.of(context),
                            mediaId: seriesId,
                            mediaType: 'tv',
                          ),
                    );
                  },
                  icon: const Icon(Icons.search, size: 16),
                  label: const Text('Search', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    minimumSize: const Size(0, 32),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
              if (season.EPISODES.isEmpty ||
                  season.EPISODES.every((episode) => episode.FILES.isEmpty))
                ContentRequestButton(
                  itemId: tvSeries.ID,
                  itemType: 'tv',
                  seasonId: season.ID,
                  apiService: ApiServiceProvider.of(context),
                ),
            ],
          ),
        ),
        if (season.DESCRIPTION.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Text(
              season.DESCRIPTION,
              style: TextStyle(color: Colors.grey[400], fontSize: 14),
            ),
          ),

        Expanded(
          child: ListView.builder(
            itemCount: season.EPISODES.length,
            itemBuilder: (context, index) {
              final episode = season.EPISODES[index];
              return _buildEpisodeItem(episode);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEpisodeItem(EPISODE episode) {
    final hasStartedWatching = episode.WATCH.current > 0;
    final progress =
        hasStartedWatching ? episode.WATCH.current / episode.WATCH.total : 0.0;

    // Get selected file index for this episode, defaulting to 0
    final selectedFileIndex = _selectedEpisodeFileIndices[episode.ID] ?? 0;
    final selectedFile =
        episode.FILES.isNotEmpty ? episode.FILES[selectedFileIndex] : null;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(4),
      ),
      child: InkWell(
        onTap: () {
          // Action pour lire l'épisode
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => PlayerPage(
                    transcodeUrl:
                        selectedFile != null
                            ? selectedFile.transcodeUrl
                            : episode.TRANSCODE_URL,
                  ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Main episode row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Ajout de l'icône info si aucun fichier
                  if (episode.FILES.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(right: 6.0, top: 2.0),
                      child: Tooltip(
                        message: "Aucun fichier disponible pour cet épisode",
                        child: Icon(
                          Icons.info_outline,
                          color: Colors.amber[300],
                          size: 18,
                        ),
                      ),
                    ),
                  SizedBox(
                    width: 30,
                    child: Text(
                      episode.EPISODE_NUMBER.toString(),
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  Container(
                    width: 130,
                    height: 80,
                    margin: const EdgeInsets.only(right: 16.0),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child:
                              episode.STILL.contains('tmdb')
                                  ? Image.network(
                                    episode.STILL,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            Container(color: Colors.grey[800]),
                                  )
                                  : CookieImage(
                                    imageUrl: episode.STILL,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            Container(color: Colors.grey[800]),
                                  ),
                        ),

                        Center(
                          child: Container(
                            width: 40,
                            height: 40,

                            decoration: BoxDecoration(
                              color: Colors.black38,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(
                              Icons.play_arrow,
                              color: Colors.white,
                            ),
                          ),
                        ),

                        if (hasStartedWatching)
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: LinearProgressIndicator(
                              value: progress,
                              color: Colors.red,
                              backgroundColor: Colors.white24,
                              minHeight: 3,
                            ),
                          ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                episode.NAME,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              episode.WATCH.total > 0
                                  ? '${(episode.WATCH.total / 60).round()} min'
                                  : '',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          episode.DESCRIPTION,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14,
                            height: 1.2,
                          ),
                        ),
                        if (hasStartedWatching)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.check_circle_outline,
                                  color: Colors.red,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Watched ${(progress * 100).toStringAsFixed(0)}%',
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),

                  Row(
                    children: [
                      if (episode.DOWNLOAD_URL.isNotEmpty)
                        IconButton(
                          icon: const Icon(
                            Icons.download_outlined,
                            color: Colors.white70,
                          ),
                          onPressed: () {
                            // Action de téléchargement
                          },
                        ),
                      PopupMenuButton<String>(
                        icon: const Icon(
                          Icons.more_vert,
                          color: Colors.white70,
                        ),
                        onSelected: (value) {
                          if (value == 'share' && selectedFile != null) {
                            _shareFile(selectedFile.id.toString());
                          }
                        },
                        itemBuilder:
                            (context) => [
                              if (selectedFile != null)
                                const PopupMenuItem(
                                  value: 'share',
                                  child: Row(
                                    children: [
                                      Icon(Icons.share, size: 18),
                                      SizedBox(width: 8),
                                      Text('Share Episode'),
                                    ],
                                  ),
                                ),
                              const PopupMenuItem(
                                value: 'options',
                                child: Row(
                                  children: [
                                    Icon(Icons.settings, size: 18),
                                    SizedBox(width: 8),
                                    Text('Episode Options'),
                                  ],
                                ),
                              ),
                            ],
                      ),
                    ],
                  ),
                ],
              ),

              if (episode.FILES.length > 1)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0, left: 46.0),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.file_present,
                        size: 16,
                        color: Colors.white60,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        "File:",
                        style: TextStyle(color: Colors.white60, fontSize: 14),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButton<int>(
                          value: selectedFileIndex,
                          dropdownColor: Colors.grey[850],
                          style: const TextStyle(color: Colors.white),
                          isExpanded: true,
                          underline: Container(
                            height: 1,
                            color: Colors.white24,
                          ),
                          onChanged: (int? newValue) {
                            if (newValue != null) {
                              setState(() {
                                _selectedEpisodeFileIndices[episode.ID] =
                                    newValue;
                              });
                            }
                          },
                          items: List.generate(
                            episode.FILES.length,
                            (index) => DropdownMenuItem<int>(
                              value: index,
                              child: Text(
                                episode.FILES[index].filename,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSimilarContent(List<SkinnyRender> similars) {
    final int halfLength = similars.length ~/ 2;
    final firstHalf = similars.take(halfLength).toList();
    final secondHalf = similars.skip(halfLength).toList();
    final bool isMobile = MediaQuery.of(context).size.width <= 800;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Text(
            'You might also like',
            style: TextStyle(
              color: Colors.white,
              fontSize: isMobile ? 24 : 20, // Plus grand sur mobile
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        if (firstHalf.isNotEmpty) ...[
          SizedBox(
            height: isMobile ? 240 : 200, // Plus haut sur mobile
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: firstHalf.length,
              itemBuilder: (context, index) {
                return MediaCard(
                  media: firstHalf[index],
                  width: isMobile ? 320 : 280, // Plus large sur mobile
                  height: isMobile ? 220 : 180, // Plus haut sur mobile
                  displayMode: MediaCardDisplayMode.backdrop,
                );
              },
            ),
          ),
          const SizedBox(height: 20),
        ],
        if (secondHalf.isNotEmpty) ...[
          SizedBox(
            height: isMobile ? 280 : 240, // Plus haut sur mobile
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: secondHalf.length,
              itemBuilder: (context, index) {
                return MediaCard(
                  media: secondHalf[index],
                  width: isMobile ? 180 : 150, // Plus large sur mobile
                  height: isMobile ? 260 : 220, // Plus haut sur mobile
                  displayMode: MediaCardDisplayMode.poster,
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  // Méthode pour calculer la taille totale des fichiers
  String _getFilesSize(List<dynamic> files) {
    if (files.isEmpty) return '0 MB';
    // Simulation d'une taille basée sur le nombre de fichiers et leur qualité
    double totalSize = 0.0;
    for (var file in files) {
      final quality = _getFileQuality(file.filename);
      if (quality.contains('4K')) {
        totalSize += 8.5; // GB
      } else if (quality.contains('1080p')) {
        totalSize += 4.2; // GB
      } else if (quality.contains('720p')) {
        totalSize += 2.1; // GB
      } else {
        totalSize += 1.5; // GB
      }
    }
    return totalSize > 1
        ? '${totalSize.toStringAsFixed(1)} GB'
        : '${(totalSize * 1024).toStringAsFixed(0)} MB';
  }

  // Méthode pour afficher un fichier unique avec design amélioré
  Widget _buildEnhancedSingleFileItem(dynamic file) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF10B981).withOpacity(0.1),
            const Color(0xFF059669).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF10B981).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Icône avec animation
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF059669)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF10B981).withOpacity(0.4),
                      spreadRadius: 0,
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.play_circle_filled_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              // Informations du fichier
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      file.filename,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildFileInfoChip(
                          Icons.high_quality_rounded,
                          _getFileQuality(file.filename),
                          _getQualityColor(_getFileQuality(file.filename)),
                        ),
                        const SizedBox(width: 12),
                        _buildFileInfoChip(
                          Icons.storage_rounded,
                          _getFileSize(file.filename),
                          Colors.blue,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Menu d'options
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.more_vert_rounded,
                    color: Colors.white,
                  ),
                  onSelected: (value) {
                    if (value == 'share') {
                      _shareFile(file.id.toString());
                    }
                  },
                  itemBuilder:
                      (context) => [
                        const PopupMenuItem(
                          value: 'share',
                          child: Row(
                            children: [
                              Icon(Icons.share_rounded, size: 18),
                              SizedBox(width: 8),
                              Text('Partager le fichier'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'info',
                          child: Row(
                            children: [
                              Icon(Icons.info_rounded, size: 18),
                              SizedBox(width: 8),
                              Text('Informations'),
                            ],
                          ),
                        ),
                      ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Barre de progression si applicable
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[700],
              borderRadius: BorderRadius.circular(2),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: 1.0, // Simule un fichier prêt
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF059669)],
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Prêt à être lu',
            style: TextStyle(
              color: const Color(0xFF10B981),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // Méthode pour afficher un fichier dans une liste avec design amélioré
  Widget _buildEnhancedFileItem(dynamic file, bool isSelected, int index) {
    return Row(
      children: [
        // Indicateur de sélection avec animation
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            gradient:
                isSelected
                    ? const LinearGradient(
                      colors: [Color(0xFF3B82F6), Color(0xFF6366F1)],
                    )
                    : null,
            color: isSelected ? null : Colors.transparent,
            border:
                isSelected
                    ? null
                    : Border.all(color: Colors.grey[600]!, width: 2),
            borderRadius: BorderRadius.circular(14),
            boxShadow:
                isSelected
                    ? [
                      BoxShadow(
                        color: const Color(0xFF3B82F6).withOpacity(0.4),
                        spreadRadius: 0,
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                    : [],
          ),
          child:
              isSelected
                  ? const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 18,
                  )
                  : Center(
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
        ),
        const SizedBox(width: 16),

        // Icône du fichier avec animation
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient:
                isSelected
                    ? LinearGradient(
                      colors: [
                        const Color(0xFF3B82F6).withOpacity(0.3),
                        const Color(0xFF6366F1).withOpacity(0.2),
                      ],
                    )
                    : null,
            color: isSelected ? null : Colors.grey[800]!.withOpacity(0.3),
            borderRadius: BorderRadius.circular(10),
            boxShadow:
                isSelected
                    ? [
                      BoxShadow(
                        color: const Color(0xFF3B82F6).withOpacity(0.2),
                        spreadRadius: 0,
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                    : [],
          ),
          child: Icon(
            Icons.play_circle_filled_rounded,
            color: isSelected ? const Color(0xFF3B82F6) : Colors.grey[500],
            size: 24,
          ),
        ),
        const SizedBox(width: 16),

        // Informations du fichier
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                file.filename,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[300],
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildFileInfoChip(
                    Icons.high_quality_rounded,
                    _getFileQuality(file.filename),
                    _getQualityColor(_getFileQuality(file.filename)),
                  ),
                  const SizedBox(width: 8),
                  _buildFileInfoChip(
                    Icons.storage_rounded,
                    _getFileSize(file.filename),
                    Colors.blue,
                  ),
                ],
              ),
            ],
          ),
        ),

        // Menu d'options
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
          ),
          child: PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert_rounded,
              color: Colors.grey[400],
              size: 20,
            ),
            onSelected: (value) {
              if (value == 'share') {
                _shareFile(file.id.toString());
              }
            },
            itemBuilder:
                (context) => [
                  const PopupMenuItem(
                    value: 'share',
                    child: Row(
                      children: [
                        Icon(Icons.share_rounded, size: 18),
                        SizedBox(width: 8),
                        Text('Partager'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'info',
                    child: Row(
                      children: [
                        Icon(Icons.info_rounded, size: 18),
                        SizedBox(width: 8),
                        Text('Informations'),
                      ],
                    ),
                  ),
                ],
          ),
        ),
      ],
    );
  }

  // Widget helper pour les puces d'informations
  Widget _buildFileInfoChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // Méthode helper pour extraire la qualité du nom de fichier
  String _getFileQuality(String filename) {
    if (filename.toUpperCase().contains('4K') ||
        filename.toUpperCase().contains('2160P')) {
      return '4K';
    } else if (filename.toUpperCase().contains('1080P')) {
      return '1080p';
    } else if (filename.toUpperCase().contains('720P')) {
      return '720p';
    } else if (filename.toUpperCase().contains('480P')) {
      return '480p';
    }
    return 'SD';
  }

  // Méthode helper pour obtenir la couleur selon la qualité
  Color _getQualityColor(String quality) {
    switch (quality) {
      case '4K':
        return Colors.purple;
      case '1080p':
        return Colors.green;
      case '720p':
        return Colors.blue;
      case '480p':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  // Méthode helper pour extraire la taille approximative du fichier
  String _getFileSize(String filename) {
    // Extraction basique basée sur les patterns courants
    if (filename.toUpperCase().contains('4K') ||
        filename.toUpperCase().contains('2160P')) {
      return '~15-25 GB';
    } else if (filename.toUpperCase().contains('1080P')) {
      return '~2-8 GB';
    } else if (filename.toUpperCase().contains('720P')) {
      return '~1-3 GB';
    } else if (filename.toUpperCase().contains('480P')) {
      return '~500MB-1GB';
    }
    return 'Taille inconnue';
  }
}
