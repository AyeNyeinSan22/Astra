import 'package:permission_handler/permission_handler.dart';

Future<bool> ensureBluetoothPermissions() async {
  final statuses = await [
    Permission.bluetoothConnect,
    Permission.bluetoothScan,
  ].request();
  return statuses.values.every((status) => status.isGranted);
}
