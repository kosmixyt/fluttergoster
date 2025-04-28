import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttergoster/models/data_models.dart';
import 'package:fluttergoster/services/api_service.dart';
import 'package:fluttergoster/widgets/media_card.dart';
import 'package:fluttergoster/main.dart'; // For ApiServiceProvider
import 'dart:async';

class SearchModal extends StatefulWidget {
  const SearchModal({super.key});
  
  static Future<void> show(BuildContext context) async {
    await showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.85),
      builder: (context) => Dialog(
        insetPadding: EdgeInsets.zero,
        backgroundColor: Colors.transparent,
        child: const SearchModal(),
      ),
    );
  }

  @override
  _SearchModalState createState() => _SearchModalState();
}

class _SearchModalState extends State<SearchModal> {
  final TextEditingController _searchController = TextEditingController();
  List<SkinnyRender> _searchResults = [];
  bool _isLoading = false;
  Timer? _debounceTimer;
  late ApiService _apiService;
  
  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    // Give focus to the text field automatically
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus();
    });
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Access the ApiService through the provider
    _apiService = ApiServiceProvider.of(context);
  }
  
  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }
  
  void _onSearchChanged() {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (_searchController.text.isNotEmpty) {
        _performSearch(_searchController.text);
      } else {
        setState(() {
          _searchResults = [];
        });
      }
    });
  }
  
  Future<void> _performSearch(String query) async {
    if (query.isEmpty) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final results = await _apiService.searchMedia(query);
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        // Handle error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur de recherche: $e')),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    // Calculate screen dimensions
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Container(
      height: screenHeight,
      width: screenWidth,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.95),
      ),
      child: Column(
        children: [
          // Search bar area
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            child: Row(
              children: [
                // Close button
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 28),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                
                // Search field
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    autofocus: true,
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                    decoration: InputDecoration(
                      hintText: 'Rechercher des films, séries...',
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    onSubmitted: _performSearch,
                    cursorColor: Colors.blue,
                  ),
                ),
                
                // Clear button
                if (_searchController.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear, color: Colors.grey, size: 20),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _searchResults = [];
                      });
                    },
                  ),
              ],
            ),
          ),
          
          // Divider
          Divider(height: 1, color: Colors.grey.shade800),
          
          // Results area
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : _searchResults.isEmpty && _searchController.text.isNotEmpty
                ? Center(
                    child: Text(
                      'Aucun résultat trouvé',
                      style: TextStyle(color: Colors.grey.shade400, fontSize: 18),
                    ),
                  )
                : _searchController.text.isEmpty
                  ? Center(
                      child: Text(
                        'Tapez quelque chose pour commencer la recherche',
                        style: TextStyle(color: Colors.grey.shade400, fontSize: 18),
                      ),
                    )
                  : _buildResponsiveGrid(screenWidth),
          ),
        ],
      ),
    );
  }
  
  Widget _buildResponsiveGrid(double screenWidth) {
    // Calculate grid parameters based on screen width
    final crossAxisCount = _calculateCrossAxisCount(screenWidth);
    final posterWidth = _calculatePosterWidth(screenWidth, crossAxisCount);
    final aspectRatio = 2/3; // Standard poster aspect ratio
    
    // Calculate extra padding to keep everything centered
    final totalPosterWidth = posterWidth * crossAxisCount;
    final horizontalSpacing = (screenWidth - totalPosterWidth) / (crossAxisCount + 1);
    
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: max(8.0, horizontalSpacing / 2), 
        vertical: 16.0
      ),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          childAspectRatio: aspectRatio,
          crossAxisSpacing: 8,
          mainAxisSpacing: 16,
        ),
        itemCount: _searchResults.length,
        itemBuilder: (context, index) {
          return SizedBox(
            width: posterWidth,
            child: MediaCard(
              media: _searchResults[index],
              displayMode: MediaCardDisplayMode.poster,
            ),
          );
        },
      ),
    );
  }
  
  // Calculate how many posters per row based on screen width
  int _calculateCrossAxisCount(double width) {
    if (width > 1400) return 8;     // Very large screens
    if (width > 1200) return 7;     // Large screens
    if (width > 900) return 6;      // Medium-large screens
    if (width > 700) return 5;      // Medium screens
    if (width > 500) return 4;      // Small-medium screens
    if (width > 350) return 3;      // Small screens
    return 2;                       // Very small screens
  }
  
  // Calculate poster width based on screen width and number of items per row
  double _calculatePosterWidth(double screenWidth, int crossAxisCount) {
    // Base width calculations
    double baseWidth;
    if (screenWidth > 1200) {
      baseWidth = 130;              // Larger screens
    } else if (screenWidth > 900) {
      baseWidth = 120;              // Medium screens
    } else if (screenWidth > 600) {
      baseWidth = 110;              // Small screens
    } else {
      baseWidth = 100;              // Very small screens
    }
    
    // Constrain the width to fit the available space
    double availableWidth = screenWidth - (16 * (crossAxisCount + 1)); // Account for margins
    double calculatedWidth = availableWidth / crossAxisCount;
    
    // Use the smaller of the two to ensure it always fits
    return calculatedWidth < baseWidth ? calculatedWidth : baseWidth;
  }
  
  // Helper function to get the maximum of two values
  double max(double a, double b) => a > b ? a : b;
}
