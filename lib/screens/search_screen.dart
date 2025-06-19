import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';

import '../screens/player_screen.dart';
import '../providers/player_provider.dart';
import '../models/song.dart';
import '../widgets/song_options.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _tracks = [];
  bool _isLoading = false;
  String? _error;

  Future<void> fetchTracks(String keyword) async {
    setState(() {
      _isLoading = true;
      _error = null;
      _tracks = [];
    });
    try {
      final url = Uri.parse('https://api.deezer.com/search?q=$keyword');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _tracks = data['data'] ?? [];
        });
      } else {
        setState(() {
          _error = tr('network_or_api_error');
        });
      }
    } catch (e) {
      setState(() {
        _error = tr('search_failed', args: ['$e']);
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onSearch() {
    final keyword = _searchController.text.trim();
    if (keyword.isNotEmpty) {
      fetchTracks(keyword);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('search_song'.tr()),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onSubmitted: (_) => _onSearch(),
                    decoration: InputDecoration(
                      hintText: tr('search_song_hint'),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: _onSearch,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.only(top: 32.0),
              child: CircularProgressIndicator(),
            ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 32.0),
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            ),
          if (!_isLoading && _error == null)
            Expanded(
              child: _tracks.isEmpty
                  ? Center(child: Text(tr('search_no_result')))
                  : ListView.separated(
                padding: const EdgeInsets.only(
                  bottom: 54,
                ),
                itemCount: _tracks.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final track = _tracks[index];
                  final song = Song(
                    id: track['id'].toString(),
                    title: track['title'] ?? '',
                    artist: track['artist']?['name'] ?? '',
                    audioUrl: track['preview'] ?? '',
                    coverUrl: track['album']?['cover_big'] ?? '',
                  );
                  return ListTile(
                    leading: (track['album']?['cover_medium'] ?? '').isNotEmpty
                        ? ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.network(
                        track['album']['cover_medium'],
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                      ),
                    )
                        : const Icon(Icons.music_note, size: 40),
                    title: Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text(song.artist, maxLines: 1, overflow: TextOverflow.ellipsis),
                    onTap: () {
                      Provider.of<PlayerProvider>(context, listen: false).setQueue([song], startIndex: 0);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PlayerScreen(originalSongs: [song]),
                        ),
                      );
                    },
                    onLongPress: () {
                      showSongOptions(context, song);
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