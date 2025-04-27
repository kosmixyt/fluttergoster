import 'package:flutter/material.dart';
import 'dart:typed_data';
import '../services/api_service.dart';
import '../main.dart';

class CookieImage extends StatefulWidget {
  final String imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget Function(BuildContext, Object, StackTrace?)? errorBuilder;

  const CookieImage({
    Key? key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.errorBuilder,
  }) : super(key: key);

  @override
  State<CookieImage> createState() => _CookieImageState();
}

class _CookieImageState extends State<CookieImage> {
  Uint8List? _imageData;
  Object? _error;
  bool _loading = true;
  bool _fetched = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_fetched) {
      _fetched = true;
      _loadImage();
    }
  }

  Future<void> _loadImage() async {
    if (!mounted) return;
    
    try {
      final apiService = ApiServiceProvider.of(context);
      final imageData = await apiService.getImage(widget.imageUrl);
      
      if (mounted) {
        setState(() {
          _imageData = imageData;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e;
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Container(
        width: widget.width,
        height: widget.height,
        color: Colors.grey[800],
        child: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    
    if (_error != null) {
      if (widget.errorBuilder != null) {
        return widget.errorBuilder!(context, _error!, StackTrace.current);
      }
      return Container(
        width: widget.width,
        height: widget.height,
        color: Colors.grey[900],
      );
    }
    
    return Image.memory(
      _imageData!,
      fit: widget.fit,
      width: widget.width,
      height: widget.height,
    );
  }
}
