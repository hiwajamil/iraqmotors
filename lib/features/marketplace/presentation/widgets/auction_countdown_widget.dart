import 'dart:async';
import 'package:flutter/material.dart';

import 'package:iq_motors/core/theme/app_theme.dart';

class AuctionCountdownWidget extends StatefulWidget {
  const AuctionCountdownWidget({
    super.key,
    required this.endTime,
    this.onEnded,
  });

  final DateTime endTime;
  final VoidCallback? onEnded;

  @override
  State<AuctionCountdownWidget> createState() => _AuctionCountdownWidgetState();
}

class _AuctionCountdownWidgetState extends State<AuctionCountdownWidget>
    with SingleTickerProviderStateMixin {
  late Timer _timer;
  late Duration _remaining;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _remaining = widget.endTime.difference(DateTime.now());
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final newRemaining = widget.endTime.difference(DateTime.now());
      if (newRemaining.isNegative) {
        _timer.cancel();
        setState(() => _remaining = Duration.zero);
        widget.onEnded?.call();
      } else {
        setState(() => _remaining = newRemaining);
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    if (d.inSeconds <= 0) return 'Auction Ended';
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);
    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final textTheme = context.textTheme;

    final isEnded = _remaining.inSeconds <= 0;
    final isUrgent = _remaining.inMinutes < 5 && !isEnded;
    final isWarning = _remaining.inMinutes < 30 && !isUrgent && !isEnded;

    final badgeColor = isEnded
        ? colorScheme.surfaceContainerHighest
        : isUrgent
            ? const Color(0xFFEF4444)
            : isWarning
                ? const Color(0xFFF59E0B)
                : const Color(0xFF10B981);

    final textColor = isEnded
        ? colorScheme.onSurfaceVariant
        : Colors.white;

    final child = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: isUrgent
            ? [
                BoxShadow(
                  color: badgeColor.withValues(alpha: 0.4),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isEnded ? Icons.timer_off_outlined : Icons.timer_outlined,
            size: 14,
            color: textColor,
          ),
          const SizedBox(width: 5),
          Text(
            _formatDuration(_remaining),
            style: textTheme.labelSmall?.copyWith(
              color: textColor,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );

    if (isUrgent) {
      return FadeTransition(
        opacity: Tween<double>(begin: 0.6, end: 1.0).animate(_pulseController),
        child: child,
      );
    }

    return child;
  }
}
