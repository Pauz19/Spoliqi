import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:easy_localization/easy_localization.dart';

class NetworkStatusListener extends StatefulWidget {
  final Widget child;
  const NetworkStatusListener({super.key, required this.child});

  @override
  State<NetworkStatusListener> createState() => _NetworkStatusListenerState();
}

class _NetworkStatusListenerState extends State<NetworkStatusListener> {
  late final Connectivity _connectivity;
  late final Stream<ConnectivityResult> _stream;
  bool _wasDisconnected = false;

  @override
  void initState() {
    super.initState();
    _connectivity = Connectivity();
    // Đúng cho version mới
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