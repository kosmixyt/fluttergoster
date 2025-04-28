import 'package:flutter/material.dart';
import 'package:fluttergoster/models/data_models.dart';
import 'package:fluttergoster/services/api_service.dart';
import 'package:fluttergoster/widgets/goster_top_bar.dart';
import 'package:fluttergoster/widgets/cookie_image.dart';
import 'package:fluttergoster/main.dart';
import 'package:url_launcher/url_launcher.dart';

class MePage extends StatefulWidget {
  const MePage({Key? key}) : super(key: key);

  @override
  State<MePage> createState() => _MePageState();
}

class _MePageState extends State<MePage> {
  late Future<Me> _meFuture;
  late ApiService _apiService;
  bool _isInitialized = false;

  // Variables pour la pagination des shares
  int _sharesPerPage = 5;
  int _currentSharesPage = 0;

  // Ajout d'une référence locale à l'objet Me pour manipuler les listes sans reload global
  Me? _meData;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _apiService = ApiServiceProvider.of(context);
      _loadData();
      _isInitialized = true;
    }
  }

  void _loadData() {
    _meFuture = _apiService.getMe().then((me) {
      _meData = me;
      return me;
    });
  }

  // Méthode pour supprimer une requête de téléchargement
  Future<void> _deleteRequest(MeRequest request) async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                backgroundColor: const Color(0xFF1E1E1E),
                title: const Text(
                  'Confirmer la suppression',
                  style: TextStyle(color: Colors.white),
                ),
                content: Text(
                  'Êtes-vous sûr de vouloir supprimer la demande de téléchargement pour "${request.mediaName}" ?',
                  style: const TextStyle(color: Colors.white70),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Annuler'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text('Supprimer'),
                  ),
                ],
              ),
        ) ??
        false;

    if (confirmed) {
      try {
        await _apiService.deleteRequest(request.id);
        // Rafraîchir les données après la suppression
        setState(() {
          _loadData();
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Demande supprimée avec succès'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur lors de la suppression: $e'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  // Méthode pour supprimer un partage
  Future<void> _deleteShare(MeShare share) async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                backgroundColor: const Color(0xFF1E1E1E),
                title: const Text(
                  'Confirmer la suppression',
                  style: TextStyle(color: Colors.white),
                ),
                content: Text(
                  'Êtes-vous sûr de vouloir supprimer le partage pour "${share.file.filename}" ?',
                  style: const TextStyle(color: Colors.white70),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Annuler'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text('Supprimer'),
                  ),
                ],
              ),
        ) ??
        false;

    if (confirmed) {
      try {
        await _apiService.deleteShare(share.id);
        setState(() {
          // On retire le share localement sans reload global
          _meData?.shares.removeWhere((s) => s.id == share.id);
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Partage supprimé avec succès'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur lors de la suppression: $e'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  // Méthode pour mettre en pause ou reprendre un torrent
  Future<void> _pauseResumeTorrent(TorrentItem torrent) async {
    final action = torrent.paused ? 'resume' : 'pause';

    try {
      await _apiService.torrentAction(action, torrent.id.toString());
      // Rafraîchir les données après l'action
      setState(() {
        // _loadData();
        torrent.paused = !torrent.paused;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Torrent ${torrent.paused ? 'repris' : 'mis en pause'} avec succès',
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // Méthode pour supprimer un torrent
  Future<void> _deleteTorrent(TorrentItem torrent) async {
    // Premier dialogue de confirmation
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                backgroundColor: const Color(0xFF1E1E1E),
                title: const Text(
                  'Confirmer la suppression',
                  style: TextStyle(color: Colors.white),
                ),
                content: Text(
                  'Êtes-vous sûr de vouloir supprimer le torrent "${torrent.name}" ?',
                  style: const TextStyle(color: Colors.white70),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Annuler'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text('Supprimer'),
                  ),
                ],
              ),
        ) ??
        false;

    if (!confirmed) return;

    // Second dialogue pour demander la suppression des fichiers
    final deleteFiles =
        await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                backgroundColor: const Color(0xFF1E1E1E),
                title: const Text(
                  'Supprimer les fichiers',
                  style: TextStyle(color: Colors.white),
                ),
                content: const Text(
                  'Voulez-vous également supprimer les fichiers du système de fichiers ?',
                  style: TextStyle(color: Colors.white70),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Non, garder les fichiers'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text('Oui, supprimer les fichiers'),
                  ),
                ],
              ),
        ) ??
        false;

    try {
      await _apiService.torrentAction(
        'delete',
        torrent.id.toString(),
        deleteFiles,
      );

      setState(() {
        // On retire le torrent localement sans reload global
        _meData?.torrents.removeWhere((t) => t.id == torrent.id);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Torrent supprimé avec succès'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Fermer la bottom sheet si elle est ouverte
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la suppression: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: GosterTopBar(showBackButton: true),
      body: FutureBuilder<Me>(
        future: _meFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: Colors.white),
              ),
            );
          } else if (snapshot.hasData || _meData != null) {
            final me = _meData ?? snapshot.data!;
            return _buildContent(me);
          } else {
            return const Center(
              child: Text(
                'No user data available',
                style: TextStyle(color: Colors.white),
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildContent(Me me) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(me),
          const SizedBox(height: 20),
          _buildStats(me),
          const SizedBox(height: 30),
          _buildSectionTitle('Download Requests'),
          _buildDownloadRequests(me),
          const SizedBox(height: 30),
          _buildSectionTitle('Torrents'),
          _buildTorrents(me),
          const SizedBox(height: 30),
          if (me.shares.isNotEmpty) ...[
            _buildSectionTitle('My Shares'),
            _buildShares(me),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(Me me) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Text(
            'Welcome ${me.username}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildActionButton(
                icon: Icons.shield,
                label: 'Admin Panel',
                onTap: () {},
              ),
              const SizedBox(width: 10),
              _buildActionButton(
                icon: Icons.logout,
                label: 'Logout',
                onTap: () async {
                  await _apiService.logout();
                  // Navigate to login screen
                },
              ),
              const SizedBox(width: 10),
              _buildActionButton(
                icon: Icons.vpn_key,
                label: 'Update Token',
                onTap: () {},
              ),
              const SizedBox(width: 10),
              _buildActionButton(
                icon: Icons.download,
                label: 'Downloads',
                onTap: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, color: Colors.white),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: const BorderSide(color: Colors.blue, width: 1),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  Widget _buildStats(Me me) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              title:
                  '${_formatSize(me.currentUploadSize)} / ${_formatSize(me.allowedUploadSize)}',
              subtitle: 'Allowed Upload Size',
              progress:
                  me.currentUploadSize /
                  (me.allowedUploadSize > 0 ? me.allowedUploadSize : 1),
              color: Colors.blue,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: _buildStatCard(
              title: '${me.currentTranscode} / ${me.allowedTranscode}',
              subtitle: 'Allowed Transcodes',
              progress:
                  me.currentTranscode /
                  (me.allowedTranscode > 0 ? me.allowedTranscode : 1),
              color: Colors.green,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: _buildStatCard(
              title: '${me.currentUploadNumber} / ${me.allowedUploadNumber}',
              subtitle: 'Allowed Uploads',
              progress:
                  me.currentUploadNumber /
                  (me.allowedUploadNumber > 0 ? me.allowedUploadNumber : 1),
              color: Colors.purple,
            ),
          ),
        ],
      ),
    );
  }

  String _formatSize(int sizeInBytes) {
    const int KB = 1024;
    const int MB = KB * 1024;
    const int GB = MB * 1024;

    if (sizeInBytes >= GB) {
      return '${(sizeInBytes / GB).toStringAsFixed(2)} GB';
    } else if (sizeInBytes >= MB) {
      return '${(sizeInBytes / MB).toStringAsFixed(2)} MB';
    } else if (sizeInBytes >= KB) {
      return '${(sizeInBytes / KB).toStringAsFixed(2)} KB';
    } else {
      return '$sizeInBytes B';
    }
  }

  Widget _buildStatCard({
    required String title,
    required String subtitle,
    required double progress,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF171717),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          Text(subtitle, style: TextStyle(color: Colors.grey[400])),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[800],
              color: color,
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            color: Colors.blue,
            margin: const EdgeInsets.only(right: 10),
          ),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadRequests(Me me) {
    if (me.requests.isEmpty) {
      return _buildEmptyState('No download requests');
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      itemCount: me.requests.length,
      itemBuilder: (context, index) {
        final request = me.requests[index];
        return _buildRequestCard(request);
      },
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: const Color(0xFF171717),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade800),
      ),
      child: Column(
        children: [
          Icon(Icons.inbox_outlined, size: 50, color: Colors.grey.shade600),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(color: Colors.grey.shade400, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRequestCard(MeRequest request) {
    Color statusColor;
    IconData statusIcon;

    switch (request.status.toLowerCase()) {
      case 'completed':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'failed':
        statusColor = Colors.red;
        statusIcon = Icons.error;
        break;
      case 'processing':
        statusColor = Colors.amber;
        statusIcon = Icons.hourglass_top;
        break;
      default:
        statusColor = Colors.blue;
        statusIcon = Icons.sync;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 80,
                height: 120,
                child: CookieImage(
                  imageUrl: request.render.poster,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (context, error, stackTrace) => Container(
                        color: Colors.grey.shade800,
                        child: const Icon(Icons.image, color: Colors.grey),
                      ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          request.mediaName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: statusColor, width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(statusIcon, color: statusColor, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              request.status,
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildInfoChip(
                    Icons.category,
                    "Type: ${request.mediaType.toUpperCase()}",
                  ),
                  const SizedBox(height: 4),
                  _buildInfoChip(
                    Icons.sd_storage,
                    "Max Size: ${_formatSize(request.maxSize)}",
                  ),
                  const SizedBox(height: 4),
                  _buildInfoChip(
                    Icons.schedule,
                    "Created: ${_formatTimestamp(request.created)}",
                  ),
                  const SizedBox(height: 8),
                  if (request.torrentName.isNotEmpty) ...[
                    Text(
                      "Selected torrent: ${request.torrentName}",
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 12),
                  // Bouton de suppression
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton.filled(
                      onPressed: () => _deleteRequest(request),
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.white,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.red.withOpacity(0.7),
                        minimumSize: const Size(40, 40),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      tooltip: 'Supprimer cette demande',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey.shade400, size: 16),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _formatTimestamp(String timestamp) {
    try {
      if (timestamp.contains('-')) {
        final date = DateTime.parse(timestamp);
        return '${date.day}/${date.month}/${date.year}';
      } else {
        final date = DateTime.fromMillisecondsSinceEpoch(
          int.tryParse(timestamp) ?? 0,
        );
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return timestamp;
    }
  }

  Widget _buildShares(Me me) {
    if (me.shares.isEmpty) {
      return _buildEmptyState('No active shares');
    }

    // Calculer le nombre total de pages
    final totalPages = (me.shares.length / _sharesPerPage).ceil();

    // Vérifier que la page actuelle est valide
    if (_currentSharesPage >= totalPages) {
      _currentSharesPage = totalPages - 1;
    }

    // Calculer les indices de début et de fin pour la page actuelle
    final startIndex = _currentSharesPage * _sharesPerPage;
    final endIndex =
        (startIndex + _sharesPerPage < me.shares.length)
            ? startIndex + _sharesPerPage
            : me.shares.length;

    // Obtenir les shares à afficher pour cette page
    final currentPageShares = me.shares.sublist(startIndex, endIndex);

    return Column(
      children: [
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          itemCount: currentPageShares.length,
          itemBuilder: (context, index) {
            final share = currentPageShares[index];
            return _buildShareCard(share);
          },
        ),

        // Contrôles de pagination
        if (totalPages > 1) _buildPaginationControls(totalPages),
      ],
    );
  }

  Widget _buildPaginationControls(int totalPages) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Bouton précédent
          IconButton(
            onPressed:
                _currentSharesPage > 0
                    ? () => setState(() => _currentSharesPage--)
                    : null,
            icon: const Icon(Icons.arrow_back_ios),
            color: _currentSharesPage > 0 ? Colors.blue : Colors.grey,
            tooltip: 'Page précédente',
          ),

          // Indicateur de page actuelle
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.blue.shade700),
            ),
            child: Text(
              'Page ${_currentSharesPage + 1}/$totalPages',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Bouton suivant
          IconButton(
            onPressed:
                _currentSharesPage < totalPages - 1
                    ? () => setState(() => _currentSharesPage++)
                    : null,
            icon: const Icon(Icons.arrow_forward_ios),
            color:
                _currentSharesPage < totalPages - 1 ? Colors.blue : Colors.grey,
            tooltip: 'Page suivante',
          ),
        ],
      ),
    );
  }

  Widget _buildShareCard(MeShare share) {
    final daysLeft = share.expire.difference(DateTime.now()).inDays;
    final isExpiringSoon = daysLeft <= 3;
    final isExpired = DateTime.now().isAfter(share.expire);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color:
                  isExpired
                      ? Colors.red.shade900
                      : isExpiringSoon
                      ? Colors.amber.shade900
                      : Colors.blue.shade900,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isExpired ? Icons.error_outline : Icons.access_time,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isExpired
                        ? 'Expired on ${_formatDate(share.expire)}'
                        : 'Expires ${daysLeft <= 0 ? 'today' : 'in $daysLeft days'} (${_formatDate(share.expire)})',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.content_copy, color: Colors.white),
                  onPressed: () {
                    // Copy share link
                  },
                  tooltip: 'Copy share link',
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade800,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getFileTypeIcon(share.file.filename),
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        share.file.filename,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'File Size: ${_formatSize(share.file.size)}',
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                // Download file
                                // launchUrl(share)
                                // api service.downloadFile(share.file.id);

                                launchUrl(
                                  Uri.parse(
                                    this._apiService.getShareUrl(share.id),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.download, size: 16),
                              label: const Text('Download'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.blue,
                                side: const BorderSide(color: Colors.blue),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 0,
                                ),
                                minimumSize: const Size(0, 30),
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Bouton de suppression
                          IconButton.filled(
                            onPressed: () => _deleteShare(share),
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.white,
                            ),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.red.withOpacity(0.7),
                              minimumSize: const Size(40, 40),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            tooltip: 'Supprimer ce partage',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  IconData _getFileTypeIcon(String filename) {
    final extension = filename.split('.').last.toLowerCase();

    switch (extension) {
      case 'mp4':
      case 'mkv':
      case 'avi':
      case 'mov':
        return Icons.movie;
      case 'mp3':
      case 'wav':
      case 'flac':
        return Icons.music_note;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Icons.image;
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      case 'zip':
      case 'rar':
      case '7z':
        return Icons.archive;
      default:
        return Icons.insert_drive_file;
    }
  }

  Widget _buildTorrents(Me me) {
    if (me.torrents.isEmpty) {
      return _buildEmptyState('No torrents');
    }

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.7,
        crossAxisSpacing: 15,
        mainAxisSpacing: 15,
      ),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      itemCount: me.torrents.length,
      itemBuilder: (context, index) {
        final torrent = me.torrents[index];
        return _buildTorrentCard(torrent);
      },
    );
  }

  Widget _buildTorrentCard(TorrentItem torrent) {
    String imageUrl = torrent.skinny.backdrop;
    if (imageUrl.isEmpty) {
      imageUrl = torrent.skinny.poster;
    }

    return GestureDetector(
      onTap: () => _showTorrentDetails(torrent),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Hero(
              tag: 'torrent-${torrent.id}',
              child: CookieImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                errorBuilder:
                    (context, error, stackTrace) => Container(
                      color: Colors.grey[900],
                      child: const Icon(Icons.broken_image, color: Colors.grey),
                    ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.3),
                    Colors.black.withOpacity(0.8),
                  ],
                  stops: const [0.4, 0.7, 1.0],
                ),
              ),
            ),
            if (torrent.paused)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  color: Colors.red.withOpacity(0.7),
                  child: const Text(
                    'EN PAUSE',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            Positioned(
              top: 16,
              right: 16,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      shape: BoxShape.circle,
                    ),
                    child: CircularProgressIndicator(
                      value: torrent.progress,
                      backgroundColor: Colors.grey.withOpacity(0.3),
                      color: _getProgressColor(torrent.progress),
                      strokeWidth: 5,
                    ),
                  ),
                  Text(
                    '${(torrent.progress * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 16,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blueGrey.shade700),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.sd_storage, color: Colors.white, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      _formatSize(torrent.size),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      torrent.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _showTorrentDetails(torrent),
                            icon: const Icon(Icons.info_outline, size: 16),
                            label: const Text('Détails'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: Colors.black.withOpacity(0.5),
                              side: const BorderSide(color: Colors.white70),
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(0, 30),
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                        ),
                      ],
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

  Color _getProgressColor(double progress) {
    if (progress < 0.3) return Colors.red;
    if (progress < 0.7) return Colors.amber;
    return Colors.green;
  }

  void _showTorrentDetails(TorrentItem torrent) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Color(0xFF171717),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: DefaultTabController(
                length: 2,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      alignment: Alignment.center,
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[400],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                      child: Text(
                        torrent.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    TabBar(
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: Colors.blue,
                      tabs: const [
                        Tab(icon: Icon(Icons.info_outline), text: "Aperçu"),
                        Tab(icon: Icon(Icons.folder_open), text: "Fichiers"),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          _buildTorrentOverviewTab(torrent, scrollController),
                          _buildTorrentFilesTab(torrent, scrollController),
                        ],
                      ),
                    ),
                    _buildActionBar(torrent),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTorrentOverviewTab(
    TorrentItem torrent,
    ScrollController scrollController,
  ) {
    String imageUrl = torrent.skinny.backdrop;
    if (imageUrl.isEmpty) {
      imageUrl = torrent.skinny.poster;
    }

    return SingleChildScrollView(
      controller: scrollController,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CookieImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                errorBuilder:
                    (context, error, stackTrace) => Container(
                      color: Colors.grey[900],
                      child: const Icon(
                        Icons.broken_image,
                        color: Colors.grey,
                        size: 50,
                      ),
                    ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          _buildInfoRow(
            "État",
            torrent.paused ? "En pause" : "En téléchargement",
          ),
          _buildInfoRow("Taille totale", _formatSize(torrent.size)),
          _buildInfoRow("Téléchargé", _formatSize(torrent.totalDownloaded)),
          _buildInfoRow("Partagé", _formatSize(torrent.totalUploaded)),
          _buildInfoRow(
            "Ratio de partage",
            torrent.totalDownloaded > 0
                ? (torrent.totalUploaded / torrent.totalDownloaded)
                    .toStringAsFixed(2)
                : "0",
          ),
          const SizedBox(height: 10),
          const Text(
            "Progression",
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: LinearProgressIndicator(
              value: torrent.progress,
              backgroundColor: Colors.grey[800],
              color: Colors.green,
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "${(torrent.progress * 100).toStringAsFixed(1)}%",
            style: TextStyle(color: Colors.grey[400]),
          ),
          if (torrent.skinny.description.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Text(
              "Description",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              torrent.skinny.description,
              style: TextStyle(color: Colors.grey[400]),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            "$label: ",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(value, style: TextStyle(color: Colors.grey[400])),
        ],
      ),
    );
  }

  Widget _buildTorrentFilesTab(
    TorrentItem torrent,
    ScrollController scrollController,
  ) {
    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: torrent.files.length,
      itemBuilder: (context, index) {
        final file = torrent.files[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          color: const Color(0xFF2A2A2A),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: file.progress,
                    backgroundColor: Colors.grey[800],
                    color: Colors.green,
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "${(file.progress * 100).toStringAsFixed(1)}%",
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionBar(TorrentItem torrent) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      child: Column(
        children: [
          Row(
            children: [
              _buildActionButton(
                icon: Icons.file_download,
                label: "Télécharger .torrent",
                onTap: () {
                  // Download .torrent file
                },
              ),
              const SizedBox(width: 10),
              _buildActionButton(
                icon: Icons.archive,
                label: "Télécharger .zip",
                onTap: () {
                  // Download zip of files
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildActionButton(
                icon: torrent.paused ? Icons.play_arrow : Icons.pause,
                label: torrent.paused ? "Reprendre" : "Mettre en pause",
                onTap: () {
                  // Pause/Resume torrent
                  _pauseResumeTorrent(torrent);
                },
              ),
              const SizedBox(width: 10),
              _buildActionButton(
                icon: Icons.delete,
                label: "Supprimer",
                onTap: () {
                  // Delete torrent with confirmation
                  _deleteTorrent(torrent);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
