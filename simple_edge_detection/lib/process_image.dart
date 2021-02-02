import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:ui';
import 'package:ffi/ffi.dart';
import 'package:flutter/material.dart';


class Coordinate extends Struct {
  @Double()
  double x;

  @Double()
  double y;

  factory Coordinate.allocate(double x, double y) =>
      allocate<Coordinate>().ref
        ..x = x
        ..y = y;
}

class NativeDetectionResult extends Struct {
  Pointer<Coordinate> topLeft;
  Pointer<Coordinate> topRight;
  Pointer<Coordinate> bottomLeft;
  Pointer<Coordinate> bottomRight;

  factory NativeDetectionResult.allocate(
      Pointer<Coordinate> topLeft,
      Pointer<Coordinate> topRight,
      Pointer<Coordinate> bottomLeft,
      Pointer<Coordinate> bottomRight) =>
      allocate<NativeDetectionResult>().ref
        ..topLeft = topLeft
        ..topRight = topRight
        ..bottomLeft = bottomLeft
        ..bottomRight = bottomRight;
}

class ImageProcessingResult {
  ImageProcessingResult({
    @required this.topLeft,
    @required this.topRight,
    @required this.bottomLeft,
    @required this.bottomRight,
  });

  Offset topLeft;
  Offset topRight;
  Offset bottomLeft;
  Offset bottomRight;
}

typedef DetectEdgesFunction = Pointer<NativeDetectionResult> Function(
  Pointer<Utf8> imagePath
);

typedef Process_Function = Pointer<NativeDetectionResult> Function(
  Pointer<Utf8> imagePath,
  Pointer<Utf8> imageOutPath,
  Pointer<Utf8> mergeOutPath,
  Int32 roi1,
  Int32 roi2,
  Int32 roi3,
  Int32 roi4,
  Int32 roi5,
  Int32 roi6,
  Int32 roi7,
  Int32 roi8,
  Int32 roi9,
  Int32 roi10,
  Int32 roi11,
  Int32 roi12,
  Int32 roi13,
  Int32 roi14,
  Int32 roi15,
  Int32 roi16,
  Int32 roi17,
  Int32 roi18,
  Int32 roi19,
  Int32 roi20,
);

typedef ImageProcessing = Pointer<NativeDetectionResult> Function(
  Pointer<Utf8> imagePath,
  Pointer<Utf8> imageOutPath,
  Pointer<Utf8> mergeOutPath,
  int roi1,
  int roi2,
  int roi3,
  int roi4,
  int roi5,
  int roi6,
  int roi7,
  int roi8,
  int roi9,
  int roi10,
  int roi11,
  int roi12,
  int roi13,
  int roi14,
  int roi15,
  int roi16,
  int roi17,
  int roi18,
  int roi19,
  int roi20
);

// https://github.com/dart-lang/samples/blob/master/ffi/structs/structs.dart

class ProcessImage { 
  static Future<ImageProcessingResult> processImage(String input, String outputClean, String outputMerge, 
                                            dynamic roi1, dynamic roi2, dynamic roi3, dynamic roi4,
                                            dynamic roi5, dynamic roi6, dynamic roi7, dynamic roi8,
                                            dynamic roi9, dynamic roi10, dynamic roi11, dynamic roi12,
                                            dynamic roi13, dynamic roi14, dynamic roi15, dynamic roi16,
                                            dynamic roi17, dynamic roi18, dynamic roi19, dynamic roi20) async {

    DynamicLibrary nativeEdgeDetection = _getDynamicLibrary();    
    
    final processImage = nativeEdgeDetection
        .lookup<NativeFunction<Process_Function>>("image_processing")
        .asFunction<ImageProcessing>();    
    
    NativeDetectionResult detectionResult = processImage(Utf8.toUtf8(input), Utf8.toUtf8(outputClean), Utf8.toUtf8(outputMerge), 
                        roi1, roi2, roi3, roi4, roi5,roi6, roi7, roi8, roi9, roi10, roi11, roi12, roi13, roi14, roi15, roi16, roi17, roi18, roi19, roi20).ref;

    return ImageProcessingResult(
        topLeft: Offset(
            detectionResult.topLeft.ref.x, detectionResult.topLeft.ref.y
        ),
        topRight: Offset(
            detectionResult.topRight.ref.x, detectionResult.topRight.ref.y
        ),
        bottomLeft: Offset(
            detectionResult.bottomLeft.ref.x, detectionResult.bottomLeft.ref.y
        ),
        bottomRight: Offset(
            detectionResult.bottomRight.ref.x, detectionResult.bottomRight.ref.y
        )
    );
  
  }  

  static DynamicLibrary _getDynamicLibrary() {
    final DynamicLibrary nativeEdgeDetection = Platform.isAndroid
        ? DynamicLibrary.open("libnative_edge_detection.so")
        : DynamicLibrary.process();
    return nativeEdgeDetection;
  }
}