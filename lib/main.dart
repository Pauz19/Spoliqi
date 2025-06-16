import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import 'screens/home_screen.dart';
import 'screens/search_screen.dart';
import 'screens/splash_screen.dart';
import 'widgets/mini_player.dart';
import 'providers/player_provider.dart';
import 'providers/playlist_provider.dart';
import 'screens/playlist_screen.dart';
import 'login_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: 'AIzaSyAh4yK2BVohuBnOlv3v9B3vcJ8pU6zTK5k',
      appId: '1:853945114681:android:4aa417fa91b1c83b76ade8',
      messagingSenderId: '853945114681',
      projectId: 'spoliqi',
      storageBucket: 'spoliqi.firebasestorage.app',
      databaseURL: 'https://spoliqi-default-rtdb.asia-southeast1.firebasedatabase.app', // Bắt buộc cho Realtime Database
    ),
  );
  runApp(const SpotifyCloneApp());
}

class SpotifyCloneApp extends StatelessWidget {
  const SpotifyCloneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PlayerProvider()),
        ChangeNotifierProvider(create: (_) => PlaylistProvider()),
      ],
      child: MaterialApp(
        title: 'Spotify Clone',
        theme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: Colors.black,
          primaryColor: Colors.greenAccent,
        ),
        debugShowCheckedModeBanner: false,
        home: const RootScreen(),
      ),
    );
  }
}

class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  User? _lastUser;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        final user = snapshot.data;

        // Chỉ clear/load playlist khi thực sự đổi trạng thái user
        if (user != _lastUser) {
          _lastUser = user;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final playlistProvider = Provider.of<PlaylistProvider>(context, listen: false);
            if (user == null) {
              playlistProvider.clearPlaylists();
            } else {
              playlistProvider.loadPlaylists();
            }
          });
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }
        if (user == null) {
          return const LoginPage();
        }
        return const MainWrapper();
      },
    );
  }
}

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    SearchScreen(),
    PlaylistScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final showMiniPlayer = context.select<PlayerProvider, bool>(
          (provider) => provider.currentSong != null,
    );

    return Scaffold(
      body: Stack(
        children: [
          _screens[_selectedIndex],
          if (showMiniPlayer)
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: MiniPlayer(),
            ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.black,
        selectedItemColor: Colors.greenAccent,
        unselectedItemColor: Colors.white54,
        currentIndex: _selectedIndex,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Trang chủ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Tìm kiếm',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.playlist_play),
            label: 'Playlist',
          ),
        ],
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
}