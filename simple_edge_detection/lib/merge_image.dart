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


typedef DetectEdgesFunction = Pointer<NativeDetectionResult> Function(
  Pointer<Utf8> imagePath
);

typedef DetectWarp_Function = Pointer<Utf8> Function(
  Pointer<Utf8> imagePath1,
  Pointer<Utf8> imagePath2,
  Pointer<Utf8> imagePath3,
  Pointer<Utf8> imagePath4,
  Pointer<Utf8> imagePath5,
  Pointer<Utf8> imageOutPath,
);

typedef DetectWarp = Pointer<Utf8> Function(
  Pointer<Utf8> imagePath1,
  Pointer<Utf8> imagePath2,
  Pointer<Utf8> imagePath3,
  Pointer<Utf8> imagePath4,
  Pointer<Utf8> imagePath5,
  Pointer<Utf8> imageOutPath,
);

// https://github.com/dart-lang/samples/blob/master/ffi/structs/structs.dart

class MergeImage { 
  static Future<Pointer<Utf8>> mergeImage(String input1, String input2, String input3, String input4, String input5, String out) async {
    DynamicLibrary nativeEdgeDetection = _getDynamicLibrary();    
    
    final Pointer<Utf8> Function(Pointer<Utf8> imagePath1, Pointer<Utf8> imagePath2, Pointer<Utf8> imagePath3, Pointer<Utf8> imagePath4, Pointer<Utf8> imagePath5, Pointer<Utf8> imageOutPath) mergeImage = nativeEdgeDetection
        .lookup<NativeFunction<DetectWarp_Function>>("image_merge")
        .asFunction<DetectWarp >();    
    
    return mergeImage(Utf8.toUtf8(input1), Utf8.toUtf8(input2), Utf8.toUtf8(input3), Utf8.toUtf8(input4), Utf8.toUtf8(input5), Utf8.toUtf8(out));
  }  

  static DynamicLibrary _getDynamicLibrary() {
    final DynamicLibrary nativeEdgeDetection = Platform.isAndroid
        ? DynamicLibrary.open("libnative_edge_detection.so")
        : DynamicLibrary.process();
    return nativeEdgeDetection;
  }
}