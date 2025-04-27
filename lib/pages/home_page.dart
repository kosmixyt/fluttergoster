import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../main.dart';
import '../models/data_models.dart';
import '../widgets/cookie_image.dart';
import '../widgets/media_card.dart';
import '../widgets/goster_top_bar.dart';
import 'package:fluttergoster/pages/media_details_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  ApiHome? _homeData;
  String? _error;
  bool _loading = true;
  bool _fetched = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_fetched) {
      _fetched = true;
      _fetchHome();
    }
  }

  Future<void> _fetchHome() async {
    final apiService = ApiServiceProvider.of(context);
    try {
      final data = await apiService.getHome();
      setState(() {
        _homeData = data;
        _loading = false;
      });
    } catch (e) {
      print(e);
      if (e.toString().contains('Unauthorized') || e.toString().contains('403')) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => LoginPage()),
          );
        }
      } else {
        setState(() {
          _error = "Erreur réseau";
          _loading = false;
        });
      }
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
        appBar: const GosterTopBar(),
        body: Center(child: Text(_error!)),
      );
    }
    if (_homeData != null) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: const GosterTopBar(),
        body: NetflixStyleHome(homeData: _homeData!),
      );
    }
    return const Scaffold(
      appBar: GosterTopBar(),
      body: Center(child: Text('Aucune donnée')),
    );
  }
}

class NetflixStyleHome extends StatelessWidget {
  final ApiHome homeData;

  const NetflixStyleHome({super.key, required this.homeData});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        if (homeData.recents.data.isNotEmpty)
          FeaturedContentSection(skinnyRender: homeData.recents.data.first),
        ContentRow(
          title: homeData.recents.title,
          items: homeData.recents.data,
          displayMode: MediaCardDisplayMode.backdrop,
        ),
        ...homeData.lines.asMap().entries.map((entry) {
          int index = entry.key;
          LineRender line = entry.value;
          
          // Use TopTenRow for the third line (index 2) instead of first line
          if (index == 2 && line.data.isNotEmpty) {
            return TopTenRow(
              title: "Top 10 Today",
              items: line.data.take(10).toList(),
            );
          }
          
          // Use regular ContentRow for other lines
          return line.data.isNotEmpty
              ? ContentRow(
                  title: line.title,
                  items: line.data,
                  displayMode: index % 2 == 0
                      ? MediaCardDisplayMode.poster
                      : MediaCardDisplayMode.backdrop,
                )
              : const SizedBox();
        }).toList(),
        if (homeData.providers.isNotEmpty)
          ProviderRow(
              title: homeData.providers.first.title,
              providers: homeData.providers.first.data),
        const SizedBox(height: 20),
      ],
    );
  }
}

class FeaturedContentSection extends StatelessWidget {
  final SkinnyRender skinnyRender;

