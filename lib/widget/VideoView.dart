import 'dart:async';

import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter/material.dart';

class VideoApp extends StatefulWidget {
  final String videoUrl;

  VideoApp({Key key, this.videoUrl}) : super(key: key);

  @override
  _VideoAppState createState() => _VideoAppState();
}

class _VideoAppState extends State<VideoApp> {
  VideoPlayerController _controller;
  VideoPlayerValue _videoPlayerValue;
  Timer checkVideoPlaying;
  String showTime = '';
  int totalTimeSeconds = 0;
  int totalTimeMinutes = 0;
  int currentTimeSeconds = 0;
  int currentTimeMinutes = 0;
  double percentValue = 0;
  double totalValue = 0;
  double currentValue = 0;
  double progressValue = 0;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network('${widget.videoUrl}')
      ..initialize().then((_) {
        _videoPlayerValue = _controller.value;
        Duration totalDuration = _videoPlayerValue.duration;
        // Ensure the first frame is shown after the video is initialized, even before the play button has been pressed.
        setState(() {
          totalTimeMinutes = parseDuration(totalDuration.toString()).inMinutes;
          totalTimeSeconds = parseDuration(totalDuration.toString()).inSeconds;
          _controller.play();
          countTime();
        });
      });
  }

  Duration parseDuration(String s) {
    int hours = 0;
    int minutes = 0;
    int micros;
    List<String> parts = s.split(':');
    if (parts.length > 2) {
      hours = int.parse(parts[parts.length - 3]);
    }
    if (parts.length > 1) {
      minutes = int.parse(parts[parts.length - 2]);
    }
    micros = (double.parse(parts[parts.length - 1]) * 1000000).round();
    return Duration(hours: hours, minutes: minutes, microseconds: micros);
  }

  void countTime() async {
    checkVideoPlaying =
        new Timer.periodic(Duration(milliseconds: 100), (Timer timer) async {
      Duration currentDuration = await _controller.position;
      Duration totalDuration = _videoPlayerValue.duration;
      totalValue = double.parse(
          (parseDuration(totalDuration.toString()).inMilliseconds).toString());
      currentValue = double.parse(
          (parseDuration(currentDuration.toString()).inMilliseconds)
              .toString());
      percentValue = currentValue / totalValue;

      setState(() {
        if (currentTimeSeconds < 10 && totalTimeSeconds < 10) {
          showTime =
              '$totalTimeMinutes:0$totalTimeSeconds/$currentTimeMinutes:0$currentTimeSeconds';
        } else if (currentTimeSeconds < 10) {
          showTime =
              '$totalTimeMinutes:$totalTimeSeconds/$currentTimeMinutes:0$currentTimeSeconds';
        } else if (totalTimeSeconds < 10) {
          showTime =
              '$totalTimeMinutes:0$totalTimeSeconds/$currentTimeMinutes:$currentTimeSeconds';
        } else {
          showTime =
              '$totalTimeMinutes:$totalTimeSeconds/$currentTimeMinutes:$currentTimeSeconds';
        }
        currentTimeMinutes =
            parseDuration(currentDuration.toString()).inMinutes;
        currentTimeSeconds =
            parseDuration(currentDuration.toString()).inSeconds;
        if (percentValue <= 1) {
          progressValue = percentValue;
        } else if (percentValue > 1) {
          progressValue = 1;
        }
      });
      print('現在進度：$currentValue, $progressValue');

      if (currentValue >= totalValue) {
        print('影片結束了');
        if (checkVideoPlaying!=null){
          checkVideoPlaying.cancel();
          checkVideoPlaying = null;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Container(
            color: Colors.black,
            child: Column(
              children: <Widget>[
                SizedBox(height: 20),
                Expanded(
                    flex: 1,
                    child: Row(
                      children: <Widget>[
                        SizedBox(
                          width: 10,
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton(
                              icon: Icon(Icons.arrow_back),
                              alignment: Alignment.centerLeft,
                              color: Colors.white,
                              onPressed: () {
                                Navigator.of(context).pop();
                              }),
                        )
                      ],
                    )),
                Expanded(
                  flex: 8,
                  child: _controller.value.isInitialized
                      ? AspectRatio(
                          aspectRatio: _controller.value.aspectRatio,
                          child: VideoPlayer(_controller),
                        )
                      : Container(),
                ),
                Expanded(
                    flex: 1,
                    child: Padding(
                      padding: EdgeInsets.only(right: 10),
                      child: new LinearPercentIndicator(
                        lineHeight: 10,
                        percent: progressValue,
                        leading: IconButton(
                          color: Colors.white,
                          icon: _controller.value.isPlaying
                              ? Icon(Icons.pause)
                              : Icon(Icons.play_arrow),
                          iconSize: 32,
                          onPressed: () {
                            setState(() {
                              _controller.value.isPlaying
                                  ? _controller.pause()
                                  : _controller.play();
                              if (currentValue >= totalValue) {
                                var period = Duration(seconds: 0);
                                _controller.seekTo(period);
                                countTime();
                              }
                            });
                          },
                        ),
                        trailing: Text(
                          '$showTime',
                          style: TextStyle(color: Colors.white),
                        ),
                        backgroundColor: Color(0xffE0E0E0),
                        progressColor: Color(0xffdc143c),
                      ),
                    )),
              ],
            )));
  }

  @override
  void dispose() {
    super.dispose();
    if (checkVideoPlaying!=null){
      checkVideoPlaying.cancel();
      checkVideoPlaying = null;
    }
    _controller.dispose();
  }
}
