import 'dart:io';
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart' as shelf_router;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../../../../core/theme/app_theme.dart';

class WebShareScreen extends StatefulWidget {
  const WebShareScreen({super.key});

  @override
  State<WebShareScreen> createState() => _WebShareScreenState();
}

class _WebShareScreenState extends State<WebShareScreen> {
  String? _localIp;
  int _port = 8080;
  HttpServer? _server;
  bool _serverRunning = false;
  String? _selectedMode; // 'hotspot' | 'wifi'
  List<FileSystemEntity> _sharedFiles = [];
  bool _loading = false;

  @override
  void dispose() {
    _server?.close(force: true);
    super.dispose();
  }

  Future<void> _startServer(String mode) async {
    setState(() {
      _loading = true;
      _selectedMode = mode;
    });

    try {
      final info = NetworkInfo();
      _localIp = await info.getWifiIP() ?? '192.168.1.1';

      // Find port
      _port = 8080 + Random().nextInt(20);

      // Load files from FileShare folder
      final savePath = await _getFileSharePath();
      final dir = Directory(savePath);
      if (await dir.exists()) {
        _sharedFiles = await dir.list().toList();
      }

      // Build server
      final router = shelf_router.Router();

      // Serve UI
      router.get('/', (shelf.Request req) {
        return shelf.Response.ok(
          _buildHtml(),
          headers: {'Content-Type': 'text/html; charset=utf-8'},
        );
      });

      // Download file
      router.get('/download/<filename>', (shelf.Request req, String filename) async {
        final filePath = p.join(savePath, filename);
        final file = File(filePath);
        if (!await file.exists()) {
          return shelf.Response.notFound('File not found');
        }
        return shelf.Response.ok(
          file.openRead(),
          headers: {
            'Content-Type': 'application/octet-stream',
            'Content-Disposition': 'attachment; filename="$filename"',
            'Content-Length': (await file.length()).toString(),
          },
        );
      });

      // List files (JSON)
      router.get('/api/files', (shelf.Request req) async {
        final files = <Map<String, dynamic>>[];
        for (final f in _sharedFiles) {
          if (f is File) {
            files.add({
              'name': p.basename(f.path),
              'size': await f.length(),
            });
          }
        }
        return shelf.Response.ok(
          '{"files": ${files.map((f) => '{"name":"${f['name']}","size":${f['size']}}').join(',').replaceFirst('', '[').padRight(1)}}',
          headers: {'Content-Type': 'application/json'},
        );
      });

      // Upload file
      router.post('/upload', (shelf.Request req) async {
        final bytes = await req.read().toList();
        final all = bytes.expand((e) => e).toList();
        final filename =
            req.headers['x-filename'] ?? 'upload_${DateTime.now().millisecondsSinceEpoch}';
        final filePath = p.join(savePath, filename);
        await File(filePath).writeAsBytes(all);
        return shelf.Response.ok('{"success":true}',
            headers: {'Content-Type': 'application/json'});
      });

      final handler = const shelf.Pipeline().addHandler(router.call);
      _server = await io.serve(handler, InternetAddress.anyIPv4, _port);

      setState(() {
        _serverRunning = true;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error starting server: $e')),
        );
      }
    }
  }

  Future<String> _getFileSharePath() async {
    if (Platform.isAndroid) {
      return '/storage/emulated/0/Downloads/FileShare/Received';
    }
    final dir = await getApplicationDocumentsDirectory();
    return p.join(dir.path, 'FileShare', 'Received');
  }

  Future<void> _stopServer() async {
    await _server?.close(force: true);
    setState(() {
      _serverRunning = false;
      _selectedMode = null;
    });
  }

  String get _serverUrl => 'http://$_localIp:$_port';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () {
            _stopServer();
            Navigator.pop(context);
          },
        ),
        title: const Text('Web Share', style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          if (_serverRunning)
            TextButton.icon(
              onPressed: _stopServer,
              icon: const Icon(Icons.stop_circle_rounded, color: AppColors.error),
              label: const Text('Stop', style: TextStyle(color: AppColors.error)),
            ),
        ],
      ),
      body: _serverRunning ? _buildActiveServer() : _buildModeSelector(),
    );
  }

  Widget _buildModeSelector() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 16),
          const Text(
            'Select a transmission mode',
            style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 40),
          _buildModeCard(
            mode: 'hotspot',
            icon: Icons.settings_input_antenna_rounded,
            color: const Color(0xFF16A34A),
            title: 'Hotspot Mode',
            badge: 'Faster',
            badgeColor: const Color(0xFFF59E0B),
            description:
                'The other device connects to the phone\'s hotspot.\nNo internet data usage.',
          ),
          const Divider(height: 48),
          _buildModeCard(
            mode: 'wifi',
            icon: Icons.wifi_rounded,
            color: const Color(0xFF3B82F6),
            title: 'Wi-Fi Mode',
            badge: 'Convenient',
            badgeColor: const Color(0xFFF59E0B),
            description:
                'Phone and the other device connect to the same Wi-Fi.',
          ),
        ],
      ),
    );
  }

  Widget _buildModeCard({
    required String mode,
    required IconData icon,
    required Color color,
    required String title,
    required String badge,
    required Color badgeColor,
    required String description,
  }) {
    return GestureDetector(
      onTap: _loading ? null : () => _startServer(mode),
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withAlpha(80),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: _loading && _selectedMode == mode
                    ? const Center(
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 3))
                    : Icon(icon, color: Colors.white, size: 44),
              ),
              Positioned(
                right: -6,
                top: -4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    badge,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveServer() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Status banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.success.withAlpha(15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.success.withAlpha(60)),
            ),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                      color: AppColors.success, shape: BoxShape.circle),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Server is running',
                  style: TextStyle(
                      fontWeight: FontWeight.w700, color: AppColors.success),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // QR Code
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(15),
                  blurRadius: 20,
                  spreadRadius: 2,
                )
              ],
            ),
            child: QrImageView(
              data: _serverUrl,
              version: QrVersions.auto,
              size: 200,
            ),
          ),
          const SizedBox(height: 20),

          const Text(
            'Scan QR Code or open URL on PC',
            style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),

          // URL Display
          GestureDetector(
            onTap: () {},
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withAlpha(15),
                borderRadius: BorderRadius.circular(14),
                border:
                    Border.all(color: const Color(0xFF3B82F6).withAlpha(60)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.link_rounded,
                      color: Color(0xFF3B82F6), size: 20),
                  const SizedBox(width: 10),
                  Text(
                    _serverUrl,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF3B82F6),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),

          // Instructions
          _buildInstructionTile('1', 'Connect your PC to the same Wi-Fi network'),
          _buildInstructionTile('2', 'Open a browser and go to the URL above'),
          _buildInstructionTile('3', 'You can send/receive files from the browser'),

          const SizedBox(height: 28),

          // Files count
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.divider),
            ),
            child: Row(
              children: [
                const Icon(Icons.folder_rounded, color: Color(0xFFF59E0B)),
                const SizedBox(width: 12),
                Text(
                  '${_sharedFiles.whereType<File>().length} files available for download',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionTile(String step, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: const Color(0xFF16A34A),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                step,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 13),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                text,
                style: const TextStyle(fontSize: 14, height: 1.4),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _buildHtml() {
    return '''<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>File Share - Web Access</title>
<style>
  * { box-sizing: border-box; margin: 0; padding: 0; }
  body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; background: #f8fafc; color: #0f172a; }
  .header { background: linear-gradient(135deg, #16a34a, #15803d); padding: 20px 24px; color: white; display: flex; align-items: center; gap: 12px; }
  .header h1 { font-size: 22px; font-weight: 700; }
  .container { max-width: 720px; margin: 0 auto; padding: 24px 16px; }
  .card { background: white; border-radius: 16px; padding: 20px; margin-bottom: 20px; box-shadow: 0 1px 3px rgba(0,0,0,0.1); }
  .card h2 { font-size: 16px; font-weight: 700; margin-bottom: 16px; color: #374151; }
  .upload-area { border: 2px dashed #d1d5db; border-radius: 12px; padding: 32px; text-align: center; cursor: pointer; transition: all 0.2s; }
  .upload-area:hover { border-color: #16a34a; background: #f0fdf4; }
  .upload-area input { display: none; }
  .btn { display: inline-block; padding: 10px 20px; border-radius: 10px; border: none; cursor: pointer; font-weight: 600; font-size: 14px; transition: all 0.2s; }
  .btn-green { background: #16a34a; color: white; } .btn-green:hover { background: #15803d; }
  .btn-blue { background: #3b82f6; color: white; } .btn-blue:hover { background: #2563eb; }
  .file-item { display: flex; align-items: center; justify-content: space-between; padding: 12px; border-radius: 10px; background: #f8fafc; margin-bottom: 8px; }
  .file-name { font-weight: 500; font-size: 14px; flex: 1; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
  .file-size { font-size: 12px; color: #6b7280; margin: 0 12px; }
  progress { width: 100%; height: 8px; border-radius: 4px; margin-top: 8px; }
  .status { font-size: 13px; color: #16a34a; font-weight: 600; margin-top: 4px; }
</style>
</head>
<body>
<div class="header">
  <svg width="28" height="28" fill="white" viewBox="0 0 24 24"><path d="M18 16.08c-.76 0-1.44.3-1.96.77L8.91 12.7c.05-.23.09-.46.09-.7s-.04-.47-.09-.7l7.05-4.11c.54.5 1.25.81 2.04.81 1.66 0 3-1.34 3-3s-1.34-3-3-3-3 1.34-3 3c0 .24.04.47.09.7L8.04 9.81C7.5 9.31 6.79 9 6 9c-1.66 0-3 1.34-3 3s1.34 3 3 3c.79 0 1.5-.31 2.04-.81l7.12 4.16c-.05.21-.08.43-.08.65 0 1.61 1.31 2.92 2.92 2.92s2.92-1.31 2.92-2.92c0-1.61-1.31-2.92-2.92-2.92z"/></svg>
  <h1>File Share</h1>
</div>
<div class="container">
  <div class="card">
    <h2>📤 Upload Files to Device</h2>
    <div class="upload-area" onclick="document.getElementById('fileInput').click()">
      <input type="file" id="fileInput" multiple onchange="uploadFiles(this.files)">
      <div style="font-size:40px;margin-bottom:12px">📁</div>
      <p style="font-weight:600;font-size:15px">Click to select files or drag & drop</p>
      <p style="font-size:13px;color:#6b7280;margin-top:6px">Files will be saved to FileShare/Received on the device</p>
    </div>
    <div id="uploadList" style="margin-top:16px"></div>
  </div>
  <div class="card">
    <h2>📥 Download Files from Device</h2>
    <div id="fileList"><p style="color:#6b7280;font-size:14px">Loading files...</p></div>
  </div>
</div>
<script>
  async function loadFiles() {
    try {
      const res = await fetch('/api/files');
      const data = await res.json();
      const list = document.getElementById('fileList');
      if (!data.files || !data.files.length) {
        list.innerHTML = '<p style="color:#6b7280;font-size:14px">No files available yet</p>'; return;
      }
      list.innerHTML = data.files.map(f => {
        const kb = (f.size/1024).toFixed(1);
        return '<div class="file-item"><span class="file-name">📄 '+f.name+'</span><span class="file-size">'+kb+' KB</span><a class="btn btn-blue" href="/download/'+encodeURIComponent(f.name)+'" download>Download</a></div>';
      }).join('');
    } catch(e) { document.getElementById('fileList').innerHTML='<p style="color:red">Error loading files</p>'; }
  }
  async function uploadFiles(files) {
    const ul = document.getElementById('uploadList');
    for (const file of files) {
      const div = document.createElement('div');
      div.style = 'padding:10px;background:#f0fdf4;border-radius:8px;margin-bottom:8px';
      div.innerHTML = '<div style="font-weight:600;font-size:13px">'+file.name+'</div><progress value="0" max="100"></progress><div class="status">Uploading...</div>';
      ul.prepend(div);
      try {
        const res = await fetch('/upload', { method:'POST', headers:{'x-filename':file.name}, body: file });
        const data = await res.json();
        div.querySelector('progress').value = 100;
        div.querySelector('.status').textContent = data.success ? '✅ Uploaded successfully' : '❌ Upload failed';
        loadFiles();
      } catch(e) { div.querySelector('.status').textContent = '❌ Error: '+e.message; }
    }
  }
  loadFiles();
</script>
</body>
</html>''';
  }
}
