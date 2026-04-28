import 'package:flutter/material.dart';

class StickerToolsPanel extends StatelessWidget {
  final Function(String) onStickerSelected;

  const StickerToolsPanel({
    super.key,
    required this.onStickerSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1E), // Dark background matching Instagram
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle indicator
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.white30,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Search bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.search, color: Colors.white54, size: 20),
                const SizedBox(width: 10),
                const Text('Search', style: TextStyle(color: Colors.white54, fontSize: 16)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          
          // Sticker Grid
          Flexible(
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 12,
                runSpacing: 16,
                alignment: WrapAlignment.center,
                children: [
                  _buildStickerItem('Location', Icons.location_on, Colors.purpleAccent, () => onStickerSelected('location')),
                  _buildStickerItem('Mention', Icons.alternate_email, Colors.orange, () => onStickerSelected('mention')),
                  _buildStickerItem('Music', Icons.music_note, Colors.pinkAccent, () => onStickerSelected('music')),
                  _buildStickerItem('Photo', Icons.photo, Colors.greenAccent, () => onStickerSelected('photo')),
                  _buildStickerItem('GIF', Icons.gif_box, Colors.green, () => onStickerSelected('gif')),
                  _buildStickerItem('Add Yours', Icons.add_box, Colors.pink, () => onStickerSelected('add_yours')),
                  _buildStickerItem('Frames', Icons.filter_frames, Colors.orangeAccent, () => onStickerSelected('frames')),
                  _buildStickerItem('Questions', Icons.help_outline, Colors.purple, () => onStickerSelected('questions')),
                  _buildStickerItem('Cutouts', Icons.cut, Colors.green, () => onStickerSelected('cutouts')),
                  _buildStickerItem('Highlight', Icons.favorite_border, Colors.pink, () => onStickerSelected('highlight')),
                  _buildStickerItem('Avatar', Icons.person, Colors.blueGrey, () => onStickerSelected('avatar')),
                  _buildStickerItem('Poll', Icons.poll, Colors.cyan, () => onStickerSelected('poll')),
                  _buildStickerItem('Link', Icons.link, Colors.blueAccent, () => onStickerSelected('link')),
                  _buildStickerItem('Hashtag', Icons.tag, Colors.redAccent, () => onStickerSelected('hashtag')),
                  _buildStickerItem('Countdown', Icons.timer, Colors.purpleAccent, () => onStickerSelected('countdown')),
                  _buildStickerItem('Text', Icons.text_fields, Colors.orange, () => onStickerSelected('text')),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStickerItem(String title, IconData icon, Color iconColor, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100, // Fixed width for wrap items to form roughly a grid
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
