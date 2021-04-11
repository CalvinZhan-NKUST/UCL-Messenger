import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:ext_storage/ext_storage.dart';
import 'package:flutter/material.dart';
import 'package:media_scanner_scan_file/media_scanner_scan_file.dart';
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
    Map<Permission, PermissionStatus> status =
    await [Permission.notification, Permission.camera, Permission.storage, Permission.microphone].request();
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
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
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
          SizedBox(height: 20,child:Container(
            color: Colors.black,
          )),
          Expanded(
              flex:1,child: Container(
            color: Colors.black,
          child:Align(
            alignment: Alignment.centerLeft,
            child:IconButton(
                icon: Icon(Icons.arrow_back),
                alignment: Alignment.centerLeft,
                color: Colors.white,
                onPressed: () {
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

  /// Toggle recording audio
//  Widget _toggleAudioWidget() {
//    return Padding(
//      padding: const EdgeInsets.only(left: 25),
//      child: Row(
//        children: <Widget>[
//          const Text('Enable Audio:'),
//          Switch(
//            value: enableAudio,
//            onChanged: (bool value) {
//              enableAudio = value;
//              if (controller != null) {
//                onNewCameraSelected(controller.description);
//              }
//            },
//          ),
//        ],
//      ),
//    );
//  }

  /// Display the thumbnail of the captured image or video.
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

  /// Display the control bar with buttons to take pictures and record videos.
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

  /// Display a row of toggle to select the camera (or a message if no camera is available).
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
              title: Icon(getCameraLensIcon(cameraDescription.lensDirection),color: Colors.black,),
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
//        if (filePath != null) showInSnackBar('Picture saved to $filePath');
        uploadVideoAndImage('Image', filePath);
        _scanFile(File(filePath));
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

  void countVideoRecordTime(){
    videoRecordTimer = new Timer.periodic(Duration(seconds: 1), (Timer timer) {
      countTime++;
      if (countTime>=60)
        onStopButtonPressed();
    });
  }


  void onStopButtonPressed() {
    stopVideoRecording().then((_) {
      if (mounted) setState(() {});
//      showInSnackBar('Video recorded to: $videoPath');
      _scanFile(File(videoPath));
      uploadVideoAndImage('Video', videoPath);
      videoRecordTimer.cancel();
      videoRecordTimer = null;
      countTime = 0;
      Navigator.of(context).pop();
    });
  }

  void onPauseButtonPressed() {
    pauseVideoRecording().then((_) {
      if (mounted) setState(() {});
      showInSnackBar('Video recording paused');
    });
  }

  void onResumeButtonPressed() {
    resumeVideoRecording().then((_) {
      if (mounted) setState(() {});
      showInSnackBar('Video recording resumed');
    });
  }

  Future<String> startVideoRecording() async {
    if (!controller.value.isInitialized) {
      showInSnackBar('Error: select a camera first.');
      return null;
    }

    final String extDir = await ExtStorage.getExternalStoragePublicDirectory(
        ExtStorage.DIRECTORY_DCIM);
    print('exDir：' + extDir.toString());
    await Directory(extDir).create(recursive: true);
    final String filePath = '$extDir/${timestamp()}.mp4';

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

  Future<void> pauseVideoRecording() async {
    if (!controller.value.isRecordingVideo) {
      return null;
    }

    try {
      await controller.pauseVideoRecording();
    } on CameraException catch (e) {
      _showCameraException(e);
      rethrow;
    }
  }

  Future<void> resumeVideoRecording() async {
    if (!controller.value.isRecordingVideo) {
      return null;
    }

    try {
      await controller.resumeVideoRecording();
    } on CameraException catch (e) {
      _showCameraException(e);
      rethrow;
    }
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
    final String dirPath = await ExtStorage.getExternalStoragePublicDirectory(
        ExtStorage.DIRECTORY_DCIM);
    print('exDir：' + dirPath.toString());
    await Directory(dirPath).create(recursive: true);
//    final String dirPath = await ExtStorage.getExternalStoragePublicDirectory(ExtStorage.DIRECTORY_DCIM);
//    await Directory(dirPath).create(recursive: true);
    final String filePath = '$dirPath/${timestamp()}.jpg';

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

  Future<String> _scanFile(File f) async{
    final result = await MediaScannerScanFile.scanFile(f.path);
    return result['filePath'];
  }
}

//class CameraApp extends StatelessWidget {
//  @override
//  Widget build(BuildContext context) {
//    return MaterialApp(
//      debugShowCheckedModeBanner: false,
//      home: CameraView(),
//    );
//  }
//}
