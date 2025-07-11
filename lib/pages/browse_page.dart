import 'package:flutter/material.dart';
import 'package:fluttergoster/main.dart';
import 'package:fluttergoster/models/data_models.dart';
import 'package:fluttergoster/widgets/goster_top_bar.dart';
import 'package:fluttergoster/widgets/media_card.dart';

class BrowsePage extends StatefulWidget {
  final String mediaType; // "movie" or "tv"

  const BrowsePage({super.key, required this.mediaType});

  @override
  State<BrowsePage> createState() => _BrowsePageState();
}

class _BrowsePageState extends State<BrowsePage> {
  List<SkinnyRender> _allItems = []; // All items fetched from API
  List<SkinnyRender> _displayedItems = []; // Items currently displayed
  bool _isLoading = false;
  bool _isInitialLoad = true;
  final int _batchSize = 30; // Number of items to add each time
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_allItems.isEmpty) {
      _loadAllItems();
    }
  }

  void _onScroll() {
    // If we're near the bottom and not currently loading more items
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoading &&
        _displayedItems.length < _allItems.length) {
      _addMoreItemsToDisplay();
    }
  }

  // Fetch all items at once
  Future<void> _loadAllItems() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _isInitialLoad = true;
    });

    try {
      final apiService = ApiServiceProvider.of(context);

      // Using a large limit to get all items at once
      // In a real-world scenario, you might want to cap this or implement pagination
      // if the number of items could be extremely large
      final allItems = await apiService.getBrowseItems(
        widget.mediaType,
        offset: 0,
        limit: 1000, // Using a large number to get all items
      );

      setState(() {
        _allItems = allItems;

        // Initially display only the first batch
        _displayedItems = allItems.take(_batchSize).toList();
        _isLoading = false;
        _isInitialLoad = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isInitialLoad = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur de chargement: ${e.toString()}')),
        );
      }
    }
  }

  // Add more items to the display list
  Future<void> _addMoreItemsToDisplay() async {
    setState(() {
      _isLoading = true;
    });

    // Small artificial delay to make loading more smooth/visible
    await Future.delayed(const Duration(milliseconds: 300));

    setState(() {
      final newEndIndex = (_displayedItems.length + _batchSize).clamp(
        0,
        _allItems.length,
      );
      _displayedItems = _allItems.sublist(0, newEndIndex);
      _isLoading = false;
    });
  }

  // Pull-to-refresh handler
  Future<void> _refreshItems() async {
    _allItems = [];
    _displayedItems = [];
    await _loadAllItems();
  }

  @override
  Widget build(BuildContext context) {
    // Enhanced responsive grid layout
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 1200;
    final isTablet = screenWidth > 800 && screenWidth <= 1200;
    final isPhone = screenWidth <= 800;

    // Responsive item sizing
    final double desiredItemWidth = isDesktop ? 200 : (isTablet ? 180 : 160);
    final double horizontalPadding = isDesktop ? 48 : (isTablet ? 24 : 16);
    final double spacing = isDesktop ? 20 : 16;

    // Calculate optimal grid layout
    int crossAxisCount =
        ((screenWidth - (horizontalPadding * 2)) / (desiredItemWidth + spacing))
            .floor();
    crossAxisCount = crossAxisCount.clamp(isPhone ? 2 : 3, isDesktop ? 8 : 6);

    return Scaffold(
      appBar: GosterTopBar(
        showBackButton: true,
        title: widget.mediaType == "movie" ? "Films" : "Séries TV",
      ),
      backgroundColor: Colors.black,
      body: RefreshIndicator(
        onRefresh: _refreshItems,
        color: Colors.blue,
        backgroundColor: Colors.grey[900],
        child:
            _isInitialLoad
                ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(
                        'Chargement du contenu...',
                        style: TextStyle(color: Colors.grey[400], fontSize: 16),
                      ),
                    ],
                  ),
                )
                : _allItems.isEmpty
                ? Center(
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    margin: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.grey[900]?.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[700]!, width: 1),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          widget.mediaType == "movie"
                              ? Icons.movie_outlined
                              : Icons.tv_outlined,
                          size: 64,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Aucun contenu trouvé',
                          style: TextStyle(
                            color: Colors.grey[300],
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Aucun ${widget.mediaType == "movie" ? "film" : "série"} n\'est disponible pour le moment.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: _loadAllItems,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Réessayer'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[600],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                : CustomScrollView(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    // Header section with stats
                    SliverToBoxAdapter(
                      child: Container(
                        padding: EdgeInsets.all(horizontalPadding),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Découvrir',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: isDesktop ? 32 : 24,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        '${_allItems.length} ${widget.mediaType == "movie" ? "films" : "séries"} disponibles',
                                        style: TextStyle(
                                          color: Colors.grey[400],
                                          fontSize: isDesktop ? 16 : 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isDesktop)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.blue[600],
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          widget.mediaType == "movie"
                                              ? Icons.movie
                                              : Icons.tv,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          widget.mediaType == "movie"
                                              ? "Films"
                                              : "Séries",
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),

                    // Grid content
                    SliverPadding(
                      padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding,
                      ),
                      sliver: SliverGrid(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          childAspectRatio: 2 / 3,
                          crossAxisSpacing: spacing,
                          mainAxisSpacing: spacing,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            // Loading indicator at the end
                            if (index >= _displayedItems.length) {
                              return Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey[900]?.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      CircularProgressIndicator(strokeWidth: 2),
                                      SizedBox(height: 8),
                                      Text(
                                        'Chargement...',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }

                            // Media card with enhanced hover effects
                            final item = _displayedItems[index];
                            return MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                curve: Curves.easeInOut,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: MediaCard(
                                  media: item,
                                  displayMode: MediaCardDisplayMode.poster,
                                ),
                              ),
                            );
                          },
                          childCount:
                              _displayedItems.length +
                              (_displayedItems.length < _allItems.length
                                  ? 1
                                  : 0),
                        ),
                      ),
                    ),

                    // Bottom padding
                    const SliverToBoxAdapter(child: SizedBox(height: 40)),
                  ],
                ),
      ),
    );
  }
}
