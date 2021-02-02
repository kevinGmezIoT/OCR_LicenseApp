import 'package:flutter/material.dart';
import 'package:image/image.dart' as imglib;

class ImagePreview extends StatelessWidget {

  final imglib.Image img;
  final String text1;
  final String text2;
  final String text3;
  final String text4;
  final String text5;
  final String text6;

  const ImagePreview({Key key, this.img, this.text1, this.text2, this.text3, this.text4, this.text5, this.text6}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Preview Image"),
      ),
      body: Stack(
        children: [Center(
                        child: Image.memory(imglib.encodeJpg(img))
                          ),
                    Positioned(left: 120,
                                top: 500,
                                child: Column(
                                  children: [
                                    Text("Title: $text1"),
                                    Text("Last name: $text2"),
                                    Text("Name: $text3"),
                                    Text("Number: $text4"),
                                    Text("DOB: $text5"),
                                    Text("Detection Time: $text6")
                                  ]
                                ),)
                    ],
                  )      
    );
  }
}