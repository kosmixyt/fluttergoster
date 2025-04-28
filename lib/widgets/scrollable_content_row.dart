import 'package:flutter/material.dart';
import '../models/data_models.dart';
import '../widgets/media_card.dart';

class ScrollableContentRow extends StatefulWidget {
  final String title;
  final List<SkinnyRender> items;
  final MediaCardDisplayMode displayMode;
  final bool showTitle;

  const ScrollableContentRow({
    super.key,
    required this.title,
    required this.items,
    this.displayMode = MediaCardDisplayMode.backdrop,
    this.showTitle = true,
  });

  @override
  State<ScrollableContentRow> createState() => _ScrollableContentRowState();
}

class _ScrollableContentRowState extends State<ScrollableContentRow> {
  final ScrollController _scrollController = ScrollController();
  bool _showLeftButton = false;
  bool _showRightButton = true;
  int _currentPage = 0;
  int _totalPages = 0;
  bool _isHovering = false;

  // Nombre d'éléments visibles en même temps
  int get _itemsPerPage {
    // Calcul du nombre d'éléments affichables en fonction de la largeur d'écran et du mode d'affichage
    final screenWidth = MediaQuery.of(context).size.width;
    final itemWidth = widget.displayMode == MediaCardDisplayMode.backdrop ? 300.0 + 16.0 : 150.0 + 16.0; // Width + margin
    return (screenWidth / itemWidth).floor();
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_updateScrollButtons);
    
    // Calculer le nombre total de pages après le build initial
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _calculateTotalPages();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_updateScrollButtons);
    _scrollController.dispose();
    super.dispose();
  }
  
  void _calculateTotalPages() {
    if (widget.items.isEmpty || _itemsPerPage <= 0) {
      _totalPages = 1;
    } else {
      _totalPages = (widget.items.length / _itemsPerPage).ceil();
    }
    setState(() {});
  }

  void _updateScrollButtons() {
    setState(() {
      _showLeftButton = _scrollController.position.pixels > 0;
      _showRightButton = _scrollController.position.pixels < _scrollController.position.maxScrollExtent;
      
      // Calculer la page actuelle
      if (_scrollController.position.maxScrollExtent > 0) {
        _currentPage = (_scrollController.position.pixels / (_scrollController.position.maxScrollExtent / (_totalPages - 1))).round();
      } else {
        _currentPage = 0;
      }
    });
  }

  void _scrollToPage(int page) {
    if (page >= 0 && page < _totalPages) {
      final maxScrollExtent = _scrollController.position.maxScrollExtent;
      final targetScroll = maxScrollExtent * page / (_totalPages - 1);
      
      _scrollController.animateTo(
        targetScroll,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  void _scrollLeft() {
    final viewportWidth = _scrollController.position.viewportDimension;
    final targetScroll = _scrollController.offset - viewportWidth;
    
    _scrollController.animateTo(
      targetScroll.clamp(0.0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  void _scrollRight() {
    final viewportWidth = _scrollController.position.viewportDimension;
    final targetScroll = _scrollController.offset + viewportWidth;
    
    _scrollController.animateTo(
      targetScroll.clamp(0.0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Déterminer les dimensions en fonction du mode d'affichage
    final double itemHeight = widget.displayMode == MediaCardDisplayMode.poster ? 240 : 170;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.showTitle && widget.title.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward,
                    color: Colors.white70,
                    size: 20,
                  ),
                ],
              ),
            ),
          Stack(
            children: [
              // Content ListView
              SizedBox(
                height: itemHeight,
                child: widget.items.isEmpty 
                ? const Center(child: Text('No content available', style: TextStyle(color: Colors.white70)))
                : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  scrollDirection: Axis.horizontal,
                  itemCount: widget.items.length,
                  itemBuilder: (context, index) {
                    final item = widget.items[index];
                    return MediaCard(
                      media: item,
                      displayMode: widget.displayMode,
                      height: widget.displayMode == MediaCardDisplayMode.poster ? 220 : 170,
                      width: widget.displayMode == MediaCardDisplayMode.poster ? 150 : 300,
                    );
                  },
                ),
              ),
              
              // Left navigation button (only visible if not at the start and hovering)
              if (_showLeftButton && _isHovering)
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.chevron_left, color: Colors.white),
                        onPressed: _scrollLeft,
                        padding: EdgeInsets.zero,
                        splashRadius: 20,
                        tooltip: 'Previous',
                      ),
                    ),
                  ),
                ),
              
              // Right navigation button (only visible if not at the end and hovering)
              if (_showRightButton && _isHovering)
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.chevron_right, color: Colors.white),
                        onPressed: _scrollRight,
                        padding: EdgeInsets.zero,
                        splashRadius: 20,
                        tooltip: 'Next',
                      ),
                    ),
                  ),
                ),
            ],
          ),
          
          // Pagination indicators
          if (widget.items.isNotEmpty && _totalPages > 1)
            Padding(
              padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_totalPages, (index) {
                  return GestureDetector(
                    onTap: () => _scrollToPage(index),
                    child: Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _currentPage == index ? Colors.white : Colors.white.withOpacity(0.3),
                      ),
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }
}
