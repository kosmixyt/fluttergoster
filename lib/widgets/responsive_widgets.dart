import 'package:flutter/material.dart';
import '../utils/responsive_utils.dart';

class ResponsiveButton extends StatefulWidget {
  final String text;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool isPrimary;
  final bool isOutlined;

  const ResponsiveButton({
    super.key,
    required this.text,
    this.icon,
    this.onPressed,
    this.isPrimary = true,
    this.isOutlined = false,
  });

  @override
  State<ResponsiveButton> createState() => _ResponsiveButtonState();
}

class _ResponsiveButtonState extends State<ResponsiveButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AnimationConstants.fast,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(
        parent: _controller,
        curve: AnimationConstants.defaultCurve,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveUtils.isDesktop(context);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => _controller.forward(),
        onTapUp: (_) => _controller.reverse(),
        onTapCancel: () => _controller.reverse(),
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: AnimatedContainer(
                duration: AnimationConstants.medium,
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 24 : 16,
                  vertical: isDesktop ? 12 : 10,
                ),
                decoration: BoxDecoration(
                  color:
                      widget.isOutlined
                          ? Colors.transparent
                          : (widget.isPrimary
                              ? (_isHovered
                                  ? AppTheme.primaryDark
                                  : AppTheme.primary)
                              : (_isHovered
                                  ? Colors.white.withOpacity(0.2)
                                  : Colors.white)),
                  borderRadius: BorderRadius.circular(8),
                  border:
                      widget.isOutlined
                          ? Border.all(
                            color:
                                _isHovered
                                    ? Colors.white
                                    : Colors.white.withOpacity(0.7),
                            width: 2,
                          )
                          : null,
                  boxShadow:
                      _isHovered && !widget.isOutlined
                          ? [
                            BoxShadow(
                              color: (widget.isPrimary
                                      ? AppTheme.primary
                                      : Colors.white)
                                  .withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ]
                          : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.icon != null) ...[
                      Icon(
                        widget.icon,
                        color:
                            widget.isOutlined
                                ? Colors.white
                                : (widget.isPrimary
                                    ? Colors.white
                                    : Colors.black),
                        size: isDesktop ? 20 : 18,
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      widget.text,
                      style: TextStyle(
                        color:
                            widget.isOutlined
                                ? Colors.white
                                : (widget.isPrimary
                                    ? Colors.white
                                    : Colors.black),
                        fontWeight: FontWeight.w600,
                        fontSize: isDesktop ? 16 : 14,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class LoadingCard extends StatelessWidget {
  final double? width;
  final double? height;

  const LoadingCard({super.key, this.width, this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[900]?.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(strokeWidth: 2),
          SizedBox(height: 8),
          Text(
            'Chargement...',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionText;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionText,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveUtils.isDesktop(context);

    return Container(
      padding: EdgeInsets.all(isDesktop ? 48 : 32),
      margin: const EdgeInsets.all(24),
      decoration: AppTheme.cardDecoration,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: isDesktop ? 80 : 64, color: Colors.grey[600]),
          SizedBox(height: isDesktop ? 24 : 16),
          Text(
            title,
            style: AppTheme.titleStyle(context),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: AppTheme.bodyStyle(context),
            textAlign: TextAlign.center,
          ),
          if (actionText != null && onAction != null) ...[
            const SizedBox(height: 24),
            ResponsiveButton(
              text: actionText!,
              icon: Icons.refresh,
              onPressed: onAction,
            ),
          ],
        ],
      ),
    );
  }
}

class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double itemWidth;
  final double aspectRatio;
  final int maxColumns;
  final int minColumns;
  final double spacing;

  const ResponsiveGrid({
    super.key,
    required this.children,
    required this.itemWidth,
    this.aspectRatio = 2 / 3,
    this.maxColumns = 8,
    this.minColumns = 2,
    this.spacing = 16,
  });

  @override
  Widget build(BuildContext context) {
    final crossAxisCount = ResponsiveUtils.getGridCrossAxisCount(
      context,
      itemWidth: itemWidth,
      maxColumns: maxColumns,
      minColumns: minColumns,
    );

    return GridView.builder(
      padding: ResponsiveUtils.getContentPadding(context),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: aspectRatio,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
      ),
      itemCount: children.length,
      itemBuilder: (context, index) => children[index],
    );
  }
}

class HoverCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  final Duration duration;

  const HoverCard({
    super.key,
    required this.child,
    this.onTap,
    this.scale = 1.05,
    this.duration = const Duration(milliseconds: 200),
  });

  @override
  State<HoverCard> createState() => _HoverCardState();
}

class _HoverCardState extends State<HoverCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor:
          widget.onTap != null
              ? SystemMouseCursors.click
              : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: widget.duration,
          transform:
              _isHovered
                  ? (Matrix4.identity()
                    ..translate(0.0, -4.0)
                    ..scale(widget.scale))
                  : Matrix4.identity(),
          transformAlignment: Alignment.center,
          child: AnimatedContainer(
            duration: widget.duration,
            decoration:
                _isHovered ? AppTheme.hoverDecoration : AppTheme.cardDecoration,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
