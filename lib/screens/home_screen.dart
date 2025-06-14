import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/song.dart';
import '../services/deezer_service.dart';
import '../providers/player_provider.dart';
import '../screens/player_screen.dart';
import 'dart:math';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DeezerService _deezerService = DeezerService();
  late Future<List<dynamic>> _tracksFuture;
  late Future<List<dynamic>> _vpopFuture;
  bool _isRefreshing = false;

  final TextEditingController _searchController = TextEditingController();
  String searchKeyword = '';
  List<dynamic> searchResults = [];
  bool isSearching = false;
  bool isLoadingSearch = false;
  String? searchError;

  @override
  void initState() {
    super.initState();
    _initFutures();
  }

  void _initFutures() {
    _tracksFuture = _deezerService.fetchTopTracks();
    _vpopFuture = _deezerService.fetchPlaylistTracks('3155776842');
  }

  Future<void> _refresh() async {
    setState(() {
      _isRefreshing = true;
    });
    _tracksFuture = _deezerService.fetchTopTracks();
    _vpopFuture = _deezerService.fetchPlaylistTracks('3155776842');
    await Future.wait([
      _tracksFuture,
      _vpopFuture,
    ]);
    setState(() {
      _isRefreshing = false;
    });
  }

  Future<void> _onSearch() async {
    final keyword = _searchController.text.trim();
    if (keyword.isEmpty) {
      setState(() {
        isSearching = false;
        searchResults = [];
        searchError = null;
      });
      return;
    }
    setState(() {
      isSearching = true;
      isLoadingSearch = true;
      searchError = null;
    });
    try {
      final results = await _deezerService.searchTracks(keyword);
      setState(() {
        searchResults = results;
        isLoadingSearch = false;
      });
    } catch (e) {
      setState(() {
        searchError = 'Lỗi tìm kiếm: $e';
        isLoadingSearch = false;
        searchResults = [];
      });
    }
  }

  void _onClearSearch() {
    _searchController.clear();
    FocusScope.of(context).unfocus();
    setState(() {
      isSearching = false;
      searchResults = [];
      searchError = null;
      searchKeyword = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final userName = 'Pauz19';
    final avatarUrl = 'https://i.scdn.co/image/ab6775700000ee85c6e2a7e1f7c0ceab811bc7bd';

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundImage: NetworkImage(avatarUrl),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.notifications_none, color: Colors.white, size: 28),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings, color: Colors.white, size: 28),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 4, bottom: 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Good morning, $userName!',
                  style: const TextStyle(
                    fontSize: 29,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onSubmitted: (_) => _onSearch(),
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Nghệ sĩ, bài hát hoặc album...',
                        hintStyle: const TextStyle(color: Colors.white54),
                        filled: true,
                        fillColor: Colors.white12,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 0),
                        suffixIcon: searchKeyword.isNotEmpty || isSearching
                            ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.white54),
                          onPressed: _onClearSearch,
                        )
                            : IconButton(
                          icon: const Icon(Icons.search, color: Colors.white70),
                          onPressed: _onSearch,
                        ),
                      ),
                      onChanged: (v) {
                        setState(() {
                          searchKeyword = v;
                        });
                        if (v.isEmpty) _onClearSearch();
                      },
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: isSearching
                  ? _buildSearchResults()
                  : RefreshIndicator(
                color: Colors.greenAccent,
                onRefresh: _refresh,
                child: ListView(
                  padding: const EdgeInsets.only(
                    bottom: 54 + 12, // CHỈ cộng chiều cao MiniPlayer + dư 1 chút!
                  ),
                  children: [
                    // Playlist đề xuất section
                    FutureBuilder<List<dynamic>>(
                      future: _vpopFuture,
                      builder: (context, snapshot) {
                        if (_isRefreshing) return const SizedBox.shrink();
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const SizedBox.shrink();
                        }
                        if (snapshot.hasError) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Text(
                              'Lỗi tải playlist: ${snapshot.error}',
                              style: const TextStyle(color: Colors.redAccent, fontSize: 16),
                            ),
                          );
                        }
                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Text('Không tìm thấy bài hát', style: TextStyle(color: Colors.white)),
                          );
                        }
                        final shuffledTracks = List<dynamic>.from(snapshot.data!)..shuffle(Random());
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: Text(
                                'Playlist đề xuất',
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ),
                            SizedBox(
                              height: 180,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                itemCount: shuffledTracks.length > 12 ? 12 : shuffledTracks.length,
                                separatorBuilder: (_, __) => const SizedBox(width: 12),
                                itemBuilder: (context, index) {
                                  final track = shuffledTracks[index];
                                  return _VpopSongCard(
                                    track: track,
                                    onTap: () {
                                      final song = Song(
                                        id: track['id'].toString(),
                                        title: track['title'] ?? 'Không rõ tên',
                                        artist: track['artist']?['name'] ?? 'Không rõ nghệ sĩ',
                                        audioUrl: track['preview'] ?? '',
                                        coverUrl: track['album']?['cover_big'] ?? '',
                                      );
                                      Provider.of<PlayerProvider>(context, listen: false)
                                          .setQueue([song], startIndex: 0);
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => const PlayerScreen(),
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    // Top tracks section
                    FutureBuilder<List<dynamic>>(
                      future: _tracksFuture,
                      builder: (context, snapshot) {
                        if (_isRefreshing) return const SizedBox.shrink();
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const SizedBox.shrink();
                        }
                        if (snapshot.hasError) {
                          return Center(
                            child: Text(
                              'Lỗi: ${snapshot.error}',
                              style: const TextStyle(color: Colors.redAccent, fontSize: 16),
                            ),
                          );
                        }
                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.music_off, size: 60, color: Colors.white24),
                              const SizedBox(height: 16),
                              const Text('Không có bài hát nào.', style: TextStyle(color: Colors.white60, fontSize: 18)),
                            ],
                          );
                        }
                        final shuffledTracks = List<dynamic>.from(snapshot.data!)..shuffle(Random());
                        final highlightTracks = shuffledTracks.take(6).toList();
                        final recommendedTracks = shuffledTracks.skip(6).take(10).toList();

                        return Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: highlightTracks.length,
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  mainAxisSpacing: 14,
                                  crossAxisSpacing: 14,
                                  childAspectRatio: 2.7,
                                ),
                                itemBuilder: (context, index) {
                                  final track = highlightTracks[index];
                                  return _SpotifyPlaylistTile(
                                    track: track,
                                    onTap: () {
                                      final song = Song(
                                        id: track['id'].toString(),
                                        title: track['title'] ?? 'Không rõ tên',
                                        artist: track['artist']?['name'] ?? 'Không rõ nghệ sĩ',
                                        audioUrl: track['preview'] ?? '',
                                        coverUrl: track['album']?['cover_big'] ?? '',
                                      );
                                      Provider.of<PlayerProvider>(context, listen: false)
                                          .setQueue([song], startIndex: 0);
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => const PlayerScreen(),
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 16, right: 16, top: 30, bottom: 8),
                              child: Row(
                                children: const [
                                  Text(
                                    'Recommended for you',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                              height: 182,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                itemCount: recommendedTracks.length,
                                separatorBuilder: (context, i) => const SizedBox(width: 16),
                                itemBuilder: (context, index) {
                                  final track = recommendedTracks[index];
                                  return _SpotifyCardVertical(
                                    track: track,
                                    onTap: () {
                                      final song = Song(
                                        id: track['id'].toString(),
                                        title: track['title'] ?? 'Không rõ tên',
                                        artist: track['artist']?['name'] ?? 'Không rõ nghệ sĩ',
                                        audioUrl: track['preview'] ?? '',
                                        coverUrl: track['album']?['cover_big'] ?? '',
                                      );
                                      Provider.of<PlayerProvider>(context, listen: false)
                                          .setQueue([song], startIndex: 0);
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => const PlayerScreen(),
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 30),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (isLoadingSearch) {
      return const Center(child: CircularProgressIndicator(color: Colors.greenAccent));
    }
    if (searchError != null) {
      return Center(
        child: Text(
          searchError!,
          style: const TextStyle(color: Colors.redAccent, fontSize: 16),
        ),
      );
    }
    if (searchResults.isEmpty) {
      return const Center(
        child: Text('Không tìm thấy kết quả.', style: TextStyle(color: Colors.white70, fontSize: 17)),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.only(
        bottom: 54 + 12, // CHỈ cộng chiều cao MiniPlayer + dư 1 chút!
      ),
      itemCount: searchResults.length,
      separatorBuilder: (context, i) => const Divider(height: 1, color: Colors.white12),
      itemBuilder: (context, index) {
        final track = searchResults[index];
        final song = Song(
          id: track['id'].toString(),
          title: track['title'] ?? 'Không rõ tên',
          artist: track['artist']?['name'] ?? 'Không rõ nghệ sĩ',
          audioUrl: track['preview'] ?? '',
          coverUrl: track['album']?['cover_big'] ?? '',
        );
        return ListTile(
          leading: track['album']?['cover_medium'] != null
              ? ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.network(
              track['album']?['cover_medium'],
              width: 40,
              height: 40,
              fit: BoxFit.cover,
            ),
          )
              : const Icon(Icons.music_note, color: Colors.white70, size: 32),
          title: Text(song.title, style: const TextStyle(color: Colors.white)),
          subtitle: Text(song.artist, style: const TextStyle(color: Colors.white70)),
          onTap: () {
            Provider.of<PlayerProvider>(context, listen: false).setQueue([song], startIndex: 0);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const PlayerScreen(),
              ),
            );
          },
        );
      },
    );
  }
}

// Card cho playlist section
class _VpopSongCard extends StatelessWidget {
  final dynamic track;
  final VoidCallback? onTap;

  const _VpopSongCard({required this.track, this.onTap});

  @override
  Widget build(BuildContext context) {
    final String title = track['title'] ?? 'Không rõ tên';
    final String artist = track['artist']?['name'] ?? 'Không rõ nghệ sĩ';
    final String? coverUrl = track['album']?['cover_medium'];

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 120,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: (coverUrl != null && coverUrl.isNotEmpty)
                  ? Image.network(
                coverUrl,
                width: 120,
                height: 120,
                fit: BoxFit.cover,
              )
                  : Container(
                width: 120,
                height: 120,
                color: Colors.black26,
                child: const Icon(Icons.music_note, color: Colors.white54, size: 40),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              artist,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// 2-cột playlist tile Spotify style
class _SpotifyPlaylistTile extends StatelessWidget {
  final dynamic track;
  final VoidCallback? onTap;
  const _SpotifyPlaylistTile({required this.track, this.onTap});

  @override
  Widget build(BuildContext context) {
    final String title = track['title'] ?? 'Không rõ tên';
    final String artist = track['artist']?['name'] ?? 'Không rõ nghệ sĩ';
    final String? coverUrl = track['album']?['cover_small'];

    final bgColors = [
      Colors.green.shade700,
      Colors.blue.shade700,
      Colors.purple.shade700,
      Colors.orange.shade700,
      Colors.pink.shade700,
      Colors.teal.shade700,
    ];
    final color = bgColors[title.hashCode.abs() % bgColors.length].withOpacity(0.85);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
              child: (coverUrl != null && coverUrl.isNotEmpty)
                  ? Image.network(
                coverUrl,
                width: 56,
                height: 56,
                fit: BoxFit.cover,
              )
                  : Container(
                width: 56,
                height: 56,
                color: Colors.black26,
                child: const Icon(Icons.music_note, color: Colors.white54, size: 30),
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 5),
          ],
        ),
      ),
    );
  }
}

// Card dọc cho horizontal list
class _SpotifyCardVertical extends StatelessWidget {
  final dynamic track;
  final VoidCallback? onTap;
  const _SpotifyCardVertical({required this.track, this.onTap});

  @override
  Widget build(BuildContext context) {
    final String title = track['title'] ?? 'Không rõ tên';
    final String artist = track['artist']?['name'] ?? 'Không rõ nghệ sĩ';
    final String? coverUrl = track['album']?['cover_medium'];

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 120,
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              child: (coverUrl != null && coverUrl.isNotEmpty)
                  ? Image.network(
                coverUrl,
                width: 120,
                height: 120,
                fit: BoxFit.cover,
              )
                  : Container(
                width: 120,
                height: 120,
                color: Colors.black26,
                child: const Icon(Icons.music_note, color: Colors.white54, size: 48),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    artist,
                    style: const TextStyle(color: Colors.greenAccent, fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}