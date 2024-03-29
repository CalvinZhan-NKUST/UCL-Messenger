import 'package:photo_view/photo_view.dart';
import 'package:flutter/material.dart';

class ImageApp extends StatefulWidget {
  final String imageUrl;

  ImageApp({Key key, this.imageUrl}) : super(key: key);

  @override
  _ImageAppState createState() => _ImageAppState();
}

class _ImageAppState extends State<ImageApp> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Container(
            color: Colors.black,
            child: Column(
              children: <Widget>[
                SizedBox(height: 20,),
                Expanded(
                  flex: 1,
                  child: Row(
                    children: <Widget>[
                      SizedBox(width: 10,),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                            icon: Icon(Icons.arrow_back),
                            alignment: Alignment.centerLeft,
                            color: Colors.white,
                            onPressed: () {
                              Navigator.of(context).pop();
                            }),
                      ),
                    ],
                  )
                ),
                Expanded(
                  flex: 9,
                  child: PhotoView(
                    imageProvider: NetworkImage('${widget.imageUrl}'),
                    minScale: 1.0,
                    maxScale: 3.0,
                    enableRotation: false,
                  ),
                )
              ],
            )));
  }
}
