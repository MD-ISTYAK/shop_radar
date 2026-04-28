import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/snap_filters.dart';
import 'snap_preview_screen.dart';

class SnapCameraScreen extends StatefulWidget {
  const SnapCameraScreen({super.key});

  @override
  State<SnapCameraScreen> createState() => _SnapCameraScreenState();
}

class _SnapCameraScreenState extends State<SnapCameraScreen> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  int _selectedCameraIndex = 0;
  bool _isInitializing = true;
  FlashMode _flashMode = FlashMode.off;
  int _timerSeconds = 0;
  String _selectedFilterName = 'Original';
  double _brightness = 0.0;
  bool _showSettings = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        _onNewCameraSelected(_cameras![_selectedCameraIndex]);
      }
    } catch (e) {
      debugPrint('Camera initialization error: $e');
    }
  }

  Future<void> _onNewCameraSelected(CameraDescription cameraDescription) async {
    if (_controller != null) {
      await _controller!.dispose();
    }

    _controller = CameraController(
      cameraDescription,
      ResolutionPreset.high,
      enableAudio: false,
    );

    try {
      await _controller!.initialize();
      if (mounted) {
        setState(() => _isInitializing = false);
      }
    } catch (e) {
      debugPrint('Error selecting camera: $e');
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _toggleFlash() {
    if (_controller == null) return;
    setState(() {
      _flashMode = _flashMode == FlashMode.off ? FlashMode.torch : FlashMode.off;
      _controller!.setFlashMode(_flashMode);
    });
  }

  void _switchCamera() {
    if (_cameras == null || _cameras!.length < 2) return;
    setState(() {
      _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras!.length;
      _isInitializing = true;
    });
    _onNewCameraSelected(_cameras![_selectedCameraIndex]);
  }

  void _capturePhoto() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    if (_timerSeconds > 0) {
      int count = _timerSeconds;
      Timer.periodic(const Duration(seconds: 1), (timer) {
        if (count == 0) {
          timer.cancel();
          _takePicture();
        } else {
          setState(() => _currentCount = count);
          count--;
        }
      });
    } else {
      _takePicture();
    }
  }

  int _currentCount = 0;
  bool _isRecording = false;

  void _takePicture() async {
    try {
      final image = await _controller!.takePicture();
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SnapPreviewScreen(
              mediaPath: image.path,
              isVideo: false,
              filter: SnapFilters.allFilters[_selectedFilterName]!,
              filterName: _selectedFilterName,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error taking picture: $e');
    }
  }

  void _startVideoRecording() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (_controller!.value.isRecordingVideo) return;
    try {
      await _controller!.startVideoRecording();
      setState(() => _isRecording = true);
    } catch (e) {
      debugPrint('Error starting video recording: $e');
    }
  }

  void _stopVideoRecording() async {
    if (_controller == null || !_controller!.value.isRecordingVideo) return;
    try {
      final video = await _controller!.stopVideoRecording();
      setState(() => _isRecording = false);
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SnapPreviewScreen(
              mediaPath: video.path,
              isVideo: true,
              filter: SnapFilters.allFilters[_selectedFilterName]!,
              filterName: _selectedFilterName,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error stopping video recording: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ─── Camera Preview with Filter ───
          Positioned.fill(
            child: ColorFiltered(
              colorFilter: ColorFilter.matrix(SnapFilters.allFilters[_selectedFilterName]!),
              child: Builder(
                builder: (context) {
                  final size = MediaQuery.of(context).size;
                  // Calculate scale to fill screen
                  var scale = size.aspectRatio * _controller!.value.aspectRatio;
                  // If scale is less than 1, we need to flip it
                  if (scale < 1) scale = 1 / scale;

                  return Transform.scale(
                    scale: scale,
                    child: Center(
                      child: CameraPreview(_controller!),
                    ),
                  );
                },
              ),
            ),
          ),

          // ─── Top Controls ───
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildIconButton(Icons.close, () => Navigator.pop(context)),
                Row(
                  children: [
                    _buildIconButton(
                      _flashMode == FlashMode.torch ? Icons.flash_on : Icons.flash_off,
                      _toggleFlash,
                    ),
                    const SizedBox(width: 15),
                    _buildIconButton(
                      _timerSeconds == 0 ? Icons.timer_off : Icons.timer,
                      () {
                        setState(() {
                          if (_timerSeconds == 0) _timerSeconds = 3;
                          else if (_timerSeconds == 3) _timerSeconds = 5;
                          else if (_timerSeconds == 5) _timerSeconds = 10;
                          else _timerSeconds = 0;
                        });
                      },
                      label: _timerSeconds > 0 ? '${_timerSeconds}s' : null,
                    ),
                    const SizedBox(width: 15),
                    _buildIconButton(Icons.settings, () => setState(() => _showSettings = !_showSettings)),
                  ],
                ),
              ],
            ),
          ),

          // ─── Timer Display ───
          if (_currentCount > 0)
            Center(
              child: Text(
                '$_currentCount',
                style: const TextStyle(color: Colors.white, fontSize: 100, fontWeight: FontWeight.bold),
              ).animate().scale(duration: 500.ms).fadeOut(delay: 500.ms),
            ),

          // ─── Bottom Controls ───
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Filter Selector
                _buildFilterSelector(),
                const SizedBox(height: 15),
                const Text(
                  'Tap for photo, hold for video',
                  style: TextStyle(
                    color: Colors.white70, 
                    fontSize: 13, 
                    fontWeight: FontWeight.w500,
                    shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                  ),
                ),
                const SizedBox(height: 15),
                // Main Buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildIconButton(Icons.photo_library, () {
                        // Open Gallery logic
                      }),
                      _buildCaptureButton(),
                      _buildIconButton(Icons.flip_camera_ios, _switchCamera),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ─── Settings Panel (Brightness/etc) ───
          if (_showSettings)
            Positioned(
              right: 20,
              top: 150,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.wb_sunny, color: Colors.white, size: 20),
                    RotatedBox(
                      quarterTurns: 3,
                      child: Slider(
                        value: _brightness,
                        min: -1.0,
                        max: 1.0,
                        onChanged: (v) => setState(() => _brightness = v),
                        activeColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildIconButton(IconData icon, VoidCallback onTap, {String? label}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3), 
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          if (label != null) ...[
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ],
      ),
    );
  }

  Widget _buildCaptureButton() {
    return GestureDetector(
      onTap: _capturePhoto,
      onLongPress: _startVideoRecording,
      onLongPressEnd: (details) => _stopVideoRecording(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: _isRecording ? 95 : 85,
        width: _isRecording ? 95 : 85,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: _isRecording ? Colors.redAccent : Colors.white, width: _isRecording ? 6 : 4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              spreadRadius: 2,
            )
          ],
        ),
        padding: const EdgeInsets.all(4),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: _isRecording ? Colors.red : Colors.white, 
            shape: BoxShape.circle
          ),
        ),
      ),
    );
  }

  Widget _buildFilterSelector() {
    return SizedBox(
      height: 110,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: SnapFilters.allFilters.length,
        itemBuilder: (context, index) {
          final name = SnapFilters.allFilters.keys.elementAt(index);
          final isSelected = name == _selectedFilterName;
          return GestureDetector(
            onTap: () => setState(() => _selectedFilterName = name),
            child: Container(
              margin: const EdgeInsets.only(right: 15),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: isSelected ? 72 : 60,
                    height: isSelected ? 72 : 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: _getFilterGradient(name),
                      border: Border.all(
                        color: isSelected ? Colors.white : Colors.white24,
                        width: isSelected ? 3 : 1,
                      ),
                      boxShadow: isSelected ? [
                        BoxShadow(color: Colors.white.withOpacity(0.5), blurRadius: 15, spreadRadius: 2)
                      ] : null,
                    ),
                    child: isSelected 
                      ? const Icon(Icons.check, color: Colors.white, size: 26)
                      : null,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    name,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      shadows: const [Shadow(color: Colors.black54, blurRadius: 4)],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Gradient _getFilterGradient(String name) {
    switch (name) {
      case 'Original':
        return const LinearGradient(colors: [Colors.grey, Colors.white]);
      case 'Aesthetic':
        return const LinearGradient(colors: [Color(0xFFE0E0E0), Color(0xFFFFFFFF)]);
      case 'Moody':
        return const LinearGradient(colors: [Color(0xFF1A3C40), Color(0xFF417D7A)]);
      case 'Golden':
        return const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFFA500)]);
      case 'Cyber':
        return const LinearGradient(colors: [Color(0xFFFF00FF), Color(0xFF00FFFF)]);
      case 'Glow':
        return const LinearGradient(colors: [Color(0xFF00FF00), Color(0xFFADFF2F)]);
      case 'Noir':
        return const LinearGradient(colors: [Color(0xFF000000), Color(0xFF434343)]);
      case 'Rose':
        return const LinearGradient(colors: [Color(0xFFFFC0CB), Color(0xFFFFB6C1)]);
      case 'Ocean':
        return const LinearGradient(colors: [Color(0xFF000080), Color(0xFF0000FF)]);
      case '80s':
        return const LinearGradient(colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)]);
      default:
        return const LinearGradient(colors: [Colors.blue, Colors.purple]);
    }
  }
}
