import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:flutter/rendering.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image_picker/image_picker.dart';
import 'package:test_project/core/widgets/reusable_app_bar.dart';
import 'package:path_provider/path_provider.dart';

class EyeGlassesArScreen extends StatefulWidget {
  const EyeGlassesArScreen({super.key});

  @override
  State<EyeGlassesArScreen> createState() => _EyeGlassesVRState();
}

class _EyeGlassesVRState extends State<EyeGlassesArScreen> {
  File? _selectedImage;
  String? _selectedSpecsAsset;
  String? _status;
  Face? _face;
  Size? _imageSize;
  late final FaceDetector _faceDetector;

  @override
  void initState() {
    super.initState();
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        performanceMode: FaceDetectorMode.accurate,
        enableLandmarks: true,
        enableContours: true,
        enableClassification: false,
        minFaceSize: 0.2,
      ),
    );
  }

  @override
  void dispose() {
    _faceDetector.close();
    super.dispose();
  }

  final List<String> specsAssets = const [
    'assets/images/square_black_frame_specs.png',
    'assets/images/round_black_frame_specs.png',
  ];

  Future<void> _onPickFromCameraPressed() async {
    final file = await ImagePicker().pickImage(source: ImageSource.camera);
    if (file == null) return;
    await _processPickedImage(File(file.path));
  }

  // Future<void> _onPickFromGalleryPressed() async {
  //   final file = await ImagePicker().pickImage(source: ImageSource.gallery);
  //   if (file == null) return;
  //   await _processPickedImage(File(file.path));
  // }

  Future<void> _onPickFromGalleryPressed() async {
    final x = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (x == null) return;

    // Read bytes from gallery and save to app cache to ensure a stable file path
    final bytes = await x.readAsBytes();
    final dir = await getTemporaryDirectory(); // import path_provider
    final tmp =
        File('${dir.path}/gal_${DateTime.now().millisecondsSinceEpoch}.jpg');
    await tmp.writeAsBytes(bytes, flush: true);

    await _processPickedImage(tmp);
  }

  // Future<void> _processPickedImage(File file) async {
  // setState(() {
  //   _selectedImage = file;
  //   _selectedSpecsAsset = null;
  //   _status = 'Processing image...';
  //   _face = null;
  //   _imageSize = null;
  // });

  // final bytes = await file.readAsBytes();
  // final decoded = await decodeImageFromList(bytes);
  // final pxSize = Size(decoded.width.toDouble(), decoded.height.toDouble());

  // List<Face> faces = const [];
  // try {
  //   final inputImage = InputImage.fromFilePath(file.path);
  //   faces = await _faceDetector.processImage(inputImage);
  // } catch (_) {
  //   // Fallback: re-encode upright and retry once
  //   try {
  //     final fixed = await _reencodeUprightPng(bytes);
  //     final input2 = InputImage.fromFilePath(fixed.path);
  //     faces = await _faceDetector.processImage(input2);
  //   } catch (e2) {
  //     setState(() {
  //       _status = 'Failed to run face detection. Please try another photo.';
  //       _imageSize = pxSize;
  //     });
  //     return;
  //   }
  // }
  Future<void> _processPickedImage(File file) async {
    setState(() {
      _selectedImage = file;
      _selectedSpecsAsset = null;
      _status = 'Processing image...';
      _face = null;
      _imageSize = null;
    });

    final decoded = await decodeImageFromList(await file.readAsBytes());
    final Size pxSize =
        Size(decoded.width.toDouble(), decoded.height.toDouble());

    final inputImage = InputImage.fromFilePath(file.path);
    List<Face> faces;
    try {
      faces = await _faceDetector.processImage(inputImage);
    } catch (e) {
      print("image processing failed : $e");
      setState(() {
        _status = 'Failed to run face detection. Please try another photo.';
        _face = null;
        _imageSize = pxSize;
      });
      return;
    }
    if (faces.isEmpty) {
      setState(() {
        _status =
            'Face not detected — use a clear, front-facing photo in good light.';
        _face = null;
        _imageSize = pxSize;
      });
      return;
    }
    if (faces.length > 1) {
      setState(() {
        _status =
            'Multiple faces detected — choose a photo with only one face.';
        _face = null;
        _imageSize = pxSize;
      });
      return;
    }

    final face = faces.first;

    final leftEye = face.landmarks[FaceLandmarkType.leftEye]?.position;
    final rightEye = face.landmarks[FaceLandmarkType.rightEye]?.position;
    final leftEar = face.landmarks[FaceLandmarkType.leftEar]?.position;
    final rightEar = face.landmarks[FaceLandmarkType.rightEar]?.position;

    final yaw = face.headEulerAngleY ?? 0.0;
    final roll = face.headEulerAngleZ ?? 0.0;

    String? message;
    if (leftEye == null || rightEye == null) {
      message = 'Eyes not clearly visible — face the camera directly.';
    } else if (leftEar == null || rightEar == null) {
      message = 'Only one ear visible — please look straight at the camera.';
    } else if (yaw.abs() > 12 || roll.abs() > 12) {
      message = 'Please face the camera directly with minimal tilt.';
    } else if (face.boundingBox.width < 200 || face.boundingBox.height < 200) {
      message = 'Move closer for a larger face in frame (better accuracy).';
    }

    setState(() {
      _face = (message == null) ? face : null;
      _selectedImage = file;
      // _status = message ?? 'Perfect! Tap on a pair of glasses to try them on.';
      _status = message;
      _imageSize = pxSize;
    });
  }

  // Future<File> _reencodeUprightPng(List<int> bytes) async {
  //   final codec = await instantiateImageCodec(bytes);
  //   final frame = await codec.getNextFrame();
  //   final uiImage = frame.image;
  //   final bd = await uiImage.toByteData(format: ImageByteFormat.png);
  //   final dir = await getTemporaryDirectory(); // path_provider
  //   final out = File(
  //       '${dir.path}/upright_${DateTime.now().millisecondsSinceEpoch}.png');
  //   await out.writeAsBytes(bd!.buffer.asUint8List(), flush: true);
  //   return out;
  // }

  void _clearImage() {
    setState(() {
      _selectedImage = null;
      _selectedSpecsAsset = null;
      _status = null;
      _face = null;
      _imageSize = null;
    });
  }

  void _selectSpecs(String? assetPath) {
    setState(() => _selectedSpecsAsset = assetPath);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ReusableAppBar(title: "Eye Glasses AR"),
      body: _selectedImage == null
          ? _buildLandingCard(context)
          : _buildTryOn(context),
    );
  }

  // Landing card with guidance and capsule button
  Widget _buildLandingCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Card(
            elevation: 3,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Tap to capture or upload a photo to try eyeglasses',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  _Guidelines(),
                  const SizedBox(height: 16),
                  if (_status != null)
                    Positioned(
                      top: 12,
                      left: 12,
                      right: 12,
                      child: Text(_status ?? ""),
                    ),
                  const SizedBox(height: 16),
                  Material(
                    elevation: 2,
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      width: double.infinity,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          InkWell(
                            onTap: _onPickFromCameraPressed,
                            borderRadius: const BorderRadius.horizontal(
                                left: Radius.circular(24)),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Row(
                                children: [
                                  Icon(Icons.camera_alt, size: 18),
                                  SizedBox(width: 6),
                                  Text('Camera',
                                      style: TextStyle(fontSize: 14)),
                                ],
                              ),
                            ),
                          ),
                          Container(
                              width: 1,
                              height: 24,
                              color: Colors.grey.shade300),
                          InkWell(
                            onTap: _onPickFromGalleryPressed,
                            borderRadius: const BorderRadius.horizontal(
                                right: Radius.circular(24)),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Row(
                                children: [
                                  Icon(Icons.insert_drive_file, size: 18),
                                  SizedBox(width: 6),
                                  Text('File', style: TextStyle(fontSize: 14)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTryOn(BuildContext context) {
    final File? file = _selectedImage;
    if (file == null) return const SizedBox.shrink();

    return Column(
      children: [
        Expanded(child: LayoutBuilder(builder: (context, constraints) {
          final displayW = constraints.maxWidth;
          final displayH = constraints.maxHeight;

          final size = _imageSize;
          double scale = 1, dx = 0, dy = 0;
          if (size != null) {
            final imgW = size.width;
            final imgH = size.height;
            final scaleW = displayW / imgW;
            final scaleH = displayH / imgH;
            scale = math.min(scaleW, scaleH);
            final renderW = imgW * scale;
            final renderH = imgH * scale;
            dx = (displayW - renderW) / 2;
            dy = (displayH - renderH) / 2;
          }

          _OverlayTransform? overlay;
          if (_face != null && _imageSize != null) {
            overlay =
                _computeOverlayTransform(_face!, _imageSize!, scale, dx, dy);
          }

          return Stack(
            children: [
              Positioned.fill(
                child: Image.file(file, fit: BoxFit.contain),
              ),
              if (_selectedSpecsAsset != null && overlay != null)
                Positioned(
                  left: overlay.left,
                  top: overlay.top,
                  child: Transform.rotate(
                    angle: overlay.rotationRad,
                    child: Image.asset(
                      _selectedSpecsAsset!,
                      width: overlay.width,
                      fit: BoxFit.contain,
                    ),
                  ),
                )
            ],
          );
        })),
        SizedBox(
          height: 110,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Text('Choose eyeglasses',
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ),
              Expanded(
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: specsAssets.length + 1, // +1 for None
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      final isSelected = _selectedSpecsAsset == null;
                      return _SpecsChip(
                        label: 'None',
                        isSelected: isSelected,
                        onTap: () => _selectSpecs(null),
                        thumbnail: const Icon(Icons.block, size: 28),
                      );
                    }
                    final asset = specsAssets[index - 1];
                    final isSelected = _selectedSpecsAsset == asset;
                    return _SpecsChip(
                      label: 'Specs ${index}',
                      isSelected: isSelected,
                      onTap: () => _selectSpecs(asset),
                      thumbnail: Image.asset(asset, fit: BoxFit.contain),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        // Remove image button
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton.icon(
              onPressed: _clearImage,
              icon: const Icon(Icons.delete_outline),
              label: const Text('Remove Image'),
            ),
          ),
        ),
      ],
    );
  }

  _OverlayTransform? _computeOverlayTransform(
    Face face,
    Size imageSize,
    double scale,
    double dx,
    double dy,
  ) {
    final leftEye = face.landmarks[FaceLandmarkType.leftEye]?.position;
    final rightEye = face.landmarks[FaceLandmarkType.rightEye]?.position;
    final leftEar = face.landmarks[FaceLandmarkType.leftEar]?.position;
    final rightEar = face.landmarks[FaceLandmarkType.rightEar]?.position;
    if (leftEye == null || rightEye == null) return null;

    double widthPx;
    if (leftEar != null && rightEar != null) {
      widthPx = _dist(leftEar.x.toDouble(), leftEar.y.toDouble(),
          rightEar.x.toDouble(), rightEar.y.toDouble());
    } else {
      final eyeDist = _dist(leftEye.x.toDouble(), leftEye.y.toDouble(),
          rightEye.x.toDouble(), rightEye.y.toDouble());
      widthPx = eyeDist * 2.4; // estimate full face width based on eye distance
    }

    final angle = math.atan2(
      (rightEye.y - leftEye.y).toDouble(),
      (rightEye.x - leftEye.x).toDouble(),
    );

    final cxPx = (leftEye.x + rightEye.x) / 2.0;
    final cyPx = (leftEye.y + rightEye.y) / 2.0;
    final verticalOffsetPx = 0.12 * widthPx;

    final widthDisplay = widthPx * scale;
    final cxDisplay = cxPx * scale + dx;
    final cyDisplay = cyPx * scale + dy + verticalOffsetPx * scale;

    final left = cxDisplay - widthDisplay / 2.0;
    final top = cyDisplay - (widthDisplay * 0.25);

    return _OverlayTransform(
      left: left,
      top: top,
      width: widthDisplay,
      rotationRad: angle,
    );
  }

  double _dist(double x1, double y1, double x2, double y2) {
    final dx = x2 - x1;
    final dy = y2 - y1;
    return math.sqrt(dx * dx + dy * dy);
  }
}

class _OverlayTransform {
  final double left;
  final double top;
  final double width;
  final double rotationRad;
  _OverlayTransform({
    required this.left,
    required this.top,
    required this.width,
    required this.rotationRad,
  });
}

class _Guidelines extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text('Face the camera directly with both eyes visible'),
        Text('Use good, even lighting (avoid backlight)'),
        Text('Remove existing glasses, hats, or masks'),
        Text('Upload a high‑quality photo for better results'),
        Text('Recommended aspect ratios: 1:1, 4:5, or 2:3'),
      ],
    );
  }
}

// class _GuidelineRow extends StatelessWidget {
//   final String text;
//   const _GuidelineRow({required this.text});

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 4),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Icon(Icons.check_circle, color: Colors.green, size: 18),
//           const SizedBox(width: 8),
//           Expanded(child: Text(text)),
//         ],
//       ),
//     );
//   }
// }

class _SpecsChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Widget thumbnail;

  const _SpecsChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.thumbnail,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 88,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue.shade50 : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? Colors.blue : Colors.grey.shade300,
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Expanded(child: Center(child: thumbnail)),
              const SizedBox(height: 6),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
