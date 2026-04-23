import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

class BinLevelMonitor extends StatefulWidget {
  final BluetoothDevice device;

  const BinLevelMonitor({super.key, required this.device});

  @override
  State<BinLevelMonitor> createState() => _BinLevelMonitorState();
}

class _BinLevelMonitorState extends State<BinLevelMonitor> {
  BluetoothConnection? _connection;
  StreamSubscription<Uint8List>? _subscription;
  String _buffer = '';
  bool _isConnecting = true;
  bool _isConnected = false;

  double _plasticLevel = 0;
  double _paperLevel = 0;
  double _metalLevel = 0;

  @override
  void initState() {
    super.initState();
    _connectToDevice();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _connection?.dispose();
    super.dispose();
  }

  Future<void> _connectToDevice() async {
    try {
      final connection =
          await BluetoothConnection.toAddress(widget.device.address);
      if (!mounted) {
        await connection.close();
        return;
      }

      setState(() {
        _connection = connection;
        _isConnecting = false;
        _isConnected = true;
      });

      _subscription = connection.input?.listen(
        (bytes) => _onDataReceived(String.fromCharCodes(bytes)),
        onDone: () {
          if (!mounted) return;
          setState(() {
            _isConnected = false;
          });
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isConnecting = false;
        _isConnected = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to connect to Bluetooth device.')),
      );
    }
  }

  void _onDataReceived(String data) {
    _buffer += data;
    final lines = _buffer.split('\n');
    _buffer = lines.removeLast();

    for (final rawLine in lines) {
      final line = rawLine.trim();
      if (!line.startsWith('DATA|')) continue;

      final parts = line.split('|');
      if (parts.length != 4) continue;

      final plastic = double.tryParse(parts[1]);
      final paper = double.tryParse(parts[2]);
      final metal = double.tryParse(parts[3]);
      if (plastic == null || paper == null || metal == null) continue;

      if (!mounted) return;
      setState(() {
        _plasticLevel = (plastic.clamp(0, 100)).toDouble();
        _paperLevel = (paper.clamp(0, 100)).toDouble();
        _metalLevel = (metal.clamp(0, 100)).toDouble();
      });
    }
  }

  Future<void> _sendCommand(String command) async {
    if (_connection == null || !_isConnected) return;
    _connection!.output.add(Uint8List.fromList(command.codeUnits));
    await _connection!.output.allSent;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.device.name ?? 'Smart Bin Monitor'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _isConnecting
                  ? 'Connecting...'
                  : _isConnected
                      ? 'Connected: ${widget.device.address}'
                      : 'Disconnected',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),
            _buildLevelTile('Plastic Bin', _plasticLevel, Colors.blue),
            _buildLevelTile('Paper Bin', _paperLevel, Colors.orange),
            _buildLevelTile('Metal Bin', _metalLevel, Colors.grey),
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _isConnected ? () => _sendCommand('P') : null,
                  child: const Text('Open Plastic (P)'),
                ),
                ElevatedButton(
                  onPressed: _isConnected ? () => _sendCommand('S') : null,
                  child: const Text('Open Paper (S)'),
                ),
                ElevatedButton(
                  onPressed: _isConnected ? () => _sendCommand('M') : null,
                  child: const Text('Open Metal (M)'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelTile(String label, double value, Color color) {
    final progress = (value / 100).clamp(0, 1);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$label: ${value.toStringAsFixed(0)}%',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress.toDouble(),
                minHeight: 12,
                backgroundColor: color.withValues(alpha: 0.15),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
