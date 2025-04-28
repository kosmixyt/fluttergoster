import 'package:flutter/material.dart';
import 'package:fluttergoster/pages/player_page.dart';
import '../services/api_service.dart';
import '../models/data_models.dart';
import '../main.dart'; // For ApiServiceProvider

class TorrentInfoButton extends StatefulWidget {
  final String itemId;
  final String itemType;
  final bool hasFiles;
  final int? seasonNumber; // Keep this for display purposes
  final String? seasonId; // Added parameter for season ID
  final dynamic sourceItem; // New parameter to pass movie or TV show data

  const TorrentInfoButton({
    super.key,
    required this.itemId,
    required this.itemType,
    required this.hasFiles,
    this.seasonNumber,
    this.seasonId,
    this.sourceItem, // Optional parameter for source item (MovieItem or TVItem)
  });

  @override
  State<TorrentInfoButton> createState() => _TorrentInfoButtonState();
}

class _TorrentInfoButtonState extends State<TorrentInfoButton> {
  List<AvailableTorrent>? _torrents;
  bool _isLoading = false;
  String? _error;
  bool _didFetch = false; // Ajouté pour éviter plusieurs fetchs

  @override
  void initState() {
    super.initState();
    // Ne rien faire ici concernant le contexte
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didFetch && !widget.hasFiles) {
      _fetchTorrents();
      _didFetch = true;
    }
  }

  @override
  void didUpdateWidget(covariant TorrentInfoButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If hasFiles changes from true to false, attempt to load torrents
    if (!widget.hasFiles && oldWidget.hasFiles) {
      _fetchTorrents();
    }

    // Re-fetch torrents if season number or season ID changes (for TV series)
    if (widget.itemType == 'tv' &&
        (widget.seasonNumber != oldWidget.seasonNumber ||
            widget.seasonId != oldWidget.seasonId) &&
        (widget.seasonNumber != null || widget.seasonId != null)) {
      _fetchTorrents();
    }
  }

  Future<void> _fetchTorrents() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _error = null;
      _torrents = null; // Reset previous torrents when fetching new ones
    });

    try {
      final apiService = ApiServiceProvider.of(context);
      final torrents = await apiService.fetchAvailableTorrents(
        widget.itemId,
        widget.itemType,
        widget.seasonId ??
            '', // Use season ID if available, otherwise empty string
      );

      setState(() {
        _torrents = torrents;
        _isLoading = false;
      });
    } catch (e) {
      print(e);
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _showTorrentDetails() {
    if (_torrents == null || _torrents!.isEmpty) return;

    showDialog(
      context: context,
      builder:
          (context) => TorrentDetailsDialog(
            torrents: _torrents!,
            sourceItem: widget.sourceItem, // Pass the source item
            itemType: widget.itemType,
            itemId: widget.itemId,
            seasonId: widget.seasonId,
            seasonNumber: widget.seasonNumber,
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // If the item has files, don't show the button
    if (widget.hasFiles) {
      return const SizedBox.shrink();
    }

    // Loading state
    if (_isLoading) {
      return Flexible(
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
          icon: const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          label: const Text(
            'Loading torrents...',
            overflow: TextOverflow.ellipsis,
          ),
        ),
      );
    }

    // Error state: affiche le message d'erreur
    if (_error != null) {
      return Flexible(
        child: OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.red,
            side: const BorderSide(color: Colors.red),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          onPressed: null,
          icon: const Icon(Icons.error_outline, size: 20),
          label: Text(
            "$_error",
            style: TextStyle(color: Colors.red),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      );
    }

    // Success state with torrents
    if (_torrents != null && _torrents!.isNotEmpty) {
      return Flexible(
        child: OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.green,
            side: const BorderSide(color: Colors.green),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          onPressed: _showTorrentDetails,
          icon: const Icon(Icons.file_download, size: 20),
          label: Text(
            '${_torrents!.length} torrents available',
            overflow: TextOverflow.ellipsis,
          ),
        ),
      );
    }

    // No torrents found
    return Flexible(
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.grey,
          side: const BorderSide(color: Colors.grey),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        onPressed: null,
        icon: const Icon(Icons.info_outline, size: 20),
        label: const Text('No torrents found', overflow: TextOverflow.ellipsis),
      ),
    );
  }
}

