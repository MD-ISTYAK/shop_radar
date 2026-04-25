import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import '../../core/theme/app_theme.dart';
import '../../core/utils/file_manager.dart';

class MagicoFilesScreen extends StatefulWidget {
  const MagicoFilesScreen({super.key});

  @override
  State<MagicoFilesScreen> createState() => _MagicoFilesScreenState();
}

class _MagicoFilesScreenState extends State<MagicoFilesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, List<File>> _categorizedFiles = {
    'All': [],
    'Images': [],
    'Videos': [],
    'Documents': [],
  };
  bool _isLoading = true;
  bool _hasPermission = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _checkPermissionAndLoad();
  }

  Future<void> _checkPermissionAndLoad() async {
    setState(() => _isLoading = true);
    
    bool granted = false;
    if (Platform.isAndroid) {
      if (await Permission.manageExternalStorage.isGranted) {
         granted = true;
      } else {
        // Try requesting media permissions for Android 13+
        Map<Permission, PermissionStatus> statuses = await [
          Permission.photos,
          Permission.videos,
          Permission.audio,
        ].request();
        granted = statuses.values.every((s) => s.isGranted);
        
        if (!granted) {
          // Try legacy storage permission
          granted = await Permission.storage.request().isGranted;
        }
      }
    } else {
      granted = true; // iOS handled differently or don't need explicit storage for app docs
    }

    setState(() {
      _hasPermission = granted;
    });

    if (granted) {
      await _loadFiles();
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadFiles() async {
    final files = await FileManager.listFiles();
    setState(() {
      _categorizedFiles = FileManager.categorizeFiles(files);
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Magico Files', style: TextStyle(fontWeight: FontWeight.bold)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(110),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
                  decoration: InputDecoration(
                    hintText: 'Search files...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Theme.of(context).cardColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                ),
              ),
              TabBar(
                controller: _tabController,
                isScrollable: false,
                indicatorColor: AppColors.primary,
                labelColor: AppColors.primary,
                unselectedLabelColor: Theme.of(context).textTheme.bodyMedium?.color,
                tabs: const [
                  Tab(text: 'All'),
                  Tab(text: 'Images'),
                  Tab(text: 'Videos'),
                  Tab(text: 'Docs'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : !_hasPermission
              ? _buildPermissionGate()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildFileList('All'),
                    _buildFileList('Images'),
                    _buildFileList('Videos'),
                    _buildFileList('Documents'),
                  ],
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadFiles,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.refresh, color: Colors.white),
      ),
    );
  }

  Widget _buildPermissionGate() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.security_rounded, size: 80, color: Theme.of(context).textTheme.bodySmall?.color),
            SizedBox(height: 24),
            const Text(
              'Storage Access Required',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Text(
              'To show and manage your files in the Magico folder, we need storage permission.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _checkPermissionAndLoad,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Grant Permission', style: TextStyle(color: Colors.white)),
            ),
            TextButton(
              onPressed: () => openAppSettings(),
              child: const Text('Open Settings'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileList(String category) {
    var files = _categorizedFiles[category] ?? [];
    
    if (_searchQuery.isNotEmpty) {
      files = files.where((f) => p.basename(f.path).toLowerCase().contains(_searchQuery)).toList();
    }

    if (files.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open_rounded, size: 64, color: Theme.of(context).textTheme.bodySmall?.color),
            SizedBox(height: 16),
            Text('No files found', style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 18)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: files.length,
      itemBuilder: (context, index) {
        final file = files[index];
        final fileName = p.basename(file.path);
        final stats = file.statSync();
        final size = FileManager.getFileSizeString(stats.size);
        final date = DateFormat.yMMMd().format(stats.modified);
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Theme.of(context).dividerColor.withAlpha(50)),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: _getFileIcon(fileName),
            title: Text(
              fileName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text('$size • $date', style: const TextStyle(fontSize: 12)),
            trailing: PopupMenuButton(
              icon: const Icon(Icons.more_vert),
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'open', child: Row(children: [Icon(Icons.open_in_new, size: 18), SizedBox(width: 8), Text('Open')])),
                const PopupMenuItem(value: 'share', child: Row(children: [Icon(Icons.share, size: 18), SizedBox(width: 8), Text('Share')])),
                const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline, size: 18, color: Colors.red), SizedBox(width: 8), Text('Delete', style: TextStyle(color: Colors.red))])),
              ],
              onSelected: (value) => _handleFileAction(value, file),
            ),
            onTap: () => _handleFileAction('open', file),
          ),
        );
      },
    );
  }

  Widget _getFileIcon(String fileName) {
    final ext = p.extension(fileName).toLowerCase();
    IconData iconData = Icons.insert_drive_file_rounded;
    Color color = Colors.grey;

    if (['.jpg', '.jpeg', '.png', '.gif', '.webp'].contains(ext)) {
      iconData = Icons.image_rounded;
      color = Colors.blue;
    } else if (['.mp4', '.mov', '.avi'].contains(ext)) {
      iconData = Icons.video_library_rounded;
      color = Colors.red;
    } else if (ext == '.pdf') {
      iconData = Icons.picture_as_pdf_rounded;
      color = Colors.orange;
    } else if (['.doc', '.docx'].contains(ext)) {
      iconData = Icons.description_rounded;
      color = Colors.blue.shade800;
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: (color ?? Colors.transparent).withAlpha(20),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(iconData, color: color, size: 28),
    );
  }

  Future<void> _handleFileAction(String action, File file) async {
    if (action == 'open' || action == 'share') {
      await Share.shareXFiles([XFile(file.path)], text: 'Sharing file from Shop Radar');
    } else if (action == 'delete') {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete File'),
          content: Text('Are you sure you want to delete ${p.basename(file.path)}?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
          ],
        ),
      );
      
      if (confirm == true) {
        await file.delete();
        _loadFiles();
      }
    }
  }
}











