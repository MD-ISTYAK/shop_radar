import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import '../../../../core/theme/app_theme.dart';
import '../../data/models/sharing_models.dart';

enum SendTab { apps, files, videos, photos, music }

class SendScreen extends ConsumerStatefulWidget {
  const SendScreen({super.key});

  @override
  ConsumerState<SendScreen> createState() => _SendScreenState();
}

class _SendScreenState extends ConsumerState<SendScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Set<String> _selectedPaths = {};
  int _selectedSize = 0;

  // Data holders
  List<AssetEntity> _photos = [];
  List<AssetEntity> _videos = [];
  List<AssetEntity> _music = [];
  List<_AppInfo> _apps = [];
  List<File> _allFiles = [];

  bool _loading = true;
  bool _mediaPermissionDenied = false;
  String _searchQuery = '';
  int _photoPage = 0;
  int _videoPage = 0;
  bool _hasMorePhotos = true;
  bool _hasMoreVideos = true;
  static const int _pageSize = 80;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        // Refresh media when switching to Videos (2), Photos (3), or Music (4)
        if (_tabController.index >= 2) {
          _refreshMedia();
        }
        setState(() {});
      }
    });
    // Register real-time change callback (ContentObserver equivalent)
    PhotoManager.addChangeCallback(_onMediaChanged);
    PhotoManager.startChangeNotify();
    _loadContent();
  }

  @override
  void dispose() {
    PhotoManager.removeChangeCallback(_onMediaChanged);
    PhotoManager.stopChangeNotify();
    _tabController.dispose();
    super.dispose();
  }

  /// Called by PhotoManager when device media changes (new photo taken, etc.)
  void _onMediaChanged(MethodCall call) {
    if (mounted) {
      _refreshMedia();
    }
  }

  Future<void> _loadContent() async {
    setState(() => _loading = true);
    await _loadMedia();
    await _loadInstalledApps();
    await _loadFiles();
    if (mounted) setState(() => _loading = false);
  }

  /// Lightweight refresh: only reloads media (called on tab switch or pull-to-refresh)
  Future<void> _refreshMedia() async {
    _photoPage = 0;
    _videoPage = 0;
    _hasMorePhotos = true;
    _hasMoreVideos = true;
    await _loadMedia();
    if (mounted) setState(() {});
  }

  Future<void> _loadMedia() async {
    // Request permissions properly for Android 13+ and below
    final PermissionState ps = await PhotoManager.requestPermissionExtend();
    if (!ps.isAuth && !ps.hasAccess) {
      if (mounted) setState(() => _mediaPermissionDenied = true);
      return;
    }
    setState(() => _mediaPermissionDenied = false);

    // FilterOptionGroup: sort by createDate DESCENDING (newest first)
    final FilterOptionGroup sortNewest = FilterOptionGroup(
      orders: [
        const OrderOption(type: OrderOptionType.createDate, asc: false),
      ],
    );

    // Get the unified 'All' album (hasAll: true, index 0 = all photos/videos)
    // This includes DCIM/Camera, Screenshots, WhatsApp, Downloads, etc.
    final photoAlbums = await PhotoManager.getAssetPathList(
      type: RequestType.image,
      hasAll: true,
      filterOption: sortNewest,
    );
    final videoAlbums = await PhotoManager.getAssetPathList(
      type: RequestType.video,
      hasAll: true,
      filterOption: sortNewest,
    );
    final audioAlbums = await PhotoManager.getAssetPathList(
      type: RequestType.audio,
      hasAll: true,
      filterOption: sortNewest,
    );

    // Find the true 'All' album (name is '' or 'Recent' or largest count)
    AssetPathEntity? _findAllAlbum(List<AssetPathEntity> albums) {
      if (albums.isEmpty) return null;
      // On Android, hasAll=true places the all-media album first
      return albums.first;
    }

    final photoAll = _findAllAlbum(photoAlbums);
    final videoAll = _findAllAlbum(videoAlbums);
    final audioAll = _findAllAlbum(audioAlbums);

    if (photoAll != null) {
      _photos = await photoAll.getAssetListPaged(
          page: _photoPage, size: _pageSize);
    }
    if (videoAll != null) {
      _videos = await videoAll.getAssetListPaged(
          page: _videoPage, size: _pageSize);
    }
    if (audioAll != null) {
      _music = await audioAll.getAssetListPaged(page: 0, size: 200);
    }
  }

  /// Load next page of photos (pagination)
  Future<void> _loadMorePhotos() async {
    if (!_hasMorePhotos) return;
    final FilterOptionGroup sortNewest = FilterOptionGroup(
      orders: [const OrderOption(type: OrderOptionType.createDate, asc: false)],
    );
    final albums = await PhotoManager.getAssetPathList(
      type: RequestType.image, hasAll: true, filterOption: sortNewest);
    if (albums.isEmpty) return;
    _photoPage++;
    final more = await albums.first.getAssetListPaged(page: _photoPage, size: _pageSize);
    if (more.isEmpty) {
      _hasMorePhotos = false;
    } else {
      if (mounted) setState(() => _photos.addAll(more));
    }
  }

  /// Load next page of videos (pagination)
  Future<void> _loadMoreVideos() async {
    if (!_hasMoreVideos) return;
    final FilterOptionGroup sortNewest = FilterOptionGroup(
      orders: [const OrderOption(type: OrderOptionType.createDate, asc: false)],
    );
    final albums = await PhotoManager.getAssetPathList(
      type: RequestType.video, hasAll: true, filterOption: sortNewest);
    if (albums.isEmpty) return;
    _videoPage++;
    final more = await albums.first.getAssetListPaged(page: _videoPage, size: _pageSize);
    if (more.isEmpty) {
      _hasMoreVideos = false;
    } else {
      if (mounted) setState(() => _videos.addAll(more));
    }
  }

  Future<void> _loadInstalledApps() async {
    if (!Platform.isAndroid) return;
    // Scan all common directories where APK files can be found
    final apkSearchDirs = [
      '/storage/emulated/0/Download',
      '/storage/emulated/0/Downloads',
      '/storage/emulated/0/WhatsApp/Media/WhatsApp Documents',
      '/storage/emulated/0/Telegram',
      '/storage/emulated/0/Android/data',
      '/storage/emulated/0/APKs',
      '/storage/emulated/0/APK',
      '/storage/emulated/0/MIUI/backup/AllBackup',
    ];
    try {
      final entries = <_AppInfo>[];
      final seen = <String>{};
      for (final dirPath in apkSearchDirs) {
        final dir = Directory(dirPath);
        if (!await dir.exists()) continue;
        try {
          await for (final entity in dir.list(recursive: true)) {
            if (entity is File &&
                entity.path.toLowerCase().endsWith('.apk') &&
                !seen.contains(entity.path)) {
              seen.add(entity.path);
              int size = 0;
              try { size = await entity.length(); } catch (_) {}
              entries.add(_AppInfo(
                name: p.basenameWithoutExtension(entity.path),
                apkPath: entity.path,
                sizeBytes: size,
              ));
            }
          }
        } catch (_) {} // skip permission-denied dirs
      }
      // Sort by name
      entries.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      _apps = entries;
    } catch (_) {}
  }

  Future<void> _loadFiles() async {
    if (!Platform.isAndroid) {
      // iOS: use path_provider
      try {
        final docDir = await getApplicationDocumentsDirectory();
        final files = <File>[];
        await for (final entity in docDir.list(recursive: true)) {
          if (entity is File && !p.basename(entity.path).startsWith('.')) {
            files.add(entity);
          }
        }
        _allFiles = files
          ..sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
      } catch (_) {}
      return;
    }

    // Android: scan all common user-accessible subdirectories
    final scanDirs = [
      '/storage/emulated/0/Download',
      '/storage/emulated/0/Downloads',
      '/storage/emulated/0/Documents',
      '/storage/emulated/0/WhatsApp/Media/WhatsApp Documents',
      '/storage/emulated/0/WhatsApp/Media/WhatsApp Images',
      '/storage/emulated/0/WhatsApp/Media/WhatsApp Video',
      '/storage/emulated/0/WhatsApp/Media/WhatsApp Audio',
      '/storage/emulated/0/Telegram',
      '/storage/emulated/0/DCIM',
      '/storage/emulated/0/Pictures',
      '/storage/emulated/0/Movies',
      '/storage/emulated/0/Music',
      '/storage/emulated/0/Ringtones',
      '/storage/emulated/0/Notifications',
      '/storage/emulated/0/Alarms',
      '/storage/emulated/0/Recordings',
      '/storage/emulated/0/Android/media',
    ];

    try {
      final files = <File>[];
      final seen = <String>{};
      for (final dirPath in scanDirs) {
        final dir = Directory(dirPath);
        if (!await dir.exists()) continue;
        try {
          await for (final entity in dir.list(recursive: true)) {
            if (entity is File &&
                !seen.contains(entity.path) &&
                !p.basename(entity.path).startsWith('.')) {
              seen.add(entity.path);
              files.add(entity);
            }
          }
        } catch (_) {} // skip permission-denied dirs
      }
      _allFiles = files
        ..sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
    } catch (_) {}
  }

  // Manual file picker fallback
  Future<void> _pickFilesManually() async {
    final result = await FilePicker.pickFiles(
      allowMultiple: true,
      type: FileType.any,
    );
    if (result == null) return;
    setState(() {
      for (final f in result.files) {
        if (f.path != null) {
          final file = File(f.path!);
          if (!_allFiles.any((e) => e.path == f.path)) {
            _allFiles.insert(0, file);
          }
          _toggleSelection(f.path!, f.size);
        }
      }
    });
  }

  Future<void> _pickApksManually() async {
    final result = await FilePicker.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['apk'],
    );
    if (result == null) return;
    setState(() {
      for (final f in result.files) {
        if (f.path != null) {
          final info = _AppInfo(
            name: p.basenameWithoutExtension(f.path!),
            apkPath: f.path!,
            sizeBytes: f.size,
          );
          if (!_apps.any((e) => e.apkPath == f.path)) {
            _apps.insert(0, info);
          }
          _toggleSelection(f.path!, f.size);
        }
      }
    });
  }

  void _toggleSelection(String path, int sizeBytes) {
    setState(() {
      if (_selectedPaths.contains(path)) {
        _selectedPaths.remove(path);
        _selectedSize -= sizeBytes;
      } else {
        _selectedPaths.add(path);
        _selectedSize += sizeBytes;
      }
    });
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    if (bytes < 1024 * 1024 * 1024)
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)}GB';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Send', style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          // Search bar
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
                style: const TextStyle(fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'Search...',
                  hintStyle: TextStyle(fontSize: 14),
                  prefixIcon: Icon(Icons.search, size: 20),
                  border: InputBorder.none,
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  isDense: true,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          unselectedLabelStyle:
              const TextStyle(fontWeight: FontWeight.w400, fontSize: 14),
          indicator: UnderlineTabIndicator(
            borderSide: const BorderSide(
              width: 3,
              color: Color(0xFF16A34A),
            ),
            borderRadius: BorderRadius.circular(2),
          ),
          labelColor: const Color(0xFF16A34A),
          unselectedLabelColor: AppColors.textSecondary,
          tabs: const [
            Tab(text: 'Apps'),
            Tab(text: 'Files'),
            Tab(text: 'Videos'),
            Tab(text: 'Photos'),
            Tab(text: 'Music'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildAppsTab(),
                _buildFilesTab(),
                _buildMediaGridTab(_videos, RequestType.video),
                _buildMediaGridTab(_photos, RequestType.image),
                _buildMusicTab(),
              ],
            ),
      bottomNavigationBar: _buildBottomBar(context),
    );
  }

  Widget _buildAppsTab() {
    final filtered = _apps
        .where((a) =>
            _searchQuery.isEmpty ||
            a.name.toLowerCase().contains(_searchQuery))
        .toList();

    return Column(
      children: [
        // Browse button
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
          child: GestureDetector(
            onTap: _pickApksManually,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF16A34A).withAlpha(15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: const Color(0xFF16A34A).withAlpha(60)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.folder_open_rounded,
                      color: Color(0xFF16A34A), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Browse & Pick APK Files',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF16A34A),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (filtered.isEmpty)
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.android_rounded,
                      size: 64, color: AppColors.divider),
                  const SizedBox(height: 12),
                  const Text(
                    'No APK files found',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 6),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      'APKs will appear here if found in\nDownloads, WhatsApp, or Telegram folders.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 13, color: AppColors.textLight),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final app = filtered[index];
                final isSelected = _selectedPaths.contains(app.apkPath);

                return GestureDetector(
                  onTap: () => _toggleSelection(app.apkPath, app.sizeBytes),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF16A34A).withAlpha(15)
                          : Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF16A34A).withAlpha(80)
                            : AppColors.divider,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF16A34A).withAlpha(20),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.android_rounded,
                              color: Color(0xFF16A34A), size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                app.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14),
                              ),
                              Text(
                                _formatSize(app.sizeBytes),
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        isSelected
                            ? const Icon(Icons.check_circle_rounded,
                                color: Color(0xFF16A34A))
                            : const Icon(Icons.circle_outlined,
                                color: AppColors.divider),
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

  Widget _buildFilesTab() {
    final filtered = _allFiles
        .where((f) =>
            _searchQuery.isEmpty ||
            p.basename(f.path).toLowerCase().contains(_searchQuery))
        .toList();

    return Column(
      children: [
        // Browse button
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
          child: GestureDetector(
            onTap: _pickFilesManually,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withAlpha(15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: const Color(0xFF3B82F6).withAlpha(60)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_circle_outline_rounded,
                      color: Color(0xFF3B82F6), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Browse & Pick Files',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF3B82F6),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (filtered.isEmpty)
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.folder_open_rounded,
                      size: 64, color: AppColors.divider),
                  const SizedBox(height: 12),
                  const Text(
                    'No files found',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 6),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      'Files will load from Downloads, Documents,\nWhatsApp, Telegram and other folders.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 13, color: AppColors.textLight),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final file = filtered[index];
                final name = p.basename(file.path);
                int size = 0;
                try { size = file.lengthSync(); } catch (_) {}
                final isSelected = _selectedPaths.contains(file.path);

                return _FileListTile(
                  name: name,
                  size: size,
                  isSelected: isSelected,
                  onTap: () => _toggleSelection(file.path, size),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildMediaGridTab(List<AssetEntity> assets, RequestType type) {
    final isPhoto = type == RequestType.image;

    // Show permission denied state
    if (_mediaPermissionDenied) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.no_photography_rounded,
                  size: 64, color: AppColors.textLight),
              const SizedBox(height: 16),
              const Text(
                'Media Permission Required',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
              const Text(
                'Grant storage/media permission to browse photos & videos',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 13, color: AppColors.textLight),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () async {
                  await PhotoManager.openSetting();
                  await _refreshMedia();
                },
                icon: const Icon(Icons.settings_rounded, size: 18),
                label: const Text('Open Settings'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A)),
              ),
            ],
          ),
        ),
      );
    }

    final filtered = assets
        .where((a) =>
            _searchQuery.isEmpty ||
            (a.title ?? '').toLowerCase().contains(_searchQuery))
        .toList();

    return RefreshIndicator(
      color: const Color(0xFF16A34A),
      onRefresh: _refreshMedia,
      child: CustomScrollView(
        slivers: [
          // Refresh hint + count header
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(
                children: [
                  Icon(
                    isPhoto ? Icons.photo_library_rounded : Icons.video_library_rounded,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${filtered.length}${_hasMorePhotos && isPhoto || _hasMoreVideos && !isPhoto ? '+' : ''} ${isPhoto ? 'photos' : 'videos'} · Newest first',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _refreshMedia,
                    child: const Row(
                      children: [
                        Icon(Icons.refresh_rounded,
                            size: 16, color: Color(0xFF16A34A)),
                        SizedBox(width: 4),
                        Text(
                          'Refresh',
                          style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF16A34A),
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (filtered.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isPhoto ? Icons.photo_outlined : Icons.videocam_outlined,
                      size: 64,
                      color: AppColors.divider,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      isPhoto ? 'No photos found' : 'No videos found',
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Pull down to refresh',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.textLight),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 2,
                crossAxisSpacing: 2,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  // Trigger load-more when near end
                  if (index == filtered.length - 8) {
                    if (isPhoto) _loadMorePhotos();
                    if (!isPhoto) _loadMoreVideos();
                  }
                  final asset = filtered[index];
                  final isSelected = _selectedPaths.contains(asset.id);

                  return _MediaThumbnailTile(
                    key: ValueKey(asset.id),
                    asset: asset,
                    isSelected: isSelected,
                    isVideo: type == RequestType.video,
                    onTap: () async {
                      // Use asset ID as the key and resolve file path lazily
                      final file = await asset.file;
                      if (file != null && mounted) {
                        int sz = 0;
                        try { sz = file.lengthSync(); } catch (_) {}
                        _toggleSelection(file.path, sz);
                        // Update the selected set with the real path
                        if (_selectedPaths.contains(asset.id)) {
                          setState(() {
                            _selectedPaths.remove(asset.id);
                            _selectedPaths.add(file.path);
                          });
                        }
                      } else {
                        // Fallback to asset ID if file not available
                        _toggleSelection(asset.id, 0);
                      }
                    },
                  );
                },
                childCount: filtered.length,
              ),
            ),

          // Load more indicator
          if ((isPhoto && _hasMorePhotos || !isPhoto && _hasMoreVideos) &&
              filtered.isNotEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Color(0xFF16A34A),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMusicTab() {
    final filtered = _music
        .where((a) =>
            _searchQuery.isEmpty ||
            (a.title ?? '').toLowerCase().contains(_searchQuery))
        .toList();

    return RefreshIndicator(
      color: const Color(0xFF16A34A),
      onRefresh: _refreshMedia,
      child: filtered.isEmpty
          ? const Center(child: Text('No music found'))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final asset = filtered[index];
                final isSelected = _selectedPaths.contains(asset.id);

                return ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B5CF6).withAlpha(20),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.music_note_rounded,
                        color: Color(0xFF8B5CF6)),
                  ),
                  title: Text(
                    asset.title ?? 'Unknown',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: const Text('Audio File',
                      style: TextStyle(fontSize: 12)),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle_rounded,
                          color: Color(0xFF16A34A))
                      : const Icon(Icons.circle_outlined,
                          color: AppColors.divider),
                  onTap: () => _toggleSelection(asset.id, 0),
                );
              },
            ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    final count = _selectedPaths.length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.divider.withAlpha(80),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Text(
                count == 0
                    ? '0 SELECTED'
                    : '$count SELECTED • ${_formatSize(_selectedSize)}',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: count == 0
                      ? AppColors.textSecondary
                      : AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: count == 0
                    ? null
                    : () {
                        Navigator.pushNamed(
                          context,
                          '/sharing/discovery',
                          arguments: {
                            'selectedPaths': _selectedPaths.toList(),
                            'totalSize': _selectedSize,
                          },
                        );
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF16A34A),
                  disabledBackgroundColor: AppColors.divider,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: const Text(
                  'NEXT',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FileListTile extends StatelessWidget {
  final String name;
  final int size;
  final bool isSelected;
  final VoidCallback onTap;

  const _FileListTile({
    required this.name,
    required this.size,
    required this.isSelected,
    required this.onTap,
  });

  String _formatSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    if (bytes < 1024 * 1024 * 1024)
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)}GB';
  }

  IconData _getIcon() {
    final ext = p.extension(name).toLowerCase();
    if (['.jpg', '.jpeg', '.png', '.gif', '.webp'].contains(ext))
      return Icons.image_rounded;
    if (['.mp4', '.mov', '.avi', '.mkv'].contains(ext))
      return Icons.movie_rounded;
    if (['.mp3', '.aac', '.wav', '.flac'].contains(ext))
      return Icons.music_note_rounded;
    if (ext == '.pdf') return Icons.picture_as_pdf_rounded;
    if (['.doc', '.docx'].contains(ext)) return Icons.description_rounded;
    if (['.xls', '.xlsx'].contains(ext)) return Icons.table_chart_rounded;
    if (['.zip', '.rar', '.tar'].contains(ext)) return Icons.archive_rounded;
    if (['.apk'].contains(ext)) return Icons.android_rounded;
    return Icons.insert_drive_file_rounded;
  }

  Color _getColor() {
    final ext = p.extension(name).toLowerCase();
    if (['.jpg', '.jpeg', '.png', '.gif', '.webp'].contains(ext))
      return const Color(0xFF3B82F6);
    if (['.mp4', '.mov', '.avi', '.mkv'].contains(ext))
      return const Color(0xFFEF4444);
    if (['.mp3', '.aac', '.wav', '.flac'].contains(ext))
      return const Color(0xFF8B5CF6);
    if (ext == '.pdf') return const Color(0xFFEF4444);
    if (['.doc', '.docx'].contains(ext)) return const Color(0xFF3B82F6);
    if (['.xls', '.xlsx'].contains(ext)) return const Color(0xFF16A34A);
    if (['.zip', '.rar', '.tar'].contains(ext))
      return const Color(0xFFF59E0B);
    if (['.apk'].contains(ext)) return const Color(0xFF16A34A);
    return AppColors.textSecondary;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF16A34A).withAlpha(15)
              : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF16A34A).withAlpha(80)
                : AppColors.divider,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _getColor().withAlpha(20),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(_getIcon(), color: _getColor(), size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.w500, fontSize: 14),
                  ),
                  Text(
                    _formatSize(size),
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            isSelected
                ? const Icon(Icons.check_circle_rounded,
                    color: Color(0xFF16A34A))
                : const Icon(Icons.circle_outlined, color: AppColors.divider),
          ],
        ),
      ),
    );
  }
}

