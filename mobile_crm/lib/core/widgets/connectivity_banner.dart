import 'dart:async';
import 'package:flutter/material.dart';
import '../services/connectivity_service.dart';
import '../services/service_locator.dart';

class ConnectivityBanner extends StatefulWidget {
  final Widget child;
  final Color offlineColor;
  final Color onlineColor;
  final String offlineMessage;
  final bool showOnlineStatus;
  final double height;
  final Duration onlineStatusDuration;

  const ConnectivityBanner({
    Key? key,
    required this.child,
    this.offlineColor = Colors.red,
    this.onlineColor = Colors.green,
    this.offlineMessage = 'No internet connection',
    this.showOnlineStatus = false,
    this.height = 40.0,
    this.onlineStatusDuration = const Duration(seconds: 3),
  }) : super(key: key);

  @override
  State<ConnectivityBanner> createState() => _ConnectivityBannerState();
}

class _ConnectivityBannerState extends State<ConnectivityBanner>
    with SingleTickerProviderStateMixin {
  late final ConnectivityService _connectivityService;
  bool _isFirstRun = true;
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  ConnectivityStatus _previousStatus = ConnectivityStatus.unknown;
  Timer? _onlineStatusTimer;
  bool _showOnlineTemporarily = false;

  @override
  void initState() {
    super.initState();
    _connectivityService = getService<ConnectivityService>();

    // Setup animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _slideAnimation = Tween<double>(begin: -1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutQuart,
      ),
    );
  }

  @override
  void dispose() {
    _onlineStatusTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ConnectivityStatus>(
      stream: _connectivityService.statusStream,
      initialData: _connectivityService.currentStatus,
      builder: (context, snapshot) {
        final status = snapshot.data ?? ConnectivityStatus.unknown;

        // For better UX, avoid showing momentary connectivity banner on first run if online
        if (_isFirstRun && status == ConnectivityStatus.online) {
          _isFirstRun = false;
          _previousStatus = status;
          return widget.child;
        }
        _isFirstRun = false;

        // Detect status change from offline to online
        if (_previousStatus == ConnectivityStatus.offline &&
            status == ConnectivityStatus.online &&
            widget.showOnlineStatus) {
          // If we just came back online, show online message temporarily
          _showOnlineTemporarily = true;

          // Cancel existing timer if any
          _onlineStatusTimer?.cancel();

          // Set a timer to hide the online status after a duration
          _onlineStatusTimer = Timer(widget.onlineStatusDuration, () {
            if (mounted) {
              setState(() {
                _showOnlineTemporarily = false;
              });
            }
          });
        }

        _previousStatus = status;

        // Show banner animation if offline or if online status should be shown temporarily
        final shouldShowBanner = status == ConnectivityStatus.offline ||
            (status == ConnectivityStatus.online &&
                widget.showOnlineStatus &&
                _showOnlineTemporarily);

        if (shouldShowBanner) {
          _animationController.forward();
        } else {
          _animationController.reverse();
        }

        return Stack(
          children: [
            widget.child,
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Positioned(
                  top: _slideAnimation.value * (widget.height + 10),
                  left: 16,
                  right: 16,
                  child: SafeArea(
                    child: Material(
                      elevation: 4,
                      borderRadius: BorderRadius.circular(12),
                      child: child!,
                    ),
                  ),
                );
              },
              child: Container(
                height: widget.height,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: status == ConnectivityStatus.online
                        ? [
                            widget.onlineColor.withOpacity(0.8),
                            widget.onlineColor
                          ]
                        : [
                            widget.offlineColor.withOpacity(0.8),
                            widget.offlineColor
                          ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      status == ConnectivityStatus.online
                          ? Icons.wifi
                          : Icons.wifi_off,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        status == ConnectivityStatus.online
                            ? 'Back Online'
                            : widget.offlineMessage,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    if (status == ConnectivityStatus.offline)
                      Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Pulse(duration: Duration(seconds: 2)),
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// Pulse animation widget
class Pulse extends StatefulWidget {
  final Duration duration;
  const Pulse({Key? key, this.duration = const Duration(seconds: 1)})
      : super(key: key);

  @override
  State<Pulse> createState() => _PulseState();
}

class _PulseState extends State<Pulse> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: child,
        );
      },
      child: Container(
        color: Colors.white,
      ),
    );
  }
}
