import 'dart:async';

import 'package:flutter/material.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

class NetworkWrapper extends StatefulWidget {
  final Widget child;

  const NetworkWrapper({super.key, required this.child});

  @override
  State<NetworkWrapper> createState() => _NetworkWrapperState();
}

class _NetworkWrapperState extends State<NetworkWrapper> {
  bool _hasInternet = true;
  bool _isChecking = true;

  StreamSubscription<InternetStatus>? _internetSubscription;

  @override
  void initState() {
    super.initState();
    _checkInternet();

    _internetSubscription = InternetConnection().onStatusChange.listen((
      InternetStatus status,
    ) {
      if (!mounted) return;

      setState(() {
        _hasInternet = status == InternetStatus.connected;
      });
    });
  }

  Future<void> _checkInternet() async {
    try {
      final hasInternet = await InternetConnection().hasInternetAccess;

      if (!mounted) return;

      setState(() {
        _hasInternet = hasInternet;
        _isChecking = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _hasInternet = false;
        _isChecking = false;
      });
    }
  }

  @override
  void dispose() {
    _internetSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!_hasInternet) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'lib/assets/images/network.png',
                    height: 370,
                    fit: BoxFit.cover,
                  ),

                  const Text(
                    'No Internet Connection',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 12),

                  const Text(
                    'Please check your internet connection and try again.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15, color: Colors.grey),
                  ),

                  const SizedBox(height: 24),

                  SizedBox(
                    width: 180,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _checkInternet,
                      icon: const Icon(
                        Icons.refresh_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                      label: const Text(
                        'Retry',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        elevation: 6,
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        shadowColor: Colors.red.withOpacity(0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return widget.child;
  }
}