class TorrentDetailsDialog extends StatelessWidget {
  final List<AvailableTorrent> torrents;
  final dynamic sourceItem; // Can be MovieItem, TVItem, or null
  final String? itemType;
  final String? itemId;
  final String? seasonId;
  final int? seasonNumber;

  const TorrentDetailsDialog({
    super.key,
    required this.torrents,
    this.sourceItem,
    this.itemType,
    this.itemId,
    this.seasonId,
    this.seasonNumber,
  });

  // Helper function to format file size
  String _formatSize(int? sizeInBytes) {
    if (sizeInBytes == null) return 'Unknown';

    const units = ['B', 'KB', 'MB', 'GB', 'TB'];
    var size = sizeInBytes.toDouble();
    var unitIndex = 0;

    while (size >= 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex++;
    }

    return '${size.toStringAsFixed(2)} ${units[unitIndex]}';
  }

  @override
  Widget build(BuildContext context) {
    // Sort torrents by seed count (highest first)
    final sortedTorrents = [...torrents]
      ..sort((a, b) => (b.seed ?? 0).compareTo(a.seed ?? 0));

    // Check if we're on a small screen
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 16 : 24,
        vertical: isSmallScreen ? 24 : 40,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.7),
              blurRadius: 24,
              spreadRadius: 2,
            ),
          ],
        ),
        padding: const EdgeInsets.all(0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[850],
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 16 : 24,
                vertical: isSmallScreen ? 12 : 18,
              ),
              child: Row(
                children: [
                  Icon(Icons.download, color: Colors.green[400]),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Available Torrents (${torrents.length})',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isSmallScreen ? 18 : 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54),
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    splashRadius: 20,
                  ),
                ],
              ),
            ),

            // Table or List view depending on screen size
            Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.7,
                // Remove fixed width constraint for better mobile layout
              ),
              padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 8 : 16,
                vertical: 12,
              ),
              child:
                  isSmallScreen
                      ? _buildMobileList(context, sortedTorrents)
                      : _buildDesktopTable(context, sortedTorrents),
            ),

            // Actions
            Container(
              alignment: Alignment.centerRight,
              padding: EdgeInsets.only(
                right: isSmallScreen ? 16 : 24,
                bottom: 16,
                top: 4,
              ),
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.green[700],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 16 : 18,
                    vertical: isSmallScreen ? 12 : 10,
                  ),
                ),
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.check, size: 18),
                label: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Desktop table layout
  Widget _buildDesktopTable(
    BuildContext context,
    List<AvailableTorrent> sortedTorrents,
  ) {
    return Column(
      children: [
        // Header row
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Row(
            children: const [
              SizedBox(
                width: 90,
                child: Text(
                  'Provider',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(
                width: 320,
                child: Text(
                  'Name',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(
                width: 90,
                child: Text(
                  'Size',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(
                width: 80,
                child: Text(
                  'Seeds',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(
                width: 140,
                child: Text(
                  'Quality',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 2),

        // Data rows
        Expanded(
          child:
              sortedTorrents.isEmpty
                  ? Center(
                    child: Text(
                      "No torrents found",
                      style: TextStyle(color: Colors.white54),
                    ),
                  )
                  : ListView.separated(
                    itemCount: sortedTorrents.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 2),
                    itemBuilder: (context, idx) {
                      final torrent = sortedTorrents[idx];
                      final flags = torrent.flags?.join(', ') ?? '';

                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[850],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 8,
                        ),
                        child: Row(
                          children: [
                            // Provider column
                            SizedBox(
                              width: 90,
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.cloud,
                                    color: Colors.green[300],
                                    size: 18,
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      torrent.providerName ?? 'Unknown',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Torrent name
                            SizedBox(
                              width: 320,
                              child: Text(
                                torrent.name ?? 'Unknown',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),

                            // Size
                            SizedBox(
                              width: 90,
                              child: Text(
                                _formatSize(torrent.size),
                                style: const TextStyle(color: Colors.white70),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),

                            // Seeds
                            SizedBox(
                              width: 80,
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.arrow_upward,
                                    size: 16,
                                    color:
                                        (torrent.seed ?? 0) > 0
                                            ? Colors.greenAccent
                                            : Colors.redAccent,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    torrent.seed?.toString() ?? '0',
                                    style: TextStyle(
                                      color:
                                          (torrent.seed ?? 0) > 0
                                              ? Colors.greenAccent
                                              : Colors.redAccent,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Flags/Quality
                            SizedBox(
                              width: 140,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      flags.contains('1080p')
                                          ? Colors.blue.withOpacity(0.18)
                                          : Colors.white10,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  flags,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),

                            // Action buttons
                            const SizedBox(width: 16),
                            Flexible(
                              flex: 0,
                              child: ElevatedButton.icon(
                                onPressed: null, // No action for now
                                icon: const Icon(
                                  Icons.download,
                                  size: 18,
                                  color: Colors.white,
                                ),
                                label: const Text(
                                  "Télécharger",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green[700],
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size(0, 38),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  elevation: 2,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Only show the streaming button for movies
                            if (itemType == "movie")
                              Flexible(
                                flex: 0,
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder:
                                            (context) => PlayerPage(
                                              transcodeUrl:
                                                  (sourceItem.transcodeUrl) +
                                                  "&torrent_id=${torrent.id}",
                                              sourceItem:
                                                  sourceItem, // Pass the source item
                                              sourceItemId: itemId,
                                              sourceItemType: itemType,
                                              seasonId: seasonId,
                                              seasonNumber: seasonNumber,
                                              torrentInfo:
                                                  torrent, // Pass torrent info as well
                                            ),
                                      ),
                                    );
                                  },
                                  icon: const Icon(
                                    Icons.play_arrow,
                                    size: 18,
                                    color: Colors.green,
                                  ),
                                  label: const Text(
                                    "Streamer",
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.green,
                                    side: BorderSide(
                                      color: Colors.green[700]!,
                                      width: 2,
                                    ),
                                    minimumSize: const Size(0, 38),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 10,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
        ),
      ],
    );
  }

  // Mobile-friendly list layout
  Widget _buildMobileList(
    BuildContext context,
    List<AvailableTorrent> sortedTorrents,
  ) {
    return sortedTorrents.isEmpty
        ? Center(
          child: Text(
            "No torrents found",
            style: TextStyle(color: Colors.white54),
          ),
        )
        : ListView.separated(
          itemCount: sortedTorrents.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, idx) {
            final torrent = sortedTorrents[idx];
            final flags = torrent.flags?.join(', ') ?? '';

            return Container(
              decoration: BoxDecoration(
                color: Colors.grey[850],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color:
                      (torrent.seed ?? 0) > 10
                          ? Colors.green.withOpacity(0.3)
                          : Colors.transparent,
                ),
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Torrent name and provider
                  Row(
                    children: [
                      Icon(Icons.cloud, color: Colors.green[300], size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              torrent.name ?? 'Unknown',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              torrent.providerName ?? 'Unknown',
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Info row: Size, Seeds, Quality
                  Row(
                    children: [
                      // Size
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Size',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _formatSize(torrent.size),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Seeds
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Seeds',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Icon(
                                  Icons.arrow_upward,
                                  size: 14,
                                  color:
                                      (torrent.seed ?? 0) > 0
                                          ? Colors.greenAccent
                                          : Colors.redAccent,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  torrent.seed?.toString() ?? '0',
                                  style: TextStyle(
                                    color:
                                        (torrent.seed ?? 0) > 0
                                            ? Colors.greenAccent
                                            : Colors.redAccent,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Quality
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Quality',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    flags.contains('1080p')
                                        ? Colors.blue.withOpacity(0.18)
                                        : Colors.white10,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                flags.isEmpty ? 'Unknown' : flags,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Action buttons - full width for better tap targets
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: null, // No action for now
                          icon: const Icon(Icons.download, size: 18),
                          label: const Text(
                            "Télécharger",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[700],
                            foregroundColor: Colors.white,
                            minimumSize: const Size(0, 42),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Only show the streaming icon button for movies
                      if (itemType == "movie")
                        IconButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder:
                                    (context) => PlayerPage(
                                      transcodeUrl:
                                          sourceItem.transcodeUrl +
                                          "&torrent_id=${torrent.id}",
                                      sourceItem: sourceItem,
                                      sourceItemId: itemId,
                                      sourceItemType: itemType,
                                      seasonId: seasonId,
                                      seasonNumber: seasonNumber,
                                      torrentInfo: torrent,
                                    ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.play_arrow),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.grey[800],
                            foregroundColor: Colors.green,
                            minimumSize: const Size(42, 42),
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(
                                color: Colors.green[700]!,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
  }
}
