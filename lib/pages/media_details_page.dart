import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Add this import for clipboard functionality
import '../services/api_service.dart';
import '../main.dart';
import '../models/data_models.dart';
import '../widgets/cookie_image.dart';
import '../widgets/goster_top_bar.dart';
import '../pages/home_page.dart';
import 'package:fluttergoster/widgets/media_card.dart';

class MediaDetailsPage extends StatefulWidget {
  final String mediaId;
  final String mediaType;

  const MediaDetailsPage({
    Key? key,
    required this.mediaId,
    required this.mediaType,
  }) : super(key: key);

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
  Map<int, int> _selectedEpisodeFileIndices = {}; // Track selected files for episodes

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
  Future<void> _toggleWatchlist(String itemType, String itemId, bool currentStatus) async {
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
            currentStatus 
                ? 'Removed from watchlist' 
                : 'Added to watchlist',
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
        builder: (context) => AlertDialog(
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
                      const Icon(Icons.content_copy, color: Colors.white60, size: 20),
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
          titleTextStyle: const TextStyle(color: Colors.white, fontSize: 18),
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
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
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
      final selectedFile = movie.files.isNotEmpty ? movie.files[_selectedFileIndex] : null;
      final runtimeMinutes = movie.runtime.isNotEmpty ? movie.runtime : 'N/A';
      
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
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.25,
                  child: CookieImage(
                    imageUrl: movie.poster,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => 
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
                          imageUrl: movie.backdrop,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => 
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
                      left: MediaQuery.of(context).size.width > 800 ? 
                        MediaQuery.of(context).size.width * 0.28 : 24.0,
                      right: 24.0,
                      top: 8.0,
                      bottom: 32.0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: movie.logo.isNotEmpty ? 
                            SizedBox(
                              height: 100,
                              child: CookieImage(
                                imageUrl: movie.logo,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) => 
                                  Text(
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
                            ) : 
                            Text(
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
                        
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          child: Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[850],
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  child: Text(
                                    movie.year.toString(),
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[850],
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  child: Text(
                                    movie.voteAverage > 0 ? movie.voteAverage.toString() : 'N/A',
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
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                ),
                                onPressed: _isUpdatingWatchlist 
                                    ? null 
                                    : () => _toggleWatchlist('movie', movie.id, movie.watchlisted),
                                child: _isUpdatingWatchlist
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      )
                                    : Text(movie.watchlisted ? 'Remove from Watchlist' : 'Add to Watchlist'),
                              ),
                            ],
                          ),
                        ),
                        
                        Container(
                          margin: const EdgeInsets.symmetric(vertical: 16),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.grey[900],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  selectedFile != null ? selectedFile.filename : 'Aucun fichier disponible',
                                  style: const TextStyle(color: Colors.white),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (movie.files.length > 1)
                                PopupMenuButton<int>(
                                  icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                                  onSelected: (index) {
                                    setState(() {
                                      _selectedFileIndex = index;
                                    });
                                  },
                                  itemBuilder: (context) => List.generate(
                                    movie.files.length,
                                    (index) => PopupMenuItem<int>(
                                      value: index,
                                      child: Text(
                                        movie.files[index].filename,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                )
                              else
                                const Icon(Icons.arrow_drop_down, color: Colors.white),
                              
                              if (selectedFile != null)
                                PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert, color: Colors.white70),
                                  onSelected: (value) {
                                    if (value == 'share') {
                                      _shareFile(selectedFile.id.toString());
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'share',
                                      child: Row(
                                        children: [
                                          Icon(Icons.share, size: 18),
                                          SizedBox(width: 8),
                                          Text('Share File'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'options',
                                      child: Row(
                                        children: [
                                          Icon(Icons.settings, size: 18),
                                          SizedBox(width: 8),
                                          Text('More Options'),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                        
                        Padding(
                          padding: const EdgeInsets.only(bottom: 24.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextButton.icon(
                                  style: TextButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  onPressed: () {},
                                  icon: const Icon(Icons.play_arrow, size: 24),
                                  label: Text(
                                    movie.watch.current > 0 ? 'Resume' : 'Play',
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextButton.icon(
                                  style: TextButton.styleFrom(
                                    backgroundColor: Colors.grey[850],
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  onPressed: () {},
                                  icon: const Icon(Icons.download, size: 24),
                                  label: const Text(
                                    'Download',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
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
                            children: movie.genre.map((genre) => Chip(
                              label: Text(genre.name),
                              backgroundColor: Colors.grey[850],
                              labelStyle: const TextStyle(color: Colors.white),
                            )).toList(),
                          ),
                        ],

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
        body: Center(child: Text('Erreur lors du chargement des détails du film: ${e.toString()}')),
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
            child: Text(
              value,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTvDetails(TVItem tvSeries) {
    final hasNextEpisode = tvSeries.NEXT.TRANSCODE_URL.isNotEmpty;
    
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: const GosterTopBar(showBackButton: true,),
      body: Stack(
        children: [
          if (MediaQuery.of(context).size.width > 800)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: MediaQuery.of(context).size.width * 0.25,
                child: CookieImage(
                  imageUrl: tvSeries.POSTER,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => 
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
                        errorBuilder: (context, error, stackTrace) => 
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
                    left: MediaQuery.of(context).size.width > 800 ? 
                      MediaQuery.of(context).size.width * 0.28 : 24.0,
                    right: 24.0,
                    top: 8.0,
                    bottom: 32.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: tvSeries.LOGO.isNotEmpty ? 
                          SizedBox(
                            height: 100,
                            child: CookieImage(
                              imageUrl: tvSeries.LOGO,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) => 
                                Text(
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
                          ) : 
                          Text(
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
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
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
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.grey[850],
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: Text(
                                  tvSeries.Vote_average > 0 ? tvSeries.Vote_average.toString() : 'N/A',
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
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                              onPressed: _isUpdatingWatchlist 
                                  ? null 
                                  : () => _toggleWatchlist('tv', tvSeries.ID, tvSeries.WATCHLISTED),
                              child: _isUpdatingWatchlist
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : Text(tvSeries.WATCHLISTED ? 'Remove from Watchlist' : 'Add to Watchlist'),
                            ),
                            const SizedBox(width: 12),
                            PopupMenuButton<String>(
                              onSelected: (value) {
                                // No files directly accessible at TV series level
                              },
                              itemBuilder: (context) => [
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
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                ),
                                onPressed: null,
                                icon: const Icon(Icons.menu, size: 20),
                                label: const Text('Series Options'),
                              ),
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
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  onPressed: () {
                                    // Action pour lire le prochain épisode
                                  },
                                  icon: const Icon(Icons.play_arrow, size: 24),
                                  label: const Text(
                                    'Continue Watching',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                                    const Icon(Icons.schedule, color: Colors.white70),
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
                          children: tvSeries.GENRE.map((genre) => Chip(
                            label: Text(genre.name),
                            backgroundColor: Colors.grey[850],
                            labelStyle: const TextStyle(color: Colors.white),
                          )).toList(),
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
            tabs: tvSeries.SEASONS.map((season) => 
              Tab(text: 'Season ${season.SEASON_NUMBER}')
            ).toList(),
          ),
          
          SizedBox(
            height: 500,
            child: TabBarView(
              children: tvSeries.SEASONS.map((season) => _buildSeasonEpisodes(season)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeasonEpisodes(SEASON season) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
          child: Text(
            season.NAME,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
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
    final progress = hasStartedWatching ? episode.WATCH.current / episode.WATCH.total : 0.0;
    
    // Get selected file index for this episode, defaulting to 0
    final selectedFileIndex = _selectedEpisodeFileIndices[episode.ID] ?? 0;
    final selectedFile = episode.FILES.isNotEmpty ? 
      episode.FILES[selectedFileIndex] : null;
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(4),
      ),
      child: InkWell(
        onTap: () {
          // Action pour lire l'épisode
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
                          child: episode.STILL.contains('tmdb') 
                            ? Image.network(
                                episode.STILL, 
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => 
                                    Container(color: Colors.grey[800])
                              )
                            : CookieImage(
                                imageUrl: episode.STILL,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => 
                                    Container(color: Colors.grey[800])
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
                          icon: const Icon(Icons.download_outlined, color: Colors.white70),
                          onPressed: () {
                            // Action de téléchargement
                          },
                        ),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, color: Colors.white70),
                        onSelected: (value) {
                          if (value == 'share' && selectedFile != null) {
                            _shareFile(selectedFile.id.toString());
                          }
                        },
                        itemBuilder: (context) => [
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
                      const Icon(Icons.file_present, size: 16, color: Colors.white60),
                      const SizedBox(width: 8),
                      const Text(
                        "File:", 
                        style: TextStyle(color: Colors.white60, fontSize: 14)
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
                                _selectedEpisodeFileIndices[episode.ID] = newValue;
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
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 16.0),
          child: Text(
            'You might also like',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        if (firstHalf.isNotEmpty) ...[
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: firstHalf.length,
              itemBuilder: (context, index) {
                return MediaCard(
                  media: firstHalf[index],
                  width: 280,
                  height: 180,
                  displayMode: MediaCardDisplayMode.backdrop,
                );
              },
            ),
          ),
          const SizedBox(height: 20),
        ],
        if (secondHalf.isNotEmpty) ...[
          SizedBox(
            height: 240,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: secondHalf.length,
              itemBuilder: (context, index) {
                return MediaCard(
                  media: secondHalf[index],
                  width: 150,
                  height: 220,
                  displayMode: MediaCardDisplayMode.poster,
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}
