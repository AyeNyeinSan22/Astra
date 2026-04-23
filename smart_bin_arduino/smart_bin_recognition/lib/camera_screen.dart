import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'dart:ui';import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
class CameraScreen extends StatefulWidget {
  final List<CameraDescription> cameras;

  const CameraScreen({super.key, required this.cameras});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> with SingleTickerProviderStateMixin {

  CameraController? _controller;
  Interpreter? _interpreter;

  List<String> _labels = [];

  bool _isPredicting = false;

  String _predictionText = "Initializing...";
  double _confidence = 0.0;
  bool _isSending = false;

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

      log("INPUT SHAPE: ${_interpreter!.getInputTensor(0).shape}");

    } catch (e) {

      log("MODEL LOAD ERROR: $e");

      _predictionText = "Model Load Error";
    }
  }

  Future<void> _loadLabels() async {

    final labelData =
    await rootBundle.loadString('assets/labels.txt');

    _labels =
        labelData.split('\n').where((e) => e.isNotEmpty).toList();

    log("LABELS: $_labels");
  }

  Future<void> _initCamera() async {

    _controller = CameraController(
      widget.cameras.first,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup:
      Platform.isAndroid
          ? ImageFormatGroup.yuv420
          : ImageFormatGroup.bgra8888,
    );

    await _controller!.initialize();

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

      img.Image? image =
      _convertCameraImage(cameraImage);

      if (image == null) {

        _isPredicting = false;

        return;
      }

      img.Image resized =
      img.copyResize(image,
          width: _inputSize,
          height: _inputSize);

      var input = _imageToInputTensor(resized);

      var output =
      List.generate(
          1,
              (_) => List.filled(
              _labels.length,
              0.0));

      _interpreter!.run(input, output);

      List<double> scores =
      output[0].cast<double>();

      int maxIndex = 0;

      double maxScore = 0;

      for (int i = 0;
      i < scores.length;
      i++) {

        if (scores[i] > maxScore) {

          maxScore = scores[i];

          maxIndex = i;
        }
      }

      setState(() {

        _predictionText =
        _labels[maxIndex];

        _confidence =
            maxScore;
      });

    } catch (e) {

      log("INFERENCE ERROR: $e");

    } finally {

      _isPredicting = false;
    }
  }

  List<List<List<List<double>>>> _imageToInputTensor(
      img.Image image) {

    return [

      List.generate(
          _inputSize,
              (y) =>

              List.generate(
                  _inputSize,
                      (x) {

                    var pixel =
                    image.getPixel(x, y);

                    return [

                      pixel.r / 255.0,

                      pixel.g / 255.0,

                      pixel.b / 255.0

                    ];
                  }))

    ];
  }

  img.Image? _convertCameraImage(
      CameraImage image) {

    if (Platform.isAndroid) {

      return _convertYUV420(image);
    }

    return null;
  }

  img.Image _convertYUV420(
      CameraImage image) {

    final width = image.width;

    final height = image.height;

    final uvRowStride =
        image.planes[1].bytesPerRow;

    final uvPixelStride =
    image.planes[1].bytesPerPixel!;

    final result =
    img.Image(width: width,
        height: height);

    for (int y = 0;
    y < height;
    y++) {

      int pY =
          y *
              image.planes[0]
                  .bytesPerRow;

      int pUV =
          (y >> 1) *
              uvRowStride;

      for (int x = 0;
      x < width;
      x++) {

        int uvOffset =
            pUV +
                (x >> 1) *
                    uvPixelStride;

        int yp =
        image.planes[0]
            .bytes[pY + x];

        int up =
        image.planes[1]
            .bytes[uvOffset];

        int vp =
        image.planes[2]
            .bytes[uvOffset];

        int r =
        (yp +
            vp *
                1436 /
                1024 -
            179)
            .round();

        int g =
        (yp -
            up *
                46549 /
                131072 +
            44 -
            vp *
                93604 /
                131072 +
            91)
            .round();

        int b =
        (yp +
            up *
                1814 /
                1024 -
            227)
            .round();

        result.setPixelRgb(
            x,
            y,
            r.clamp(0, 255),
            g.clamp(0, 255),
            b.clamp(0, 255));
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
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF2BCE82),
          ),
        ),
      );
    }

    String displayLabel = _predictionText;
    String percentageText = "";
    if (_predictionText == "Initializing..." || _predictionText == "Model Load Error") {
      displayLabel = "Scanning...";
    } else {
      percentageText = "${(_confidence * 100).toStringAsFixed(0)}%";
    }

    Color themeColor = const Color(0xFF2BCE82);
    String binName = "green bag";

    String labelLower = _predictionText.toLowerCase();
    if (labelLower.contains("paper")) {
      themeColor = Colors.blue;
      binName = "blue bin";
    } else if (labelLower.contains("plastic")) {
      themeColor = Colors.amber.shade700;
      binName = "yellow bin";
    } else if (labelLower.contains("metal")) {
      themeColor = Colors.grey.shade700;
      binName = "gray bin";
    }

    String titleCaseBinName = binName.split(' ').map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '').join(' ');

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Scan", style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.grid_view, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          children: [
            // Camera Area
            Expanded(
              flex: 5,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: SizedBox(
                      width: double.infinity,
                      height: double.infinity,
                      child: FittedBox(
                        fit: BoxFit.cover,
                        child: SizedBox(
                          width: _controller!.value.previewSize?.height ?? 1,
                          height: _controller!.value.previewSize?.width ?? 1,
                          child: CameraPreview(_controller!),
                        ),
                      ),
                    ),
                  ),
                  // Corner brackets
                  Positioned.fill(
                    child: CustomPaint(
                      painter: ScannerOverlayPainter(color: themeColor),
                    ),
                  ),
                  // Scanning Line
                  AnimatedBuilder(
                    animation: _animation,
                    builder: (context, child) {
                      return Positioned(
                        top: _animation.value * 400, // Roughly adjust based on height
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 120,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                themeColor.withOpacity(0.0),
                                themeColor.withOpacity(0.4),
                              ],
                            ),
                          ),
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: Container(
                              height: 3,
                              color: themeColor,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            // Bottom Result Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.grey.shade200, width: 2),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 10)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                displayLabel,
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                              ),
                              if (percentageText.isNotEmpty) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: themeColor.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    percentageText,
                                    style: TextStyle(color: themeColor, fontSize: 12, fontWeight: FontWeight.w800),
                                  ),
                                ),
                              ],
                              const SizedBox(width: 8),
                              Icon(Icons.recycling, color: themeColor, size: 20),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "Place item in $binName",
                            style: const TextStyle(color: Colors.black54, fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text("Points", style: TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text(
                            _predictionText == "Initializing..." ? "-" : (_confidence * 10).toInt().toString(),
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: themeColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      onPressed: _isSending ? null : () async {
                        if (_predictionText == "Initializing..." || _predictionText == "Model Load Error") return;
                        
                        setState(() {
                          _isSending = true;
                        });

                        try {
                          // Change the IP to your computer's local IP when testing on a physical device
                          var response = await http.post(
                            Uri.parse('http://10.0.2.2:5000/open_bin'),
                            headers: {'Content-Type': 'application/json'},
                            body: jsonEncode({'bin': binName}),
                          );
                          
                          if (response.statusCode == 200) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Bin opened successfully!')));
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to open bin')));
                          }
                        } catch (e) {
                          log('HTTP Error: $e');
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Network error. Check connection.')));
                        } finally {
                          if (mounted) {
                            setState(() {
                              _isSending = false;
                            });
                          }
                        }
                      },
                      child: _isSending ? const CircularProgressIndicator(color: Colors.white) : Text(
                        "Add To $titleCaseBinName",
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}

class ScannerOverlayPainter extends CustomPainter {
  final Color color;

  ScannerOverlayPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const double cornerLength = 40.0;
    const double radius = 20.0;
    const double padding = 0.0;

    // Top Left
    canvas.drawPath(Path()
      ..moveTo(padding, cornerLength + radius + padding)
      ..lineTo(padding, radius + padding)
      ..arcToPoint(const Offset(radius + padding, padding), radius: const Radius.circular(radius))
      ..lineTo(cornerLength + radius + padding, padding), paint);

    // Top Right
    canvas.drawPath(Path()
      ..moveTo(size.width - cornerLength - radius - padding, padding)
      ..lineTo(size.width - radius - padding, padding)
      ..arcToPoint(Offset(size.width - padding, radius + padding), radius: const Radius.circular(radius))
      ..lineTo(size.width - padding, cornerLength + radius + padding), paint);

    // Bottom Left
    canvas.drawPath(Path()
      ..moveTo(padding, size.height - cornerLength - radius - padding)
      ..lineTo(padding, size.height - radius - padding)
      ..arcToPoint(Offset(radius + padding, size.height - padding), radius: const Radius.circular(radius), clockwise: false)
      ..lineTo(cornerLength + radius + padding, size.height - padding), paint);

    // Bottom Right
    canvas.drawPath(Path()
      ..moveTo(size.width - cornerLength - radius - padding, size.height - padding)
      ..lineTo(size.width - radius - padding, size.height - padding)
      ..arcToPoint(Offset(size.width - padding, size.height - radius - padding), radius: const Radius.circular(radius), clockwise: false)
      ..lineTo(size.width - padding, size.height - cornerLength - radius - padding), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}