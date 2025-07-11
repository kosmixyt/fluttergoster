import 'package:flutter/material.dart';
import 'package:fluttergoster/models/data_models.dart';
import 'package:fluttergoster/services/api_service.dart';
import 'package:fluttergoster/widgets/goster_top_bar.dart';
import 'package:fluttergoster/widgets/cookie_image.dart';
import 'package:fluttergoster/utils/responsive_utils.dart';
import 'package:fluttergoster/main.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';

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
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 1200;
        final isTablet =
            constraints.maxWidth > 800 && constraints.maxWidth <= 1200;

        if (isDesktop) {
          return _buildDesktopLayout(me);
        } else if (isTablet) {
          return _buildTabletLayout(me);
        } else {
          return _buildMobileLayout(me);
        }
      },
    );
  }

  Widget _buildDesktopLayout(Me me) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Header
            _buildHeader(me),
            const SizedBox(height: 30),

            // Stats
            _buildStats(me),
            const SizedBox(height: 40),

            // Torrents section (full width)
            _buildSectionTitle('Torrents'),
            const SizedBox(height: 16),
            _buildTorrents(me),
            const SizedBox(height: 40),

            // Two-column layout for desktop
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left column
                Expanded(
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('Download Requests'),
                      const SizedBox(height: 16),
                      _buildDownloadRequests(me),
                    ],
                  ),
                ),
                const SizedBox(width: 40),

                // Right column
                Expanded(
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (me.shares.isNotEmpty) ...[
                        _buildSectionTitle('My Shares'),
                        const SizedBox(height: 16),
                        _buildShares(me),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabletLayout(Me me) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(me),
            const SizedBox(height: 24),
            _buildStats(me),
            const SizedBox(height: 32),

            // Torrents first (full width)
            _buildSectionTitle('Torrents'),
            const SizedBox(height: 16),
            _buildTorrents(me),
            const SizedBox(height: 32),

            _buildSectionTitle('Download Requests'),
            const SizedBox(height: 16),
            _buildDownloadRequests(me),
            const SizedBox(height: 32),

            if (me.shares.isNotEmpty) ...[
              _buildSectionTitle('My Shares'),
              const SizedBox(height: 16),
              _buildShares(me),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMobileLayout(Me me) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(me),
          const SizedBox(height: 20),
          _buildStats(me),
          const SizedBox(height: 30),
          _buildSectionTitle('Torrents'),
          _buildTorrents(me),
          const SizedBox(height: 30),
          _buildSectionTitle('Download Requests'),
          _buildDownloadRequests(me),
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
      padding: EdgeInsets.all(ResponsiveUtils.isDesktop(context) ? 32 : 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryDark.withOpacity(0.8),
            AppTheme.primary.withOpacity(0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Avatar et nom d'utilisateur
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: ResponsiveUtils.isDesktop(context) ? 80 : 60,
                height: ResponsiveUtils.isDesktop(context) ? 80 : 60,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    me.username.isNotEmpty ? me.username[0].toUpperCase() : "?",
                    style: TextStyle(
                      color: AppTheme.primary,
                      fontSize: ResponsiveUtils.isDesktop(context) ? 36 : 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SizedBox(width: ResponsiveUtils.isDesktop(context) ? 20 : 15),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome, ${me.username}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: ResponsiveUtils.getFontSize(
                          context,
                          desktop: 32,
                          tablet: 28,
                          mobile: 24,
                        ),
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Member since Unknow',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: ResponsiveUtils.getFontSize(
                          context,
                          desktop: 16,
                          tablet: 14,
                          mobile: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveUtils.isDesktop(context) ? 30 : 20),

          // Boutons d'action avec design amélioré
          LayoutBuilder(
            builder: (context, constraints) {
              if (ResponsiveUtils.isDesktop(context)) {
                // Layout desktop: 4 boutons sur une ligne
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildActionButton(
                      icon: Icons.shield,
                      label: 'Admin Panel',
                      onTap: () {},
                      gradient: const LinearGradient(
                        colors: [Colors.purple, Colors.deepPurple],
                      ),
                    ),
                    const SizedBox(width: 15),
                    _buildActionButton(
                      icon: Icons.vpn_key,
                      label: 'Update Token',
                      onTap: () {},
                      gradient: const LinearGradient(
                        colors: [Colors.blue, Colors.indigo],
                      ),
                    ),
                    const SizedBox(width: 15),
                    _buildActionButton(
                      icon: Icons.download,
                      label: 'Downloads',
                      onTap: () {},
                      gradient: const LinearGradient(
                        colors: [Colors.green, Colors.teal],
                      ),
                    ),
                    const SizedBox(width: 15),
                    _buildActionButton(
                      icon: Icons.logout,
                      label: 'Logout',
                      onTap: () async {
                        await _apiService.logout();
                      },
                      gradient: const LinearGradient(
                        colors: [Colors.orange, Colors.deepOrange],
                      ),
                    ),
                  ],
                );
              } else if (ResponsiveUtils.isTablet(context)) {
                // Layout tablette: 2 lignes de 2 boutons
                return Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildActionButton(
                          icon: Icons.shield,
                          label: 'Admin Panel',
                          onTap: () {},
                          gradient: const LinearGradient(
                            colors: [Colors.purple, Colors.deepPurple],
                          ),
                        ),
                        const SizedBox(width: 15),
                        _buildActionButton(
                          icon: Icons.vpn_key,
                          label: 'Update Token',
                          onTap: () {},
                          gradient: const LinearGradient(
                            colors: [Colors.blue, Colors.indigo],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildActionButton(
                          icon: Icons.download,
                          label: 'Downloads',
                          onTap: () {},
                          gradient: const LinearGradient(
                            colors: [Colors.green, Colors.teal],
                          ),
                        ),
                        const SizedBox(width: 15),
                        _buildActionButton(
                          icon: Icons.logout,
                          label: 'Logout',
                          onTap: () async {
                            await _apiService.logout();
                          },
                          gradient: const LinearGradient(
                            colors: [Colors.orange, Colors.deepOrange],
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              } else {
                // Mobile: Grille compacte 2x2
                return Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _buildActionButton(
                      icon: Icons.shield,
                      label: 'Admin',
                      onTap: () {},
                      compact: true,
                      gradient: const LinearGradient(
                        colors: [Colors.purple, Colors.deepPurple],
                      ),
                    ),
                    _buildActionButton(
                      icon: Icons.vpn_key,
                      label: 'Token',
                      onTap: () {},
                      compact: true,
                      gradient: const LinearGradient(
                        colors: [Colors.blue, Colors.indigo],
                      ),
                    ),
                    _buildActionButton(
                      icon: Icons.download,
                      label: 'Downloads',
                      onTap: () {},
                      compact: true,
                      gradient: const LinearGradient(
                        colors: [Colors.green, Colors.teal],
                      ),
                    ),
                    _buildActionButton(
                      icon: Icons.logout,
                      label: 'Logout',
                      onTap: () async {
                        await _apiService.logout();
                      },
                      compact: true,
                      gradient: const LinearGradient(
                        colors: [Colors.orange, Colors.deepOrange],
                      ),
                    ),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isDesktop = false,
    bool compact = false,
    LinearGradient? gradient,
  }) {
    final buttonPadding =
        compact
            ? const EdgeInsets.symmetric(horizontal: 12, vertical: 8)
            : isDesktop
            ? const EdgeInsets.symmetric(horizontal: 24, vertical: 14)
            : const EdgeInsets.symmetric(horizontal: 16, vertical: 10);
    final iconSize =
        compact
            ? 18.0
            : isDesktop
            ? 24.0
            : 20.0;
    final fontSize =
        compact
            ? 12.0
            : isDesktop
            ? 16.0
            : 14.0;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient:
            gradient ??
            LinearGradient(colors: [AppTheme.primary, AppTheme.primaryDark]),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          splashColor: Colors.white.withOpacity(0.1),
          highlightColor: Colors.white.withOpacity(0.05),
          child: Padding(
            padding: buttonPadding,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.white, size: iconSize),
                SizedBox(width: compact ? 6 : 10),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: fontSize,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStats(Me me) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 1200;

        // Ajuster le padding et l'espacement selon la taille d'écran
        final horizontalPadding = isDesktop ? 0.0 : 20.0;
        final cardSpacing = isDesktop ? 24.0 : 15.0;

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
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
                  isDesktop: isDesktop,
                ),
              ),
              SizedBox(width: cardSpacing),
              Expanded(
                child: _buildStatCard(
                  title: '${me.currentTranscode} / ${me.allowedTranscode}',
                  subtitle: 'Allowed Transcodes',
                  progress:
                      me.currentTranscode /
                      (me.allowedTranscode > 0 ? me.allowedTranscode : 1),
                  color: Colors.green,
                  isDesktop: isDesktop,
                ),
              ),
              SizedBox(width: cardSpacing),
              Expanded(
                child: _buildStatCard(
                  title:
                      '${me.currentUploadNumber} / ${me.allowedUploadNumber}',
                  subtitle: 'Allowed Uploads',
                  progress:
                      me.currentUploadNumber /
                      (me.allowedUploadNumber > 0 ? me.allowedUploadNumber : 1),
                  color: Colors.purple,
                  isDesktop: isDesktop,
                ),
              ),
            ],
          ),
        );
      },
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
    bool isDesktop = false,
  }) {
    final cardPadding = isDesktop ? 20.0 : 15.0;
    final titleFontSize = isDesktop ? 20.0 : 18.0;
    final subtitleFontSize = isDesktop ? 14.0 : 13.0;
    final progressHeight = isDesktop ? 10.0 : 8.0;

    return Container(
      padding: EdgeInsets.all(cardPadding),
      decoration: BoxDecoration(
        color: const Color(0xFF171717),
        borderRadius: BorderRadius.circular(10),
        boxShadow:
            isDesktop
                ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
                : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.white,
              fontSize: titleFontSize,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: subtitleFontSize,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[800],
              color: color,
              minHeight: progressHeight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 800;
        final horizontalPadding = isDesktop ? 0.0 : 20.0;
        final titleFontSize = isDesktop ? 22.0 : 18.0;
        final barHeight = isDesktop ? 24.0 : 20.0;
        final barWidth = isDesktop ? 5.0 : 4.0;

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Row(
            children: [
              Container(
                width: barWidth,
                height: barHeight,
                color: Colors.blue,
                margin: EdgeInsets.only(right: isDesktop ? 15 : 10),
              ),
              Text(
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: titleFontSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDownloadRequests(Me me) {
    if (me.requests.isEmpty) {
      return _buildEmptyState('No download requests');
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 800;
        final horizontalPadding = isDesktop ? 0.0 : 20.0;

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: 10,
          ),
          itemCount: me.requests.length,
          itemBuilder: (context, index) {
            final request = me.requests[index];
            return _buildRequestCard(request, isDesktop: isDesktop);
          },
        );
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

  Widget _buildRequestCard(MeRequest request, {bool isDesktop = false}) {
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

    final cardPadding = isDesktop ? 16.0 : 12.0;
    final posterWidth = isDesktop ? 100.0 : 80.0;
    final posterHeight = isDesktop ? 150.0 : 120.0;
    final titleFontSize = isDesktop ? 18.0 : 16.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: isDesktop ? 4 : 2,
      child: Padding(
        padding: EdgeInsets.all(cardPadding),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: posterWidth,
                height: posterHeight,
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
            SizedBox(width: isDesktop ? 20 : 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          request.mediaName,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: titleFontSize,
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
                  SizedBox(height: isDesktop ? 12 : 8),

                  // Affichage en colonnes sur desktop
                  if (isDesktop) ...[
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              _buildInfoChip(
                                Icons.category,
                                "Type: ${request.mediaType.toUpperCase()}",
                              ),
                              const SizedBox(height: 6),
                              _buildInfoChip(
                                Icons.sd_storage,
                                "Max Size: ${_formatSize(request.maxSize)}",
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            children: [
                              _buildInfoChip(
                                Icons.schedule,
                                "Created: ${_formatTimestamp(request.created)}",
                              ),
                              if (request.torrentName.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                _buildInfoChip(
                                  Icons.download,
                                  "Torrent: ${request.torrentName}",
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    // Affichage en liste sur mobile
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
                    if (request.torrentName.isNotEmpty) ...[
                      const SizedBox(height: 8),
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
                  ],

                  SizedBox(height: isDesktop ? 16 : 12),
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 800;
        final horizontalPadding = isDesktop ? 0.0 : 20.0;

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
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: 10,
              ),
              itemCount: currentPageShares.length,
              itemBuilder: (context, index) {
                final share = currentPageShares[index];
                return _buildShareCard(share, isDesktop: isDesktop);
              },
            ),

            // Contrôles de pagination
            if (totalPages > 1) _buildPaginationControls(totalPages),
          ],
        );
      },
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

  Widget _buildShareCard(MeShare share, {bool isDesktop = false}) {
    final daysLeft = share.expire.difference(DateTime.now()).inDays;
    final isExpiringSoon = daysLeft <= 3;
    final isExpired = DateTime.now().isAfter(share.expire);

    final cardPadding = isDesktop ? 16.0 : 12.0;
    final iconSize = isDesktop ? 60.0 : 50.0;
    final titleFontSize = isDesktop ? 17.0 : 15.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: isDesktop ? 4 : 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(cardPadding),
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
                  size: isDesktop ? 24 : 20,
                ),
                SizedBox(width: isDesktop ? 12 : 8),
                Expanded(
                  child: Text(
                    isExpired
                        ? 'Expired on ${_formatDate(share.expire)}'
                        : 'Expires ${daysLeft <= 0 ? 'today' : 'in $daysLeft days'} (${_formatDate(share.expire)})',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isDesktop ? 16 : 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.content_copy,
                    color: Colors.white,
                    size: isDesktop ? 24 : 20,
                  ),
                  onPressed: () {
                    // Copy share link
                  },
                  tooltip: 'Copy share link',
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(cardPadding),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: iconSize,
                  height: iconSize,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade800,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getFileTypeIcon(share.file.filename),
                    color: Colors.white,
                    size: isDesktop ? 35 : 30,
                  ),
                ),
                SizedBox(width: isDesktop ? 16 : 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        share.file.filename,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: titleFontSize,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: isDesktop ? 8 : 4),
                      Text(
                        'File Size: ${_formatSize(share.file.size)}',
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: isDesktop ? 14 : 13,
                        ),
                      ),
                      SizedBox(height: isDesktop ? 12 : 8),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                launchUrl(
                                  Uri.parse(
                                    this._apiService.getShareUrl(share.id),
                                  ),
                                );
                              },
                              icon: Icon(
                                Icons.download,
                                size: isDesktop ? 18 : 16,
                              ),
                              label: const Text('Download'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.blue,
                                side: const BorderSide(color: Colors.blue),
                                padding: EdgeInsets.symmetric(
                                  horizontal: isDesktop ? 16 : 12,
                                  vertical: isDesktop ? 8 : 0,
                                ),
                                minimumSize: Size(0, isDesktop ? 40 : 30),
                                visualDensity:
                                    isDesktop
                                        ? VisualDensity.comfortable
                                        : VisualDensity.compact,
                              ),
                            ),
                          ),
                          SizedBox(width: isDesktop ? 12 : 8),
                          // Bouton de suppression
                          IconButton.filled(
                            onPressed: () => _deleteShare(share),
                            icon: Icon(
                              Icons.delete_outline,
                              color: Colors.white,
                              size: isDesktop ? 22 : 18,
                            ),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.red.withOpacity(0.7),
                              minimumSize: Size(
                                isDesktop ? 45 : 40,
                                isDesktop ? 45 : 40,
                              ),
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

    return LayoutBuilder(
      builder: (context, constraints) {
        // Déterminer le nombre de colonnes selon la largeur
        int crossAxisCount;
        double childAspectRatio;
        double spacing;
        double horizontalPadding;

        if (constraints.maxWidth > 1400) {
          // Très large écran (desktop)
          crossAxisCount = 5;
          childAspectRatio = 0.65;
          spacing = 20;
          horizontalPadding = 0;
        } else if (constraints.maxWidth > 1200) {
          // Large écran (desktop)
          crossAxisCount = 4;
          childAspectRatio = 0.7;
          spacing = 18;
          horizontalPadding = 0;
        } else if (constraints.maxWidth > 800) {
          // Tablette
          crossAxisCount = 3;
          childAspectRatio = 0.75;
          spacing = 16;
          horizontalPadding = 10;
        } else if (constraints.maxWidth > 600) {
          // Petite tablette
          crossAxisCount = 2;
          childAspectRatio = 0.8;
          spacing = 15;
          horizontalPadding = 15;
        } else {
          // Mobile
          crossAxisCount = 1;
          childAspectRatio = 1.2;
          spacing = 15;
          horizontalPadding = 20;
        }

        return GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: childAspectRatio,
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
          ),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: 10,
          ),
          itemCount: me.torrents.length,
          itemBuilder: (context, index) {
            final torrent = me.torrents[index];
            return _buildTorrentCard(torrent);
          },
        );
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
                    Colors.black.withOpacity(0.4),
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withOpacity(0.9),
                  ],
                  stops: const [0.0, 0.3, 0.7, 1.0],
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
                  color: Colors.red.withOpacity(0.9),
                  child: const Text(
                    'PAUSED',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            // Taille du fichier en haut à gauche
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _formatSize(torrent.size),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            // Pourcentage en haut à droite
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getProgressColor(torrent.progress).withOpacity(0.9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${(torrent.progress * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            // Titre en bas
            Positioned(
              bottom: 12,
              left: 12,
              right: 12,
              child: Text(
                torrent.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      offset: Offset(0, 1),
                      blurRadius: 3,
                      color: Colors.black,
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
