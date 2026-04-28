import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:uuid/uuid.dart';

class StickerData {
  final String id;
  final String type;
  Map<String, dynamic> data;
  Offset position;
  double scale;
  double rotation;

  StickerData({
    required this.id,
    required this.type,
    this.data = const {},
    this.position = Offset.zero,
    this.scale = 1.0,
    this.rotation = 0.0,
  });

  StickerData copyWith({
    String? id,
    Offset? position,
    double? scale,
    double? rotation,
    Map<String, dynamic>? data,
  }) {
    return StickerData(
      id: id ?? this.id,
      type: type,
      data: data ?? Map.from(this.data),
      position: position ?? this.position,
      scale: scale ?? this.scale,
      rotation: rotation ?? this.rotation,
    );
  }
}

class InteractiveStickerCanvas extends StatefulWidget {
  final Widget child; // The background media
  final List<StickerData> initialStickers;
  final Function(List<StickerData>) onStickersUpdated;
  final Widget Function(BuildContext, StickerData) stickerBuilder;
  final void Function(StickerData)? onStickerDoubleTapped;

  const InteractiveStickerCanvas({
    super.key,
    required this.child,
    this.initialStickers = const [],
    required this.onStickersUpdated,
    required this.stickerBuilder,
    this.onStickerDoubleTapped,
  });

  @override
  InteractiveStickerCanvasState createState() => InteractiveStickerCanvasState();
}

class InteractiveStickerCanvasState extends State<InteractiveStickerCanvas> {
  late List<StickerData> _stickers;
  final List<List<StickerData>> _undoHistory = [];
  final List<List<StickerData>> _redoHistory = [];

  // Gesture state
  String? _activeStickerId;
  Offset _initialFocalPoint = Offset.zero;
  Offset _initialStickerPosition = Offset.zero;
  double _initialScale = 1.0;
  double _initialRotation = 0.0;

  // Snap guides
  bool _showVerticalGuide = false;
  bool _showHorizontalGuide = false;
  bool _showTrashBin = false;
  bool _isOverTrashBin = false;

  @override
  void initState() {
    super.initState();
    _stickers = List.from(widget.initialStickers);
    _saveHistory();
  }

  void _saveHistory() {
    // Save deep copy
    _undoHistory.add(_stickers.map((s) => s.copyWith()).toList());
    _redoHistory.clear();
    widget.onStickersUpdated(_stickers);
  }

  void undo() {
    if (_undoHistory.length > 1) {
      _redoHistory.add(_undoHistory.removeLast());
      setState(() {
        _stickers = _undoHistory.last.map((s) => s.copyWith()).toList();
      });
      widget.onStickersUpdated(_stickers);
    }
  }

  void redo() {
    if (_redoHistory.isNotEmpty) {
      final state = _redoHistory.removeLast();
      _undoHistory.add(state.map((s) => s.copyWith()).toList());
      setState(() {
        _stickers = state.map((s) => s.copyWith()).toList();
      });
      widget.onStickersUpdated(_stickers);
    }
  }

  void addSticker(String type, Map<String, dynamic> data) {
    setState(() {
      final screenCenter = Offset(
        MediaQuery.of(context).size.width / 2,
        MediaQuery.of(context).size.height / 2,
      );
      _stickers.add(StickerData(
        id: const Uuid().v4(),
        type: type,
        data: data,
        position: screenCenter,
      ));
      _saveHistory();
    });
  }

  void _bringToFront(String id) {
    final index = _stickers.indexWhere((s) => s.id == id);
    if (index != -1 && index != _stickers.length - 1) {
      setState(() {
        final sticker = _stickers.removeAt(index);
        _stickers.add(sticker);
      });
    }
  }

  void _sendToBack(String id) {
    final index = _stickers.indexWhere((s) => s.id == id);
    if (index > 0) {
      setState(() {
        final sticker = _stickers.removeAt(index);
        _stickers.insert(0, sticker);
        _saveHistory();
      });
    }
  }

  void _duplicate(String id) {
    final sticker = _stickers.firstWhere((s) => s.id == id);
    setState(() {
      _stickers.add(sticker.copyWith(
        id: const Uuid().v4(),
        position: sticker.position + const Offset(20, 20),
      ));
      _saveHistory();
    });
  }

  void _delete(String id) {
    setState(() {
      _stickers.removeWhere((s) => s.id == id);
      _saveHistory();
    });
  }

  void updateStickerData(String id, Map<String, dynamic> newData) {
    final index = _stickers.indexWhere((s) => s.id == id);
    if (index != -1) {
      setState(() {
        _stickers[index].data = newData;
        _saveHistory();
      });
    }
  }

