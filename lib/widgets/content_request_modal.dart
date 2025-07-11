import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ContentRequestButton extends StatefulWidget {
  final String itemId;
  final String itemType;
  final int? seasonId;
  final ApiService apiService;

  const ContentRequestButton({
    Key? key,
    required this.itemId,
    required this.itemType,
    this.seasonId,
    required this.apiService,
  }) : super(key: key);

  @override
  State<ContentRequestButton> createState() => _ContentRequestButtonState();
}

class _ContentRequestButtonState extends State<ContentRequestButton> {
  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.search, color: Colors.white70),
      tooltip: 'Request content',
      onPressed: () {
        showDialog(
          context: context,
          builder:
              (context) => ContentRequestModal(
                itemId: widget.itemId,
                itemType: widget.itemType,
                seasonId: widget.seasonId,
                apiService: widget.apiService,
              ),
        );
      },
    );
  }
}

class ContentRequestModal extends StatefulWidget {
  final String itemId;
  final String itemType;
  final int? seasonId;
  final ApiService apiService;

  const ContentRequestModal({
    Key? key,
    required this.itemId,
    required this.itemType,
    this.seasonId,
    required this.apiService,
  }) : super(key: key);

  @override
  State<ContentRequestModal> createState() => _ContentRequestModalState();
}

class _ContentRequestModalState extends State<ContentRequestModal> {
  int? _selectedSize;
  bool _isSubmitting = false;
  String? _errorMessage;
  String? _successMessage;

  // Available size options (in GB)
  final List<int> _sizeOptions = [1, 2, 4, 6];

  Future<void> _submitRequest() async {
    if (_selectedSize == null) {
      setState(() {
        _errorMessage = 'Please select a maximum file size';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      var goodSize = _selectedSize! * 1024 * 1024 * 1024;
      print("selected size: $goodSize bytes");
      await widget.apiService.sendContentRequest(
        widget.itemId,
        widget.itemType,
        seasonId: widget.seasonId,
      );

      setState(() {
        _isSubmitting = false;
        _successMessage = 'Request submitted successfully!';
      });

      // Close the dialog after a successful request with a short delay
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      });
    } catch (e) {
      setState(() {
        _isSubmitting = false;
        _errorMessage = 'Failed to submit request: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Request Content'),
      backgroundColor: Colors.grey[900],
      titleTextStyle: const TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      contentTextStyle: const TextStyle(color: Colors.white70),
      content: SizedBox(
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select maximum file size:',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),

            // Size selection grid
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 2,
              childAspectRatio: 2.5,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              children:
                  _sizeOptions.map((size) {
                    final isSelected = _selectedSize == size;
                    return InkWell(
                      onTap:
                          _isSubmitting
                              ? null
                              : () {
                                setState(() {
                                  _selectedSize = size;
                                });
                              },
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.blue : Colors.grey[800],
                          borderRadius: BorderRadius.circular(8),
                          border:
                              isSelected
                                  ? Border.all(
                                    color: Colors.blue.shade300,
                                    width: 2,
                                  )
                                  : null,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '$size GB',
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.white70,
                            fontWeight:
                                isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
            ),

            const SizedBox(height: 20),

            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: Colors.red[300]),
                ),
              ),

            if (_successMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Text(
                  _successMessage!,
                  style: TextStyle(color: Colors.green[300]),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
          onPressed: _isSubmitting ? null : _submitRequest,
          child:
              _isSubmitting
                  ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                  : const Text('Submit Request'),
        ),
      ],
    );
  }
}
