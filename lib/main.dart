import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:easy_localization/easy_localization.dart';
import 'screens/settings_page.dart';
import 'screens/home_screen.dart';
import 'screens/search_screen.dart';
import 'screens/splash_screen.dart';
import 'widgets/mini_player.dart';
import 'providers/player_provider.dart';
import 'providers/playlist_provider.dart';
import 'providers/liked_songs_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/notification_provider.dart';
import 'widgets/notification_dialog.dart';
import 'screens/playlist_screen.dart';
import 'login_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/account_dialog.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: 'AIzaSyAh4yK2BVohuBnOlv3v9B3vcJ8pU6zTK5k',
      appId: '1:853945114681:android:4aa417fa91b1c83b76ade8',
      messagingSenderId: '853945114681',
      projectId: 'spoliqi',
      storageBucket: 'spoliqi.firebasestorage.app',
      databaseURL: 'https://spoliqi-default-rtdb.asia-southeast1.firebasedatabase.app',
    ),
  );
  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('vi'), Locale('en')],
      path: 'assets/lang',
      fallbackLocale: const Locale('vi'),
      child: const SpotifyCloneApp(),
    ),
  );
}

class NetworkStatusListener extends StatefulWidget {
  final Widget child;
  const NetworkStatusListener({super.key, required this.child});

  @override
  State<NetworkStatusListener> createState() => _NetworkStatusListenerState();
}

class _NetworkStatusListenerState extends State<NetworkStatusListener> {
  late final Connectivity _connectivity;
  late Stream<ConnectivityResult> _stream;
  bool _wasDisconnected = false;

  @override
  void initState() {
    super.initState();
    _connectivity = Connectivity();
    _stream = _connectivity.onConnectivityChanged.map((list) => list.first);
    _checkConnection();
  }

  Future<void> _checkConnection() async {
    final result = await _connectivity.checkConnectivity();
    if (result == ConnectivityResult.none) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showSnackbar(disconnected: true);
        _wasDisconnected = true;
      });
    }
  }

  void _showSnackbar({required bool disconnected}) {
    final mess = disconnected
        ? tr('network_disconnected')
        : tr('network_connected');
    final color = disconnected ? Colors.red : Colors.green;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(mess),
          backgroundColor: color,
          duration: const Duration(seconds: 2),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ConnectivityResult>(
      stream: _stream,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final connected = snapshot.data != ConnectivityResult.none;
          if (!connected && !_wasDisconnected) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _showSnackbar(disconnected: true);
              _wasDisconnected = true;
            });
          }
          if (connected && _wasDisconnected) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _showSnackbar(disconnected: false);
              _wasDisconnected = false;
            });
          }
        }
        return widget.child;
      },
    );
  }
}

