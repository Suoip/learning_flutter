import 'dart:async';

import 'package:flutter/material.dart';

void main() => runApp(const StopWatchApp());

class StopWatchApp extends StatelessWidget {
  const StopWatchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(debugShowCheckedModeBanner: false, home: Home());
  }
}

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  Map<String, dynamic> _worldTimeData = {};

  @override
  Widget build(BuildContext context) {
    final routeData = ModalRoute.of(context)?.settings.arguments;
    if (_worldTimeData.isEmpty && routeData is Map) {
      _worldTimeData = Map<String, dynamic>.from(routeData);
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Stopwatch'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: const Body(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        backgroundColor: Colors.black,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.access_time),
            label: 'Clock',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.timer),
            label: 'Stopwatch',
          ),
        ],
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacementNamed(
              context,
              '/home',
              arguments: _worldTimeData,
            );
          }
        },
      ),
    );
  }
}

class Body extends StatefulWidget {
  const Body({super.key});

  @override
  State<Body> createState() => _BodyState();
}

class _BodyState extends State<Body> {
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _ticker;
  final List<Duration> _laps = [];

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _startStopwatch() {
    _stopwatch.start();
    _ticker ??= Timer.periodic(const Duration(milliseconds: 30), (_) {
      if (!mounted) return;
      setState(() {});
    });
    setState(() {});
  }

  void _stopStopwatch() {
    _stopwatch.stop();
    _ticker?.cancel();
    _ticker = null;
    setState(() {});
  }

  void _recordLap() {
    if (!_stopwatch.isRunning) return;
    setState(() {
      _laps.add(_stopwatch.elapsed);
    });
  }

  void _reset() {
    if (_stopwatch.isRunning) return;
    setState(() {
      _stopwatch.reset();
      _laps.clear();
    });
  }

  String _format(Duration duration) {
    final int minutes = duration.inMinutes;
    final int seconds = duration.inSeconds.remainder(60);
    final int hundredths =
        (duration.inMilliseconds.remainder(1000) / 10).floor();
    final String mm = minutes.toString().padLeft(2, '0');
    final String ss = seconds.toString().padLeft(2, '0');
    final String hh = hundredths.toString().padLeft(2, '0');
    return '$mm:$ss.$hh';
  }

  @override
  Widget build(BuildContext context) {
    final bool isRunning = _stopwatch.isRunning;
    final List<Duration> laps = _laps.reversed.toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Column(
        children: [
          const SizedBox(height: 36),
          Text(
            _format(_stopwatch.elapsed),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 72,
              fontWeight: FontWeight.w300,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 42),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _ActionButton(
                label: isRunning ? 'Lap' : 'Reset',
                fill: const Color(0xFF2C2C2E),
                textColor: Colors.white,
                onTap: isRunning ? _recordLap : _reset,
              ),
              _ActionButton(
                label: isRunning ? 'Stop' : 'Start',
                fill: isRunning
                    ? const Color(0xFF3A0D12)
                    : const Color(0xFF003A1A),
                textColor: isRunning
                    ? const Color(0xFFFF453A)
                    : const Color(0xFF30D158),
                onTap: isRunning ? _stopStopwatch : _startStopwatch,
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(color: Color(0xFF1F1F1F), height: 1),
          Expanded(
            child: laps.isEmpty
                ? const SizedBox.shrink()
                : ListView.separated(
                    itemCount: laps.length,
                    separatorBuilder: (context, index) =>
                        const Divider(color: Color(0xFF1F1F1F), height: 1),
                    itemBuilder: (context, index) {
                      final int lapNumber = _laps.length - index;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Lap $lapNumber',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                              ),
                            ),
                            Text(
                              _format(laps[index]),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontFeatures: [FontFeature.tabularFigures()],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.fill,
    required this.textColor,
    required this.onTap,
  });

  final String label;
  final Color fill;
  final Color textColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF121212), width: 3),
      ),
      child: SizedBox(
        width: 82,
        height: 82,
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            shape: const CircleBorder(),
            elevation: 0,
            padding: EdgeInsets.zero,
            backgroundColor: fill,
            foregroundColor: textColor,
          ),
          child: Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 20,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
