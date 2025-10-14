import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:flutter/rendering.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image_picker/image_picker.dart';
import 'package:test_project/core/theme/app_colors.dart';
import 'package:test_project/core/widgets/reusable_app_bar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class EyeGlassesArScreen extends StatefulWidget {
  const EyeGlassesArScreen({super.key});

  @override
  State<EyeGlassesArScreen> createState() => _EyeGlassesVRState();
}

class _EyeGlassesVRState extends State<EyeGlassesArScreen> {
  File? _selectedImage;
  String? _selectedSpecsAsset;
  String? _loadingStatus;
  Face? _face;
  Size? _imageSize;
  late final FaceDetector _faceDetector;

// Replace your entire guidelines list with this:
  List<GuidelineItem> guidelines = [
    // VALIDATABLE ITEMS - these have error checking
    GuidelineItem(
      guideline: 'Upload a high-quality photo with size more than 0.5 MB',
      guidelineError: 'Image too small - upload larger than 0.5 MB',
      hasError: false,
      isValidatable: true,
    ),
    GuidelineItem(
      guideline: 'Use a clear, front-facing photo with a single face only',
      guidelineError: 'Multiple faces or no face detected',
      hasError: false,
      isValidatable: true,
    ),
    GuidelineItem(
      guideline: 'Face the camera directly with both eyes visible',
      guidelineError: 'Eyes not clearly visible or face not straight',
      hasError: false,
      isValidatable: true,
    ),
    GuidelineItem(
      guideline: 'Make sure the face occupies a large portion of the photo',
      guidelineError: 'Face too small in frame - move closer',
      hasError: false,
      isValidatable: true,
    ),

    // STATIC SUGGESTIONS - no error checking, always green
    GuidelineItem(
      guideline: 'Use good, even lighting (avoid backlight)',
      guidelineError: '',
      hasError: false,
      isValidatable: false,
    ),
    GuidelineItem(
      guideline: 'Remove existing glasses, hats, or masks',
      guidelineError: '',
      hasError: false,
      isValidatable: false,
    ),
    GuidelineItem(
      guideline: 'Ensure the photo is sharp and in focus for best results',
      guidelineError: '',
      hasError: false,
      isValidatable: false,
    ),
  ];

// Update error indices to match new order
  static const int ERROR_FILE_SIZE = 0; // Upload high-quality photo
  static const int ERROR_SINGLE_FACE = 1; // Single face only
  static const int ERROR_FACE_DIRECTION = 2; // Face camera directly
  static const int ERROR_FACE_SIZE = 3; // Face occupies large portion

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