class _AppInfo {
  final String name;
  final String apkPath;
  final int sizeBytes;

  _AppInfo({
    required this.name,
    required this.apkPath,
    required this.sizeBytes,
  });
}

class _MediaThumbnailTile extends StatelessWidget {
  final AssetEntity asset;
  final bool isSelected;
  final bool isVideo;
  final VoidCallback onTap;

  const _MediaThumbnailTile({
    super.key,
    required this.asset,
    required this.isSelected,
    required this.isVideo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Efficiently load thumbnail using AssetEntityImage (provided by photo_manager)
          AssetEntityImage(
            asset,
            isOriginal: false,
            thumbnailSize: const ThumbnailSize(250, 250),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              color: AppColors.divider,
              child: const Icon(Icons.broken_image_outlined,
                  color: AppColors.textLight, size: 24),
            ),
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(color: AppColors.divider);
            },
          ),

          // Video duration overlay
          if (isVideo)
            Positioned(
              bottom: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(150),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.play_arrow_rounded,
                        color: Colors.white, size: 10),
                    const SizedBox(width: 2),
                    Text(
                      _formatDuration(asset.duration),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Selection overlay
          if (isSelected)
            Container(
              color: const Color(0xFF16A34A).withAlpha(100),
              child: const Center(
                child: Icon(
                  Icons.check_circle_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
          
          // New/Recent Badge (Optional aesthetic)
          if (DateTime.now().difference(asset.createDateTime).inHours < 24)
            Positioned(
              top: 4,
              left: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF16A34A),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'NEW',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    final min = seconds ~/ 60;
    final sec = seconds % 60;
    return '$min:${sec.toString().padLeft(2, '0')}';
  }
}
