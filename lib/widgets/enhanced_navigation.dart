import 'package:flutter/material.dart';
import '../utils/responsive_utils.dart';

class EnhancedScrollNavigation extends StatefulWidget {
  final ScrollController scrollController;
  final bool showNavigation;
  final VoidCallback? onScrollLeft;
  final VoidCallback? onScrollRight;
  final bool showLeftButton;
  final bool showRightButton;
  final int currentPage;
  final int totalPages;
  final Function(int)? onPageTap;

  const EnhancedScrollNavigation({
    super.key,
    required this.scrollController,
    required this.showNavigation,
    this.onScrollLeft,
    this.onScrollRight,
    this.showLeftButton = false,
    this.showRightButton = false,
    this.currentPage = 0,
    this.totalPages = 0,
    this.onPageTap,
  });

  @override
  State<EnhancedScrollNavigation> createState() =>
      _EnhancedScrollNavigationState();
}

class _EnhancedScrollNavigationState extends State<EnhancedScrollNavigation> {
  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveUtils.isDesktop(context);

    if (!isDesktop) return const SizedBox.shrink();

    return Stack(
      children: [
        // Left navigation button
        if (widget.showLeftButton && widget.showNavigation)
          Positioned(
            left: -24,
            top: 0,
            bottom: 0,
            child: Center(
              child: _NavButton(
                icon: Icons.chevron_left,
                onPressed: widget.onScrollLeft,
              ),
            ),
          ),

        // Right navigation button
        if (widget.showRightButton && widget.showNavigation)
          Positioned(
            right: -24,
            top: 0,
            bottom: 0,
            child: Center(
              child: _NavButton(
                icon: Icons.chevron_right,
                onPressed: widget.onScrollRight,
              ),
            ),
          ),

        // Page indicators
        if (widget.totalPages > 1)
          Positioned(
            bottom: -40,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(widget.totalPages, (index) {
                    return GestureDetector(
                      onTap: () => widget.onPageTap?.call(index),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color:
                              widget.currentPage == index
                                  ? AppTheme.primary
                                  : Colors.white.withOpacity(0.4),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _NavButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onPressed;

  const _NavButton({required this.icon, this.onPressed});

  @override
  State<_NavButton> createState() => _NavButtonState();
}

class _NavButtonState extends State<_NavButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: AnimationConstants.fast,
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color:
              _isHovered
                  ? Colors.white.withOpacity(0.9)
                  : Colors.black.withOpacity(0.8),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.white.withOpacity(_isHovered ? 0.8 : 0.3),
            width: 2,
          ),
          boxShadow:
              _isHovered
                  ? [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                  : null,
        ),
        child: IconButton(
          onPressed: widget.onPressed,
          icon: Icon(
            widget.icon,
            color: _isHovered ? Colors.black : Colors.white,
            size: 24,
          ),
          padding: EdgeInsets.zero,
        ),
      ),
    );
  }
}

class ResponsiveContentRow extends StatefulWidget {
  final String title;
  final Widget child;
  final bool showMoreButton;
  final VoidCallback? onShowMore;

  const ResponsiveContentRow({
    super.key,
    required this.title,
    required this.child,
    this.showMoreButton = false,
    this.onShowMore,
  });

  @override
  State<ResponsiveContentRow> createState() => _ResponsiveContentRowState();
}

class _ResponsiveContentRowState extends State<ResponsiveContentRow> {
  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveUtils.isDesktop(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Enhanced title section
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(widget.title, style: AppTheme.titleStyle(context)),
              if (widget.showMoreButton && isDesktop)
                _ShowMoreButton(onPressed: widget.onShowMore)
              else if (widget.showMoreButton)
                Icon(Icons.arrow_forward, color: Colors.white70, size: 20),
            ],
          ),
        ),

        // Content
        widget.child,
      ],
    );
  }
}

class _ShowMoreButton extends StatefulWidget {
  final VoidCallback? onPressed;

  const _ShowMoreButton({this.onPressed});

  @override
  State<_ShowMoreButton> createState() => _ShowMoreButtonState();
}

class _ShowMoreButtonState extends State<_ShowMoreButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: AnimationConstants.fast,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color:
                _isHovered
                    ? Colors.white.withOpacity(0.15)
                    : Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(_isHovered ? 0.3 : 0.1),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Voir plus',
                style: TextStyle(
                  color: _isHovered ? Colors.white : Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.arrow_forward,
                color: _isHovered ? Colors.white : Colors.white70,
                size: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
