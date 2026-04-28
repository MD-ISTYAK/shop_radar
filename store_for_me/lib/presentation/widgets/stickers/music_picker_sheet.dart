import 'package:flutter/material.dart';
import '../../../../data/models/social_models.dart';
import '../../../../core/theme/app_theme.dart';

class MusicPickerSheet extends StatelessWidget {
  const MusicPickerSheet({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock royalty-free library
    final List<Map<String, String>> mockSongs = [
      {
        'id': 'bensound-acousticbreeze',
        'title': 'Acoustic Breeze',
        'artist': 'Bensound (Royalty Free)',
        'url': 'https://www.bensound.com/bensound-music/bensound-acousticbreeze.mp3'
      },
      {
        'id': 'bensound-creativeminds',
        'title': 'Creative Minds',
        'artist': 'Bensound (Royalty Free)',
        'url': 'https://www.bensound.com/bensound-music/bensound-creativeminds.mp3'
      },
      {
        'id': 'fma-lofi',
        'title': 'Lofi Chill',
        'artist': 'FMA Collection',
        'url': 'https://example.com/lofi.mp3'
      },
      {
        'id': 'audio-summer',
        'title': 'Summer Beats',
        'artist': 'AudioLibrary',
        'url': 'https://example.com/summer.mp3'
      },
      {
        'id': 'rfp-epic',
        'title': 'Epic Cinematic',
        'artist': 'RoyaltyFreePlanet',
        'url': 'https://example.com/epic.mp3'
      },
    ];

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white30,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Search Music', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextField(
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search royalty-free songs...',
                hintStyle: const TextStyle(color: Colors.white54),
                prefixIcon: const Icon(Icons.search, color: Colors.white54),
                filled: true,
                fillColor: Colors.white10,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: mockSongs.length,
              itemBuilder: (context, index) {
                final song = mockSongs[index];
                return ListTile(
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.music_note, color: Colors.white),
                  ),
                  title: Text(song['title']!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  subtitle: Text(song['artist']!, style: const TextStyle(color: Colors.white70)),
                  trailing: const Icon(Icons.play_circle_outline, color: Colors.white54),
                  onTap: () {
                    final music = PostMusic(
                      songId: song['id']!,
                      title: song['title']!,
                      artist: song['artist']!,
                      url: song['url']!,
                      duration: 30000,
                      startTime: 0,
                    );
                    Navigator.pop(context, music);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
