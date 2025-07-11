import 'package:flutter/material.dart';
import 'package:fluttergoster/pages/player_page.dart';
import '../main.dart';
import '../models/data_models.dart';
import '../widgets/cookie_image.dart';
import '../widgets/media_card.dart';
import '../widgets/goster_top_bar.dart';
import 'package:fluttergoster/pages/media_details_page.dart';

// Constantes pour les espacements
const double kVerticalSpacing = 8.0;
const double kBottomPadding = 0.0;
const double kProviderSectionPadding = 16.0;
const double kFeaturedBottomMargin = 4.0;

// Constantes pour les tailles
const double kDesktopBreakpoint = 900.0;
const double kTabletBreakpoint = 600.0;
const double kIconButtonSize = 40.0;
const double kPaginationDotSize = 8.0;
const double kPaginationDotSpacing = 4.0;

// Constantes pour les opacités et rayons
const double kOverlayOpacity = 0.7;
const double kBlurRadius = 8.0;
const double kBorderRadius = 8.0;
const double kCardElevation = 2.0;
const int kAnimationDuration = 200;

// Constantes pour les dimensions du Top Ten
const double kTopTenItemWidth = 220.0;
const double kTopTenHeight = 290.0;
const double kTopTenLeftOffset = 50.0;

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
      if (e.toString().contains('Unauthorized') ||
          e.toString().contains('403')) {
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
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > kDesktopBreakpoint;
    final isTablet =
        screenWidth > kTabletBreakpoint && screenWidth <= kDesktopBreakpoint;

    return CustomScrollView(
      slivers: [
        // Featured content section
        if (homeData.recents.data.isNotEmpty)
          SliverToBoxAdapter(
            child: FeaturedContentSection(
              skinnyRender: homeData.recents.data.first,
              isDesktop: isDesktop,
            ),
          ),

        // Main content with better spacing for desktop
        SliverPadding(
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 24 : (isTablet ? 16 : 12),
          ),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              const SizedBox(height: kVerticalSpacing),

              // Recent/Continue watching row
              if (homeData.recents.data.isNotEmpty)
                ContentRow(
                  title: homeData.recents.title,
                  items: homeData.recents.data,
                  displayMode: MediaCardDisplayMode.backdrop,
                  isWatchingRow:
                      homeData.recents.title.contains("Watching") ||
                      homeData.recents.title.contains("Regarder"),
                  isDesktop: isDesktop,
                ),

              const SizedBox(height: kVerticalSpacing),

              // Dynamic content rows
              ...homeData.lines.asMap().entries.map((entry) {
                int index = entry.key;
                LineRender line = entry.value;

                bool isWatchingRow =
                    line.title.contains("Watching") ||
                    line.title.contains("Regarder");

                if (index == 2 && line.data.isNotEmpty) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: kBottomPadding),
                    child: TopTenRow(
                      title: "Top 10 Today",
                      items: line.data.take(10).toList(),
                      isDesktop: isDesktop,
                    ),
                  );
                }

                return line.data.isNotEmpty
                    ? Padding(
                      padding: const EdgeInsets.only(bottom: kBottomPadding),
                      child: ContentRow(
                        title: line.title,
                        items: line.data,
                        displayMode:
                            index % 2 == 0
                                ? MediaCardDisplayMode.poster
                                : MediaCardDisplayMode.backdrop,
                        isWatchingRow: isWatchingRow,
                        isDesktop: isDesktop,
                      ),
                    )
                    : const SizedBox();
              }),

              // Providers section
              if (homeData.providers.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(
                    bottom: kProviderSectionPadding,
                  ),
                  child: ProviderRow(
                    title: homeData.providers.first.title,
                    providers: homeData.providers.first.data,
                    isDesktop: isDesktop,
                  ),
                ),
            ]),
          ),
        ),
      ],
    );
  }
}

class FeaturedContentSection extends StatelessWidget {
  final SkinnyRender skinnyRender;
  final bool isDesktop;

  const FeaturedContentSection({
    super.key,
    required this.skinnyRender,
    this.isDesktop = false,
  });

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final double height = screenHeight * 0.8;
    final double horizontalPadding = isDesktop ? 24 : 16;