  void _onScaleStart(ScaleStartDetails details, StickerData sticker) {
    _bringToFront(sticker.id);
    _activeStickerId = sticker.id;
    _initialFocalPoint = details.focalPoint;
    _initialStickerPosition = sticker.position;
    _initialScale = sticker.scale;
    _initialRotation = sticker.rotation;
    setState(() {
      _showTrashBin = true;
    });
  }

  void _onScaleUpdate(ScaleUpdateDetails details, int index) {
    if (_activeStickerId != _stickers[index].id) return;

    setState(() {
      final screenCenter = Offset(
        MediaQuery.of(context).size.width / 2,
        MediaQuery.of(context).size.height / 2,
      );

      // Pan
      Offset newPos = _initialStickerPosition + (details.focalPoint - _initialFocalPoint);

      // Snap to center logic
      const snapThreshold = 15.0;
      _showVerticalGuide = (newPos.dx - screenCenter.dx).abs() < snapThreshold;
      _showHorizontalGuide = (newPos.dy - screenCenter.dy).abs() < snapThreshold;

      if (_showVerticalGuide) newPos = Offset(screenCenter.dx, newPos.dy);
      if (_showHorizontalGuide) newPos = Offset(newPos.dx, screenCenter.dy);

      // Trash bin logic
      final trashRect = Rect.fromCenter(
        center: Offset(screenCenter.dx, MediaQuery.of(context).size.height - 60),
        width: 80,
        height: 80,
      );
      _isOverTrashBin = trashRect.contains(details.focalPoint);

      _stickers[index].position = newPos;

      // Scale & Rotate
      if (details.scale != 1.0) {
        _stickers[index].scale = _initialScale * details.scale;
      }
      if (details.rotation != 0.0) {
        _stickers[index].rotation = _initialRotation + details.rotation;
      }
    });
  }

  void _onScaleEnd(ScaleEndDetails details, int index) {
    if (_isOverTrashBin && _activeStickerId == _stickers[index].id) {
      _stickers.removeAt(index);
    }
    setState(() {
      _activeStickerId = null;
      _showVerticalGuide = false;
      _showHorizontalGuide = false;
      _showTrashBin = false;
      _isOverTrashBin = false;
    });
    _saveHistory();
  }

  void _showContextMenu(BuildContext context, StickerData sticker) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.copy, color: Colors.white),
              title: const Text('Duplicate', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _duplicate(sticker.id);
              },
            ),
            ListTile(
              leading: const Icon(Icons.flip_to_front, color: Colors.white),
              title: const Text('Bring to Front', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _bringToFront(sticker.id);
                _saveHistory();
              },
            ),
            ListTile(
              leading: const Icon(Icons.flip_to_back, color: Colors.white),
              title: const Text('Send to Back', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _sendToBack(sticker.id);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _delete(sticker.id);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,

        // Snap Guides
        if (_showVerticalGuide)
          Positioned(
            left: MediaQuery.of(context).size.width / 2,
            top: 0,
            bottom: 0,
            child: Container(width: 2, color: Colors.blueAccent.withAlpha(200)),
          ),
        if (_showHorizontalGuide)
          Positioned(
            top: MediaQuery.of(context).size.height / 2,
            left: 0,
            right: 0,
            child: Container(height: 2, color: Colors.blueAccent.withAlpha(200)),
          ),

        // Stickers
        ...List.generate(_stickers.length, (index) {
          final sticker = _stickers[index];
          final isOverTrash = _isOverTrashBin && _activeStickerId == sticker.id;

          return Positioned(
            left: sticker.position.dx,
            top: sticker.position.dy,
            child: FractionalTranslation(
              translation: const Offset(-0.5, -0.5), // Center the widget on position
              child: Transform.rotate(
                angle: sticker.rotation,
                child: Transform.scale(
                  scale: isOverTrash ? sticker.scale * 0.5 : sticker.scale,
                  child: GestureDetector(
                    onScaleStart: (d) => _onScaleStart(d, sticker),
                    onScaleUpdate: (d) => _onScaleUpdate(d, index),
                    onScaleEnd: (d) => _onScaleEnd(d, index),
                    onLongPress: () => _showContextMenu(context, sticker),
                    onDoubleTap: () {
                      if (widget.onStickerDoubleTapped != null) {
                        widget.onStickerDoubleTapped!(sticker);
                      }
                    },
                    child: Opacity(
                      opacity: isOverTrash ? 0.5 : 1.0,
                      child: widget.stickerBuilder(context, sticker),
                    ),
                  ),
                ),
              ),
            ),
          );
        }),

        // Trash Bin
        if (_showTrashBin)
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: Center(
                child: Container(
                  width: _isOverTrashBin ? 70 : 50,
                  height: _isOverTrashBin ? 70 : 50,
                  decoration: BoxDecoration(
                    color: _isOverTrashBin ? Colors.red : Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.delete_outline,
                    color: Colors.white,
                    size: _isOverTrashBin ? 36 : 28,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