class SpotifyCloneApp extends StatelessWidget {
  const SpotifyCloneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PlayerProvider()),
        ChangeNotifierProvider(create: (_) => PlaylistProvider()),
        ChangeNotifierProvider(create: (_) => LikedSongsProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Spotify Clone',
            theme: ThemeData(
              brightness: Brightness.light,
              scaffoldBackgroundColor: const Color(0xFFF6F6F6),
              primaryColor: Colors.greenAccent,
              dividerColor: Colors.grey.shade300,
              iconTheme: const IconThemeData(color: Colors.black87),
              colorScheme: ColorScheme.light(
                primary: Colors.greenAccent,
                secondary: Colors.greenAccent,
                background: const Color(0xFFF6F6F6),
                surface: Colors.white,
                onPrimary: Colors.black87,
                onSecondary: Colors.black87,
                onSurface: Colors.black87,
                onBackground: Colors.black87,
                error: Colors.red,
                onError: Colors.white,
                brightness: Brightness.light,
              ),
              appBarTheme: const AppBarTheme(
                backgroundColor: Color(0xFFF6F6F6),
                iconTheme: IconThemeData(color: Colors.black87),
                titleTextStyle: TextStyle(
                  color: Colors.black87,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                elevation: 0,
              ),
              textTheme: const TextTheme(
                displayLarge: TextStyle(color: Colors.black87),
                displayMedium: TextStyle(color: Colors.black87),
                displaySmall: TextStyle(color: Colors.black87),
                headlineLarge: TextStyle(color: Colors.black87),
                headlineMedium: TextStyle(color: Colors.black87),
                headlineSmall: TextStyle(color: Colors.black87),
                titleLarge: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
                titleMedium: TextStyle(color: Colors.black87),
                titleSmall: TextStyle(color: Colors.black87),
                bodyLarge: TextStyle(color: Colors.black87),
                bodyMedium: TextStyle(color: Colors.black87),
                bodySmall: TextStyle(color: Colors.black54),
                labelLarge: TextStyle(color: Colors.black87),
                labelMedium: TextStyle(color: Colors.black87),
                labelSmall: TextStyle(color: Colors.black54),
              ),
              listTileTheme: const ListTileThemeData(
                iconColor: Colors.black87,
                textColor: Colors.black87,
              ),
              switchTheme: SwitchThemeData(
                thumbColor: MaterialStatePropertyAll(Colors.greenAccent),
                trackColor: MaterialStatePropertyAll(Color(0xFFB2DFDB)),
              ),
            ),
            darkTheme: ThemeData.dark().copyWith(
              scaffoldBackgroundColor: Colors.black,
              primaryColor: Colors.greenAccent,
              iconTheme: const IconThemeData(color: Colors.white),
              appBarTheme: const AppBarTheme(
                backgroundColor: Colors.black,
                iconTheme: IconThemeData(color: Colors.white),
                titleTextStyle: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              listTileTheme: const ListTileThemeData(
                iconColor: Colors.white,
                textColor: Colors.white,
              ),
            ),
            themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            debugShowCheckedModeBanner: false,

            // ADD THIS: Provide named route support for /home, /search, /playlist
            initialRoute: '/',
            routes: {
              '/': (context) => const RootScreen(),
              '/home': (context) => HomeScreen(),
              '/search': (context) => const SearchScreen(),
              '/playlist': (context) => const PlaylistScreen(),
            },

            // keep home property null to avoid conflict with initialRoute
            builder: (context, child) => NetworkStatusListener(child: child!),
            localizationsDelegates: context.localizationDelegates,
            supportedLocales: context.supportedLocales,
            locale: context.locale,
          );
        },
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

        if (user != _lastUser) {
          _lastUser = user;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final playlistProvider = Provider.of<PlaylistProvider>(context, listen: false);
            final likedSongsProvider = Provider.of<LikedSongsProvider>(context, listen: false);
            final playerProvider = Provider.of<PlayerProvider>(context, listen: false);
            if (user == null) {
              playlistProvider.clearPlaylists();
              likedSongsProvider.clearLikedSongs();
              playerProvider.clear();
            } else {
              playlistProvider.loadPlaylists();
              likedSongsProvider.loadLikedSongs();
              playerProvider.clear();
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

  // Dùng GlobalKey để hỗ trợ reload HomeScreen khi nhấn lại icon Home
  final GlobalKey<HomeScreenState> homeKey = GlobalKey<HomeScreenState>();

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      HomeScreen(key: homeKey),
      const SearchScreen(),
      const PlaylistScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final showMiniPlayer = context.select<PlayerProvider, bool>(
          (provider) => provider.currentSong != null,
    );

    final isDark = context.watch<ThemeProvider>().isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _selectedIndex == 0
              ? tr('home')
              : _selectedIndex == 1
              ? tr('search')
              : tr('playlist'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => const NotificationDialog(),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsPage()),
              );
            },
          ),
          // Avatar
          Padding(
            padding: const EdgeInsets.only(right: 8, left: 8),
            child: GestureDetector(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (_) => AccountDialog(user: FirebaseAuth.instance.currentUser),
                );
              },
              child: CircleAvatar(
                radius: 18,
                backgroundImage: FirebaseAuth.instance.currentUser?.photoURL != null
                    ? NetworkImage(FirebaseAuth.instance.currentUser!.photoURL!)
                    : null,
                child: FirebaseAuth.instance.currentUser?.photoURL == null
                    ? const Icon(Icons.person, size: 22)
                    : null,
                backgroundColor: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[800]
                    : Colors.grey[300],
              ),
            ),
          ),
        ],
      ),
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
        backgroundColor: isDark ? Colors.black : const Color(0xFFF6F6F6),
        selectedItemColor: Colors.greenAccent,
        unselectedItemColor: isDark ? Colors.white54 : Colors.black38,
        currentIndex: _selectedIndex,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home),
            label: tr('home'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.search),
            label: tr('search'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.playlist_play),
            label: tr('playlist'),
          ),
        ],
        onTap: (index) {
          if (index == 0 && _selectedIndex == 0) {
            homeKey.currentState?.refresh();
          }
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
}

Future<void> signOutUser(BuildContext context) async {
  try {
    await GoogleSignIn().signOut();
  } catch (_) {}
  await FirebaseAuth.instance.signOut();
}