    return Container(
      height: height,
      margin: const EdgeInsets.only(bottom: kFeaturedBottomMargin),
      child: Stack(
        children: [
          // Background image with better quality scaling
          Positioned.fill(
            child: CookieImage(
              imageUrl: skinnyRender.backdrop,
              fit: BoxFit.cover,
              errorBuilder:
                  (context, error, stackTrace) =>
                      Container(color: Colors.grey[900]),
            ),
          ),

          // Enhanced gradient overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.0, 0.4, 0.7, 1.0],
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.1),
                    Colors.black.withOpacity(0.6),
                    Colors.black.withOpacity(0.9),
                  ],
                ),
              ),
            ),
          ),

          // Content positioned better for desktop
          Positioned(
            bottom: isDesktop ? 40 : 16,
            left: horizontalPadding,
            right: horizontalPadding,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isDesktop ? 600 : double.infinity,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (skinnyRender.logo.isNotEmpty)
                    Container(
                      height: isDesktop ? 80 : 60,
                      margin: const EdgeInsets.only(bottom: 10),
                      child: CookieImage(
                        imageUrl: skinnyRender.logo,
                        errorBuilder:
                            (context, error, stackTrace) => Text(
                              skinnyRender.name,
                              style: TextStyle(
                                fontSize: isDesktop ? 32 : 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                      ),
                    )
                  else
                    Text(
                      skinnyRender.name,
                      style: TextStyle(
                        fontSize: isDesktop ? 32 : 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  const SizedBox(height: 12),
                  Text(
                    skinnyRender.description,
                    maxLines: isDesktop ? 3 : 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: isDesktop ? 16 : 14,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => PlayerPage(
                                    transcodeUrl: skinnyRender.transcodeUrl,
                                  ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Lecture'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          padding: EdgeInsets.symmetric(
                            horizontal: isDesktop ? 24 : 16,
                            vertical: isDesktop ? 12 : 8,
                          ),
                          textStyle: TextStyle(
                            fontSize: isDesktop ? 16 : 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => MediaDetailsPage(
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
                          side: const BorderSide(color: Colors.white),
                          padding: EdgeInsets.symmetric(
                            horizontal: isDesktop ? 24 : 16,
                            vertical: isDesktop ? 12 : 8,
                          ),
                          textStyle: TextStyle(
                            fontSize: isDesktop ? 16 : 14,
                            fontWeight: FontWeight.w600,
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
    );
  }
}

class ContentRow extends StatefulWidget {
  final String title;
  final List<SkinnyRender> items;
  final MediaCardDisplayMode displayMode;
  final bool isWatchingRow;
  final bool isDesktop;

  const ContentRow({
    super.key,
    required this.title,
    required this.items,
    this.displayMode = MediaCardDisplayMode.poster,
    this.isWatchingRow = false,
    this.isDesktop = false,
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
  bool _isDeleting = false;
  final Set<String> _deletedItemIds = {};

  int get _itemsPerPage {
    final screenWidth = MediaQuery.of(context).size.width;
    final baseItemWidth =
        widget.displayMode == MediaCardDisplayMode.backdrop ? 300.0 : 150.0;
    final spacing = 16.0;

    // Responsive item width calculation
    double itemWidth;
    if (widget.isDesktop) {
      itemWidth =
          widget.displayMode == MediaCardDisplayMode.backdrop ? 320.0 : 180.0;
    } else if (screenWidth > 600) {
      itemWidth =
          widget.displayMode == MediaCardDisplayMode.backdrop ? 280.0 : 160.0;
    } else {
      itemWidth = baseItemWidth;
    }

    final totalItemWidth = itemWidth + spacing;
    final availableWidth =
        screenWidth - (widget.isDesktop ? 96 : 32); // Account for padding

    return (availableWidth / totalItemWidth).floor().clamp(
      2,
      widget.isDesktop ? 8 : 6,
    );
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
    final visibleItems =
        widget.items
            .where((item) => !_deletedItemIds.contains(item.id))
            .toList();
    if (visibleItems.isEmpty || _itemsPerPage <= 0) {
      _totalPages = 1;
    } else {
      _totalPages = (visibleItems.length / _itemsPerPage).ceil();
    }
    setState(() {});
  }

  void _updateScrollButtons() {
    setState(() {
      _showLeftButton = _scrollController.position.pixels > 0;
      _showRightButton =
          _scrollController.position.pixels <
          _scrollController.position.maxScrollExtent;
      if (_scrollController.position.maxScrollExtent > 0) {
        _currentPage =
            (_scrollController.position.pixels /
                    (_scrollController.position.maxScrollExtent /
                        (_totalPages - 1)))
                .round();
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

  Future<void> _deleteWatchingItem(SkinnyRender item) async {
    if (_isDeleting) return;

    setState(() {
      _isDeleting = true;
    });

    try {
      final apiService = ApiServiceProvider.of(context);
      final success = await apiService.deleteContinueWithToast(
        item.type,
        item.id,
      );

      if (success && mounted) {
        setState(() {
          _deletedItemIds.add(item.id);
          _isDeleting = false;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _calculateTotalPages();
          });
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Removed from continue watching'),
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        setState(() {
          _isDeleting = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to remove: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final double itemHeight =
        widget.displayMode == MediaCardDisplayMode.poster ? 240 : 170;

    final visibleItems =
        widget.items
            .where((item) => !_deletedItemIds.contains(item.id))
            .toList();

    if (widget.isWatchingRow && visibleItems.isEmpty) {
      return const SizedBox.shrink();
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit:
          (_) => setState(() {
            _isHovering = false;
            _hoveredIndex = null;
          }),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 3),
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
                Icon(Icons.arrow_forward, color: Colors.white70, size: 20),
              ],
            ),
          ),
          Stack(
            children: [
              SizedBox(
                height: itemHeight + 20,
                child:
                    visibleItems.isEmpty
                        ? const Center(
                          child: Text(
                            'No content available',
                            style: TextStyle(color: Colors.white70),
                          ),
                        )
                        : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          scrollDirection: Axis.horizontal,
                          clipBehavior: Clip.none,
                          itemCount: visibleItems.length,
                          itemBuilder: (context, index) {
                            final item = visibleItems[index];
                            return MouseRegion(
                              onEnter:
                                  (_) => setState(() => _hoveredIndex = index),
                              onExit:
                                  (_) => setState(() => _hoveredIndex = null),
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                alignment: Alignment.center,
                                child: AnimatedContainer(
                                  duration: const Duration(
                                    milliseconds: kAnimationDuration,
                                  ),
                                  curve: Curves.easeInOut,
                                  transform:
                                      _hoveredIndex == index
                                          ? (Matrix4.identity()
                                            ..translate(0.0, -8.0)
                                            ..scale(1.05))
                                          : Matrix4.identity(),
                                  transformAlignment: Alignment.center,
                                  child: Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      MediaCard(
                                        media: item,
                                        displayMode: widget.displayMode,
                                        height:
                                            widget.displayMode ==
                                                    MediaCardDisplayMode.poster
                                                ? 220
                                                : 170,
                                        width:
                                            widget.displayMode ==
                                                    MediaCardDisplayMode.poster
                                                ? 150
                                                : 300,
                                      ),
                                      if (widget.isWatchingRow &&
                                          _hoveredIndex == index)
                                        Positioned(
                                          top: 8,
                                          right: 8,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: Colors.black.withOpacity(
                                                kOverlayOpacity,
                                              ),
                                              shape: BoxShape.circle,
                                            ),
                                            child: IconButton(
                                              icon:
                                                  _isDeleting
                                                      ? SizedBox(
                                                        width: 20,
                                                        height: 20,
                                                        child: CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                          valueColor:
                                                              AlwaysStoppedAnimation<
                                                                Color
                                                              >(Colors.white),
                                                        ),
                                                      )
                                                      : const Icon(
                                                        Icons.close,
                                                        color: Colors.white,
                                                        size: 20,
                                                      ),
                                              tooltip:
                                                  'Remove from continue watching',
                                              onPressed:
                                                  () =>
                                                      _deleteWatchingItem(item),
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(
                                                minWidth: 36,
                                                minHeight: 36,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
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
                      width: kIconButtonSize,
                      height: kIconButtonSize,
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
                        icon: const Icon(
                          Icons.chevron_left,
                          color: Colors.white,
                        ),
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
                      width: kIconButtonSize,
                      height: kIconButtonSize,
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
                        icon: const Icon(
                          Icons.chevron_right,
                          color: Colors.white,
                        ),
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
                      width: kPaginationDotSize,
                      height: kPaginationDotSize,
                      margin: const EdgeInsets.symmetric(
                        horizontal: kPaginationDotSpacing,
                      ),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color:
                            _currentPage == index
                                ? Colors.white
                                : Colors.white.withOpacity(0.3),
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
  final bool isDesktop;

  const ProviderRow({
    super.key,
    required this.title,
    required this.providers,
    this.isDesktop = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            title,
            style: TextStyle(
              color: Colors.white,
              fontSize: isDesktop ? 22 : 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ),
        SizedBox(
          height: isDesktop ? 100 : 80,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: providers.length,
            itemBuilder: (context, index) {
              final provider = providers[index];
              return Container(
                width: isDesktop ? 140 : 120,
                margin: const EdgeInsets.only(right: 16),
                child: InkWell(
                  onTap: () {
                    // Action quand on clique sur un provider
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.tv,
                          color: Colors.white70,
                          size: isDesktop ? 24 : 20,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          provider.providerName,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isDesktop ? 14 : 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
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
  final bool isDesktop;

  const TopTenRow({
    super.key,
    required this.title,
    required this.items,
    this.isDesktop = false,
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
    final itemWidth = kTopTenItemWidth; // Width of each item in the carousel
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
      _showRightButton =
          _scrollController.position.pixels <
          _scrollController.position.maxScrollExtent;
      if (_scrollController.position.maxScrollExtent > 0) {
        _currentPage =
            (_scrollController.position.pixels /
                    (_scrollController.position.maxScrollExtent /
                        (_totalPages - 1)))
                .round();
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
      onExit:
          (_) => setState(() {
            _isHovering = false;
            _hoveredIndex = null;
          }),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
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
                height: kTopTenHeight,
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  scrollDirection: Axis.horizontal,
                  clipBehavior: Clip.none,
                  itemCount:
                      widget.items.length > 10 ? 10 : widget.items.length,
                  itemBuilder: (context, index) {
                    final item = widget.items[index];
                    return MouseRegion(
                      onEnter: (_) => setState(() => _hoveredIndex = index),
                      onExit: (_) => setState(() => _hoveredIndex = null),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        alignment: Alignment.center,
                        child: AnimatedContainer(
                          duration: const Duration(
                            milliseconds: kAnimationDuration,
                          ),
                          curve: Curves.easeInOut,
                          transform:
                              _hoveredIndex == index
                                  ? (Matrix4.identity()
                                    ..translate(0.0, -10.0)
                                    ..scale(1.05))
                                  : Matrix4.identity(),
                          transformAlignment: Alignment.center,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  kTopTenLeftOffset,
                                  0,
                                  6,
                                  0,
                                ),
                                child: MediaCard(
                                  media: item,
                                  displayMode: MediaCardDisplayMode.poster,
                                  height: 240,
                                  width: 160,
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
                                            color: Colors.black.withOpacity(
                                              0.5,
                                            ),
                                            blurRadius: 5,
                                            offset: const Offset(2, 2),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
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
                      width: kIconButtonSize,
                      height: kIconButtonSize,
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
                        icon: const Icon(
                          Icons.chevron_left,
                          color: Colors.white,
                        ),
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
                      width: kIconButtonSize,
                      height: kIconButtonSize,
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
                        icon: const Icon(
                          Icons.chevron_right,
                          color: Colors.white,
                        ),
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
                    width: kPaginationDotSize,
                    height: kPaginationDotSize,
                    margin: const EdgeInsets.symmetric(
                      horizontal: kPaginationDotSpacing,
                    ),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color:
                          _currentPage == index
                              ? Colors.white
                              : Colors.white.withOpacity(0.3),
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
