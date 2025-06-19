import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:easy_localization/easy_localization.dart';
import '../models/song.dart';
import '../services/deezer_service.dart';
import '../providers/player_provider.dart';
import '../screens/player_screen.dart';
import '../widgets/song_options.dart';
import '../widgets/account_dialog.dart';
import '../login_page.dart';
import 'settings_page.dart';
import 'dart:math';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../widgets/notification_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  static HomeScreenState? of(BuildContext context) =>
      context.findAncestorStateOfType<HomeScreenState>();

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
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

  /// Hàm manualFormat để thay thế {0}, {1}, ... trong chuỗi template bằng args tương ứng
  String manualFormat(String template, List<String> args) {
    var result = template;
    for (var i = 0; i < args.length; i++) {
      result = result.replaceAll('{$i}', args[i]);
    }
    return result;
  }

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

  Future<void> refresh() => _refresh();

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
        searchError = tr('search_error', args: ['$e']);
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

  /// Hàm lấy previewUrl từ Deezer API theo trackId
  Future<String?> fetchPreviewUrl(String trackId) async {
    try {
      final resp = await http.get(Uri.parse('https://api.deezer.com/track/$trackId'));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        return data['preview'];
      }
    } catch (_) {}
    return null;
  }

  /// Mở PlayerScreen với bài hát, lấy previewUrl mới nhất bằng Deezer API
  Future<void> playSongWithFreshPreview(Map track, BuildContext context) async {
    final previewUrl = await fetchPreviewUrl(track['id'].toString());
    if (previewUrl != null && previewUrl.isNotEmpty) {
      final song = Song(
        id: track['id'].toString(),
        title: track['title']?.toString() ?? tr('unknown_title'),
        artist: track['artist']?['name']?.toString() ?? tr('unknown_artist'),
        audioUrl: previewUrl,
        coverUrl: track['album']?['cover_big']?.toString() ?? '',
      );
      Provider.of<PlayerProvider>(context, listen: false)
          .setQueue([song], startIndex: 0);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PlayerScreen(originalSongs: [song]),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('preview_not_supported'))),
      );
    }
  }

  Future<void> showSongOptionsWithPreview(Map track, BuildContext context) async {
    final previewUrl = await fetchPreviewUrl(track['id'].toString());
    final song = Song(
      id: track['id'].toString(),
      title: track['title']?.toString() ?? tr('unknown_title'),
      artist: track['artist']?['name']?.toString() ?? tr('unknown_artist'),
      audioUrl: previewUrl ?? '',
      coverUrl: track['album']?['cover_big']?.toString() ?? '',
    );
    showSongOptions(context, song);
  }

  /// Hàm xác định key lời chào theo giờ
  String getGreetingKey() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return 'greeting_morning';    // Sáng
    } else if (hour >= 12 && hour < 18) {
      return 'greeting_afternoon';  // Chiều
    } else if (hour >= 18 && hour < 22) {
      return 'greeting_evening';    // Tối
    } else {
      return 'greeting_night';      // Đêm
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final userName = user?.displayName ?? user?.email ?? tr('user');

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = theme.scaffoldBackgroundColor;
    final mainTextColor = theme.textTheme.bodyLarge?.color ?? (isDark ? Colors.white : Colors.black87);
    final subTextColor = theme.textTheme.bodySmall?.color ?? (isDark ? Colors.white70 : Colors.black54);
    final iconColor = theme.iconTheme.color ?? (isDark ? Colors.white : Colors.black87);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Chỉ còn lời chào, không còn avatar nữa
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 18, bottom: 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  manualFormat(tr(getGreetingKey()), [userName]),
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: mainTextColor,
                    letterSpacing: 0.5,
                  ),
                  maxLines: 2,
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
                      style: TextStyle(color: mainTextColor),
                      decoration: InputDecoration(
                        hintText: tr('search_hint'),
                        hintStyle: TextStyle(color: subTextColor),
                        filled: true,
                        fillColor: isDark ? Colors.white12 : Colors.black12,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 0),
                        suffixIcon: searchKeyword.isNotEmpty || isSearching
                            ? IconButton(
                          icon: Icon(Icons.clear, color: subTextColor),
                          onPressed: _onClearSearch,
                        )
                            : IconButton(
                          icon: Icon(Icons.search, color: subTextColor),
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
                  ? _buildSearchResults(theme, mainTextColor, subTextColor, iconColor)
                  : RefreshIndicator(
                color: Colors.greenAccent,
                onRefresh: _refresh,
                child: ListView(
                  padding: const EdgeInsets.only(
                    bottom: 54 + 12,
                  ),
                  children: [
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
                              tr('playlist_load_error', args: ['${snapshot.error}']),
                              style: const TextStyle(color: Colors.redAccent, fontSize: 16),
                            ),
                          );
                        }
                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Text(tr('not_found_song'), style: TextStyle(color: mainTextColor)),
                          );
                        }
                        final shuffledTracks = List<dynamic>.from(snapshot.data!)..shuffle(Random());
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: Text(
                                tr('suggested_playlist'),
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: mainTextColor),
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
                                    onTap: () => playSongWithFreshPreview(track, context),
                                    onLongPress: () => showSongOptionsWithPreview(track, context),
                                    mainTextColor: mainTextColor,
                                    subTextColor: subTextColor,
                                    iconColor: iconColor,
                                    isDark: isDark,
                                  );
                                },
                              ),
                            ),
                          ],
                        );
                      },
                    ),
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
                              tr('load_error', args: ['${snapshot.error}']),
                              style: const TextStyle(color: Colors.redAccent, fontSize: 16),
                            ),
                          );
                        }
                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.music_off, size: 60, color: subTextColor),
                              const SizedBox(height: 16),
                              Text(tr('no_songs'), style: TextStyle(color: subTextColor, fontSize: 18)),
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
                                    onTap: () => playSongWithFreshPreview(track, context),
                                    onLongPress: () => showSongOptionsWithPreview(track, context),
                                    mainTextColor: mainTextColor,
                                    iconColor: iconColor,
                                    isDark: isDark,
                                  );
                                },
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 16, right: 16, top: 30, bottom: 8),
                              child: Row(
                                children: [
                                  Text(
                                    tr('recommended_for_you'),
                                    style: TextStyle(
                                      color: mainTextColor,
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
                                    onTap: () => playSongWithFreshPreview(track, context),
                                    onLongPress: () => showSongOptionsWithPreview(track, context),
                                    mainTextColor: mainTextColor,
                                    subTextColor: subTextColor,
                                    iconColor: iconColor,
                                    isDark: isDark,
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

  Widget _buildSearchResults(ThemeData theme, Color mainTextColor, Color subTextColor, Color iconColor) {
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
      return Center(
        child: Text(tr('search_not_found'), style: TextStyle(color: subTextColor, fontSize: 17)),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.only(
        bottom: 54 + 12,
      ),
      itemCount: searchResults.length,
      separatorBuilder: (context, i) => Divider(height: 1, color: subTextColor.withOpacity(0.25)),
      itemBuilder: (context, index) {
        final track = searchResults[index];
        final song = Song(
          id: track['id'].toString(),
          title: track['title']?.toString() ?? tr('unknown_title'),
          artist: track['artist']?['name']?.toString() ?? tr('unknown_artist'),
          audioUrl: track['preview']?.toString() ?? '',
          coverUrl: track['album']?['cover_big']?.toString() ?? '',
        );
        return ListTile(
          leading: (track['album']?['cover_medium']?.toString().isNotEmpty ?? false)
              ? ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.network(
              track['album']?['cover_medium'],
              width: 40,
              height: 40,
              fit: BoxFit.cover,
            ),
          )
              : Icon(Icons.music_note, color: subTextColor, size: 32),
          title: Text(song.title, style: TextStyle(color: mainTextColor)),
          subtitle: Text(song.artist, style: TextStyle(color: subTextColor)),
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
    );
  }
}

class _VpopSongCard extends StatelessWidget {
  final dynamic track;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Color mainTextColor;
  final Color subTextColor;
  final Color iconColor;
  final bool isDark;

  const _VpopSongCard({
    required this.track,
    this.onTap,
    this.onLongPress,
    required this.mainTextColor,
    required this.subTextColor,
    required this.iconColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final String title = track['title']?.toString() ?? tr('unknown_title');
    final String artist = track['artist']?['name']?.toString() ?? tr('unknown_artist');
    final String? coverUrl = track['album']?['cover_medium']?.toString();

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
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
                color: isDark ? Colors.black26 : Colors.black12,
                child: Icon(Icons.music_note, color: subTextColor, size: 40),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(fontWeight: FontWeight.bold, color: mainTextColor),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              artist,
              style: TextStyle(color: subTextColor, fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _SpotifyPlaylistTile extends StatelessWidget {
  final dynamic track;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Color mainTextColor;
  final Color iconColor;
  final bool isDark;

  const _SpotifyPlaylistTile({
    required this.track,
    this.onTap,
    this.onLongPress,
    required this.mainTextColor,
    required this.iconColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final String title = track['title']?.toString() ?? tr('unknown_title');
    final String artist = track['artist']?['name']?.toString() ?? tr('unknown_artist');
    final String? coverUrl = track['album']?['cover_small']?.toString();

    final bgColors = [
      Colors.green.shade700,
      Colors.blue.shade700,
      Colors.purple.shade700,
      Colors.orange.shade700,
      Colors.pink.shade700,
      Colors.teal.shade700,
    ];
    final color = bgColors[title.hashCode.abs() % bgColors.length].withOpacity(isDark ? 0.85 : 0.15);

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
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
                color: isDark ? Colors.black26 : Colors.black12,
                child: Icon(Icons.music_note, color: iconColor.withOpacity(0.7), size: 30),
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: mainTextColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
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

class _SpotifyCardVertical extends StatelessWidget {
  final dynamic track;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Color mainTextColor;
  final Color subTextColor;
  final Color iconColor;
  final bool isDark;

  const _SpotifyCardVertical({
    required this.track,
    this.onTap,
    this.onLongPress,
    required this.mainTextColor,
    required this.subTextColor,
    required this.iconColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final String title = track['title']?.toString() ?? tr('unknown_title');
    final String artist = track['artist']?['name']?.toString() ?? tr('unknown_artist');
    final String? coverUrl = track['album']?['cover_medium']?.toString();

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 120,
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[900] : Colors.grey[200],
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
                color: isDark ? Colors.black26 : Colors.black12,
                child: Icon(Icons.music_note, color: subTextColor, size: 48),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(color: mainTextColor, fontWeight: FontWeight.bold, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    artist,
                    style: TextStyle(color: Colors.greenAccent, fontSize: 11),
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