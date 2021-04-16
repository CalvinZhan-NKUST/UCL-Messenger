import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:ext_storage/ext_storage.dart';
import 'package:flutter/material.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:media_scanner_scan_file/media_scanner_scan_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_msg/screens/ChatRoom.dart';

class CameraView extends StatefulWidget {
  @override
  _CameraViewHomeState createState() {
    return _CameraViewHomeState();
  }
}

/// Returns a suitable camera icon for [direction].
IconData getCameraLensIcon(CameraLensDirection direction) {
  switch (direction) {
    case CameraLensDirection.back:
      return Icons.camera_rear;
    case CameraLensDirection.front:
      return Icons.camera_front;
    case CameraLensDirection.external:
      return Icons.camera;
  }
  throw ArgumentError('Unknown lens direction');
}

void logError(String code, String message) =>
    print('Error: $code\nError Message: $message');

class _CameraViewHomeState extends State<CameraView>
    with WidgetsBindingObserver {
  CameraController controller;
  String imagePath;
  String videoPath;
  int countTime = 0;
  VideoPlayerController videoController;
  VoidCallback videoPlayerListener;
  bool enableAudio = true;
  Timer videoRecordTimer;

  Future<void> permissionRequest() async {
    Map<Permission, PermissionStatus> status = await [
      Permission.notification,
      Permission.camera,
      Permission.storage,
      Permission.microphone,
      Permission.mediaLibrary,
      Permission.accessMediaLocation
    ].request();
  }

  List<CameraDescription> cameras = [];

  void getCameraList() async {
    // Fetch the available cameras before initializing the app.
    try {
      WidgetsFlutterBinding.ensureInitialized();
      cameras = await availableCameras();
      setState(() {});
    } on CameraException catch (e) {
      logError(e.code, e.description);
    }
//    runApp(CameraView());
  }

  @override
  void initState() {
    super.initState();
    permissionRequest();
    getCameraList();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    disposeController();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void disposeController() async{
    if (controller!=null){
      await controller.dispose();
      controller = null;
    }
    if (videoController!=null){
      await videoController.dispose();
      videoController = null;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // App state changed before we got the chance to initialize.
    if (controller == null || !controller.value.isInitialized) {
      return;
    }
    if (state == AppLifecycleState.inactive) {
      controller?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      if (controller != null) {
        onNewCameraSelected(controller.description);
      }
    }
  }

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white54,
      key: _scaffoldKey,
      body: Column(
        children: <Widget>[
          SizedBox(
              height: 20,
              child: Container(
                color: Colors.black,
              )),
          Expanded(
              flex: 1,
              child: Container(
                  color: Colors.black,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                        icon: Icon(Icons.arrow_back),
                        alignment: Alignment.centerLeft,
                        color: Colors.white,
                        onPressed: () async {
                          if (controller != null) {
                            await controller.dispose();
                          }
                          Navigator.of(context).pop();
                        }),
                  ))),
          Expanded(
            flex: 10,
            child: Container(
              child: Padding(
                padding: const EdgeInsets.all(1.0),
                child: Center(
                  child: _cameraPreviewWidget(),
                ),
              ),
              decoration: BoxDecoration(
                color: Colors.black,
                border: Border.all(
                  color: controller != null && controller.value.isRecordingVideo
                      ? Colors.redAccent
                      : Colors.white,
                  width: 3.0,
                ),
              ),
            ),
          ),
          _captureControlRowWidget(),
//          _toggleAudioWidget(),
          Padding(
            padding: const EdgeInsets.all(5.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                _cameraTogglesRowWidget(),
                _thumbnailWidget(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Display the preview from the camera (or a message if the preview is not available).
  Widget _cameraPreviewWidget() {
    if (controller == null || !controller.value.isInitialized) {
      return const Text(
        'Tap a camera',
        style: TextStyle(
          color: Colors.white,
          fontSize: 24.0,
          fontWeight: FontWeight.w900,
        ),
      );
    } else {
      return AspectRatio(
        aspectRatio: controller.value.aspectRatio,
        child: CameraPreview(controller),
      );
    }
  }

  Widget _thumbnailWidget() {
    return Expanded(
      child: Align(
        alignment: Alignment.centerRight,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            videoController == null && imagePath == null
                ? Container()
                : SizedBox(
                    child: (videoController == null)
                        ? Image.file(File(imagePath))
                        : Container(
                            child: Center(
                              child: AspectRatio(
                                  aspectRatio:
                                      videoController.value.size != null
                                          ? videoController.value.aspectRatio
                                          : 1.0,
                                  child: VideoPlayer(videoController)),
                            ),
                            decoration: BoxDecoration(
                                border: Border.all(color: Colors.pink)),
                          ),
                    width: 64.0,
                    height: 64.0,
                  ),
          ],
        ),
      ),
    );
  }

  Widget _captureControlRowWidget() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      mainAxisSize: MainAxisSize.max,
      children: <Widget>[
        IconButton(
          icon: Icon(Icons.camera_alt),
          color: Colors.blue,
          onPressed: controller != null &&
                  controller.value.isInitialized &&
                  !controller.value.isRecordingVideo
              ? onTakePictureButtonPressed
              : null,
        ),
        IconButton(
          icon: Icon(Icons.videocam),
          color: Colors.blue,
          onPressed: controller != null &&
                  controller.value.isInitialized &&
                  !controller.value.isRecordingVideo
              ? onVideoRecordButtonPressed
              : null,
        ),
        IconButton(
          icon: Icon(Icons.stop),
          color: Colors.red,
          onPressed: controller != null &&
                  controller.value.isInitialized &&
                  controller.value.isRecordingVideo
              ? onStopButtonPressed
              : null,
        )
      ],
    );
  }

  Widget _cameraTogglesRowWidget() {
    final List<Widget> toggles = <Widget>[];

    if (cameras.isEmpty) {
      return const Text('No camera found');
    } else {
      for (CameraDescription cameraDescription in cameras) {
        toggles.add(
          SizedBox(
            width: 90.0,
            child: RadioListTile<CameraDescription>(
              title: Icon(
                getCameraLensIcon(cameraDescription.lensDirection),
                color: Colors.black,
              ),
              groupValue: controller?.description,
              value: cameraDescription,
              onChanged: controller != null && controller.value.isRecordingVideo
                  ? null
                  : onNewCameraSelected,
            ),
          ),
        );
      }
    }

    return Row(children: toggles);
  }

  String timestamp() => DateTime.now().millisecondsSinceEpoch.toString();

  void showInSnackBar(String message) {
    _scaffoldKey.currentState.showSnackBar(SnackBar(content: Text(message)));
  }

  void onNewCameraSelected(CameraDescription cameraDescription) async {
    if (await Permission.storage.request().isGranted) {
      print("授權已經取得");
    } else {
      print("授權尚未取得");
    }
    if (controller != null) {
      await controller.dispose();
    }
    controller = CameraController(
      cameraDescription,
      ResolutionPreset.medium,
      enableAudio: enableAudio,
    );

    // If the controller is updated then update the UI.
    controller.addListener(() {
      if (mounted) setState(() {});
      if (controller.value.hasError) {
        showInSnackBar('Camera error ${controller.value.errorDescription}');
      }
    });

    try {
      await controller.initialize();
    } on CameraException catch (e) {
      _showCameraException(e);
    }

    if (mounted) {
      setState(() {});
    }
  }

  void onTakePictureButtonPressed() {
    takePicture().then((String filePath) {
      if (mounted) {
        setState(() {
          imagePath = filePath;
          videoController?.dispose();
          videoController = null;
        });
        uploadVideoAndImage('Image', filePath);
        if (Platform.isAndroid) {
          _scanFile(File(filePath));
        }else{
          GallerySaver.saveImage(filePath);
        }
        Navigator.of(context).pop();
      }
    });
  }

  void onVideoRecordButtonPressed() {
    startVideoRecording().then((String filePath) {
      countVideoRecordTime();
      if (mounted) setState(() {});
//      if (filePath != null) showInSnackBar('Saving video to $filePath');
    });
  }

  void countVideoRecordTime() {
    videoRecordTimer = new Timer.periodic(Duration(seconds: 1), (Timer timer) {
      countTime++;
      if (countTime >= 60) onStopButtonPressed();
    });
  }

  void onStopButtonPressed() {
    stopVideoRecording().then((_) {
      if (mounted) setState(() {});
//      showInSnackBar('Video recorded to: $videoPath');
      uploadVideoAndImage('Video', videoPath);
      if (Platform.isAndroid){
        _scanFile(File(videoPath));
      }else{
        GallerySaver.saveVideo(videoPath);
      }
      videoRecordTimer.cancel();
      videoRecordTimer = null;
      countTime = 0;
      Navigator.of(context).pop();
    });
  }

  Future<String> startVideoRecording() async {
    if (!controller.value.isInitialized) {
      showInSnackBar('Error: select a camera first.');
      return null;
    }
    String filePath = '';
    if (Platform.isAndroid) {
      final String extDir = await ExtStorage.getExternalStoragePublicDirectory(
          ExtStorage.DIRECTORY_DCIM);
      print('Android path：' + extDir.toString());
      await Directory(extDir).create(recursive: true);
      filePath = '$extDir/${timestamp()}.mp4';
    } else if (Platform.isIOS) {
      final String dir = (await getApplicationDocumentsDirectory()).path;
      filePath = '$dir/${timestamp()}.mp4';
      print('iOS path:$filePath');
    }

    if (controller.value.isRecordingVideo) {
      // A recording is already started, do nothing.
      return null;
    }

    try {
      videoPath = filePath;
      await controller.startVideoRecording(filePath);
    } on CameraException catch (e) {
      _showCameraException(e);
      return null;
    }
    return filePath;
  }

  Future<void> stopVideoRecording() async {
    if (!controller.value.isRecordingVideo) {
      return null;
    }

    try {
      await controller.stopVideoRecording();
    } on CameraException catch (e) {
      _showCameraException(e);
      return null;
    }

    await _startVideoPlayer();
  }

  Future<void> _startVideoPlayer() async {
    final VideoPlayerController vcontroller =
        VideoPlayerController.file(File(videoPath));
    videoPlayerListener = () {
      if (videoController != null && videoController.value.size != null) {
        // Refreshing the state to update video player with the correct ratio.
        if (mounted) setState(() {});
        videoController.removeListener(videoPlayerListener);
      }
    };
    vcontroller.addListener(videoPlayerListener);
    await vcontroller.setLooping(false);
    await vcontroller.initialize();
    await videoController?.dispose();
    if (mounted) {
      setState(() {
        imagePath = null;
        videoController = vcontroller;
      });
    }
    await vcontroller.play();
  }

  Future<String> takePicture() async {
    if (!controller.value.isInitialized) {
      showInSnackBar('Error: select a camera first.');
      return null;
    }
    String filePath = '';
    if (Platform.isAndroid) {
      final String dirPath = await ExtStorage.getExternalStoragePublicDirectory(
          ExtStorage.DIRECTORY_DCIM);
      print('android path：' + dirPath.toString());
      await Directory(dirPath).create(recursive: true);
      filePath = '$dirPath/${timestamp()}.jpg';
    } else if (Platform.isIOS) {
      final String dir = (await getApplicationDocumentsDirectory()).path;
      await Directory(dir).create(recursive: true);
      filePath = '$dir/${timestamp()}.jpg';
      print('iOS path:$filePath');
    }

    if (controller.value.isTakingPicture) {
      // A capture is already pending, do nothing.
      return null;
    }

    try {
      await controller.takePicture(filePath);
    } on CameraException catch (e) {
      _showCameraException(e);
      return null;
    }
    return filePath;
  }

  void _showCameraException(CameraException e) {
    logError(e.code, e.description);
    showInSnackBar('Error: ${e.code}\n${e.description}');
  }

  Future<String> _scanFile(File f) async {
    final result = await MediaScannerScanFile.scanFile(f.path);
    if (Platform.isAndroid) {
      return result['filePath'];
    } else {
      return result[0];
    }
  }
}
