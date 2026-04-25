import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import '../../../../core/theme/app_theme.dart';
import '../../data/models/sharing_models.dart';

class FileSelectorScreen extends StatefulWidget {
  final PeerDevice targetDevice;
  final String myName;

  const FileSelectorScreen({
    super.key,
    required this.targetDevice,
    required this.myName,
  });

  @override
  State<FileSelectorScreen> createState() => _FileSelectorScreenState();
}

class _FileSelectorScreenState extends State<FileSelectorScreen> {
  final List<File> _selectedFiles = [];

  Future<void> _pickFiles() async {
    final result = await FilePicker.pickFiles(allowMultiple: true);
    if (result != null) {
      setState(() {
        _selectedFiles.addAll(result.paths.where((path) => path != null).map((path) => File(path!)));
      });
    }
  }

  void _removeFile(int index) {
    setState(() => _selectedFiles.removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Send to ${widget.targetDevice.name}', style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          _buildDeviceHeader(),
          Expanded(
            child: _selectedFiles.isEmpty ? _buildEmptyState() : _buildFileList(),
          ),
          _buildActionFooter(),
        ],
      ),
    );
  }

  Widget _buildDeviceHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppColors.primary.withAlpha(10),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: AppColors.primary,
            child: Icon(Icons.devices, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.targetDevice.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text(widget.targetDevice.ip, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_circle_outline, size: 80, color: AppColors.textLight.withAlpha(100)),
          const SizedBox(height: 16),
          const Text('No files selected', style: TextStyle(fontSize: 18, color: AppColors.textSecondary)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _pickFiles,
            icon: const Icon(Icons.add),
            label: const Text('Add Files'),
          ),
        ],
      ),
    );
  }

  Widget _buildFileList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _selectedFiles.length,
      itemBuilder: (context, index) {
        final file = _selectedFiles[index];
        final name = p.basename(file.path);
        final size = (file.lengthSync() / (1024 * 1024)).toStringAsFixed(2);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: _getFileIcon(name),
            title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text('$size MB'),
            trailing: IconButton(
              icon: const Icon(Icons.close, color: AppColors.error),
              onPressed: () => _removeFile(index),
            ),
          ),
        );
      },
    );
  }

  Widget _getFileIcon(String fileName) {
    final ext = p.extension(fileName).toLowerCase();
    IconData iconData = Icons.insert_drive_file;
    Color color = AppColors.primary;

    if (['.jpg', '.jpeg', '.png', '.gif'].contains(ext)) {
      iconData = Icons.image;
      color = Colors.blue;
    } else if (['.mp4', '.mov', '.avi'].contains(ext)) {
      iconData = Icons.movie;
      color = Colors.red;
    } else if (ext == '.pdf') {
      iconData = Icons.picture_as_pdf;
      color = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: color.withAlpha(20), borderRadius: BorderRadius.circular(8)),
      child: Icon(iconData, color: color),
    );
  }

  Widget _buildActionFooter() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _pickFiles,
                icon: const Icon(Icons.add),
                label: const Text('Add More'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _selectedFiles.isEmpty
                    ? null
                    : () {
                        Navigator.pushReplacementNamed(
                          context,
                          '/sharing/transfer',
                          arguments: {
                            'device': widget.targetDevice,
                            'files': _selectedFiles,
                            'myName': widget.myName,
                          },
                        );
                      },
                icon: const Icon(Icons.send),
                label: const Text('Send All'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