  Future<void> _processPickedImage(File file) async {
    // Initialize state and reset only validatable guideline errors
    setState(() {
      _selectedSpecsAsset = null;
      _face = null;
      _imageSize = null;
      _loadingStatus = 'Processing image...';
      for (var g in guidelines) {
        if (g.isValidatable) g.hasError = false;
      }
    });

    Fluttertoast.showToast(
      msg: 'Processing image...',
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
    );

    // STEP 1: Read image bytes
    // STEP 1: Read image bytes
    setState(() => _loadingStatus = 'Reading image...');
    var fileBytes = await file.readAsBytes();
    final fileSizeMB = fileBytes.lengthInBytes / (1024 * 1024);

// STEP 1a: Compress only if larger than 2.5 MB to reduce MLKit latency
    if (fileSizeMB > 2.5) {
      setState(() => _loadingStatus = 'Compressing image...');
      final compressedBytes = await FlutterImageCompress.compressWithList(
        fileBytes,
        minHeight: 800,
        minWidth: 600,
        quality: 80, // adjust to hit ~1–1.5 MB
        format: CompressFormat.jpeg,
      );
      // Replace fileBytes and update the file reference
      fileBytes = compressedBytes;
      final tempDir = await getTemporaryDirectory();
      final compressedFile = File(
        '${tempDir.path}/comp_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      await compressedFile.writeAsBytes(compressedBytes, flush: true);
      file = compressedFile;
    }

    // STEP 2: Check file size
    setState(() => _loadingStatus = 'Checking file size...');
    if (fileSizeMB < 0.5) {
      guidelines[ERROR_FILE_SIZE].hasError = true;
    }

    // STEP 3: Decode for dimensions (needed later for mapping and face size)
    setState(() => _loadingStatus = 'Decoding image...');
    final decoded = await decodeImageFromList(fileBytes);
    final Size pxSize =
        Size(decoded.width.toDouble(), decoded.height.toDouble());

    // STEP 4: Run face detection
    setState(() => _loadingStatus = 'Detecting face...');
    final inputImage = InputImage.fromFilePath(file.path);
    List<Face> faces = [];
    try {
      faces = await _faceDetector.processImage(inputImage);
    } catch (e) {
      // Detection failed: keep suggestions as static and finish
      setState(() {
        _loadingStatus = null; // end loading
        _imageSize = pxSize;
        _selectedImage = null;
        _face = null;
      });
      return;
    }

    // STEP 5: Validate face count
    setState(() => _loadingStatus = 'Validating face count...');
    if (faces.isEmpty) {
      guidelines[ERROR_SINGLE_FACE].hasError = true;
      guidelines[ERROR_FACE_DIRECTION].hasError = true;
    } else if (faces.length > 1) {
      guidelines[ERROR_SINGLE_FACE].hasError = true;
    }

    // STEP 6: Validate landmarks, pose, and face size (only if exactly one face)
    Face? detectedFace;
    if (faces.length == 1) {
      setState(() => _loadingStatus = 'Validating pose and visibility...');
      final face = faces.first;
      detectedFace = face;

      final leftEye = face.landmarks[FaceLandmarkType.leftEye]?.position;
      final rightEye = face.landmarks[FaceLandmarkType.rightEye]?.position;

      if (leftEye == null || rightEye == null) {
        guidelines[ERROR_FACE_DIRECTION].hasError = true;
      }

      final yaw = face.headEulerAngleY ?? 0.0;
      final roll = face.headEulerAngleZ ?? 0.0;
      if (yaw > 8 || yaw < -8 || roll > 8 || roll < -8) {
        guidelines[ERROR_FACE_DIRECTION].hasError = true;
      }

      print(face.boundingBox.width);

      if (face.boundingBox.width < 200 || face.boundingBox.height < 200) {
        guidelines[ERROR_FACE_SIZE].hasError = true;
      }
    }

    // STEP 7: Finalize based on aggregated validatable errors
    setState(() => _loadingStatus = 'Finalizing...');
    final bool hasAnyError =
        guidelines.where((g) => g.isValidatable).any((g) => g.hasError);

    if (!hasAnyError && detectedFace != null) {
      setState(() {
        _loadingStatus = null; // clear loading
        _face = detectedFace;
        _selectedImage = file;
        _imageSize = pxSize;
      });
    } else {
      setState(() {
        _loadingStatus = null; // clear loading
        _selectedImage = null; // stay on landing card to show guideline errors
        _imageSize = pxSize;
        _face = null;
      });
    }
  }

  void _clearImage() {
    setState(() {
      _selectedImage = null;
      _selectedSpecsAsset = null;
      _loadingStatus = null;
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
      appBar: AppBar(
        // leading: IconButton(
        //   onPressed: () {
        //     context.pop();
        //   },
        //   icon: Icon(Icons.arrow_back, color: Colors.white),
        // ),
        title: Text(
          'Eye Glasses AR',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.PRIMARY,
      ),
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
                  const SizedBox(height: 16),
                  if (_loadingStatus != null && _loadingStatus!.isNotEmpty)
                    Center(
                      child: Column(
                        children: [
                          CircularProgressIndicator(
                            color: AppColors.PRIMARY,
                          ),
                          Positioned(
                            top: 12,
                            left: 12,
                            right: 12,
                            child: Text(
                              _loadingStatus ?? "",
                              style: TextStyle(color: AppColors.PRIMARY),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 12),
                  _Guidelines(
                    guidelines: guidelines,
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
// In _buildTryOn, inside LayoutBuilder:
          final double viewportWidth = constraints.maxWidth;
          final double viewportHeight = constraints.maxHeight;

          final Size? originalImagePixelSize = _imageSize;

// Scale from image pixels to on-screen pixels under BoxFit.contain
          double scaleImageToViewport =
              1.0; // multiply image pixels by this to get display pixels
          double offsetViewportLeftPx =
              0.0; // left gap in the viewport after fit
          double offsetViewportTopPx = 0.0; // top gap in the viewport after fit

          if (originalImagePixelSize != null) {
            final double imagePxWidth = originalImagePixelSize.width;
            final double imagePxHeight = originalImagePixelSize.height;

            final double scaleToFitWidth = viewportWidth / imagePxWidth;
            final double scaleToFitHeight = viewportHeight / imagePxHeight;

            // BoxFit.contain picks the smaller scale
            scaleImageToViewport = math.min(scaleToFitWidth, scaleToFitHeight);

            final double renderedImageWidthPx =
                imagePxWidth * scaleImageToViewport;
            final double renderedImageHeightPx =
                imagePxHeight * scaleImageToViewport;

            // Center the rendered image in the viewport
            offsetViewportLeftPx = (viewportWidth - renderedImageWidthPx) / 2.0;
            offsetViewportTopPx =
                (viewportHeight - renderedImageHeightPx) / 2.0;
          }

          _OverlayTransform? overlay;
          if (_face != null && originalImagePixelSize != null) {
            overlay = _computeOverlayTransform(
              _face!,
              originalImagePixelSize,
              scaleImageToViewport,
              offsetViewportLeftPx,
              offsetViewportTopPx,
            );
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
    Size
        originalImagePixelSize, // image intrinsic pixel size reported by decodeImageFromList
    double
        scaleImageToViewport, // scale factor from image pixels to on-screen pixels (BoxFit.contain)
    double
        offsetViewportLeftPx, // left padding in viewport after fitting (display coords)
    double
        offsetViewportTopPx, // top padding in viewport after fitting (display coords)
  ) {
    // Landmarks in image pixel coordinates (origin at top-left of image)
    final leftEyePx = face.landmarks[FaceLandmarkType.leftEye]?.position;
    final rightEyePx = face.landmarks[FaceLandmarkType.rightEye]?.position;
    final leftEarPx = face.landmarks[FaceLandmarkType.leftEar]?.position;
    final rightEarPx = face.landmarks[FaceLandmarkType.rightEar]?.position;

    // Need at least eyes for rotation and center
    if (leftEyePx == null || rightEyePx == null) return null;

    // 1) Desired overlay width in image pixels
    // Prefer ear-to-ear span; fall back to eye distance * factor when ears are missing.
    double overlayWidthImagePx;
    if (leftEarPx != null && rightEarPx != null) {
      overlayWidthImagePx = _dist(
        leftEarPx.x.toDouble(),
        leftEarPx.y.toDouble(),
        rightEarPx.x.toDouble(),
        rightEarPx.y.toDouble(),
      );
    } else {
      final double eyeDistanceImagePx = _dist(
        leftEyePx.x.toDouble(),
        leftEyePx.y.toDouble(),
        rightEyePx.x.toDouble(),
        rightEyePx.y.toDouble(),
      );
      overlayWidthImagePx =
          eyeDistanceImagePx * 2.4; // tuned anthropometric fallback
    }

    // 2) Overlay rotation (radians) from the eye line
    final double rotationRadians = math.atan2(
      (rightEyePx.y - leftEyePx.y).toDouble(),
      (rightEyePx.x - leftEyePx.x).toDouble(),
    );

    // 3) Anchor point in image pixels: midpoint of eyes
    final double centerEyeImageX = (leftEyePx.x + rightEyePx.x) / 2.0;
    final double centerEyeImageY = (leftEyePx.y + rightEyePx.y) / 2.0;

    // 4) Vertical offset to place bridge above the eye midpoint (positive pushes downward)
    // Use a fraction of overlay width so it scales naturally with face size.
    final double bridgeOffsetImagePx =
        0.1 * overlayWidthImagePx; // negative => move up slightly

    // 5) Convert image pixel coords to display (viewport) coords using scale and offsets
    final double overlayWidthDisplayPx =
        overlayWidthImagePx * scaleImageToViewport;

    final double centerEyeDisplayX =
        centerEyeImageX * scaleImageToViewport + offsetViewportLeftPx;
    final double centerEyeDisplayY = centerEyeImageY * scaleImageToViewport +
        offsetViewportTopPx +
        bridgeOffsetImagePx * scaleImageToViewport;

    // 6) Compute Positioned's top-left for an unrotated box whose center is at (centerEyeDisplayX, centerEyeDisplayY).
    // Glasses PNG aspect varies; approximate height as a fraction of width for placement.
    // Rotation is applied around the widget center by Transform.rotate, so we position by top-left = center - (w/2, h/2).
    final double approximateOverlayHeightDisplayPx =
        overlayWidthDisplayPx * 0.5;
    final double overlayLeftDisplayPx =
        centerEyeDisplayX - (overlayWidthDisplayPx / 2.0);
    final double overlayTopDisplayPx =
        centerEyeDisplayY - (approximateOverlayHeightDisplayPx / 2.0);

    return _OverlayTransform(
      left: overlayLeftDisplayPx, // left position in viewport pixels
      top: overlayTopDisplayPx, // top position in viewport pixels
      width: overlayWidthDisplayPx, // overlay width in viewport pixels
      rotationRad: rotationRadians, // rotation to align with the eye line
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
  final List<GuidelineItem> guidelines;

  const _Guidelines({required this.guidelines});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: guidelines
          .map((guideline) => _GuidelineRow(
                text: (guideline.isValidatable && guideline.hasError)
                    ? guideline.guidelineError
                    : guideline.guideline,
                hasError: guideline.hasError,
                isValidatable: guideline.isValidatable,
              ))
          .toList(),
    );
  }
}

class _GuidelineRow extends StatelessWidget {
  final String text;
  final bool hasError;
  final bool isValidatable;

  const _GuidelineRow({
    required this.text,
    required this.hasError,
    required this.isValidatable,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isValidatable)
            Icon(
              Icons.check_circle,
              color: hasError ? Colors.red : Colors.green,
              size: 18,
            ),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

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

class GuidelineItem {
  final String guideline;
  final String guidelineError;
  final bool isValidatable;
  bool hasError;

  GuidelineItem({
    required this.guideline,
    required this.guidelineError,
    required this.hasError,
    required this.isValidatable,
  });
}
