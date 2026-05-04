import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import '../../core/theme/app_theme.dart';
import '../../core/utils/file_manager.dart';
import '../widgets/premium_widgets.dart';

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
        Map<Permission, PermissionStatus> statuses = await [
          Permission.photos,
          Permission.videos,
          Permission.audio,
        ].request();
        granted = statuses.values.every((s) => s.isGranted);
        
        if (!granted) {
          granted = await Permission.storage.request().isGranted;
        }
      }
    } else {
      granted = true;
    }

    setState(() => _hasPermission = granted);

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // === PREMIUM HEADER ===
          SliverAppBar(
            pinned: true,
            floating: true,
            expandedHeight: 160,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            elevation: 0,
            title: Text(
              'Magico Files',
              style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
                onPressed: _loadFiles,
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Padding(
                padding: const EdgeInsets.fromLTRB(20, 100, 20, 0),
                child: TextField(
                  onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
                  style: GoogleFonts.inter(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Search your magic folder...',
                    hintStyle: GoogleFonts.inter(color: AppColors.textLight),
                    prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
                    filled: true,
                    fillColor: isDark ? AppColors.darkCard : Colors.grey[100],
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                ),
              ),
            ),
          ),

          // === CATEGORY TABS ===
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: TabBar(
                controller: _tabController,
                isScrollable: false,
                indicatorColor: AppColors.primary,
                indicatorWeight: 3,
                indicatorSize: TabBarIndicatorSize.label,
                labelStyle: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700),
                unselectedLabelStyle: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500),
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textLight,
                tabs: const [
                  Tab(text: 'All'),
                  Tab(text: 'Images'),
                  Tab(text: 'Videos'),
                  Tab(text: 'Docs'),
                ],
              ),
            ),
          ),

          // === FILE CONTENT ===
          if (_isLoading)
            const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
          else if (!_hasPermission)
            SliverFillRemaining(child: _buildPermissionGate())
          else
            SliverFillRemaining(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildFileListView('All', isDark),
                  _buildFileListView('Images', isDark),
                  _buildFileListView('Videos', isDark),
                  _buildFileListView('Documents', isDark),
                ],
              ),
            ),
        ],
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
            Icon(Icons.lock_open_rounded, size: 80, color: AppColors.primary.withOpacity(0.2)),
            const SizedBox(height: 24),
            Text(
              'Permission Required',
              style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            Text(
              'Magico needs storage access to manage your transferred files securely.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: AppColors.textLight),
            ),
            const SizedBox(height: 32),
            PremiumButton(
              text: 'Grant Access',
              onPressed: _checkPermissionAndLoad,
              width: 200,
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => openAppSettings(),
              child: Text('Open App Settings', style: GoogleFonts.inter(color: AppColors.textLight)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileListView(String category, bool isDark) {
    var files = _categorizedFiles[category] ?? [];
    
    if (_searchQuery.isNotEmpty) {
      files = files.where((f) => p.basename(f.path).toLowerCase().contains(_searchQuery)).toList();
    }

    if (files.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_off_rounded, size: 64, color: AppColors.textLight.withOpacity(0.1)),
            const SizedBox(height: 16),
            Text(
              'Folder is empty',
              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textLight),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
      itemCount: files.length,
      itemBuilder: (context, index) {
        final file = files[index];
        final fileName = p.basename(file.path);
        final stats = file.statSync();
        final size = FileManager.getFileSizeString(stats.size);
        final date = DateFormat.yMMMd().format(stats.modified);
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: PremiumGlassCard(
            borderRadius: 16,
            padding: EdgeInsets.zero,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: _getFileIcon(fileName),
              title: Text(
                fileName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14),
              ),
              subtitle: Text(
                '$size • $date',
                style: GoogleFonts.inter(fontSize: 12, color: AppColors.textLight),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.more_vert_rounded, size: 20),
                onPressed: () => _showFileOptions(file),
              ),
              onTap: () => _handleFileAction('open', file),
            ),
          ).animate().fadeIn(delay: (index * 50).ms).slideX(begin: 0.05),
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(iconData, color: color, size: 24),
    );
  }

  void _showFileOptions(File file) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => PremiumGlassCard(
        borderRadius: 32,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: AppColors.textLight.withOpacity(0.2), borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 24),
            Text(p.basename(file.path), style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 24),
            _buildOption(Icons.open_in_new_rounded, 'Open File', () => _handleFileAction('open', file)),
            _buildOption(Icons.share_rounded, 'Share File', () => _handleFileAction('share', file)),
            _buildOption(Icons.delete_outline_rounded, 'Delete permanently', () => _handleFileAction('delete', file), isDestructive: true),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildOption(IconData icon, String label, VoidCallback onTap, {bool isDestructive = false}) {
    return ListTile(
      leading: Icon(icon, color: isDestructive ? Colors.redAccent : AppColors.primary),
      title: Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: isDestructive ? Colors.redAccent : null)),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }

  Future<void> _handleFileAction(String action, File file) async {
    if (action == 'open' || action == 'share') {
      await Share.shareXFiles([XFile(file.path)], text: 'Sharing file via Magico');
    } else if (action == 'delete') {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Delete File', style: GoogleFonts.poppins(fontWeight: FontWeight.w800)),
          content: Text('Delete ${p.basename(file.path)} permanently?'),
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












