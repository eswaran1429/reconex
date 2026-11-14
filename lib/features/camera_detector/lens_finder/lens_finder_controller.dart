import 'package:camera/camera.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:reconex/features/camera_detector/lens_finder/bright_spot_detector.dart';

/// IR: front camera sees night-vision LEDs. Glint: rear camera + torch, a lens reflects it back.
enum LensMode { ir, glint }

class LensFinderController extends GetxController with WidgetsBindingObserver {
  static const Duration _frameGap = Duration(milliseconds: 110); // ~9 fps
  static const String _noTorch = 'The torch didn\'t turn on. Hold another light right next to the camera instead.';

  final Rx<LensMode> mode = LensMode.ir.obs;
  final Rxn<CameraController> camera = Rxn<CameraController>();
  final RxList<BrightSpot> spots = <BrightSpot>[].obs;
  final RxBool isStarting = false.obs;

  /// Blocking problem (no permission, no camera). Shown instead of the preview.
  final RxnString error = RxnString();

  /// Non-blocking problem, e.g. the torch didn't turn on.
  final RxnString notice = RxnString();

  final SpotTracker _tracker = SpotTracker();
  List<CameraDescription>? _cameras;
  Future<void> _queue = Future.value();
  DateTime _lastFrame = DateTime(0);
  bool _pausedByLifecycle = false;
  bool _closed = false;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    _run(_start);
  }

  @override
  void onClose() {
    _closed = true;
    WidgetsBinding.instance.removeObserver(this);
    _run(_stop);
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) => _run(_syncLifecycle);

  /// Queued behind any start in progress, and reads the state at run time, so an
  /// event during startup (e.g. the permission dialog) is never lost.
  Future<void> _syncLifecycle() async {
    final resumed = WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    if (resumed && _pausedByLifecycle && camera.value == null) {
      _pausedByLifecycle = false;
      await _start();
    } else if (!resumed && camera.value != null) {
      // Android needs the camera released when the app leaves the foreground.
      _pausedByLifecycle = true;
      await _stop();
    }
  }

  void setMode(LensMode m) {
    if (mode.value == m) return;
    mode.value = m;
    _run(() async {
      await _stop();
      await _start();
    });
  }

  void retry() => _run(_start);

  /// Camera calls run one at a time so a quick mode switch can't open two cameras.
  void _run(Future<void> Function() op) => _queue = _queue.then((_) => op()).catchError((_) {});

  Future<void> _start() async {
    if (_closed || camera.value != null) return;
    isStarting.value = true;
    error.value = null;
    notice.value = null;
    spots.clear();
    _tracker.reset();
    CameraController? c;
    try {
      _cameras ??= await availableCameras();
      final glint = mode.value == LensMode.glint;
      final want = glint ? CameraLensDirection.back : CameraLensDirection.front;
      final desc = _cameras!.firstWhereOrNull((d) => d.lensDirection == want);
      if (desc == null) {
        error.value = glint
            ? 'No rear camera found, so glint mode can\'t run.'
            : 'No front camera found. Try glint mode with the rear camera.';
        return;
      }
      final ctrl = c = CameraController(
        desc,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );
      await ctrl.initialize();
      if (_closed || WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed) {
        _pausedByLifecycle = !_closed;
        await ctrl.dispose();
        return;
      }
      if (glint) {
        // CameraX reports torch failures on the error stream rather than throwing.
        ctrl.addListener(() {
          if (ctrl.value.errorDescription != null && notice.value == null) {
            notice.value = _noTorch;
          }
        });
        try {
          await ctrl.setFlashMode(FlashMode.torch);
        } on CameraException {
          notice.value = _noTorch;
        }
      }
      // Mode is fixed per stream, so frames from a camera being swapped out use its own mode.
      await ctrl.startImageStream((image) => _onFrame(image, glint));
      camera.value = ctrl;
    } on CameraException catch (e) {
      error.value = _describe(e);
      await c?.dispose();
    } catch (e) {
      error.value = 'Couldn\'t open the camera: $e';
      await c?.dispose();
    } finally {
      isStarting.value = false;
    }
  }

  Future<void> _stop() async {
    final c = camera.value;
    camera.value = null;
    spots.clear();
    if (c == null) return;
    try {
      if (c.value.isStreamingImages) await c.stopImageStream();
      if (c.value.flashMode == FlashMode.torch) await c.setFlashMode(FlashMode.off);
    } on CameraException {
      // Disposing below releases the camera and torch anyway.
    }
    await c.dispose();
  }

  void _onFrame(CameraImage image, bool glint) {
    final now = DateTime.now();
    if (now.difference(_lastFrame) < _frameGap || camera.value == null) return;
    _lastFrame = now;
    final yPlane = image.planes.first;
    final found = findBrightSpots(yPlane.bytes, image.width, image.height, yPlane.bytesPerRow);
    spots.assignAll(glint ? _tracker.update(found) : found);
  }

  static String _describe(CameraException e) => switch (e.code) {
    'CameraAccessDenied' => 'Camera permission is off. Allow camera access for this app in Settings, then try again.',
    'CameraPermissionsRequestOngoing' => 'A camera permission request is already open.',
    _ => 'Couldn\'t open the camera${e.description == null ? '' : ': ${e.description}'}.',
  };
}
