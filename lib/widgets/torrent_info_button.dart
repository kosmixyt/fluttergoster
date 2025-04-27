import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/data_models.dart';
import '../main.dart'; // For ApiServiceProvider

class TorrentInfoButton extends StatefulWidget {
  final String itemId;
  final String itemType;
  final bool hasFiles;

  const TorrentInfoButton({
    Key? key,
    required this.itemId,
    required this.itemType,
    required this.hasFiles,
  }) : super(key: key);

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
    // Si hasFiles change de true à false, on tente de charger les torrents
    if (!widget.hasFiles && oldWidget.hasFiles) {
      _fetchTorrents();
    }
  }

  Future<void> _fetchTorrents() async {
    if (_isLoading || _torrents != null) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final apiService = ApiServiceProvider.of(context);
      final torrents = await apiService.fetchAvailableTorrents(
        widget.itemId,
        widget.itemType,
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
      builder: (context) => TorrentDetailsDialog(torrents: _torrents!),
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

  const TorrentDetailsDialog({Key? key, required this.torrents})
    : super(key: key);

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

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
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
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              child: Row(
                children: [
                  Icon(Icons.download, color: Colors.green[400]),
                  const SizedBox(width: 10),
                  Text(
                    'Available Torrents (${torrents.length})',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54),
                    onPressed: () => Navigator.of(context).pop(),
                    splashRadius: 20,
                  ),
                ],
              ),
            ),
            // Table
            Container(
              constraints: const BoxConstraints(maxHeight: 420, minWidth: 700),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                children: [
                  // Header row
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 8,
                    ),
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
                              separatorBuilder:
                                  (_, __) => const SizedBox(height: 2),
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
                                                torrent.providerName ??
                                                    'Unknown',
                                                style: const TextStyle(
                                                  color: Colors.white70,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
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
                                      SizedBox(
                                        width: 90,
                                        child: Text(
                                          _formatSize(torrent.size),
                                          style: const TextStyle(
                                            color: Colors.white70,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
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
                                                    ? Colors.blue.withOpacity(
                                                      0.18,
                                                    )
                                                    : Colors.white10,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
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
                                      // --- Ajout des boutons à droite ---
                                      const SizedBox(width: 16),
                                      Flexible(
                                        flex: 0,
                                        child: ElevatedButton.icon(
                                          onPressed:
                                              null, // Pas d'action pour l'instant
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
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            elevation: 2,
                                            textStyle: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        flex: 0,
                                        child: OutlinedButton.icon(
                                          onPressed:
                                              null, // Pas d'action pour l'instant
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
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            textStyle: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
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
              ),
            ),
            // Actions
            Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 24, bottom: 16, top: 4),
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.green[700],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
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
}
