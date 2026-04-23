import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class WifiBinMonitor extends StatefulWidget {
  const WifiBinMonitor({super.key});

  @override
  State<WifiBinMonitor> createState() => _WifiBinMonitorState();
}

class _WifiBinMonitorState extends State<WifiBinMonitor> {
  final TextEditingController _ipController = TextEditingController();
  Timer? _pollTimer;

  int _plastic = 0;
  int _paper = 0;
  int _metal = 0;
  String _status = 'Enter the laptop IP address to connect.';
  bool _connecting = false;

  @override
  void dispose() {
    _pollTimer?.cancel();
    _ipController.dispose();
    super.dispose();
  }

  String get _baseUrl {
    final input = _ipController.text.trim();
    if (input.isEmpty) return '';
    if (input.startsWith('http://') || input.startsWith('https://')) {
      return input;
    }
    return 'http://$input:5000';
  }

  Future<void> _connect() async {
    if (_baseUrl.isEmpty) return;
    _pollTimer?.cancel();
    setState(() {
      _connecting = true;
      _status = 'Connecting...';
    });
    await _fetchStatus();
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) => _fetchStatus());
    if (mounted) {
      setState(() => _connecting = false);
    }
  }

  Future<void> _fetchStatus() async {
    if (_baseUrl.isEmpty) return;
    try {
      final response = await http.get(Uri.parse('$_baseUrl/api/bin-status'));
      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (!mounted) return;
      setState(() {
        _plastic = _toPercent(data['plastic']);
        _paper = _toPercent(data['paper']);
        _metal = _toPercent(data['metal']);
        _status = 'Connected';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _status = 'Unable to fetch bin status');
    }
  }

  Future<void> _sendCommand(String command) async {
    if (_baseUrl.isEmpty) return;
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/command'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'command': command}),
      );
      if (!mounted) return;
      setState(() {
        _status = response.statusCode == 200
            ? 'Command $command sent'
            : 'Command failed (${response.statusCode})';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _status = 'Command failed');
    }
  }

  int _toPercent(dynamic value) {
    final parsed = (value is num) ? value.toInt() : int.tryParse('$value') ?? 0;
    return parsed.clamp(0, 100);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Smart Bin Wi-Fi Monitor')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(
              controller: _ipController,
              decoration: const InputDecoration(
                labelText: 'Laptop IP address',
                hintText: '192.168.x.x',
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _connecting ? null : _connect,
              child: const Text('Connect'),
            ),
            const SizedBox(height: 16),
            Text(_status),
            const SizedBox(height: 16),
            _LevelTile(label: 'Plastic', color: Colors.blue, value: _plastic),
            _LevelTile(label: 'Paper', color: Colors.orange, value: _paper),
            _LevelTile(label: 'Metal', color: Colors.grey, value: _metal),
            const SizedBox(height: 20),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton(
                  onPressed: () => _sendCommand('P'),
                  child: const Text('Open Plastic (P)'),
                ),
                ElevatedButton(
                  onPressed: () => _sendCommand('S'),
                  child: const Text('Open Paper (S)'),
                ),
                ElevatedButton(
                  onPressed: () => _sendCommand('M'),
                  child: const Text('Open Metal (M)'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LevelTile extends StatelessWidget {
  const _LevelTile({
    required this.label,
    required this.color,
    required this.value,
  });

  final String label;
  final Color color;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: $value%'),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: value / 100,
            minHeight: 12,
            backgroundColor: color.withValues(alpha: 0.15),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ],
      ),
    );
  }
}
