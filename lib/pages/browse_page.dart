import 'package:flutter/material.dart';
import 'package:fluttergoster/main.dart';
import 'package:fluttergoster/models/data_models.dart';
import 'package:fluttergoster/services/api_service.dart';
import 'package:fluttergoster/widgets/cookie_image.dart';
import 'package:fluttergoster/widgets/goster_top_bar.dart';
import 'package:fluttergoster/widgets/media_card.dart';

class BrowsePage extends StatefulWidget {
  final String mediaType; // "movie" or "tv"

  const BrowsePage({
    Key? key, 
    required this.mediaType, 
  }) : super(key: key);

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
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 &&
        !_isLoading && _displayedItems.length < _allItems.length) {
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
      final newEndIndex = (_displayedItems.length + _batchSize).clamp(0, _allItems.length);
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
    // Calculate responsive grid layout
    final screenWidth = MediaQuery.of(context).size.width;
    final double desiredItemWidth = 100;
    int crossAxisCount = (screenWidth / desiredItemWidth).floor();
    crossAxisCount = crossAxisCount.clamp(3, 8);
    final itemWidth = (screenWidth - 32 - (16 * (crossAxisCount - 1))) / crossAxisCount;

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
        child: _isInitialLoad
            ? const Center(child: CircularProgressIndicator())
            : _allItems.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.search_off, size: 50, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(
                          'Aucun contenu trouvé',
                          style: TextStyle(color: Colors.grey[400], fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: _loadAllItems,
                          child: const Text('Réessayer'),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      childAspectRatio: 2/3,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: _displayedItems.length + 
                              (_displayedItems.length < _allItems.length ? 1 : 0),
                    itemBuilder: (context, index) {
                      // Display loading indicator at the end
                      if (index >= _displayedItems.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                      
                      // Display media card
                      final item = _displayedItems[index];
                      return MediaCard(
                        media: item,
                        displayMode: MediaCardDisplayMode.poster,
                      );
                    },
                  ),
      ),
    );
  }
}