  const FeaturedContentSection({super.key, required this.skinnyRender});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 400,
      margin: const EdgeInsets.only(bottom: 10),
      child: Stack(
        children: [
          Positioned.fill(
            child: CookieImage(
              imageUrl: skinnyRender.backdrop,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  Container(color: Colors.grey[900]),
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.8),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (skinnyRender.logo.isNotEmpty)
                  Container(
                    height: 60,
                    margin: const EdgeInsets.only(bottom: 10),
                    child: CookieImage(
                      imageUrl: skinnyRender.logo,
                      errorBuilder: (context, error, stackTrace) => Text(
                        skinnyRender.name,
                        style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                    ),
                  )
                else
                  Text(
                    skinnyRender.name,
                    style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                const SizedBox(height: 8),
                Text(
                  skinnyRender.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Lecture'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                      ),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MediaDetailsPage(
                              mediaId: skinnyRender.id,
                              mediaType: skinnyRender.type,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.info_outline),
                      label: const Text('Infos'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ContentRow extends StatefulWidget {
  final String title;
  final List<SkinnyRender> items;
  final MediaCardDisplayMode displayMode;

  const ContentRow({
    super.key,
    required this.title,
    required this.items,
    this.displayMode = MediaCardDisplayMode.backdrop,
  });

  @override
  State<ContentRow> createState() => _ContentRowState();
}

class _ContentRowState extends State<ContentRow> {
  final ScrollController _scrollController = ScrollController();
  bool _showLeftButton = false;
  bool _showRightButton = true;
  int _currentPage = 0;
  int _totalPages = 0;
  bool _isHovering = false;
  int? _hoveredIndex;

  int get _itemsPerPage {
    final screenWidth = MediaQuery.of(context).size.width;
    final itemWidth = widget.displayMode == MediaCardDisplayMode.backdrop ? 300.0 + 16.0 : 150.0 + 16.0;
    return (screenWidth / itemWidth).floor();
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_updateScrollButtons);
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
      if (_scrollController.position.maxScrollExtent > 0) {
        _currentPage = (_scrollController.position.pixels / (_scrollController.position.maxScrollExtent / (_totalPages - 1))).round();
      } else {
        _currentPage = 0;
      }
    });
  }

  void _scrollToPage(int page) {
    if (page >= 0 && page < _totalPages) {
      final perPage = _itemsPerPage;
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
    final double itemHeight = widget.displayMode == MediaCardDisplayMode.poster ? 240 : 170;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() {
        _isHovering = false;
        _hoveredIndex = null; // Clear hovered index when mouse leaves the row
      }),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
              SizedBox(
                height: itemHeight + 20, // Add extra height for hover animation
                child: widget.items.isEmpty 
                ? const Center(child: Text('No content available', style: TextStyle(color: Colors.white70)))
                : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  scrollDirection: Axis.horizontal,
                  itemCount: widget.items.length,
                  itemBuilder: (context, index) {
                    final item = widget.items[index];
                    return MouseRegion(
                      onEnter: (_) => setState(() => _hoveredIndex = index),
                      onExit: (_) => setState(() => _hoveredIndex = null),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeInOut,
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        transform: _hoveredIndex == index ? (Matrix4.identity()..translate(0.0, -8.0)..scale(1.05)) : Matrix4.identity(),
                        child: Stack(
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: _hoveredIndex == index ? [
                                  BoxShadow(
                                    color: Colors.blue.withOpacity(0.5),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  )
                                ] : [],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: MediaCard(
                                  media: item,
                                  displayMode: widget.displayMode,
                                  height: widget.displayMode == MediaCardDisplayMode.poster ? 220 : 170,
                                  width: widget.displayMode == MediaCardDisplayMode.poster ? 150 : 300,
                                ),
                              ),
                            ),
                            if (_hoveredIndex == index)
                              Positioned(
                                bottom: 10,
                                left: 0,
                                right: 0,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                      child: IconButton(
                                        icon: const Icon(Icons.play_arrow, color: Colors.black, size: 20),
                                        onPressed: () {},
                                        padding: EdgeInsets.zero,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.7),
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 1),
                                      ),
                                      child: IconButton(
                                        icon: const Icon(Icons.add, color: Colors.white, size: 20),
                                        onPressed: () {},
                                        padding: EdgeInsets.zero,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
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

class ProviderRow extends StatelessWidget {
  final String title;
  final List<Provider> providers;

  const ProviderRow({super.key, required this.title, required this.providers});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(
          height: 80,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            scrollDirection: Axis.horizontal,
            itemCount: providers.length,
            itemBuilder: (context, index) {
              final provider = providers[index];
              return Container(
                width: 120,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                child: InkWell(
                  onTap: () {
                    // Action quand on clique sur un provider
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white12,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              provider.providerName,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class TopTenRow extends StatefulWidget {
  final String title;
  final List<SkinnyRender> items;

  const TopTenRow({
    super.key, 
    required this.title, 
    required this.items,
  });

  @override
  State<TopTenRow> createState() => _TopTenRowState();
}

class _TopTenRowState extends State<TopTenRow> {
  final ScrollController _scrollController = ScrollController();
  bool _showLeftButton = false;
  bool _showRightButton = true;
  int _currentPage = 0;
  int _totalPages = 0;
  bool _isHovering = false;
  int? _hoveredIndex;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_updateScrollButtons);
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
    final screenWidth = MediaQuery.of(context).size.width;
    final itemWidth = 220.0; // Width of each item in the carousel
    final itemsPerPage = (screenWidth / itemWidth).floor();
    
    if (widget.items.isEmpty || itemsPerPage <= 0) {
      _totalPages = 1;
    } else {
      _totalPages = (widget.items.length / itemsPerPage).ceil();
    }
    setState(() {});
  }

  void _updateScrollButtons() {
    setState(() {
      _showLeftButton = _scrollController.position.pixels > 0;
      _showRightButton = _scrollController.position.pixels < _scrollController.position.maxScrollExtent;
      if (_scrollController.position.maxScrollExtent > 0) {
        _currentPage = (_scrollController.position.pixels / (_scrollController.position.maxScrollExtent / (_totalPages - 1))).round();
      } else {
        _currentPage = 0;
      }
    });
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
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() {
        _isHovering = false;
        _hoveredIndex = null; // Clear hovered index when mouse leaves the row
      }),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
            child: Text(
              widget.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Stack(
            children: [
              SizedBox(
                height: 290, // Taller to accommodate the number overlay
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  scrollDirection: Axis.horizontal,
                  itemCount: widget.items.length > 10 ? 10 : widget.items.length,
                  itemBuilder: (context, index) {
                    final item = widget.items[index];
                    return MouseRegion(
                      onEnter: (_) => setState(() => _hoveredIndex = index),
                      onExit: (_) => setState(() => _hoveredIndex = null),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeInOut,
                        margin: const EdgeInsets.only(bottom: 10),
                        transform: _hoveredIndex == index 
                          ? (Matrix4.identity()..translate(0.0, -10.0)..scale(1.05))
                          : Matrix4.identity(),
                        child: Stack(
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(50, 0, 8, 0),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: _hoveredIndex == index ? [
                                    BoxShadow(
                                      color: Colors.red.shade700.withOpacity(0.5),
                                      blurRadius: 12,
                                      spreadRadius: 2,
                                    )
                                  ] : [],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: MediaCard(
                                    media: item,
                                    displayMode: MediaCardDisplayMode.poster,
                                    height: 240,
                                    width: 160,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              left: 0,
                              bottom: 0,
                              child: SizedBox(
                                height: 260,
                                width: 100,
                                child: Center(
                                  child: Text(
                                    '${index + 1}',
                                    style: TextStyle(
                                      fontSize: 160,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red.shade700,
                                      height: 0.8,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black.withOpacity(0.5),
                                          blurRadius: 5,
                                          offset: const Offset(2, 2),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            if (_hoveredIndex == index)
                              Positioned(
                                bottom: 10,
                                right: 20,
                                child: Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                      child: IconButton(
                                        icon: Icon(Icons.play_arrow, color: Colors.black),
                                        onPressed: () {},
                                        padding: EdgeInsets.zero,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.7),
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 1),
                                      ),
                                      child: IconButton(
                                        icon: Icon(Icons.add, color: Colors.white),
                                        onPressed: () {},
                                        padding: EdgeInsets.zero,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
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
          if (_totalPages > 1)
            Padding(
              padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_totalPages, (index) {
                  return Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentPage == index ? Colors.white : Colors.white.withOpacity(0.3),
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
