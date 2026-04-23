import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'dart:convert';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import '../backend/local_auth_backend.dart';
import 'home_screen.dart';

class CameraScannerScreen extends StatefulWidget {
  const CameraScannerScreen({super.key});

  @override
  State<CameraScannerScreen> createState() => _CameraScannerScreenState();
}

class _CameraScannerScreenState extends State<CameraScannerScreen> with SingleTickerProviderStateMixin {
  CameraController? _controller;
  Interpreter? _interpreter;
  List<String> _labels = [];
  bool _isPredicting = false;
  String _predictionText = "Initializing...";
  double _confidence = 0.0;
  static const int _inputSize = 224;

  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _animation = Tween<double>(begin: 0, end: 1).animate(_animationController);
    _initApp();
  }

  Future<void> _initApp() async {
    await _loadModel();
    await _loadLabels();
    await _initCamera();
  }

  Future<void> _loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/model.tflite');
      log("MODEL LOADED");
    } catch (e) {
      log("MODEL LOAD ERROR: $e");
      setState(() => _predictionText = "Model Load Error");
    }
  }

  Future<void> _loadLabels() async {
    try {
      final labelData = await rootBundle.loadString('assets/labels.txt');
      _labels = labelData.split('\n').where((e) => e.isNotEmpty).toList();
      log("LABELS: $_labels");
    } catch (e) {
      log("LABEL LOAD ERROR: $e");
    }
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;

    _controller = CameraController(
      cameras.first,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid ? ImageFormatGroup.yuv420 : ImageFormatGroup.bgra8888,
    );

    await _controller!.initialize();
    if (!mounted) return;
    setState(() {});

    _controller!.startImageStream((CameraImage image) {
      if (!_isPredicting) {
        _isPredicting = true;
        _runInference(image);
      }
    });
  }

  Future<void> _runInference(CameraImage cameraImage) async {
    if (_interpreter == null) {
      _isPredicting = false;
      return;
    }

    try {
      img.Image? image = _convertCameraImage(cameraImage);
      if (image == null) {
        _isPredicting = false;
        return;
      }

      img.Image resized = img.copyResize(image, width: _inputSize, height: _inputSize);
      var input = _imageToInputTensor(resized);
      var output = List.generate(1, (_) => List.filled(_labels.length, 0.0));

      _interpreter!.run(input, output);
      List<double> scores = output[0].cast<double>();

      int maxIndex = 0;
      double maxScore = 0;
      for (int i = 0; i < scores.length; i++) {
        if (scores[i] > maxScore) {
          maxScore = scores[i];
          maxIndex = i;
        }
      }

      if (mounted) {
        setState(() {
          _predictionText = _labels[maxIndex];
          _confidence = maxScore;
        });
      }
    } catch (e) {
      log("INFERENCE ERROR: $e");
    } finally {
      _isPredicting = false;
    }
  }

  List<List<List<List<double>>>> _imageToInputTensor(img.Image image) {
    return [
      List.generate(_inputSize, (y) => List.generate(_inputSize, (x) {
        var pixel = image.getPixel(x, y);
        return [pixel.r / 255.0, pixel.g / 255.0, pixel.b / 255.0];
      }))
    ];
  }

  img.Image? _convertCameraImage(CameraImage image) {
    try {
      if (Platform.isAndroid) return _convertYUV420(image);
      return null;
    } catch (e) {
      return null;
    }
  }

  img.Image _convertYUV420(CameraImage image) {
    final width = image.width;
    final height = image.height;
    final uvRowStride = image.planes[1].bytesPerRow;
    final uvPixelStride = image.planes[1].bytesPerPixel!;

    final result = img.Image(width: width, height: height);

    for (int y = 0; y < height; y++) {
      int pY = y * image.planes[0].bytesPerRow;
      int pUV = (y >> 1) * uvRowStride;
      for (int x = 0; x < width; x++) {
        int uvOffset = pUV + (x >> 1) * uvPixelStride;
        int yp = image.planes[0].bytes[pY + x];
        int up = image.planes[1].bytes[uvOffset];
        int vp = image.planes[2].bytes[uvOffset];

        int r = (yp + vp * 1436 / 1024 - 179).round();
        int g = (yp - up * 46549 / 131072 + 44 - vp * 93604 / 131072 + 91).round();
        int b = (yp + up * 1814 / 1024 - 227).round();

        result.setPixelRgb(x, y, r.clamp(0, 255), g.clamp(0, 255), b.clamp(0, 255));
      }
    }
    return result;
  }

  @override
  void dispose() {
    _animationController.dispose();
    _controller?.dispose();
    _interpreter?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Color(0xFF94D051))),
      );
    }

    String displayLabel = _predictionText;
    if (_predictionText == "Initializing...") displayLabel = "Scanning...";

    Color themeColor = const Color(0xFF94D051);
    String binName = "General Waste";
    String labelLower = _predictionText.toLowerCase();

    if (labelLower.contains("paper")) {
      themeColor = Colors.orange;
      binName = "Paper Bin";
    } else if (labelLower.contains("plastic")) {
      themeColor = Colors.blue;
      binName = "Plastic Bin";
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Text('Astra AI Scanner', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                  const Icon(Icons.info_outline, color: Colors.white),
                ],
              ),
            ),
            
            // Camera Area
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: CameraPreview(_controller!),
                    ),
                    // Reticle
                    Positioned.fill(
                      child: CustomPaint(painter: ScannerReticlePainter(color: themeColor)),
                    ),
                    // Scan Line
                    AnimatedBuilder(
                      animation: _animation,
                      builder: (context, child) {
                        return Positioned(
                          top: _animation.value * (MediaQuery.of(context).size.height * 0.5),
                          left: 20, right: 20,
                          child: Container(
                            height: 2,
                            decoration: BoxDecoration(
                              color: themeColor,
                              boxShadow: [BoxShadow(color: themeColor.withValues(alpha: 0.5), blurRadius: 10, spreadRadius: 2)],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Info Card
            Container(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, 10))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: themeColor.withValues(alpha: 0.1), shape: BoxShape.circle),
                        child: Icon(Icons.recycling, color: themeColor, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayLabel.toUpperCase(),
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D3142)),
                            ),
                            Text("Match: ${(_confidence * 100).toInt()}% • Place in $binName", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                      ),
                      Column(
                        children: [
                          const Text("PTS", style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
                          Text("+${(_confidence * 15).toInt()}", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: themeColor)),
                        ],
                      )
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: themeColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        elevation: 0,
                      ),
                      onPressed: () {
                        if (_predictionText == "Initializing...") {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (_) => const HomeScreen()),
                            (route) => false,
                          );
                          return;
                        }

                        final int earnedPoints = (_confidence * 15).toInt();
                        final double earnedCo2 = _confidence * 40.0;
                        final String prediction = _predictionText;
                        final String category = binName.split(' ').first.toLowerCase();

                        // 1. Add points immediately (Local state update)
                        LocalAuthBackend.addImpact(
                          title: 'Recycled $prediction',
                          points: earnedPoints,
                          co2: earnedCo2,
                          items: 1,
                          type: 'recycle',
                        );

                        // 2. Fire and forget the backend signal
                        http.post(
                          Uri.parse('http://10.0.2.2:5001/open_bin'),
                          headers: {'Content-Type': 'application/json'},
                          body: jsonEncode({'bin': category}),
                        ).timeout(const Duration(seconds: 2)).catchError((_) => http.Response('timeout', 408));

                        // 3. Render Home Screen immediately
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const HomeScreen()),
                          (route) => false,
                        );
                      },
                      child: const Text("DONE",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ScannerReticlePainter extends CustomPainter {
  final Color color;
  ScannerReticlePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..strokeWidth = 4.0..style = PaintingStyle.stroke;
    const double length = 40.0;
    canvas.drawPath(Path()..moveTo(0, length)..lineTo(0, 0)..lineTo(length, 0), paint);
    canvas.drawPath(Path()..moveTo(size.width - length, 0)..lineTo(size.width, 0)..lineTo(size.width, length), paint);
    canvas.drawPath(Path()..moveTo(0, size.height - length)..lineTo(0, size.height)..lineTo(length, size.height), paint);
    canvas.drawPath(Path()..moveTo(size.width - length, size.height)..lineTo(size.width, size.height)..lineTo(size.width, size.height - length), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
